/// Inventory Transaction Entity - Tracks all stock changes
/// Provides audit trail for inventory movements
class InventoryTransactionEntity {
  final String id;
  final String itemId;
  final String merchantId;
  final double quantityChange; // Positive for additions, negative for sales
  final double stockAfter; // Stock level after this transaction
  final TransactionType type;
  final String? sessionId; // If transaction is from a sale
  final String? notes; // Manual adjustment notes
  final DateTime timestamp;

  const InventoryTransactionEntity({
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

  InventoryTransactionEntity copyWith({
    String? id,
    String? itemId,
    String? merchantId,
    double? quantityChange,
    double? stockAfter,
    TransactionType? type,
    String? sessionId,
    String? notes,
    DateTime? timestamp,
  }) {
    return InventoryTransactionEntity(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      merchantId: merchantId ?? this.merchantId,
      quantityChange: quantityChange ?? this.quantityChange,
      stockAfter: stockAfter ?? this.stockAfter,
      type: type ?? this.type,
      sessionId: sessionId ?? this.sessionId,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// Type of inventory transaction
enum TransactionType {
  sale, // Auto-deducted from session completion
  purchase, // Stock added (purchase/restock)
  adjustment, // Manual correction
  returned, // Customer return (stock added back)
}

extension TransactionTypeExtension on TransactionType {
  String get displayName {
    switch (this) {
      case TransactionType.sale:
        return 'Sale';
      case TransactionType.purchase:
        return 'Purchase';
      case TransactionType.adjustment:
        return 'Adjustment';
      case TransactionType.returned:
        return 'Return';
    }
  }

  String get icon {
    switch (this) {
      case TransactionType.sale:
        return '📉'; // Down arrow for stock reduction
      case TransactionType.purchase:
        return '📈'; // Up arrow for stock addition
      case TransactionType.adjustment:
        return '✏️'; // Pencil for manual edit
      case TransactionType.returned:
        return '↩️'; // Return arrow
    }
  }
}
