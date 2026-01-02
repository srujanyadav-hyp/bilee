import 'package:firebase_auth/firebase_auth.dart';

/// Centralized error handler for Firebase errors
/// Converts technical Firebase errors into user-friendly messages
class FirebaseErrorHandler {
  /// Convert Firebase Auth errors to user-friendly messages
  static String handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
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
          return 'This sign-in method is not available.';
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
          return 'Login failed. Please try again.';
      }
    }
    return 'An error occurred. Please try again.';
  }

  /// Convert Firestore errors to user-friendly messages
  static String handleFirestoreError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Access denied. Please check your connection and try again.';
        case 'unavailable':
          return 'Service temporarily unavailable. Please try again.';
        case 'not-found':
          return 'Data not found. It may have been deleted.';
        case 'already-exists':
          return 'This data already exists.';
        case 'resource-exhausted':
          return 'Too many requests. Please try again later.';
        case 'failed-precondition':
          return 'Operation failed. Please try again.';
        case 'aborted':
          return 'Operation cancelled. Please try again.';
        case 'out-of-range':
          return 'Invalid data. Please check and try again.';
        case 'unimplemented':
          return 'This feature is not available yet.';
        case 'internal':
          return 'Server error. Please try again later.';
        case 'deadline-exceeded':
          return 'Request took too long. Please try again.';
        case 'unauthenticated':
          return 'Please log in to continue.';
        case 'cancelled':
          return 'Operation was cancelled.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }

    // Handle network errors
    if (error.toString().contains('network') ||
        error.toString().contains('SocketException')) {
      return 'No internet connection. Please check and try again.';
    }

    // Generic fallback
    return 'Something went wrong. Please try again.';
  }

  /// Generic error handler - automatically detects error type
  static String handleError(dynamic error) {
    if (error is FirebaseAuthException) {
      return handleAuthError(error);
    } else if (error is FirebaseException) {
      return handleFirestoreError(error);
    } else if (error is Exception) {
      // Check for specific exception messages
      final errorMessage = error.toString().toLowerCase();

      if (errorMessage.contains('permission')) {
        return 'Access denied. Please try again.';
      } else if (errorMessage.contains('network') ||
          errorMessage.contains('socket')) {
        return 'No internet connection. Please check and try again.';
      } else if (errorMessage.contains('timeout')) {
        return 'Request timed out. Please try again.';
      }
    }

    // Final fallback
    return 'Something went wrong. Please try again.';
  }

  /// Log error for debugging (in debug mode only)
  static void logError(
    String context,
    dynamic error, {
    StackTrace? stackTrace,
  }) {
    // In debug mode, print detailed error
    assert(() {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔴 ERROR in $context');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('Error: $error');
      if (stackTrace != null) {
        print('Stack trace:\n$stackTrace');
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return true;
    }());

    // In production, you could send to crash reporting service
    // e.g., Firebase Crashlytics, Sentry, etc.
  }
}
