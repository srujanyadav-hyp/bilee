import 'package:flutter/material.dart';
import '../../../../widgets/splash_animation.dart';

/// Splash Screen Page
/// Uses SplashAnimation widget for the animated splash sequence
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashAnimation();
  }
}
