import 'package:cloud_firestore/cloud_firestore.dart';

/// Data Model - Receipt Item Line
class ReceiptItemLine {
  final String name;
  final String? hsn;
  final int qty;
  final double price;
  final double taxRate;
  final double tax;
  final double total;

  const ReceiptItemLine({
    required this.name,
    this.hsn,
    required this.qty,
    required this.price,
    required this.taxRate,
    required this.tax,
    required this.total,
  });

  factory ReceiptItemLine.fromJson(Map<String, dynamic> json) {
    return ReceiptItemLine(
      name: json['name'] as String,
      hsn: json['hsn'] as String?,
      qty: json['qty'] as int,
      price: (json['price'] as num).toDouble(),
      taxRate: (json['taxRate'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'hsn': hsn,
      'qty': qty,
      'price': price,
      'taxRate': taxRate,
      'tax': tax,
      'total': total,
    };
  }
}

/// Data Model - Receipt (Firestore Representation)
/// Generated after a session is completed/paid
class ReceiptModel {
  final String receiptId;
  final String merchantId;
  final String sessionId;
  final List<ReceiptItemLine> items;
  final double subtotal;
  final double tax;
  final double total;
  final String paymentMethod;
  final String? txnId;
  final Timestamp createdAt;

  const ReceiptModel({
    required this.receiptId,
    required this.merchantId,
    required this.sessionId,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    this.txnId,
    required this.createdAt,
  });

  /// Create ReceiptModel from Firestore document
  factory ReceiptModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReceiptModel(
      receiptId: doc.id,
      merchantId: data['merchantId'] as String,
      sessionId: data['sessionId'] as String,
      items: (data['items'] as List<dynamic>)
          .map((item) => ReceiptItemLine.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (data['subtotal'] as num).toDouble(),
      tax: (data['tax'] as num).toDouble(),
      total: (data['total'] as num).toDouble(),
      paymentMethod: data['paymentMethod'] as String,
      txnId: data['txnId'] as String?,
      createdAt: data['createdAt'] as Timestamp,
    );
  }

  /// Create ReceiptModel from JSON map
  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      receiptId: json['receiptId'] as String,
      merchantId: json['merchantId'] as String,
      sessionId: json['sessionId'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => ReceiptItemLine.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      txnId: json['txnId'] as String?,
      createdAt: json['createdAt'] as Timestamp,
    );
  }

  /// Convert ReceiptModel to JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'merchantId': merchantId,
      'sessionId': sessionId,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
      'paymentMethod': paymentMethod,
      'txnId': txnId,
      'createdAt': createdAt,
    };
  }
}
