/// Domain Entity - Session Item
class SessionItemEntity {
  final String name;
  final String? hsnCode;
  final double price;
  final int qty;
  final double taxRate;
  final double tax;
  final double discount; // Item-level discount amount
  final double total;

  const SessionItemEntity({
    required this.name,
    this.hsnCode,
    required this.price,
    required this.qty,
    required this.taxRate,
    required this.tax,
    this.discount = 0,
    required this.total,
  });

  double get subtotal => price * qty;
  double get subtotalAfterDiscount => subtotal - discount;
}

/// Domain Entity - Billing Session
class SessionEntity {
  final String id;
  final String merchantId;
  final List<SessionItemEntity> items;
  final double subtotal;
  final double tax;
  final double total;
  final String status; // ACTIVE, EXPIRED, COMPLETED
  final String? paymentStatus; // null, PENDING, PAID
  final String? paymentMethod;
  final String? paymentTxnId;
  final List<String> connectedCustomers;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? completedAt;

  const SessionEntity({
    required this.id,
    required this.merchantId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    this.paymentStatus,
    this.paymentMethod,
    this.paymentTxnId,
    required this.connectedCustomers,
    required this.createdAt,
    required this.expiresAt,
    this.completedAt,
  });

  bool get isPaid => paymentStatus == 'PAID';
  bool get isActive => status == 'ACTIVE';
  bool get isExpired =>
      status == 'EXPIRED' || DateTime.now().isAfter(expiresAt);
}
