import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/receipt_entity.dart';

/// Data Model - Receipt
class ReceiptModel {
  final String id;
  final String receiptId;
  final String sessionId;
  final String merchantId;
  final String merchantName;
  final String? merchantLogo;
  final String? merchantAddress;
  final String? merchantPhone;
  final String? merchantGst;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String? customerEmail;
  final List<ReceiptItemModel> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final double paidAmount;
  final double pendingAmount;
  final String paymentMethod;
  final String? transactionId;
  final Timestamp paymentTime;
  final Timestamp createdAt;
  final bool isVerified;
  final String? notes;
  final String? signatureUrl;

  ReceiptModel({
    required this.id,
    required this.receiptId,
    required this.sessionId,
    required this.merchantId,
    required this.merchantName,
    this.merchantLogo,
    this.merchantAddress,
    this.merchantPhone,
    this.merchantGst,
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

  // From Firestore
  factory ReceiptModel.fromFirestore(Map<String, dynamic> json, String docId) {
    final itemsList =
        (json['items'] as List<dynamic>?)
            ?.map(
              (item) => ReceiptItemModel.fromMap(item as Map<String, dynamic>),
            )
            .toList() ??
        [];

    return ReceiptModel(
      id: docId,
      receiptId: json['receiptId'] ?? '',
      sessionId: json['sessionId'] ?? '',
      merchantId: json['merchantId'] ?? '',
      merchantName: json['merchantName'] ?? 'Merchant',
      merchantLogo: json['merchantLogo'],
      merchantAddress: json['merchantAddress'],
      merchantPhone: json['merchantPhone'],
      merchantGst: json['merchantGst'],
      customerId: json['customerId'],
      customerName: json['customerName'],
      customerPhone: json['customerPhone'],
      customerEmail: json['customerEmail'],
      items: itemsList,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      paidAmount: (json['paidAmount'] ?? 0).toDouble(),
      pendingAmount: (json['pendingAmount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? 'upi',
      transactionId: json['transactionId'],
      paymentTime: json['paymentTime'] ?? Timestamp.now(),
      createdAt: json['createdAt'] ?? Timestamp.now(),
      isVerified: json['isVerified'] ?? false,
      notes: json['notes'],
      signatureUrl: json['signatureUrl'],
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'receiptId': receiptId,
      'sessionId': sessionId,
      'merchantId': merchantId,
      'merchantName': merchantName,
      'merchantLogo': merchantLogo,
      'merchantAddress': merchantAddress,
      'merchantPhone': merchantPhone,
      'merchantGst': merchantGst,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'paidAmount': paidAmount,
      'pendingAmount': pendingAmount,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'paymentTime': paymentTime,
      'createdAt': createdAt,
      'isVerified': isVerified,
      'notes': notes,
      'signatureUrl': signatureUrl,
    };
  }

  // To Entity
  ReceiptEntity toEntity() {
    return ReceiptEntity(
      id: id,
      receiptId: receiptId,
      sessionId: sessionId,
      merchantId: merchantId,
      merchantName: merchantName,
      merchantLogo: merchantLogo,
      merchantAddress: merchantAddress,
      merchantPhone: merchantPhone,
      merchantGst: merchantGst,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      items: items.map((item) => item.toEntity()).toList(),
      subtotal: subtotal,
      tax: tax,
      discount: discount,
      total: total,
      paidAmount: paidAmount,
      pendingAmount: pendingAmount,
      paymentMethod: _parsePaymentMethod(paymentMethod),
      transactionId: transactionId,
      paymentTime: paymentTime.toDate(),
      createdAt: createdAt.toDate(),
      isVerified: isVerified,
      notes: notes,
      signatureUrl: signatureUrl,
    );
  }

  // From Entity
  factory ReceiptModel.fromEntity(ReceiptEntity entity) {
    return ReceiptModel(
      id: entity.id,
      receiptId: entity.receiptId,
      sessionId: entity.sessionId,
      merchantId: entity.merchantId,
      merchantName: entity.merchantName,
      merchantLogo: entity.merchantLogo,
      merchantAddress: entity.merchantAddress,
      merchantPhone: entity.merchantPhone,
      merchantGst: entity.merchantGst,
      customerId: entity.customerId,
      customerName: entity.customerName,
      customerPhone: entity.customerPhone,
      customerEmail: entity.customerEmail,
      items: entity.items
          .map((item) => ReceiptItemModel.fromEntity(item))
          .toList(),
      subtotal: entity.subtotal,
      tax: entity.tax,
      discount: entity.discount,
      total: entity.total,
      paidAmount: entity.paidAmount,
      pendingAmount: entity.pendingAmount,
      paymentMethod: entity.paymentMethod.name,
      transactionId: entity.transactionId,
      paymentTime: Timestamp.fromDate(entity.paymentTime),
      createdAt: Timestamp.fromDate(entity.createdAt),
      isVerified: entity.isVerified,
      notes: entity.notes,
      signatureUrl: entity.signatureUrl,
    );
  }

  static PaymentMethod _parsePaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'upi':
        return PaymentMethod.upi;
      case 'cash':
        return PaymentMethod.cash;
      case 'card':
        return PaymentMethod.card;
      case 'netbanking':
        return PaymentMethod.netBanking;
      default:
        return PaymentMethod.other;
    }
  }
}

/// Data Model - Receipt Item
class ReceiptItemModel {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final double total;
  final String? imageUrl;
  final String? category;
  final String? hsnCode;

  ReceiptItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.total,
    this.imageUrl,
    this.category,
    this.hsnCode,
  });

  factory ReceiptItemModel.fromMap(Map<String, dynamic> json) {
    return ReceiptItemModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Item',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      total: (json['total'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'],
      category: json['category'],
      hsnCode: json['hsnCode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'total': total,
      'imageUrl': imageUrl,
      'category': category,
      'hsnCode': hsnCode,
    };
  }

  ReceiptItemEntity toEntity() {
    return ReceiptItemEntity(
      id: id,
      name: name,
      price: price,
      quantity: quantity,
      total: total,
      imageUrl: imageUrl,
      category: category,
      hsnCode: hsnCode,
    );
  }

  factory ReceiptItemModel.fromEntity(ReceiptItemEntity entity) {
    return ReceiptItemModel(
      id: entity.id,
      name: entity.name,
      price: entity.price,
      quantity: entity.quantity,
      total: entity.total,
      imageUrl: entity.imageUrl,
      category: entity.category,
      hsnCode: entity.hsnCode,
    );
  }
}
