import 'package:cloud_firestore/cloud_firestore.dart';

/// Data Model - Item (Firestore Representation)
/// Matches Firestore document structure exactly
class ItemModel {
  final String id;
  final String merchantId;
  final String name;
  final double price;
  final String? hsn;
  final String? category;
  final double taxRate;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const ItemModel({
    required this.id,
    required this.merchantId,
    required this.name,
    required this.price,
    this.hsn,
    this.category,
    required this.taxRate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ItemModel from Firestore document
  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemModel(
      id: doc.id,
      merchantId: data['merchantId'] as String,
      name: data['name'] as String,
      price: (data['price'] as num).toDouble(),
      hsn: data['hsn'] as String?,
      category: data['category'] as String?,
      taxRate: (data['taxRate'] as num).toDouble(),
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp,
    );
  }

  /// Create ItemModel from JSON map
  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as String,
      merchantId: json['merchantId'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      hsn: json['hsn'] as String?,
      category: json['category'] as String?,
      taxRate: (json['taxRate'] as num).toDouble(),
      createdAt: json['createdAt'] as Timestamp,
      updatedAt: json['updatedAt'] as Timestamp,
    );
  }

  /// Convert ItemModel to JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'merchantId': merchantId,
      'name': name,
      'price': price,
      'hsn': hsn,
      'category': category,
      'taxRate': taxRate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create a copy with updated fields
  ItemModel copyWith({
    String? id,
    String? merchantId,
    String? name,
    double? price,
    String? hsn,
    String? category,
    double? taxRate,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      name: name ?? this.name,
      price: price ?? this.price,
      hsn: hsn ?? this.hsn,
      category: category ?? this.category,
      taxRate: taxRate ?? this.taxRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
