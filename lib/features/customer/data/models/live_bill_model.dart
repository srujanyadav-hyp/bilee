import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/live_bill_entity.dart';

/// Data Model - Live Bill
class LiveBillModel {
  final String sessionId;
  final String merchantId;
  final String merchantName;
  final String? merchantLogo;
  final List<LiveBillItemModel> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String status;
  final String paymentMode;
  final String? upiPaymentString;
  final Timestamp createdAt;
  final Timestamp? updatedAt;

  LiveBillModel({
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

  // From Firestore
  factory LiveBillModel.fromFirestore(Map<String, dynamic> json) {
    final itemsList =
        (json['items'] as List<dynamic>?)
            ?.map(
              (item) => LiveBillItemModel.fromMap(item as Map<String, dynamic>),
            )
            .toList() ??
        [];

    return LiveBillModel(
      sessionId: json['sessionId'] ?? '',
      merchantId: json['merchantId'] ?? '',
      merchantName: json['merchantName'] ?? 'Merchant',
      merchantLogo: json['merchantLogo'],
      items: itemsList,
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      discount: (json['discount'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentMode: json['paymentMethod'] ?? json['paymentMode'] ?? 'upi',
      upiPaymentString: json['upiPaymentString'],
      createdAt: json['createdAt'] ?? Timestamp.now(),
      updatedAt: json['updatedAt'],
    );
  }

  // To Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'merchantId': merchantId,
      'merchantName': merchantName,
      'merchantLogo': merchantLogo,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'status': status,
      'paymentMode': paymentMode,
      'upiPaymentString': upiPaymentString,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
    };
  }

  // To Entity
  LiveBillEntity toEntity() {
    return LiveBillEntity(
      sessionId: sessionId,
      merchantId: merchantId,
      merchantName: merchantName,
      merchantLogo: merchantLogo,
      items: items.map((item) => item.toEntity()).toList(),
      subtotal: subtotal,
      tax: tax,
      discount: discount,
      total: total,
      status: _parseBillStatus(status),
      paymentMode: _parsePaymentMode(paymentMode),
      upiPaymentString: upiPaymentString,
      createdAt: createdAt.toDate(),
      updatedAt: updatedAt?.toDate(),
    );
  }

  // From Entity
  factory LiveBillModel.fromEntity(LiveBillEntity entity) {
    return LiveBillModel(
      sessionId: entity.sessionId,
      merchantId: entity.merchantId,
      merchantName: entity.merchantName,
      merchantLogo: entity.merchantLogo,
      items: entity.items
          .map((item) => LiveBillItemModel.fromEntity(item))
          .toList(),
      subtotal: entity.subtotal,
      tax: entity.tax,
      discount: entity.discount,
      total: entity.total,
      status: entity.status.name,
      paymentMode: entity.paymentMode.name,
      upiPaymentString: entity.upiPaymentString,
      createdAt: Timestamp.fromDate(entity.createdAt),
      updatedAt: entity.updatedAt != null
          ? Timestamp.fromDate(entity.updatedAt!)
          : null,
    );
  }

  static BillStatus _parseBillStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return BillStatus.active;
      case 'completed':
        return BillStatus.completed;
      case 'cancelled':
        return BillStatus.cancelled;
      default:
        return BillStatus.pending;
    }
  }

  static PaymentMode _parsePaymentMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'upi':
        return PaymentMode.upi;
      case 'cash':
        return PaymentMode.cash;
      case 'card':
        return PaymentMode.card;
      default:
        return PaymentMode.other;
    }
  }
}

/// Data Model - Live Bill Item
class LiveBillItemModel {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final double total;
  final String? imageUrl;
  final String? category;

  LiveBillItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.total,
    this.imageUrl,
    this.category,
  });

  factory LiveBillItemModel.fromMap(Map<String, dynamic> json) {
    return LiveBillItemModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Item',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      total: (json['total'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'],
      category: json['category'],
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
    };
  }

  LiveBillItemEntity toEntity() {
    return LiveBillItemEntity(
      id: id,
      name: name,
      price: price,
      quantity: quantity,
      total: total,
      imageUrl: imageUrl,
      category: category,
    );
  }

  factory LiveBillItemModel.fromEntity(LiveBillItemEntity entity) {
    return LiveBillItemModel(
      id: entity.id,
      name: entity.name,
      price: entity.price,
      quantity: entity.quantity,
      total: entity.total,
      imageUrl: entity.imageUrl,
      category: entity.category,
    );
  }
}
