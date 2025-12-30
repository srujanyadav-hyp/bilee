import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/budget.dart';

/// Widget to display budget progress with visual indicators
class BudgetProgressCard extends StatelessWidget {
  final BudgetProgress progress;
  final VoidCallback? onTap;

  const BudgetProgressCard({super.key, required this.progress, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getBorderColor(), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildStatusIcon(),
                    const SizedBox(width: 8),
                    Text(
                      progress.budget.category,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                _buildStatusBadge(),
              ],
            ),

            const SizedBox(height: 12),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress.percentage.clamp(0.0, 1.0),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
                minHeight: 8,
              ),
            ),

            const SizedBox(height: 12),

            // Amount Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spent',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      '₹${progress.spent.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getProgressColor(),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Remaining',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      '₹${progress.remaining.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Limit',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      '₹${progress.budget.monthlyLimit.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData icon;
    Color color;

    if (progress.isExceeded) {
      icon = Icons.warning_rounded;
      color = Colors.red;
    } else if (progress.isApproachingLimit) {
      icon = Icons.info_rounded;
      color = Colors.orange;
    } else {
      icon = Icons.check_circle_rounded;
      color = Colors.green;
    }

    return Icon(icon, color: color, size: 20);
  }

  Widget _buildStatusBadge() {
    String text;
    Color backgroundColor;
    Color textColor;

    if (progress.isExceeded) {
      text = 'EXCEEDED';
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
    } else if (progress.isApproachingLimit) {
      text = 'WARNING';
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
    } else {
      text = '${progress.percentageDisplay.toStringAsFixed(0)}%';
      backgroundColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Color _getProgressColor() {
    if (progress.isExceeded) return Colors.red;
    if (progress.isApproachingLimit) return Colors.orange;
    return AppColors.primaryBlue;
  }

  Color _getBorderColor() {
    if (progress.isExceeded) return Colors.red.shade200;
    if (progress.isApproachingLimit) return Colors.orange.shade200;
    return AppColors.lightBorder;
  }
}
