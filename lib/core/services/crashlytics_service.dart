import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crashlytics Service
///
/// Centralized crash reporting and error logging service.
/// Automatically captures crashes, errors, and custom logs.
///
/// Features:
/// - Automatic crash reporting
/// - Custom error logging
/// - User context tracking
/// - Custom keys for debugging
class CrashlyticsService {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Initialize Crashlytics
  /// Call this in main() before runApp()
  static Future<void> initialize() async {
    // Enable crash collection in release mode
    if (kReleaseMode) {
      await _crashlytics.setCrashlyticsCollectionEnabled(true);
    }

    // Pass all uncaught errors to Crashlytics
    FlutterError.onError = _crashlytics.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    debugPrint('✅ Crashlytics initialized');
  }

  /// Log a message to Crashlytics
  ///
  /// Useful for tracking app flow before a crash
  ///
  /// Example:
  /// ```dart
  /// CrashlyticsService.log('User started billing session');
  /// ```
  static void log(String message) {
    _crashlytics.log(message);
    debugPrint('📝 Crashlytics log: $message');
  }

  /// Record a non-fatal error
  ///
  /// Use this for caught exceptions that you want to track
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await riskyOperation();
  /// } catch (e, stack) {
  ///   CrashlyticsService.recordError(e, stack, reason: 'Failed to sync data');
  /// }
  /// ```
  static Future<void> recordError(
    dynamic error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? context,
  }) async {
    // Add context as custom keys
    if (context != null) {
      for (final entry in context.entries) {
        await setCustomKey(entry.key, entry.value);
      }
    }

    // Add reason if provided
    if (reason != null) {
      await setCustomKey('error_reason', reason);
    }

    await _crashlytics.recordError(error, stack, reason: reason, fatal: fatal);

    debugPrint('❌ Error recorded to Crashlytics: $error');
  }

  /// Set user identifier for crash reports
  ///
  /// Helps identify which user experienced the crash
  ///
  /// Example:
  /// ```dart
  /// CrashlyticsService.setUserId(FirebaseAuth.instance.currentUser?.uid);
  /// ```
  static Future<void> setUserId(String? userId) async {
    if (userId != null) {
      await _crashlytics.setUserIdentifier(userId);
      debugPrint('👤 Crashlytics user ID set: $userId');
    }
  }

  /// Set custom key-value pair for debugging
  ///
  /// These appear in crash reports to help debug issues
  ///
  /// Example:
  /// ```dart
  /// CrashlyticsService.setCustomKey('merchant_id', merchantId);
  /// CrashlyticsService.setCustomKey('session_count', sessionCount);
  /// ```
  static Future<void> setCustomKey(String key, dynamic value) async {
    await _crashlytics.setCustomKey(key, value);
  }

  /// Force a crash (for testing only!)
  ///
  /// Use this to test if Crashlytics is working
  /// DO NOT use in production code
  static void forceCrash() {
    if (kDebugMode) {
      throw Exception('Test crash from Crashlytics');
    }
  }

  /// Check if crash reporting is enabled
  static Future<bool> isCrashlyticsCollectionEnabled() async {
    return _crashlytics.isCrashlyticsCollectionEnabled;
  }

  /// Enable/disable crash reporting
  ///
  /// Useful for respecting user privacy preferences
  static Future<void> setCrashlyticsCollectionEnabled(bool enabled) async {
    await _crashlytics.setCrashlyticsCollectionEnabled(enabled);
    debugPrint('🔧 Crashlytics collection ${enabled ? 'enabled' : 'disabled'}');
  }
}
