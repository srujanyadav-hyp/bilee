import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/item_entity.dart';

/// Dialog shown when a duplicate/similar item is detected
class DuplicateItemDialog extends StatelessWidget {
  final String newItemName;
  final double newItemPrice;
  final ItemEntity existingItem;

  const DuplicateItemDialog({
    super.key,
    required this.newItemName,
    required this.newItemPrice,
    required this.existingItem,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: AppDimensions.iconLG,
          ),
          const SizedBox(width: AppDimensions.spacingSM),
          const Expanded(child: Text('Similar Item Found')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'An item with a similar name already exists in your inventory.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.lightTextSecondary,
            ),
          ),

          const SizedBox(height: AppDimensions.spacingLG),

          // New item
          _buildItemCard(
            context,
            'You said:',
            newItemName,
            newItemPrice,
            AppColors.infoLight,
            true,
          ),

          const SizedBox(height: AppDimensions.spacingSM),

          // Existing item
          _buildItemCard(
            context,
            'Already exists:',
            existingItem.name,
            existingItem.price,
            AppColors.warning,
            false,
          ),

          const SizedBox(height: AppDimensions.spacingLG),

          Text(
            'What would you like to do?',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'cancel'),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(context, 'add_new'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryBlue,
          ),
          child: const Text('Add as New'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, 'update'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
          ),
          child: const Text('Update Price'),
        ),
      ],
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    String label,
    String name,
    double price,
    Color accentColor,
    bool isNew,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '₹${price.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
