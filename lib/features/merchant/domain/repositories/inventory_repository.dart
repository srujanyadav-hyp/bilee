import '../entities/inventory_transaction_entity.dart';
import '../entities/item_entity.dart';

/// Inventory Repository Interface
/// Defines contract for inventory management operations
abstract class IInventoryRepository {
  /// Update stock for an item
  /// Creates a transaction record and updates current stock
  Future<void> updateStock({
    required String itemId,
    required String merchantId,
    required double quantityChange,
    required TransactionType type,
    String? sessionId,
    String? notes,
  });

  /// Get items with low stock for a merchant
  Future<List<ItemEntity>> getLowStockItems(String merchantId);

  /// Get items that are out of stock
  Future<List<ItemEntity>> getOutOfStockItems(String merchantId);

  /// Get transaction history for a specific item
  Future<List<InventoryTransactionEntity>> getTransactionHistory(String itemId);

  /// Enable inventory tracking for an item
  Future<void> enableInventoryTracking({
    required String itemId,
    required double initialStock,
    required double lowStockThreshold,
    required String stockUnit,
  });

  /// Disable inventory tracking for an item
  Future<void> disableInventoryTracking(String itemId);

  /// Deduct stock for multiple items (used when completing a session)
  Future<void> deductStockForSession({
    required String sessionId,
    required String merchantId,
    required Map<String, double> itemQuantities, // itemId -> quantity
  });

  /// Get current stock level for an item
  Future<double?> getCurrentStock(String itemId);
}
