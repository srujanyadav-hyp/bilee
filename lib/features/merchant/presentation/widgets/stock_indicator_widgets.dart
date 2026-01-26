import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Stock Level Indicator Badge
/// Shows current stock status with beautiful visual indicators
class StockIndicatorBadge extends StatelessWidget {
  final double? currentStock;
  final double? lowStockThreshold;
  final String? stockUnit;
  final bool inventoryEnabled;
  final bool compact;

  const StockIndicatorBadge({
    super.key,
    this.currentStock,
    this.lowStockThreshold,
    this.stockUnit,
    this.inventoryEnabled = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!inventoryEnabled || currentStock == null) {
      return const SizedBox.shrink();
    }

    final isOutOfStock = currentStock! <= 0;
    final isLowStock =
        lowStockThreshold != null && currentStock! <= lowStockThreshold!;

    Color badgeColor;
    IconData icon;
    String statusText;

    if (isOutOfStock) {
      badgeColor = AppColors.error;
      icon = Icons.remove_circle_outline;
      statusText = 'Out of Stock';
    } else if (isLowStock) {
      badgeColor = AppColors.warning;
      icon = Icons.warning_amber_rounded;
      statusText = 'Low Stock';
    } else {
      badgeColor = AppColors.success;
      icon = Icons.check_circle_outline;
      statusText = 'In Stock';
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingXS,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: badgeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
          border: Border.all(color: badgeColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: badgeColor),
            const SizedBox(width: 4),
            Text(
              '${currentStock!.toStringAsFixed(currentStock! % 1 == 0 ? 0 : 1)} ${stockUnit ?? ''}',
              style: TextStyle(
                fontSize: 11,
                color: badgeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: AppDimensions.paddingXS,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [badgeColor.withOpacity(0.1), badgeColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: badgeColor),
          const SizedBox(width: AppDimensions.spacingXS),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  color: badgeColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${currentStock!.toStringAsFixed(currentStock! % 1 == 0 ? 0 : 1)} ${stockUnit ?? 'units'}',
                style: TextStyle(
                  fontSize: 10,
                  color: badgeColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Stock Progress Bar
/// Visual representation of stock level
class StockProgressBar extends StatelessWidget {
  final double currentStock;
  final double lowStockThreshold;
  final double? maxStock;

  const StockProgressBar({
    super.key,
    required this.currentStock,
    required this.lowStockThreshold,
    this.maxStock,
  });

  @override
  Widget build(BuildContext context) {
    final max = maxStock ?? (lowStockThreshold * 2);
    final progress = (currentStock / max).clamp(0.0, 1.0);

    Color progressColor;
    if (currentStock <= 0) {
      progressColor = AppColors.error;
    } else if (currentStock <= lowStockThreshold) {
      progressColor = AppColors.warning;
    } else {
      progressColor = AppColors.success;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Stock Level',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.lightTextSecondary,
              ),
            ),
            Text(
              '${currentStock.toStringAsFixed(0)} / ${max.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 12,
                color: progressColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.lightBorder.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
