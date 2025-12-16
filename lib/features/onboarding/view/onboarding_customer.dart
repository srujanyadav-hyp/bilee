import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';

/// Customer Onboarding Screen
/// Single role-specific onboarding for customers
class CustomerOnboardingScreen extends StatefulWidget {
  const CustomerOnboardingScreen({super.key});

  @override
  State<CustomerOnboardingScreen> createState() =>
      _CustomerOnboardingScreenState();
}

class _CustomerOnboardingScreenState extends State<CustomerOnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Analytics: onboarding_customer_viewed
    debugPrint('Analytics: onboarding_customer_viewed');

    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.paddingLG),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 1),
                  // Illustration Area
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusLG,
                      ),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      size: 120,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingXL),
                  // Title
                  Text(
                    'Customer — Scan.\nSave. Simple.',
                    style: AppTypography.h1.copyWith(
                      color: AppColors.lightTextPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppDimensions.spacingMD),
                  // Body Copy
                  Text(
                    'Scan merchant QR. Collect digital receipts. Filter & search. 100% paperless.',
                    style: AppTypography.body1.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppDimensions.spacingLG),
                  // Bullet List
                  _BulletItem(
                    icon: Icons.qr_code_scanner_outlined,
                    text: 'Scan merchant QR codes',
                  ),
                  SizedBox(height: AppDimensions.spacingSM),
                  _BulletItem(
                    icon: Icons.receipt_long_outlined,
                    text: 'All receipts in one place',
                  ),
                  SizedBox(height: AppDimensions.spacingSM),
                  _BulletItem(
                    icon: Icons.search_outlined,
                    text: 'Search & filter by date or merchant',
                  ),
                  const Spacer(flex: 2),
                  // Primary Action
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _getStarted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMD,
                          ),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Get Started',
                        style: AppTypography.button.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingMD),
                  // Secondary Action
                  TextButton(
                    onPressed: _signIn,
                    child: Text(
                      'Already have an account? Sign in',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingSM),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _getStarted() async {
    // Analytics: onboarding_customer_continue
    debugPrint('Analytics: onboarding_customer_continue');

    // Mark onboarding as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      context.go('/login');
    }
  }

  void _signIn() async {
    // Mark onboarding as completed even if signing in
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    if (mounted) {
      context.go('/login');
    }
  }
}

/// Bullet Item Widget
class _BulletItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BulletItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: AppColors.primaryBlue),
        ),
        SizedBox(width: AppDimensions.spacingMD),
        Expanded(
          child: Text(
            text,
            style: AppTypography.body1.copyWith(
              color: AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
