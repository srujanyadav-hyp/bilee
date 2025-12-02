import 'package:flutter/foundation.dart';

/// Firebase service for managing Firebase-related operations
/// Phase 0: Safe placeholder stubs that won't crash if Firebase isn't configured
class FirebaseService {
  /// Initialize Firebase services (Crashlytics, Analytics, etc.)
  ///
  /// Phase 0: Safe stub that handles initialization failures gracefully
  /// TODO Phase 1: Add real Crashlytics initialization with FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled()
  /// TODO Phase 1: Add real Analytics initialization with FirebaseAnalytics.instance
  /// TODO Phase 1: Enable Firebase Remote Config if needed
  Future<void> init() async {
    try {
      if (kDebugMode) {
        print('FirebaseService.init() - Phase 0 stub');
      }

      // TODO Phase 1: Initialize Firebase Crashlytics
      // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

      // TODO Phase 1: Initialize Firebase Analytics
      // await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

      if (kDebugMode) {
        print('Firebase services initialized successfully (stub mode)');
      }
    } catch (e) {
      // Safe: App continues even if Firebase services fail
      if (kDebugMode) {
        print('Firebase service initialization failed: $e');
        print('App will continue running without Firebase services');
      }
    }
  }

  /// Sign in anonymously for development/testing
  ///
  /// Phase 0: Returns dummy UID without calling real Firebase
  /// TODO Phase 1: Replace with real Firebase Auth anonymous sign-in
  /// TODO Phase 1: Call FirebaseAuth.instance.signInAnonymously()
  Future<String> signInAnonymously() async {
    try {
      if (kDebugMode) {
        print('FirebaseService.signInAnonymously() - Phase 0 stub');
      }

      // TODO Phase 1: Replace with real Firebase Auth call
      // final userCredential = await FirebaseAuth.instance.signInAnonymously();
      // return userCredential.user?.uid ?? 'unknown';

      // Phase 0: Return dummy UID for development
      const devAnonymousUid = 'dev-anon-uid-placeholder';

      if (kDebugMode) {
        print('Anonymous sign-in successful (stub): $devAnonymousUid');
      }

      return devAnonymousUid;
    } catch (e) {
      // Safe: Return placeholder UID even on error
      if (kDebugMode) {
        print('Anonymous sign-in failed: $e');
        print('Returning placeholder UID');
      }
      return 'dev-anon-uid-error';
    }
  }
}
