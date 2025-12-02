import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase service initialization and management
class FirebaseService {
  static bool _initialized = false;

  /// Initialize Firebase with provided options
  /// Returns true if initialization is successful, false otherwise
  static Future<bool> initialize(FirebaseOptions options) async {
    if (_initialized) {
      if (kDebugMode) {
        print('Firebase already initialized');
      }
      return true;
    }

    try {
      await Firebase.initializeApp(options: options);
      _initialized = true;
      if (kDebugMode) {
        print('Firebase initialized successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase initialization failed: $e');
        print('App will continue running without Firebase services');
      }
      return false;
    }
  }

  /// Check if Firebase is initialized
  static bool get isInitialized => _initialized;
}
