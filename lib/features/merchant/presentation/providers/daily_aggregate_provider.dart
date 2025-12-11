import 'package:flutter/foundation.dart';
import '../../domain/entities/daily_aggregate_entity.dart';
import '../../domain/entities/session_entity.dart';
import '../../domain/usecases/daily_aggregate_usecases.dart';

/// Daily Aggregate Provider - State management for daily sales aggregates
class DailyAggregateProvider with ChangeNotifier {
  final GetDailyAggregate _getDailyAggregate;
  final UpdateDailyAggregate _updateDailyAggregate;
  final GenerateDailyReport _generateDailyReport;

  DailyAggregateProvider({
    required GetDailyAggregate getDailyAggregate,
    required UpdateDailyAggregate updateDailyAggregate,
    required GenerateDailyReport generateDailyReport,
  }) : _getDailyAggregate = getDailyAggregate,
       _updateDailyAggregate = updateDailyAggregate,
       _generateDailyReport = generateDailyReport;

  DailyAggregateEntity? _todayAggregate;
  DailyAggregateEntity? _selectedDateAggregate;
  bool _isLoading = false;
  String? _error;
  String? _reportDownloadUrl;

  DailyAggregateEntity? get todayAggregate => _todayAggregate;
  DailyAggregateEntity? get selectedDateAggregate => _selectedDateAggregate;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get reportDownloadUrl => _reportDownloadUrl;
  bool get hasTodayData => _todayAggregate != null;

  /// Load today's aggregate
  Future<void> loadTodayAggregate(String merchantId) async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _getDailyAggregate(merchantId, dateStr).listen(
        (aggregate) {
          _todayAggregate = aggregate;
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          _error = e.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load aggregate for a specific date
  Future<void> loadAggregateForDate(String merchantId, DateTime date) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _getDailyAggregate(merchantId, dateStr).listen(
        (aggregate) {
          _selectedDateAggregate = aggregate;
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          _error = e.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update daily aggregate (called after session completion)
  Future<bool> updateAggregate(
    String merchantId,
    String date,
    double revenue,
    List<SessionItemEntity> items,
  ) async {
    _error = null;
    notifyListeners();

    try {
      await _updateDailyAggregate(merchantId, date, revenue, items);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Generate daily report (PDF or CSV)
  Future<String?> generateReport(
    String merchantId,
    DateTime date,
    String format,
  ) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    _isLoading = true;
    _error = null;
    _reportDownloadUrl = null;
    notifyListeners();

    try {
      final url = await _generateDailyReport(merchantId, dateStr, format);
      _reportDownloadUrl = url;
      _isLoading = false;
      notifyListeners();
      return url;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Get top selling items from today's aggregate
  List<AggregatedItemEntity> getTopSellingItems({int limit = 5}) {
    if (_todayAggregate == null) return [];

    final sortedItems = List<AggregatedItemEntity>.from(_todayAggregate!.items)
      ..sort((a, b) => b.quantity.compareTo(a.quantity));

    return sortedItems.take(limit).toList();
  }

  /// Get highest revenue items from today's aggregate
  List<AggregatedItemEntity> getHighestRevenueItems({int limit = 5}) {
    if (_todayAggregate == null) return [];

    final sortedItems = List<AggregatedItemEntity>.from(_todayAggregate!.items)
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    return sortedItems.take(limit).toList();
  }

  /// Clear report URL
  void clearReportUrl() {
    _reportDownloadUrl = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _todayAggregate = null;
    _selectedDateAggregate = null;
    super.dispose();
  }
}
