/// Domain Entity - Receipt
/// Represents a completed transaction receipt
class ReceiptEntity {
  final String id;
  final String receiptId; // Human-readable ID like #RC12345
  final String sessionId;
  final String merchantId;
  final String merchantName;
  final String? merchantLogo;
  final String? merchantAddress;
  final String? merchantPhone;
  final String? merchantGst;
  final String? businessCategory; // Restaurant, Retail, Grocery, etc.

  // Customer details
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;

  // Items
  final List<ReceiptItemEntity> items;

  // Amounts
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final double paidAmount;
  final double pendingAmount;

  // Payment
  final PaymentMethod paymentMethod;
  final String? transactionId;
  final DateTime paymentTime;

  // Metadata
  final DateTime createdAt;
  final bool isVerified;
  final String? notes;
  final String? signatureUrl;

  const ReceiptEntity({
    required this.id,
    required this.receiptId,
    required this.sessionId,
    required this.merchantId,
    required this.merchantName,
    this.merchantLogo,
    this.merchantAddress,
    this.merchantPhone,
    this.merchantGst,
    this.businessCategory,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.customerEmail,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    required this.paidAmount,
    required this.pendingAmount,
    required this.paymentMethod,
    this.transactionId,
    required this.paymentTime,
    required this.createdAt,
    this.isVerified = false,
    this.notes,
    this.signatureUrl,
  });

  ReceiptEntity copyWith({
    String? id,
    String? receiptId,
    String? sessionId,
    String? merchantId,
    String? merchantName,
    String? merchantLogo,
    String? merchantAddress,
    String? merchantPhone,
    String? merchantGst,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    List<ReceiptItemEntity>? items,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    double? paidAmount,
    double? pendingAmount,
    PaymentMethod? paymentMethod,
    String? transactionId,
    DateTime? paymentTime,
    DateTime? createdAt,
    bool? isVerified,
    String? notes,
    String? signatureUrl,
  }) {
    return ReceiptEntity(
      id: id ?? this.id,
      receiptId: receiptId ?? this.receiptId,
      sessionId: sessionId ?? this.sessionId,
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      merchantLogo: merchantLogo ?? this.merchantLogo,
      merchantAddress: merchantAddress ?? this.merchantAddress,
      merchantPhone: merchantPhone ?? this.merchantPhone,
      merchantGst: merchantGst ?? this.merchantGst,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      paidAmount: paidAmount ?? this.paidAmount,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionId: transactionId ?? this.transactionId,
      paymentTime: paymentTime ?? this.paymentTime,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      notes: notes ?? this.notes,
      signatureUrl: signatureUrl ?? this.signatureUrl,
    );
  }

  bool get isPaid => pendingAmount == 0;
  bool get isPartiallyPaid => pendingAmount > 0 && paidAmount > 0;
}

/// Receipt Item Entity
class ReceiptItemEntity {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final double total;
  final String? imageUrl;
  final String? category;
  final String? hsnCode;

  const ReceiptItemEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.total,
    this.imageUrl,
    this.category,
    this.hsnCode,
  });

  ReceiptItemEntity copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    double? total,
    String? imageUrl,
    String? category,
    String? hsnCode,
  }) {
    return ReceiptItemEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      total: total ?? this.total,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      hsnCode: hsnCode ?? this.hsnCode,
    );
  }
}

/// Payment Method
enum PaymentMethod { upi, cash, card, netBanking, other }

/// Helper class for PaymentMethod utilities (Web-compatible)
class PaymentMethodHelper {
  static String getDisplayName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.netBanking:
        return 'Net Banking';
      case PaymentMethod.other:
        return 'Other';
    }
  }

  static String getIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.upi:
        return '📱';
      case PaymentMethod.cash:
        return '💵';
      case PaymentMethod.card:
        return '💳';
      case PaymentMethod.netBanking:
        return '🏦';
      case PaymentMethod.other:
        return '💰';
    }
  }
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName => PaymentMethodHelper.getDisplayName(this);
  String get icon => PaymentMethodHelper.getIcon(this);
}
