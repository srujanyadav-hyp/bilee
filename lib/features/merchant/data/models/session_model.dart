import 'package:cloud_firestore/cloud_firestore.dart';
import 'modifier_model.dart';

/// Data Model - Session Item Line (Firestore Representation)
class SessionItemLine {
  final String name;
  final String? hsn;
  final double price;
  final double
  qty; // Changed from int to double to support fractional quantities
  final double taxRate;
  final double tax;
  final double total;
  final String? unit; // Unit for weight-based items
  final double? pricePerUnit; // Price per unit for weight-based items

  // Modifiers support for food customization
  final List<SelectedModifierModel>? selectedModifiers;
  final String? specialInstructions;

  const SessionItemLine({
    required this.name,
    this.hsn,
    required this.price,
    required this.qty,
    required this.taxRate,
    required this.tax,
    required this.total,
    this.unit,
    this.pricePerUnit,
    this.selectedModifiers,
    this.specialInstructions,
  });

  factory SessionItemLine.fromJson(Map<String, dynamic> json) {
    return SessionItemLine(
      name: json['name'] as String,
      hsn: json['hsn'] as String?,
      price: (json['price'] as num).toDouble(),
      qty: (json['qty'] as num)
          .toDouble(), // Support both int and double from Firestore
      taxRate: (json['taxRate'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      unit: json['unit'] as String? ?? 'piece',
      pricePerUnit: json['pricePerUnit'] != null
          ? (json['pricePerUnit'] as num).toDouble()
          : null,
      selectedModifiers: json['selectedModifiers'] != null
          ? (json['selectedModifiers'] as List<dynamic>)
                .map(
                  (m) =>
                      SelectedModifierModel.fromJson(m as Map<String, dynamic>),
                )
                .toList()
          : null,
      specialInstructions: json['specialInstructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'hsn': hsn,
      'price': price,
      'qty': qty,
      'taxRate': taxRate,
      'tax': tax,
      'total': total,
      if (unit != null) 'unit': unit,
      if (pricePerUnit != null) 'pricePerUnit': pricePerUnit,
      if (selectedModifiers != null)
        'selectedModifiers': selectedModifiers!.map((m) => m.toJson()).toList(),
      if (specialInstructions != null)
        'specialInstructions': specialInstructions,
    };
  }
}

/// Data Model - Billing Session (Firestore Representation)
/// Matches Firestore document structure exactly
class SessionModel {
  final String sessionId;
  final String merchantId;
  final List<SessionItemLine> items;
  final double subtotal;
  final double tax;
  final double total;
  final String status; // ACTIVE, EXPIRED, COMPLETED
  final String? paymentStatus; // null, PENDING, PAID
  final bool? paymentConfirmed; // Flag for Cloud Function trigger
  final String? paymentMethod;
  final String? txnId;
  final List<String> connectedCustomers;
  final Timestamp createdAt;
  final Timestamp expiresAt;
  final Timestamp? completedAt;

  // Kitchen orders support for restaurants (optional)
  final String? kitchenStatus; // NEW, COOKING, READY, SERVED
  final String? orderType; // DINE_IN, PARCEL
  final String? customerName; // Temporary, session only
  final String? tableNumber; // For dine-in only
  final String? phoneNumber; // Optional phone for parcels
  final Timestamp? cookingStartedAt;
  final Timestamp? readyAt;

  const SessionModel({
    required this.sessionId,
    required this.merchantId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    this.paymentStatus,
    this.paymentConfirmed,
    this.paymentMethod,
    this.txnId,
    required this.connectedCustomers,
    required this.createdAt,
    required this.expiresAt,
    this.completedAt,
    this.kitchenStatus,
    this.orderType,
    this.customerName,
    this.tableNumber,
    this.phoneNumber,
    this.cookingStartedAt,
    this.readyAt,
  });

  /// Create SessionModel from Firestore document
  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionModel(
      sessionId: doc.id,
      merchantId: data['merchantId'] as String,
      items: (data['items'] as List<dynamic>)
          .map((item) => SessionItemLine.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (data['subtotal'] as num).toDouble(),
      tax: (data['tax'] as num).toDouble(),
      total: (data['total'] as num).toDouble(),
      status: data['status'] as String,
      paymentStatus: data['paymentStatus'] as String?,
      paymentConfirmed: data['paymentConfirmed'] as bool?,
      paymentMethod: data['paymentMethod'] as String?,
      txnId: data['txnId'] as String?,
      connectedCustomers: List<String>.from(data['connectedCustomers'] as List),
      createdAt: data['createdAt'] as Timestamp,
      expiresAt: data['expiresAt'] as Timestamp,
      completedAt: data['completedAt'] as Timestamp?,
      kitchenStatus: data['kitchenStatus'] as String?,
      orderType: data['orderType'] as String?,
      customerName: data['customerName'] as String?,
      tableNumber: data['tableNumber'] as String?,
      phoneNumber: data['phoneNumber'] as String?,
      cookingStartedAt: data['cookingStartedAt'] as Timestamp?,
      readyAt: data['readyAt'] as Timestamp?,
    );
  }

  /// Create SessionModel from JSON map
  factory SessionModel.fromJson(Map<String, dynamic> json) {
    return SessionModel(
      sessionId: json['sessionId'] as String,
      merchantId: json['merchantId'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => SessionItemLine.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: json['status'] as String,
      paymentStatus: json['paymentStatus'] as String?,
      paymentConfirmed: json['paymentConfirmed'] as bool?,
      paymentMethod: json['paymentMethod'] as String?,
      txnId: json['txnId'] as String?,
      connectedCustomers: List<String>.from(json['connectedCustomers'] as List),
      createdAt: json['createdAt'] as Timestamp,
      expiresAt: json['expiresAt'] as Timestamp,
      completedAt: json['completedAt'] as Timestamp?,
      kitchenStatus: json['kitchenStatus'] as String?,
      orderType: json['orderType'] as String?,
      customerName: json['customerName'] as String?,
      tableNumber: json['tableNumber'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      cookingStartedAt: json['cookingStartedAt'] as Timestamp?,
      readyAt: json['readyAt'] as Timestamp?,
    );
  }

  /// Convert SessionModel to JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'merchantId': merchantId,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentConfirmed': paymentConfirmed,
      'paymentMethod': paymentMethod,
      'txnId': txnId,
      'connectedCustomers': connectedCustomers,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'completedAt': completedAt,
      if (kitchenStatus != null) 'kitchenStatus': kitchenStatus,
      if (orderType != null) 'orderType': orderType,
      if (customerName != null) 'customerName': customerName,
      if (tableNumber != null) 'tableNumber': tableNumber,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (cookingStartedAt != null) 'cookingStartedAt': cookingStartedAt,
      if (readyAt != null) 'readyAt': readyAt,
    };
  }
}
