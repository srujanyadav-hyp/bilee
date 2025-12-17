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
      default:
        return '💰';
    }
  }
}
