import 'package:cloud_firestore/cloud_firestore.dart';

/// Data Model - Session Item Line (Firestore Representation)
class SessionItemLine {
  final String name;
  final String? hsn;
  final double price;
  final int qty;
  final double taxRate;
  final double tax;
  final double total;

  const SessionItemLine({
    required this.name,
    this.hsn,
    required this.price,
    required this.qty,
    required this.taxRate,
    required this.tax,
    required this.total,
  });

  factory SessionItemLine.fromJson(Map<String, dynamic> json) {
    return SessionItemLine(
      name: json['name'] as String,
      hsn: json['hsn'] as String?,
      price: (json['price'] as num).toDouble(),
      qty: json['qty'] as int,
      taxRate: (json['taxRate'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
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
  final String? paymentMethod;
  final String? txnId;
  final List<String> connectedCustomers;
  final Timestamp createdAt;
  final Timestamp expiresAt;
  final Timestamp? completedAt;

  const SessionModel({
    required this.sessionId,
    required this.merchantId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.status,
    this.paymentStatus,
    this.paymentMethod,
    this.txnId,
    required this.connectedCustomers,
    required this.createdAt,
    required this.expiresAt,
    this.completedAt,
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
      paymentMethod: data['paymentMethod'] as String?,
      txnId: data['txnId'] as String?,
      connectedCustomers: List<String>.from(data['connectedCustomers'] as List),
      createdAt: data['createdAt'] as Timestamp,
      expiresAt: data['expiresAt'] as Timestamp,
      completedAt: data['completedAt'] as Timestamp?,
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
      paymentMethod: json['paymentMethod'] as String?,
      txnId: json['txnId'] as String?,
      connectedCustomers: List<String>.from(json['connectedCustomers'] as List),
      createdAt: json['createdAt'] as Timestamp,
      expiresAt: json['expiresAt'] as Timestamp,
      completedAt: json['completedAt'] as Timestamp?,
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
      'paymentMethod': paymentMethod,
      'txnId': txnId,
      'connectedCustomers': connectedCustomers,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'completedAt': completedAt,
    };
  }
}
