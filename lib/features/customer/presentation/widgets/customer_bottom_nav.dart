import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

/// Reusable bottom navigation bar for all customer screens
class CustomerBottomNav extends StatelessWidget {
  final String currentRoute;

  const CustomerBottomNav({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: AppColors.lightSurface,
      elevation: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context: context,
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Home',
              isSelected: currentRoute == '/customer',
              onTap: () => context.go('/customer'),
            ),
            const SizedBox(width: 80), // Space for FAB
            _buildNavItem(
              context: context,
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long,
              label: 'Receipts',
              isSelected: currentRoute == '/customer/receipts',
              onTap: () => context.go('/customer/receipts'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primaryBlue.withOpacity(0.1),
          highlightColor: AppColors.primaryBlue.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Icon
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: ShaderMask(
                    key: ValueKey(isSelected),
                    shaderCallback: (bounds) {
                      if (isSelected) {
                        return AppColors.primaryGradient.createShader(bounds);
                      }
                      return LinearGradient(
                        colors: [
                          AppColors.lightTextSecondary,
                          AppColors.lightTextSecondary,
                        ],
                      ).createShader(bounds);
                    },
                    child: Icon(
                      isSelected ? selectedIcon : icon,
                      size: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // Animated Label
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.primaryBlue
                        : AppColors.lightTextSecondary,
                  ),
                  child: Text(label),
                ),
                const SizedBox(height: 2),
                // Animated Indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: isSelected ? 24 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating scan button for customer screens
class CustomerFloatingScanButton extends StatefulWidget {
  const CustomerFloatingScanButton({super.key});

  @override
  State<CustomerFloatingScanButton> createState() =>
      _CustomerFloatingScanButtonState();
}

class _CustomerFloatingScanButtonState extends State<CustomerFloatingScanButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        context.push('/customer/scan-qr');
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotateAnimation.value,
              child: Container(
                width: 70,
                height: 70,
                margin: const EdgeInsets.only(top: 30),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.qr_code_scanner_outlined,
                  size: 32,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
