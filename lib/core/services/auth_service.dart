import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/auth_models.dart';
import './role_storage_service.dart';

/// Authentication Service
/// Handles all Firebase Authentication operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final RoleStorageService _roleStorage = RoleStorageService();

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Analytics callback
  Function(String, Map<String, dynamic>)? onAnalyticsEvent;

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail(
    String email,
    String password, {
    String? selectedRole,
  }) async {
    try {
      _logAnalytics('auth_attempt', {'method': 'email', 'action': 'sign_in'});

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        // Authentication successful - now validate role and user data
        try {
          // Check if user document exists
          final userDoc = await _firestore
              .collection('users')
              .doc(credential.user!.uid)
              .get();

          if (!userDoc.exists) {
            // User signed in but no document exists (shouldn't happen, but handle it)
            debugPrint(
              'Warning: User signed in but no Firestore document found',
            );
            await _auth.signOut();
            return AuthResult.failure(
              'Account setup incomplete. Please contact support.',
            );
          }

          // Validate role if provided
          if (selectedRole != null) {
            final userData = userDoc.data();
            final storedRole = userData?['role'] as String?;

            if (storedRole != null && storedRole != selectedRole) {
              await _auth.signOut();
              debugPrint(
                '❌ Role mismatch: User registered as $storedRole but tried to sign in as $selectedRole',
              );
              return AuthResult.failure(
                'This account is registered as ${storedRole == "merchant" ? "Merchant" : "Customer"}. Please select the correct role.',
              );
            }
          }

          _logAnalytics('auth_attempt', {'method': 'email', 'success': true});
          return AuthResult.success(credential.user!.uid);
        } catch (firestoreError) {
          // Firestore error - but user is authenticated
          debugPrint('Firestore error after authentication: $firestoreError');
          // User is authenticated, so let them through despite Firestore issue
          _logAnalytics('auth_attempt', {
            'method': 'email',
            'success': true,
            'firestore_warning': true,
          });
          return AuthResult.success(credential.user!.uid);
        }
      }

      return AuthResult.failure('Sign in failed');
    } on FirebaseAuthException catch (e) {
      _logAnalytics('auth_attempt', {
        'method': 'email',
        'success': false,
        'error': e.code,
      });
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      debugPrint('Sign in error: $e');
      return AuthResult.failure(
        'Network error — check connection and try again.',
      );
    }
  }

  /// Register with email and password
  Future<AuthResult> registerWithEmail(RegistrationData data) async {
    try {
      _logAnalytics('auth_attempt', {
        'method': 'email',
        'action': 'register',
        'role': data.role,
      });

      final credential = await _auth.createUserWithEmailAndPassword(
        email: data.email!.trim(),
        password: data.password!,
      );

      if (credential.user != null) {
        // Wait for auth state to propagate
        await Future.delayed(const Duration(milliseconds: 500));

        // Create user document
        await _createUserDocument(
          uid: credential.user!.uid,
          role: data.role,
          displayName: data.displayName,
          email: data.email,
          category: data.category,
        );

        _logAnalytics('user_registered', {
          'method': 'email',
          'role': data.role,
        });

        return AuthResult.success(credential.user!.uid, isNewUser: true);
      }

      return AuthResult.failure('Registration failed');
    } on FirebaseAuthException catch (e) {
      _logAnalytics('auth_attempt', {
        'method': 'email',
        'success': false,
        'error': e.code,
      });
      return AuthResult.failure(_getAuthErrorMessage(e));
    } on FirebaseException catch (e) {
      // Handle Firestore errors (e.g., permission-denied)
      debugPrint(
        'Firestore error during registration: ${e.code} - ${e.message}',
      );
      if (e.code == 'permission-denied') {
        return AuthResult.failure(
          'Account created but profile setup failed. Please contact support.',
        );
      }
      return AuthResult.failure('Setup error — contact support.');
    } catch (e) {
      debugPrint('Registration error: $e');
      return AuthResult.failure(
        'Network error — check connection and try again.',
      );
    }
  }

  /// Send OTP to phone
  Future<void> sendOTP({
    required String phoneNumber,
    required String countryCode,
    required Function(String) onCodeSent,
    required Function(String) onError,
    required Function() onAutoVerify,
  }) async {
    try {
      final fullNumber = '$countryCode$phoneNumber';

      _logAnalytics('otp_sent', {'phone_country': countryCode});

      await _auth.verifyPhoneNumber(
        phoneNumber: fullNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          await _auth.signInWithCredential(credential);
          onAutoVerify();
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_getAuthErrorMessage(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Timeout
        },
      );
    } catch (e) {
      onError('Failed to send OTP. Try again.');
    }
  }

  /// Verify OTP and sign in
  Future<AuthResult> verifyOTP({
    required String verificationId,
    required String smsCode,
    required RegistrationData? registrationData,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Check if user document exists
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        bool isNewUser = false;

        if (!userDoc.exists && registrationData != null) {
          // Create new user document for registration
          await _createUserDocument(
            uid: userCredential.user!.uid,
            role: registrationData.role,
            displayName: registrationData.displayName,
            phone: '${registrationData.countryCode}${registrationData.phone}',
            category: registrationData.category,
          );

          isNewUser = true;

          _logAnalytics('user_registered', {
            'method': 'phone',
            'role': registrationData.role,
          });
        } else if (!userDoc.exists && registrationData == null) {
          // User trying to login but no Firestore document exists
          await _auth.signOut();
          return AuthResult.failure(
            'Account not found. Please register first.',
          );
        } else if (userDoc.exists && registrationData != null) {
          // Existing user trying to register - validate role
          final userData = userDoc.data();
          final storedRole = userData?['role'] as String?;

          if (storedRole != null && storedRole != registrationData.role) {
            await _auth.signOut();
            debugPrint(
              '❌ Role mismatch: User registered as $storedRole but tried to sign in as ${registrationData.role}',
            );
            return AuthResult.failure(
              'This account is registered as ${storedRole == "merchant" ? "Merchant" : "Customer"}. Please select the correct role.',
            );
          }
        }

        _logAnalytics('otp_verified', {
          'role': registrationData?.role ?? 'existing',
        });

        return AuthResult.success(
          userCredential.user!.uid,
          isNewUser: isNewUser,
        );
      }

      return AuthResult.failure('Verification failed');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        return AuthResult.failure('Invalid code. Please try again.');
      }
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('Verification failed. Try again.');
    }
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle({String? selectedRole}) async {
    try {
      _logAnalytics('auth_method_selected', {'method': 'google'});

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return AuthResult.failure('Google sign-in cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Check if user document exists
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        bool isNewUser = false;

        if (!userDoc.exists) {
          // New user - need role
          String? role = selectedRole ?? await _roleStorage.getRole();

          if (role == null) {
            // Sign out and ask for role selection
            await _auth.signOut();
            return AuthResult.failure('NEED_ROLE_SELECTION');
          }

          await _createUserDocument(
            uid: userCredential.user!.uid,
            role: role,
            displayName: userCredential.user!.displayName ?? 'User',
            email: userCredential.user!.email,
          );

          isNewUser = true;

          _logAnalytics('user_registered', {'method': 'google', 'role': role});
        } else if (selectedRole != null) {
          // Existing user - validate role
          final userData = userDoc.data();
          final storedRole = userData?['role'] as String?;

          if (storedRole != null && storedRole != selectedRole) {
            await _auth.signOut();
            debugPrint(
              '❌ Role mismatch: User registered as $storedRole but tried to sign in as $selectedRole',
            );
            return AuthResult.failure(
              'This account is registered as ${storedRole == "merchant" ? "Merchant" : "Customer"}. Please select the correct role.',
            );
          }
        }

        _logAnalytics('auth_attempt', {'method': 'google', 'success': true});

        return AuthResult.success(
          userCredential.user!.uid,
          isNewUser: isNewUser,
        );
      }

      return AuthResult.failure('Google sign-in failed');
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      if (e.toString().contains('PlatformException')) {
        return AuthResult.failure(
          'Google sign-in unavailable — try email or phone',
        );
      }
      return AuthResult.failure(
        'Network error — check connection and try again.',
      );
    }
  }

  /// Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success('');
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('Failed to send reset email. Try again.');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  /// Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromFirestore(doc.data()!);
      }
      debugPrint('User document does not exist for UID: $uid');
      return null;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      // If Firestore database doesn't exist, return null gracefully
      if (e.toString().contains('NOT_FOUND') ||
          e.toString().contains('does not exist')) {
        debugPrint(
          'Firestore database not initialized. Please create it in Firebase Console.',
        );
      }
      return null;
    }
  }

  /// Create user document in Firestore
  Future<void> _createUserDocument({
    required String uid,
    required String role,
    required String displayName,
    String? email,
    String? phone,
    String? category,
  }) async {
    try {
      debugPrint('🔵 Creating user document for UID: $uid');
      debugPrint('🔵 Current auth user: ${_auth.currentUser?.uid}');
      debugPrint('🔵 Role: $role, DisplayName: $displayName');

      final userData = <String, dynamic>{
        'uid': uid,
        'role': role,
        'display_name': displayName,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };

      // Add optional fields only if they exist
      if (email != null && email.isNotEmpty) {
        userData['email'] = email;
      }
      if (phone != null && phone.isNotEmpty) {
        userData['phone'] = phone;
      }
      if (category != null && category.isNotEmpty) {
        userData['category'] = category;
      }
      if (role == 'merchant') {
        userData['kyc_status'] = 'PENDING';
      }

      await _firestore
          .collection('users')
          .doc(uid)
          .set(userData, SetOptions(merge: true));

      // Store role locally
      await _roleStorage.saveRole(role);

      debugPrint('✅ User document created successfully for UID: $uid');
      debugPrint('📝 User data: ${userData.keys.toList()}');
    } on FirebaseException catch (e) {
      debugPrint('❌ Error creating user document: ${e.code} - ${e.message}');
      debugPrint('📋 Error details: ${e.toString()}');
      throw Exception('Failed to create user profile: ${e.message}');
    } catch (e) {
      debugPrint('❌ Error creating user document: $e');
      rethrow;
    }
  }

  /// Get user-friendly error message
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
        return 'Wrong password. Please try again.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak. Use 8+ characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'invalid-credential':
        return 'Wrong email or password.';
      case 'invalid-login-credentials':
        return 'Wrong email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'Sign in method not enabled. Contact support.';
      case 'network-request-failed':
        return 'No internet connection. Please check and try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'invalid-verification-code':
        return 'Wrong OTP code. Please try again.';
      case 'invalid-phone-number':
        return 'Invalid phone number.';
      case 'requires-recent-login':
        return 'Please log out and log in again.';
      case 'expired-action-code':
        return 'This link has expired.';
      default:
        // Catch-all for any other errors
        return 'Login failed. Please check your email and password.';
    }
  }

  /// Log analytics event
  void _logAnalytics(String eventName, Map<String, dynamic> params) {
    onAnalyticsEvent?.call(eventName, params);
    debugPrint('Analytics: $eventName - $params');
  }
}
