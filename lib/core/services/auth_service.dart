import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'bilee',
  );
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final RoleStorageService _roleStorage = RoleStorageService();

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Analytics callback
  Function(String, Map<String, dynamic>)? onAnalyticsEvent;

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      _logAnalytics('auth_attempt', {'method': 'email', 'action': 'sign_in'});

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        _logAnalytics('auth_attempt', {'method': 'email', 'success': true});

        // Check if user document exists, if not create it
        final userDoc = await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (!userDoc.exists) {
          // User signed in but no document exists (shouldn't happen, but handle it)
          debugPrint('Warning: User signed in but no Firestore document found');
        }

        return AuthResult.success(credential.user!.uid);
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

        return AuthResult.success(credential.user!.uid);
      }

      return AuthResult.failure('Registration failed');
    } on FirebaseAuthException catch (e) {
      _logAnalytics('auth_attempt', {
        'method': 'email',
        'success': false,
        'error': e.code,
      });
      return AuthResult.failure(_getAuthErrorMessage(e));
    } catch (e) {
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

        if (!userDoc.exists && registrationData != null) {
          // Create new user document for registration
          await _createUserDocument(
            uid: userCredential.user!.uid,
            role: registrationData.role,
            displayName: registrationData.displayName,
            phone: registrationData.phone,
            category: registrationData.category,
          );

          _logAnalytics('user_registered', {
            'method': 'phone',
            'role': registrationData.role,
          });
        }

        _logAnalytics('otp_verified', {
          'role': registrationData?.role ?? 'existing',
        });

        return AuthResult.success(userCredential.user!.uid);
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

          _logAnalytics('user_registered', {'method': 'google', 'role': role});
        }

        _logAnalytics('auth_attempt', {'method': 'google', 'success': true});

        return AuthResult.success(userCredential.user!.uid);
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
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'role': role,
      'display_name': displayName,
      'email': email,
      'phone': phone,
      'category': category,
      'kyc_status': role == 'merchant' ? 'PENDING' : null,
      'created_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Store role locally
    await _roleStorage.saveRole(role);
  }

  /// Get user-friendly error message
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'user-not-found':
        return 'No account found. Create one.';
      case 'email-already-in-use':
        return 'Email already in use. Sign in instead.';
      case 'weak-password':
        return 'Password must be 8+ characters.';
      case 'invalid-email':
        return 'Please enter a valid email.';
      case 'network-request-failed':
        return 'Network error — check connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'invalid-verification-code':
        return 'Invalid code. Please try again.';
      case 'invalid-phone-number':
        return 'Invalid phone number format.';
      default:
        return e.message ?? 'Authentication failed. Try again.';
    }
  }

  /// Log analytics event
  void _logAnalytics(String eventName, Map<String, dynamic> params) {
    onAnalyticsEvent?.call(eventName, params);
    debugPrint('Analytics: $eventName - $params');
  }
}
