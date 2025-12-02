import 'package:flutter/material.dart';
import 'package:bilee/core/constants/colors.dart';
import 'package:bilee/core/router.dart';

/// Splash screen placeholder with app logo
class SplashPlaceholder extends StatefulWidget {
  const SplashPlaceholder({super.key});

  @override
  State<SplashPlaceholder> createState() => _SplashPlaceholderState();
}

class _SplashPlaceholderState extends State<SplashPlaceholder> {
  @override
  void initState() {
    super.initState();
    _navigateToWelcome();
  }

  /// Navigate to welcome screen after delay
  Future<void> _navigateToWelcome() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppRouter.welcomeSlide1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryVariant,
              AppColors.secondaryVariant,
            ],
          ),
        ),
        child: Center(
          child: Image.asset(
            'assets/logos/logo_symbol_white.png',
            width: 200,
            height: 200,
          ),
        ),
      ),
    );
  }
}
