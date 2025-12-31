import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/receipt_entity.dart';
import '../../domain/usecases/get_all_receipts.dart';
import '../../domain/usecases/get_recent_receipts.dart';
import '../../domain/usecases/search_receipts.dart';
import '../../domain/repositories/receipt_repository.dart';

/// Provider for Receipt functionality
class ReceiptProvider with ChangeNotifier {
  final GetAllReceiptsUseCase getAllReceiptsUseCase;
  final GetRecentReceiptsUseCase getRecentReceiptsUseCase;
  final SearchReceiptsUseCase searchReceiptsUseCase;
  final ReceiptRepository repository;

  ReceiptProvider({
    required this.getAllReceiptsUseCase,
    required this.getRecentReceiptsUseCase,
    required this.searchReceiptsUseCase,
    required this.repository,
  });

  List<ReceiptEntity> _receipts = [];
  List<ReceiptEntity> _recentReceipts = [];
  ReceiptEntity? _selectedReceipt;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // Getters
  List<ReceiptEntity> get receipts => _receipts;
  List<ReceiptEntity> get recentReceipts => _recentReceipts;
  ReceiptEntity? get selectedReceipt => _selectedReceipt;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get hasReceipts => _receipts.isNotEmpty;
  bool get hasRecentReceipts => _recentReceipts.isNotEmpty;
  String get searchQuery => _searchQuery;

  /// Load all receipts
  Future<void> loadAllReceipts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _receipts = await getAllReceiptsUseCase.call();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load recent receipts (for home screen)
  Future<void> loadRecentReceipts({int limit = 3}) async {
    try {
      _recentReceipts = await getRecentReceiptsUseCase.call(limit: limit);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Search receipts
  Future<void> searchReceipts(String query) async {
    _searchQuery = query;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _receipts = await searchReceiptsUseCase.call(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    loadAllReceipts();
  }

  /// Refresh receipts
  Future<void> refresh() async {
    await loadAllReceipts();
    await loadRecentReceipts();
  }

  /// Get count of receipts for a specific month (for archive banner display)
  Future<int> getReceiptCountForMonth({
    required int year,
    required int month,
  }) async {
    try {
      final receipts = await repository.getReceiptsByMonth(
        year: year,
        month: month,
      );
      return receipts.length;
    } catch (e) {
      debugPrint('Error getting receipt count: $e');
      return 0;
    }
  }

  /// Get receipt by session ID (used after payment)
  Future<ReceiptEntity?> getReceiptBySessionId(String sessionId) async {
    try {
      return await repository.getReceiptBySessionId(sessionId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Load receipt by ID for detail view
  Future<void> loadReceiptById(String receiptId) async {
    _isLoading = true;
    _error = null;
    _selectedReceipt = null;
    notifyListeners();

    try {
      _selectedReceipt = await repository.getReceiptById(receiptId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create manual receipt (customer-entered expense)
  Future<void> createManualReceipt({
    required String category,
    required double amount,
    required PaymentMethod paymentMethod,
    String? merchantName,
    String? merchantUpiId,
    String? transactionId,
    bool verified = false,
    String? photoPath,
  }) async {
    try {
      await repository.createManualReceipt(
        category: category,
        amount: amount,
        paymentMethod: paymentMethod,
        merchantName: merchantName,
        merchantUpiId: merchantUpiId,
        transactionId: transactionId,
        verified: verified,
        photoPath: photoPath,
      );

      // Reload receipts after creating manual entry
      await loadAllReceipts();
      await loadRecentReceipts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get monthly spending by category
  Map<String, double> getMonthlySpendingByCategory() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    final categorySpending = <String, double>{};

    for (final receipt in _receipts) {
      final receiptMonth = DateTime(
        receipt.createdAt.year,
        receipt.createdAt.month,
      );

      // Only include receipts from current month
      if (receiptMonth.isAtSameMomentAs(currentMonth)) {
        final category = receipt.businessCategory ?? 'Other';
        categorySpending[category] =
            (categorySpending[category] ?? 0) + receipt.total;
      }
    }

    // Sort by amount (highest first)
    final sortedEntries = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  /// Get total monthly spending
  double getTotalMonthlySpending() {
    final spending = getMonthlySpendingByCategory();
    return spending.values.fold(0.0, (sum, amount) => sum + amount);
  }

  /// Get category icon
  static String getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'restaurant':
      case 'food':
        return '🍽️';
      case 'grocery':
      case 'groceries':
        return '🛒';
      case 'pharmacy':
      case 'healthcare':
        return '💊';
      case 'electronics':
        return '📱';
      case 'clothing':
      case 'fashion':
        return '👕';
      case 'retail':
      case 'shopping':
        return '🛍️';
      case 'services':
        return '🔧';
      case 'entertainment':
        return '🎬';
      case 'transport':
      case 'transportation':
      case 'travel':
        return '🚕';
      default:
        return '📦'; // Generic package/other icon
    }
  }

  /// Delete receipt
  Future<void> deleteReceipt(String receiptId) async {
    try {
      // Delete from repository (Firestore + photo)
      await repository.deleteReceipt(receiptId);

      // Remove from local cache
      _receipts.removeWhere((r) => r.id == receiptId);
      _recentReceipts.removeWhere((r) => r.id == receiptId);

      // Clear selected receipt if it was deleted
      if (_selectedReceipt?.id == receiptId) {
        _selectedReceipt = null;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Update receipt (notes, tags, etc.)
  Future<void> updateReceipt(ReceiptEntity receipt) async {
    try {
      // Update in Firestore via repository
      await repository.updateReceipt(receipt);

      // Update local caches
      final index = _receipts.indexWhere((r) => r.id == receipt.id);
      if (index != -1) {
        _receipts[index] = receipt;
      }

      final recentIndex = _recentReceipts.indexWhere((r) => r.id == receipt.id);
      if (recentIndex != -1) {
        _recentReceipts[recentIndex] = receipt;
      }

      // Update selected receipt if it's the one being updated
      if (_selectedReceipt?.id == receipt.id) {
        _selectedReceipt = receipt;
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Get receipts for a specific month
  Future<List<ReceiptEntity>> getReceiptsForMonth({
    required int year,
    required int month,
  }) async {
    try {
      return await repository.getReceiptsByMonth(year: year, month: month);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Calculate category summaries from receipts
  List<Map<String, dynamic>> calculateCategorySummaries(
    List<ReceiptEntity> receipts,
  ) {
    if (receipts.isEmpty) return [];

    // Group by category
    final Map<String, List<ReceiptEntity>> grouped = {};
    for (final receipt in receipts) {
      final category = receipt.businessCategory ?? 'Other';
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(receipt);
    }

    // Calculate totals
    final double grandTotal = receipts.fold(0, (sum, r) => sum + r.total);

    // Create summaries
    final summaries = grouped.entries.map((entry) {
      final total = entry.value.fold(0.0, (sum, r) => sum + r.total);
      final percentage = (total / grandTotal * 100);

      return {
        'name': entry.key,
        'icon': getCategoryIcon(entry.key),
        'total': total,
        'count': entry.value.length,
        'percentage': percentage,
      };
    }).toList();

    // Sort by total descending
    summaries.sort(
      (a, b) => (b['total'] as double).compareTo(a['total'] as double),
    );

    return summaries;
  }

  /// Check if receipts should be auto-kept (important)
  bool isImportantReceipt(ReceiptEntity receipt) {
    // Keep if has notes
    if (receipt.notes != null && receipt.notes!.isNotEmpty) {
      return true;
    }
    // Keep if amount > 10000
    if (receipt.total >= 10000) {
      return true;
    }
    // Keep if manual entry with photo (likely warranty)
    if (receipt.receiptPhotoPath != null &&
        receipt.receiptPhotoPath!.isNotEmpty) {
      return true;
    }
    return false;
  }

  /// Get IDs of receipts that should be kept
  List<String> getImportantReceiptIds(List<ReceiptEntity> receipts) {
    return receipts
        .where((r) => isImportantReceipt(r))
        .map((r) => r.id)
        .toList();
  }
}
