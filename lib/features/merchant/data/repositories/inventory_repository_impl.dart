import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/local_database_service.dart';
import '../../domain/entities/inventory_transaction_entity.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../mappers/entity_model_mapper.dart';
import '../models/inventory_transaction_model.dart';
import '../models/item_model.dart';

/// Inventory Repository Implementation
/// Handles both Firestore and local database operations for inventory
class InventoryRepositoryImpl implements IInventoryRepository {
  final LocalDatabaseService _localDb;
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  InventoryRepositoryImpl({
    required LocalDatabaseService localDb,
    required FirebaseFirestore firestore,
  }) : _localDb = localDb,
       _firestore = firestore;

  @override
  Future<void> updateStock({
    required String itemId,
    required String merchantId,
    required double quantityChange,
    required TransactionType type,
    String? sessionId,
    String? notes,
  }) async {
    try {
      // Get current item to calculate new stock
      final itemDoc = await _firestore.collection('items').doc(itemId).get();

      if (!itemDoc.exists) {
        throw Exception('Item not found');
      }

      final itemData = itemDoc.data()!;
      final currentStock = (itemData['currentStock'] as num?)?.toDouble() ?? 0;
      final newStock = currentStock + quantityChange;

      // Create transaction record
      final transactionId = _uuid.v4();
      final transaction = InventoryTransactionEntity(
        id: transactionId,
        itemId: itemId,
        merchantId: merchantId,
        quantityChange: quantityChange,
        stockAfter: newStock,
        type: type,
        sessionId: sessionId,
        notes: notes,
        timestamp: DateTime.now(),
      );

      final transactionModel = InventoryTransactionModel.fromEntity(
        transaction,
      );

      // Update Firestore
      await _firestore.runTransaction((txn) async {
        // Update item stock
        txn.update(_firestore.collection('items').doc(itemId), {
          'currentStock': newStock,
          'lastStockUpdate': Timestamp.now(),
        });

        // Add transaction record
        txn.set(
          _firestore.collection('inventory_transactions').doc(transactionId),
          transactionModel.toJson(),
        );
      });

      // Update local database
      await _localDb.updateItemStock(
        itemId: itemId,
        newStock: newStock,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await _localDb.insertInventoryTransaction({
        'id': transactionId,
        'itemId': itemId,
        'merchantId': merchantId,
        'quantityChange': quantityChange,
        'stockAfter': newStock,
        'type': _transactionTypeToString(type),
        'sessionId': sessionId,
        'notes': notes,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isSynced': 1, // Already synced to Firestore
      });
    } catch (e) {
      // If Firestore fails, save to local DB for later sync
      final currentStock = 0.0; // TODO: Get from local cache
      final newStock = currentStock + quantityChange;
      final transactionId = _uuid.v4();

      await _localDb.updateItemStock(
        itemId: itemId,
        newStock: newStock,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await _localDb.insertInventoryTransaction({
        'id': transactionId,
        'itemId': itemId,
        'merchantId': merchantId,
        'quantityChange': quantityChange,
        'stockAfter': newStock,
        'type': _transactionTypeToString(type),
        'sessionId': sessionId,
        'notes': notes,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'isSynced': 0, // Not synced yet
      });

      rethrow;
    }
  }

  @override
  Future<List<ItemEntity>> getLowStockItems(String merchantId) async {
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('merchantId', isEqualTo: merchantId)
          .where('inventoryEnabled', isEqualTo: true)
          .get();

      final items = snapshot.docs
          .map((doc) => ItemModel.fromFirestore(doc).toEntity())
          .where((item) => item.isLowStock)
          .toList();

      return items;
    } catch (e) {
      // Fallback to local database
      final localItems = await _localDb.getLowStockItems(merchantId);
      return localItems.map((data) => _itemEntityFromLocalData(data)).toList();
    }
  }

  @override
  Future<List<ItemEntity>> getOutOfStockItems(String merchantId) async {
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('merchantId', isEqualTo: merchantId)
          .where('inventoryEnabled', isEqualTo: true)
          .get();

      final items = snapshot.docs
          .map((doc) => ItemModel.fromFirestore(doc).toEntity())
          .where((item) => item.isOutOfStock)
          .toList();

      return items;
    } catch (e) {
      // Fallback to local database
      final localItems = await _localDb.getOutOfStockItems(merchantId);
      return localItems.map((data) => _itemEntityFromLocalData(data)).toList();
    }
  }

  @override
  Future<List<InventoryTransactionEntity>> getTransactionHistory(
    String itemId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('inventory_transactions')
          .where('itemId', isEqualTo: itemId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => InventoryTransactionModel.fromFirestore(doc).toEntity())
          .toList();
    } catch (e) {
      // Fallback to local database
      final localTransactions = await _localDb.getInventoryHistory(itemId);
      return localTransactions
          .map((data) => _transactionEntityFromLocalData(data))
          .toList();
    }
  }

  @override
  Future<void> enableInventoryTracking({
    required String itemId,
    required double initialStock,
    required double lowStockThreshold,
    required String stockUnit,
  }) async {
    await _firestore.collection('items').doc(itemId).update({
      'inventoryEnabled': true,
      'currentStock': initialStock,
      'lowStockThreshold': lowStockThreshold,
      'stockUnit': stockUnit,
      'lastStockUpdate': Timestamp.now(),
    });

    // Create initial transaction
    await updateStock(
      itemId: itemId,
      merchantId: '', // Will be fetched from item
      quantityChange: initialStock,
      type: TransactionType.adjustment,
      notes: 'Initial stock - Inventory tracking enabled',
    );
  }

  @override
  Future<void> disableInventoryTracking(String itemId) async {
    await _firestore.collection('items').doc(itemId).update({
      'inventoryEnabled': false,
      'currentStock': null,
      'lowStockThreshold': null,
      'stockUnit': null,
      'lastStockUpdate': null,
    });
  }

  @override
  Future<void> deductStockForSession({
    required String sessionId,
    required String merchantId,
    required Map<String, double> itemQuantities,
  }) async {
    for (final entry in itemQuantities.entries) {
      final itemId = entry.key;
      final quantity = entry.value;

      // Check if item has inventory enabled
      final itemDoc = await _firestore.collection('items').doc(itemId).get();

      if (itemDoc.exists) {
        final itemData = itemDoc.data()!;
        final inventoryEnabled = itemData['inventoryEnabled'] as bool? ?? false;

        if (inventoryEnabled) {
          await updateStock(
            itemId: itemId,
            merchantId: merchantId,
            quantityChange: -quantity, // Negative for deduction
            type: TransactionType.sale,
            sessionId: sessionId,
            notes: 'Auto-deducted from session completion',
          );
        }
      }
    }
  }

  @override
  Future<double?> getCurrentStock(String itemId) async {
    try {
      final doc = await _firestore.collection('items').doc(itemId).get();
      if (doc.exists) {
        return (doc.data()?['currentStock'] as num?)?.toDouble();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Helper methods

  String _transactionTypeToString(TransactionType type) {
    switch (type) {
      case TransactionType.sale:
        return 'sale';
      case TransactionType.purchase:
        return 'purchase';
      case TransactionType.adjustment:
        return 'adjustment';
      case TransactionType.returned:
        return 'returned';
    }
  }

  TransactionType _stringToTransactionType(String type) {
    switch (type) {
      case 'sale':
        return TransactionType.sale;
      case 'purchase':
        return TransactionType.purchase;
      case 'adjustment':
        return TransactionType.adjustment;
      case 'returned':
        return TransactionType.returned;
      default:
        return TransactionType.adjustment;
    }
  }

  ItemEntity _itemEntityFromLocalData(Map<String, dynamic> data) {
    return ItemEntity(
      id: data['id'] as String,
      merchantId: data['merchantId'] as String,
      name: data['name'] as String,
      price: (data['price'] as num).toDouble(),
      taxRate: (data['taxRate'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data['lastUpdated'] as int,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        data['lastUpdated'] as int,
      ),
      inventoryEnabled: (data['inventoryEnabled'] as int?) == 1,
      currentStock: (data['currentStock'] as num?)?.toDouble(),
      lowStockThreshold: (data['lowStockThreshold'] as num?)?.toDouble(),
      stockUnit: data['stockUnit'] as String?,
      lastStockUpdate: data['lastStockUpdate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['lastStockUpdate'] as int)
          : null,
    );
  }

  InventoryTransactionEntity _transactionEntityFromLocalData(
    Map<String, dynamic> data,
  ) {
    return InventoryTransactionEntity(
      id: data['id'] as String,
      itemId: data['itemId'] as String,
      merchantId: data['merchantId'] as String,
      quantityChange: (data['quantityChange'] as num).toDouble(),
      stockAfter: (data['stockAfter'] as num).toDouble(),
      type: _stringToTransactionType(data['type'] as String),
      sessionId: data['sessionId'] as String?,
      notes: data['notes'] as String?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int),
    );
  }
}
