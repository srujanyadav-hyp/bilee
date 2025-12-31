import '../entities/monthly_summary_entity.dart';

/// Repository interface for Monthly Summary operations
abstract class MonthlySummaryRepository {
  /// Get all monthly summaries for current user
  Future<List<MonthlySummaryEntity>> getAllSummaries();

  /// Get summary for specific month
  Future<MonthlySummaryEntity?> getSummaryByMonth({
    required int year,
    required int month,
  });

  /// Create monthly summary
  Future<void> createSummary(MonthlySummaryEntity summary);

  /// Delete monthly summary
  Future<void> deleteSummary(String summaryId);

  /// Check if month is already archived
  Future<bool> isMonthArchived({required int year, required int month});
}
