import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/models/parsed_item.dart';

/// Card to confirm parsed item before adding to inventory
class VoiceItemConfirmationCard extends StatelessWidget {
  final ParsedItem parsedItem;
  final VoidCallback onConfirm;
  final VoidCallback onSkip;
  final VoidCallback onEdit;
  final bool isProcessing;

  const VoiceItemConfirmationCard({
    super.key,
    required this.parsedItem,
    required this.onConfirm,
    required this.onSkip,
    required this.onEdit,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppDimensions.elevationMD,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        side: BorderSide(
          color: AppColors.primaryBlue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: AppColors.infoLight,
                    size: AppDimensions.iconMD,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingSM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item Detected',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                      Text(
                        'Please confirm',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.spacingLG),

            // Item Details
            _buildDetailRow(
              context,
              'Item Name',
              parsedItem.name,
              Icons.inventory_2,
            ),

            const SizedBox(height: AppDimensions.spacingMD),

            // Show unit and per-unit price if available
            if (parsedItem.unit != null) ...[
              _buildDetailRow(
                context,
                'Quantity',
                parsedItem.unit!,
                Icons.scale,
              ),
              const SizedBox(height: AppDimensions.spacingMD),
            ],

            _buildDetailRow(
              context,
              'Price',
              '₹${parsedItem.price?.toStringAsFixed(2) ?? '0.00'}',
              Icons.currency_rupee,
            ),

            const SizedBox(height: AppDimensions.spacingMD),

            // Show per-unit price for loose items
            if (parsedItem.pricePerUnit != null &&
                parsedItem.unitType != null) ...[
              _buildDetailRow(
                context,
                'Per ${parsedItem.unitType}',
                '₹${parsedItem.pricePerUnit!.toStringAsFixed(2)}/${parsedItem.unitType}',
                Icons.calculate,
                color: AppColors.success,
              ),
              const SizedBox(height: AppDimensions.spacingMD),
            ],

            const SizedBox(height: AppDimensions.spacingMD),

            _buildDetailRow(
              context,
              'Tax',
              '18% GST (Auto-applied)',
              Icons.receipt,
            ),

            const SizedBox(height: AppDimensions.spacingXL),

            // Action Buttons
            if (isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  // Skip button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onSkip,
                      icon: const Icon(Icons.close),
                      label: const Text('Skip'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.paddingMD,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMD,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppDimensions.spacingSM),

                  // Edit button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: const BorderSide(color: AppColors.primaryBlue),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.paddingMD,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMD,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppDimensions.spacingSM),

                  // Confirm button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check),
                      label: const Text('Add Item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.paddingMD,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMD,
                          ),
                        ),
                        elevation: AppDimensions.elevationSM,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppDimensions.iconSM,
          color: color ?? AppColors.lightTextSecondary,
        ),
        const SizedBox(width: AppDimensions.spacingSM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
