import 'package:flutter/material.dart';

import '../../domain/entities/monthly_summary_entity.dart';
import '../../domain/repositories/monthly_summary_repository.dart';
import '../../domain/repositories/receipt_repository.dart';

/// Provider for Monthly Archival functionality
class MonthlyArchiveProvider with ChangeNotifier {
  final MonthlySummaryRepository summaryRepository;
  final ReceiptRepository receiptRepository;

  MonthlyArchiveProvider({
    required this.summaryRepository,
    required this.receiptRepository,
  });

  List<MonthlySummaryEntity> _summaries = [];
  bool _isLoading = false;
  String? _error;

  List<MonthlySummaryEntity> get summaries => _summaries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  /// Load all monthly summaries
  Future<void> loadSummaries() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _summaries = await summaryRepository.getAllSummaries();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Archive a month
  Future<void> archiveMonth({
    required int year,
    required int month,
    required List<String> receiptIdsToArchive,
    required List<String> receiptIdsToKeep,
    MonthlySummaryEntity? summary,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Create summary if provided
      if (summary != null) {
        await summaryRepository.createSummary(summary);
      }

      // Archive receipts
      if (receiptIdsToArchive.isNotEmpty) {
        await receiptRepository.archiveReceipts(receiptIdsToArchive);
      }

      // Reload summaries
      await loadSummaries();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Check if month is archived
  bool isMonthArchived(int year, int month) {
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';
    return _summaries.any((s) => s.month == monthKey);
  }

  /// Get the last unarchived month (most recent month with receipts but no summary)
  /// Returns null if no unarchived months found or if current month
  Future<Map<String, int>?> getLastUnarchivedMonth() async {
    try {
      // Get all receipts
      final allReceipts = await receiptRepository.getAllReceipts();

      if (allReceipts.isEmpty) {
        debugPrint('No receipts found');
        return null;
      }

      // Get current month details
      final now = DateTime.now();
      final currentYear = now.year;
      final currentMonth = now.month;

      // Group receipts by year-month
      final Map<String, Map<String, int>> receiptMonths = {};

      for (final receipt in allReceipts) {
        final date = receipt.createdAt;
        final year = date.year;
        final month = date.month;

        // Skip current month - we only archive completed months
        if (year == currentYear && month == currentMonth) {
          continue;
        }

        // Skip future months (shouldn't happen, but safety check)
        if (year > currentYear ||
            (year == currentYear && month > currentMonth)) {
          continue;
        }

        final monthKey = '$year-${month.toString().padLeft(2, '0')}';
        receiptMonths[monthKey] = {'year': year, 'month': month};
      }

      if (receiptMonths.isEmpty) {
        debugPrint('No completed months with receipts');
        return null;
      }

      // Get all archived months (those with summaries)
      final archivedMonthKeys = _summaries.map((s) => s.month).toSet();

      // Find unarchived months
      final unarchivedMonths = receiptMonths.entries
          .where((entry) => !archivedMonthKeys.contains(entry.key))
          .toList();

      if (unarchivedMonths.isEmpty) {
        debugPrint('All months are archived');
        return null;
      }

      // Sort by year-month descending to get most recent
      unarchivedMonths.sort((a, b) => b.key.compareTo(a.key));

      final mostRecent = unarchivedMonths.first.value;
      debugPrint(
        'Found unarchived month: ${mostRecent['year']}-${mostRecent['month']}',
      );

      return mostRecent;
    } catch (e) {
      debugPrint('Error getting last unarchived month: $e');
      return null;
    }
  }
}
