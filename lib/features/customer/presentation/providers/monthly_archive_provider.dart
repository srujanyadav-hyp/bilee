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
  Future<bool> isMonthArchived({required int year, required int month}) async {
    return await summaryRepository.isMonthArchived(year: year, month: month);
  }

  /// Get last month that needs archiving
  Future<Map<String, int>?> getLastUnarchivedMonth() async {
    final now = DateTime.now();

    // Check last month
    final lastMonth = DateTime(now.year, now.month - 1);

    final isArchived = await isMonthArchived(
      year: lastMonth.year,
      month: lastMonth.month,
    );

    if (!isArchived) {
      // Check if there are receipts for that month
      final receipts = await receiptRepository.getReceiptsByMonth(
        year: lastMonth.year,
        month: lastMonth.month,
      );

      if (receipts.isNotEmpty) {
        return {'year': lastMonth.year, 'month': lastMonth.month};
      }
    }

    return null;
  }
}
