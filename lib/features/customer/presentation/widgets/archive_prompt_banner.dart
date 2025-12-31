import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';

/// Banner widget to prompt user to archive previous month
class ArchivePromptBanner extends StatelessWidget {
  final int year;
  final int month;
  final int receiptCount;
  final VoidCallback onReview;
  final VoidCallback onNotNow;
  final VoidCallback onNeverAsk;

  const ArchivePromptBanner({
    super.key,
    required this.year,
    required this.month,
    required this.receiptCount,
    required this.onReview,
    required this.onNotNow,
    required this.onNeverAsk,
  });

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(0.1),
            AppColors.primaryBlue.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.archive_outlined,
                    color: AppColors.primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Archive $monthName?',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      Text(
                        '$receiptCount receipts → 1 summary',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Clean up old receipts and create a monthly summary. Important receipts will be kept.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReview,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: const BorderSide(color: AppColors.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Review'),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(onPressed: onNotNow, child: const Text('Not Now')),
                TextButton(
                  onPressed: onNeverAsk,
                  style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  child: const Text('Never'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
