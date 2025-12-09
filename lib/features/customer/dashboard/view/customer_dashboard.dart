import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/auth_service.dart';

/// Customer Dashboard Screen (Placeholder)
class CustomerDashboardScreen extends StatelessWidget {
  const CustomerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.tealAccent,
        title: Text(
          'Customer Dashboard',
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/auth/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.paddingLG),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.tealAccent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 60,
                    color: AppColors.tealAccent,
                  ),
                ),
              ),
              SizedBox(height: AppDimensions.spacingXL),
              // Welcome Text
              Text(
                'Welcome, Customer!',
                style: AppTypography.h1.copyWith(
                  color: AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimensions.spacingMD),
              Text(
                'Your customer dashboard is under construction.',
                style: AppTypography.body1.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimensions.spacingXL),
              // Info Container
              Container(
                padding: EdgeInsets.all(AppDimensions.paddingMD),
                decoration: BoxDecoration(
                  color: AppColors.tealAccent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  border: Border.all(
                    color: AppColors.tealAccent.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppColors.success,
                          size: 20,
                        ),
                        SizedBox(width: AppDimensions.spacingSM),
                        Text(
                          'Authentication successful',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppDimensions.spacingSM),
                    Row(
                      children: [
                        Icon(
                          Icons.badge,
                          color: AppColors.tealAccent,
                          size: 20,
                        ),
                        SizedBox(width: AppDimensions.spacingSM),
                        Text(
                          'Role: Customer',
                          style: AppTypography.body2.copyWith(
                            color: AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
