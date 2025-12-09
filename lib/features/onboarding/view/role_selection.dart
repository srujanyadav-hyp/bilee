import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/services/role_storage_service.dart';

/// Role Selection Screen
/// First onboarding step where user chooses between Merchant or Customer
class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  final RoleStorageService _roleStorage = RoleStorageService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),
              // Title
              Text(
                'Choose your role',
                style: AppTypography.h2.copyWith(
                  color: AppColors.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimensions.spacingLG),
              // Role Cards
              Expanded(
                flex: 4,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isSmallScreen = constraints.maxWidth < 600;
                    return isSmallScreen
                        ? Column(
                            children: [
                              Expanded(
                                child: _RoleCard(
                                  role: 'merchant',
                                  icon: Icons.store_outlined,
                                  label: 'Merchant',
                                  subtext: 'Create bills & manage daily totals',
                                  isSelected: _selectedRole == 'merchant',
                                  onTap: () => _selectRole('merchant'),
                                ),
                              ),
                              SizedBox(height: AppDimensions.spacingMD),
                              Expanded(
                                child: _RoleCard(
                                  role: 'customer',
                                  icon: Icons.person_outline,
                                  label: 'Customer',
                                  subtext: 'Scan QR & save receipts',
                                  isSelected: _selectedRole == 'customer',
                                  onTap: () => _selectRole('customer'),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _RoleCard(
                                  role: 'merchant',
                                  icon: Icons.store_outlined,
                                  label: 'Merchant',
                                  subtext: 'Create bills & manage daily totals',
                                  isSelected: _selectedRole == 'merchant',
                                  onTap: () => _selectRole('merchant'),
                                ),
                              ),
                              SizedBox(width: AppDimensions.spacingMD),
                              Expanded(
                                child: _RoleCard(
                                  role: 'customer',
                                  icon: Icons.person_outline,
                                  label: 'Customer',
                                  subtext: 'Scan QR & save receipts',
                                  isSelected: _selectedRole == 'customer',
                                  onTap: () => _selectRole('customer'),
                                ),
                              ),
                            ],
                          );
                  },
                ),
              ),
              const Spacer(flex: 1),
              // Continue Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedRole != null ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    disabledBackgroundColor: AppColors.lightTextTertiary
                        .withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMD,
                      ),
                    ),
                    elevation: _selectedRole != null ? 2 : 0,
                  ),
                  child: Text(
                    'Continue',
                    style: AppTypography.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: AppDimensions.spacingMD),
            ],
          ),
        ),
      ),
    );
  }

  void _selectRole(String role) {
    setState(() {
      _selectedRole = role;
    });
    // Analytics: onboarding_role_selected
    // TODO: Add analytics event
    debugPrint('Analytics: onboarding_role_selected - role: $role');
  }

  Future<void> _continue() async {
    if (_selectedRole == null) return;

    // Store selected role
    await _roleStorage.saveRole(_selectedRole!);

    if (!mounted) return;

    // Navigate to role-specific onboarding
    final route = _selectedRole == 'merchant'
        ? '/onboarding/merchant'
        : '/onboarding/customer';

    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  void initState() {
    super.initState();
    // Analytics: onboarding_role_viewed
    // TODO: Add analytics event
    debugPrint('Analytics: onboarding_role_viewed');
  }
}

/// Role Card Widget
class _RoleCard extends StatelessWidget {
  final String role;
  final IconData icon;
  final String label;
  final String subtext;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.icon,
    required this.label,
    required this.subtext,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label: $subtext',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: AppColors.lightCardBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryBlue
                    : AppColors.lightBorder,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Padding(
              padding: EdgeInsets.all(AppDimensions.paddingLG),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: isSelected ? AppColors.primaryGradient : null,
                      color: isSelected
                          ? null
                          : AppColors.lightTextTertiary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 40,
                      color: isSelected
                          ? Colors.white
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  SizedBox(height: AppDimensions.spacingMD),
                  // Label
                  Text(
                    label,
                    style: AppTypography.h3.copyWith(
                      color: isSelected
                          ? AppColors.primaryBlue
                          : AppColors.lightTextPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: AppDimensions.spacingSM),
                  // Subtext
                  Text(
                    subtext,
                    style: AppTypography.body2.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
