/// Domain Entity - Live Bill
/// Represents a real-time bill being viewed by customer
class LiveBillEntity {
  final String sessionId;
  final String merchantId;
  final String merchantName;
  final String? merchantLogo;
  final List<LiveBillItemEntity> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final BillStatus status;
  final PaymentMode paymentMode;
  final String? upiPaymentString;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const LiveBillEntity({
    required this.sessionId,
    required this.merchantId,
    required this.merchantName,
    this.merchantLogo,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.discount,
    required this.total,
    required this.status,
    required this.paymentMode,
    this.upiPaymentString,
    required this.createdAt,
    this.updatedAt,
  });

  LiveBillEntity copyWith({
    String? sessionId,
    String? merchantId,
    String? merchantName,
    String? merchantLogo,
    List<LiveBillItemEntity>? items,
    double? subtotal,
    double? tax,
    double? discount,
    double? total,
    BillStatus? status,
    PaymentMode? paymentMode,
    String? upiPaymentString,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LiveBillEntity(
      sessionId: sessionId ?? this.sessionId,
      merchantId: merchantId ?? this.merchantId,
      merchantName: merchantName ?? this.merchantName,
      merchantLogo: merchantLogo ?? this.merchantLogo,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentMode: paymentMode ?? this.paymentMode,
      upiPaymentString: upiPaymentString ?? this.upiPaymentString,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive => status == BillStatus.active;
  bool get isPending => status == BillStatus.pending;
  bool get isCompleted => status == BillStatus.completed;
  bool get isCashPayment => paymentMode == PaymentMode.cash;
  bool get isUpiPayment => paymentMode == PaymentMode.upi;
}

/// Live Bill Item Entity
class LiveBillItemEntity {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final double total;
  final String? imageUrl;
  final String? category;

  const LiveBillItemEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.total,
    this.imageUrl,
    this.category,
  });

  LiveBillItemEntity copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    double? total,
    String? imageUrl,
    String? category,
  }) {
    return LiveBillItemEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      total: total ?? this.total,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
    );
  }
}

/// Bill Status
enum BillStatus { pending, active, completed, cancelled }

/// Payment Mode
enum PaymentMode { upi, cash, card, other }
