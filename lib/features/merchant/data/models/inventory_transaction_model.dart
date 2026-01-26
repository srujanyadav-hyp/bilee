import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/inventory_transaction_entity.dart';

/// Data Model - Inventory Transaction (Firestore Representation)
class InventoryTransactionModel {
  final String id;
  final String itemId;
  final String merchantId;
  final double quantityChange;
  final double stockAfter;
  final String type; // Stored as string in Firestore
  final String? sessionId;
  final String? notes;
  final Timestamp timestamp;

  const InventoryTransactionModel({
    required this.id,
    required this.itemId,
    required this.merchantId,
    required this.quantityChange,
    required this.stockAfter,
    required this.type,
    this.sessionId,
    this.notes,
    required this.timestamp,
  });

  /// Create from Firestore document
  factory InventoryTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InventoryTransactionModel(
      id: doc.id,
      itemId: data['itemId'] as String,
      merchantId: data['merchantId'] as String,
      quantityChange: (data['quantityChange'] as num).toDouble(),
      stockAfter: (data['stockAfter'] as num).toDouble(),
      type: data['type'] as String,
      sessionId: data['sessionId'] as String?,
      notes: data['notes'] as String?,
      timestamp: data['timestamp'] as Timestamp,
    );
  }

  /// Create from JSON
  factory InventoryTransactionModel.fromJson(Map<String, dynamic> json) {
    return InventoryTransactionModel(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      merchantId: json['merchantId'] as String,
      quantityChange: (json['quantityChange'] as num).toDouble(),
      stockAfter: (json['stockAfter'] as num).toDouble(),
      type: json['type'] as String,
      sessionId: json['sessionId'] as String?,
      notes: json['notes'] as String?,
      timestamp: json['timestamp'] as Timestamp,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'merchantId': merchantId,
      'quantityChange': quantityChange,
      'stockAfter': stockAfter,
      'type': type,
      if (sessionId != null) 'sessionId': sessionId,
      if (notes != null) 'notes': notes,
      'timestamp': timestamp,
    };
  }

  /// Convert to Entity
  InventoryTransactionEntity toEntity() {
    return InventoryTransactionEntity(
      id: id,
      itemId: itemId,
      merchantId: merchantId,
      quantityChange: quantityChange,
      stockAfter: stockAfter,
      type: _stringToTransactionType(type),
      sessionId: sessionId,
      notes: notes,
      timestamp: timestamp.toDate(),
    );
  }

  /// Create from Entity
  factory InventoryTransactionModel.fromEntity(
    InventoryTransactionEntity entity,
  ) {
    return InventoryTransactionModel(
      id: entity.id,
      itemId: entity.itemId,
      merchantId: entity.merchantId,
      quantityChange: entity.quantityChange,
      stockAfter: entity.stockAfter,
      type: _transactionTypeToString(entity.type),
      sessionId: entity.sessionId,
      notes: entity.notes,
      timestamp: Timestamp.fromDate(entity.timestamp),
    );
  }

  /// Convert string to TransactionType enum
  static TransactionType _stringToTransactionType(String type) {
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

  /// Convert TransactionType enum to string
  static String _transactionTypeToString(TransactionType type) {
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
}
