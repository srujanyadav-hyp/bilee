import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bilee/firebase_options_dev.dart';
import 'package:bilee/core/services/firebase_service.dart';
import 'package:bilee/core/router.dart';
import 'package:bilee/core/theme/app_theme.dart';
import 'package:bilee/widgets/splash_placeholder.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with placeholder options (guarded)
  try {
    await Firebase.initializeApp(options: firebaseOptions);

    // Initialize Firebase services (Crashlytics, Analytics, etc.) - Phase 0 safe stubs
    await FirebaseService().init();
  } catch (e) {
    if (kDebugMode) {
      print('Firebase initialization error: $e');
      print('App will continue without Firebase');
    }
  } // Global error handler stub
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
    // TODO: Add Crashlytics reporting when real credentials are configured
  };

  runApp(const BileeApp());
}

class BileeApp extends StatelessWidget {
  const BileeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bilee',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.welcomeSlide1,
      routes: AppRouter.routes,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const SplashPlaceholder(),
    );
  }
}
