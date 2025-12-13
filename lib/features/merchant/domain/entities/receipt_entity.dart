import 'payment_entity.dart';

/// Domain Entity - Receipt (Permanent Record)
/// Receipts are stored permanently even after sessions are deleted
class ReceiptEntity {
  final String id;
  final String sessionId;
  final String merchantId;
  final String? customerId;

  // Business Info
  final String businessName;
  final String? businessPhone;
  final String? businessAddress;

  // Items
  final List<ReceiptItemEntity> items;

  // Amounts
  final double subtotal;
  final double tax;
  final double total;

  // Discount
  final double discountAmount;
  final String? discountName;

  // Payment Info (legacy single payment)
  final String paymentMethod; // CASH, CARD, UPI, etc.
  final String? paymentTxnId;
  final DateTime paidAt;

  // Split Payments (new)
  final List<PaymentEntry>? payments;
  final String? paymentStatus; // PAID, PARTIAL

  // Timestamps
  final DateTime createdAt;

  // Access logs (security)
  final List<ReceiptAccessLog> accessLogs;

  const ReceiptEntity({
    required this.id,
    required this.sessionId,
    required this.merchantId,
    this.customerId,
    required this.businessName,
    this.businessPhone,
    this.businessAddress,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    this.discountAmount = 0,
    this.discountName,
    required this.paymentMethod,
    this.paymentTxnId,
    required this.paidAt,
    this.payments,
    this.paymentStatus,
    required this.createdAt,
    this.accessLogs = const [],
  });

  // Check if this is a split payment receipt
  bool get isSplitPayment => payments != null && payments!.length > 1;

  // Get total paid amount from split payments
  double get totalPaidAmount =>
      payments?.fold<double>(0.0, (sum, p) => sum + p.amount) ?? total;
}

/// Receipt Item Entity
class ReceiptItemEntity {
  final String name;
  final String? hsnCode;
  final double price;
  final int qty;
  final double taxRate;
  final double tax;
  final double total;
  final double discount; // Item-level discount

  const ReceiptItemEntity({
    required this.name,
    this.hsnCode,
    required this.price,
    required this.qty,
    required this.taxRate,
    required this.tax,
    required this.total,
    this.discount = 0,
  });
}

/// Access Log for security tracking
class ReceiptAccessLog {
  final String? userId;
  final String accessType; // VIEW, DOWNLOAD, PRINT
  final DateTime accessedAt;
  final String? ipAddress;

  const ReceiptAccessLog({
    this.userId,
    required this.accessType,
    required this.accessedAt,
    this.ipAddress,
  });
}
