import 'modifier_entity.dart';

/// Domain Entity - Session Item
class SessionItemEntity {
  final String name;
  final String? hsnCode;
  final double price;
  final double
  qty; // Changed from int to double to support fractional quantities (0.5kg, 2.5kg, etc.)
  final double taxRate;
  final double tax;
  final double discount; // Item-level discount amount
  final double total;

  // Unit support for weight-based billing
  final String unit; // 'piece', 'kg', 'gram', 'liter', 'ml'
  final double? pricePerUnit; // Price per kg/liter (null for piece-based items)

  // Modifiers support for food customization
  final List<SelectedModifierEntity>?
  selectedModifiers; // Selected customizations
  final String? specialInstructions; // "Less oil", "Extra plate", etc.

  const SessionItemEntity({
    required this.name,
    this.hsnCode,
    required this.price,
    required this.qty,
    required this.taxRate,
    required this.tax,
    this.discount = 0,
    required this.total,
    this.unit = 'piece',
    this.pricePerUnit,
    this.selectedModifiers,
    this.specialInstructions,
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
  final bool? paymentConfirmed; // Flag for Cloud Function trigger
  final String? paymentMethod;
  final String? paymentTxnId;
  final List<String> connectedCustomers;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? completedAt;

  // Kitchen orders support for restaurants (optional)
  final String? kitchenStatus; // NEW, COOKING, READY, SERVED
  final String? orderType; // DINE_IN, PARCEL
  final String? customerName; // Temporary, session only
  final String? tableNumber; // For dine-in only
  final DateTime? cookingStartedAt;
  final DateTime? readyAt;

  const SessionEntity({
    required this.id,
    required this.merchantId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    this.paymentStatus,
    this.paymentConfirmed,
    this.paymentMethod,
    this.paymentTxnId,
    required this.connectedCustomers,
    required this.createdAt,
    required this.expiresAt,
    this.completedAt,
    this.kitchenStatus,
    this.orderType,
    this.customerName,
    this.tableNumber,
    this.cookingStartedAt,
    this.readyAt,
  });

  bool get isPaid => paymentStatus == 'PAID';
  bool get isActive => status == 'ACTIVE';
  bool get isExpired =>
      status == 'EXPIRED' || DateTime.now().isAfter(expiresAt);

  /// Create a copy of this entity with some fields replaced
  SessionEntity copyWith({
    String? id,
    String? merchantId,
    List<SessionItemEntity>? items,
    double? subtotal,
    double? tax,
    double? total,
    String? status,
    String? paymentStatus,
    bool? paymentConfirmed,
    String? paymentMethod,
    String? paymentTxnId,
    List<String>? connectedCustomers,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? completedAt,
    String? kitchenStatus,
    String? orderType,
    String? customerName,
    String? tableNumber,
    DateTime? cookingStartedAt,
    DateTime? readyAt,
  }) {
    return SessionEntity(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentConfirmed: paymentConfirmed ?? this.paymentConfirmed,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentTxnId: paymentTxnId ?? this.paymentTxnId,
      connectedCustomers: connectedCustomers ?? this.connectedCustomers,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      completedAt: completedAt ?? this.completedAt,
      kitchenStatus: kitchenStatus ?? this.kitchenStatus,
      orderType: orderType ?? this.orderType,
      customerName: customerName ?? this.customerName,
      tableNumber: tableNumber ?? this.tableNumber,
      cookingStartedAt: cookingStartedAt ?? this.cookingStartedAt,
      readyAt: readyAt ?? this.readyAt,
    );
  }
}
