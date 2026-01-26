import 'package:flutter/foundation.dart';
import '../../domain/entities/inventory_transaction_entity.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/repositories/inventory_repository.dart';

/// Inventory Provider - State management for inventory operations
class InventoryProvider with ChangeNotifier {
  final IInventoryRepository _repository;

  InventoryProvider({required IInventoryRepository repository})
    : _repository = repository;

  bool _isLoading = false;
  String? _error;
  List<ItemEntity> _lowStockItems = [];
  List<ItemEntity> _outOfStockItems = [];
  List<InventoryTransactionEntity> _transactionHistory = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ItemEntity> get lowStockItems => _lowStockItems;
  List<ItemEntity> get outOfStockItems => _outOfStockItems;
  List<InventoryTransactionEntity> get transactionHistory =>
      _transactionHistory;

  /// Update stock for an item
  Future<void> updateStock({
    required String itemId,
    required String merchantId,
    required double quantityChange,
    required TransactionType type,
    String? sessionId,
    String? notes,
  }) async {
    try {
      _error = null;
      await _repository.updateStock(
        itemId: itemId,
        merchantId: merchantId,
        quantityChange: quantityChange,
        type: type,
        sessionId: sessionId,
        notes: notes,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Load low stock items
  Future<void> loadLowStockItems(String merchantId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _lowStockItems = await _repository.getLowStockItems(merchantId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Load out of stock items
  Future<void> loadOutOfStockItems(String merchantId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _outOfStockItems = await _repository.getOutOfStockItems(merchantId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Load transaction history for an item
  Future<void> loadTransactionHistory(String itemId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _transactionHistory = await _repository.getTransactionHistory(itemId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Enable inventory tracking for an item
  Future<void> enableInventoryTracking({
    required String itemId,
    required double initialStock,
    required double lowStockThreshold,
    required String stockUnit,
  }) async {
    try {
      _error = null;
      await _repository.enableInventoryTracking(
        itemId: itemId,
        initialStock: initialStock,
        lowStockThreshold: lowStockThreshold,
        stockUnit: stockUnit,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Disable inventory tracking for an item
  Future<void> disableInventoryTracking(String itemId) async {
    try {
      _error = null;
      await _repository.disableInventoryTracking(itemId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Deduct stock for all items in a session
  Future<void> deductStockForSession({
    required String sessionId,
    required String merchantId,
    required Map<String, double> itemQuantities,
  }) async {
    try {
      _error = null;
      await _repository.deductStockForSession(
        sessionId: sessionId,
        merchantId: merchantId,
        itemQuantities: itemQuantities,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      // Don't rethrow - we don't want to block session completion
      debugPrint('Error deducting stock: $e');
    }
  }

  /// Adjust stock (manual correction)
  Future<void> adjustStock({
    required String itemId,
    required String merchantId,
    required double newStock,
    required double currentStock,
    String? notes,
  }) async {
    final quantityChange = newStock - currentStock;
    await updateStock(
      itemId: itemId,
      merchantId: merchantId,
      quantityChange: quantityChange,
      type: TransactionType.adjustment,
      notes: notes ?? 'Manual stock adjustment',
    );
  }

  /// Add stock (purchase/restock)
  Future<void> addStock({
    required String itemId,
    required String merchantId,
    required double quantity,
    String? notes,
  }) async {
    await updateStock(
      itemId: itemId,
      merchantId: merchantId,
      quantityChange: quantity,
      type: TransactionType.purchase,
      notes: notes ?? 'Stock added',
    );
  }

  /// Get current stock level
  Future<double?> getCurrentStock(String itemId) async {
    try {
      return await _repository.getCurrentStock(itemId);
    } catch (e) {
      debugPrint('Error getting current stock: $e');
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh all inventory data
  Future<void> refreshInventory(String merchantId) async {
    await Future.wait([
      loadLowStockItems(merchantId),
      loadOutOfStockItems(merchantId),
    ]);
  }
}
