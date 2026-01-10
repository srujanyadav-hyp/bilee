import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';

/// Custom Number Pad Widget for Fast Item Code Entry
/// Features:
/// - Large buttons (60x60px) for easy tapping
/// - Haptic feedback on each tap
/// - Supports digits 0-9, multiply (×), and clear
/// - Display shows current input
/// - One-hand operable
class CustomNumberPad extends StatelessWidget {
  final String currentInput;
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onClear;
  final VoidCallback onMultiply;
  final VoidCallback onEnter;

  const CustomNumberPad({
    super.key,
    required this.currentInput,
    required this.onDigitPressed,
    required this.onClear,
    required this.onMultiply,
    required this.onEnter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Display area
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingLG,
              vertical: AppDimensions.paddingMD,
            ),
            margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
              border: Border.all(color: AppColors.primaryBlue, width: 2),
            ),
            child: Text(
              currentInput.isEmpty ? '0' : currentInput,
              style: AppTypography.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
                fontSize: 32,
              ),
              textAlign: TextAlign.right,
            ),
          ),

          // Number pad grid
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            mainAxisSpacing: AppDimensions.spacingSM,
            crossAxisSpacing: AppDimensions.spacingSM,
            childAspectRatio: 1.2,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // Row 1: 1 2 3 CLEAR
              _buildNumberButton('1'),
              _buildNumberButton('2'),
              _buildNumberButton('3'),
              _buildActionButton(
                label: 'CLEAR',
                icon: Icons.backspace_outlined,
                color: AppColors.error,
                onPressed: onClear,
              ),

              // Row 2: 4 5 6 ×
              _buildNumberButton('4'),
              _buildNumberButton('5'),
              _buildNumberButton('6'),
              _buildActionButton(
                label: '×',
                icon: Icons.close,
                color: AppColors.warning,
                onPressed: onMultiply,
              ),

              // Row 3: 7 8 9 ENTER
              _buildNumberButton('7'),
              _buildNumberButton('8'),
              _buildNumberButton('9'),
              _buildActionButton(
                label: 'ADD',
                icon: Icons.add_circle,
                color: AppColors.success,
                onPressed: onEnter,
                isEnter: true,
              ),

              // Row 4: empty 0 empty empty
              const SizedBox.shrink(),
              _buildNumberButton('0'),
              const SizedBox.shrink(),
              const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(String digit) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      elevation: 2,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onDigitPressed(digit);
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        child: Container(
          alignment: Alignment.center,
          child: Text(
            digit,
            style: AppTypography.h3.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 28,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isEnter = false,
  }) {
    return Material(
      color: isEnter ? color : color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      elevation: isEnter ? 4 : 2,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onPressed();
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        child: Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isEnter ? Colors.white : color, size: 24),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isEnter ? Colors.white : color,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
