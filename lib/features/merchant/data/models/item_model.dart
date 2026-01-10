import 'package:cloud_firestore/cloud_firestore.dart';
import 'modifier_model.dart';

/// Data Model - Item (Firestore Representation)
/// Matches Firestore document structure exactly
class ItemModel {
  final String id;
  final String merchantId;
  final String name;
  final double price;
  final String? hsn;
  final String? category;
  final String? barcode; // Barcode for fast scanning
  final String?
  itemCode; // 3-4 digit code for number pad fast input (e.g., "101", "205")
  final double taxRate;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  // Unit support fields
  final String unit; // 'piece', 'kg', 'gram', 'liter', 'ml'
  final bool isWeightBased; // true for variable weight items
  final double? pricePerUnit; // Price per kg/liter
  final double? defaultQuantity; // Default quantity for quick add

  // Modifiers support for restaurants
  final List<ModifierGroupModel>? modifierGroups;

  const ItemModel({
    required this.id,
    required this.merchantId,
    required this.name,
    required this.price,
    this.hsn,
    this.category,
    this.barcode,
    this.itemCode,
    required this.taxRate,
    required this.createdAt,
    required this.updatedAt,
    this.unit = 'piece',
    this.isWeightBased = false,
    this.pricePerUnit,
    this.defaultQuantity,
    this.modifierGroups,
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
      barcode: data['barcode'] as String?,
      itemCode: data['itemCode'] as String?,
      taxRate: (data['taxRate'] as num).toDouble(),
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp,
      unit: data['unit'] as String? ?? 'piece',
      isWeightBased: data['isWeightBased'] as bool? ?? false,
      pricePerUnit: data['pricePerUnit'] != null
          ? (data['pricePerUnit'] as num).toDouble()
          : null,
      defaultQuantity: data['defaultQuantity'] != null
          ? (data['defaultQuantity'] as num).toDouble()
          : null,
      modifierGroups: data['modifierGroups'] != null
          ? (data['modifierGroups'] as List<dynamic>)
                .map(
                  (m) => ModifierGroupModel.fromJson(m as Map<String, dynamic>),
                )
                .toList()
          : null,
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
      barcode: json['barcode'] as String?,
      itemCode: json['itemCode'] as String?,
      taxRate: (json['taxRate'] as num).toDouble(),
      createdAt: json['createdAt'] as Timestamp,
      updatedAt: json['updatedAt'] as Timestamp,
      unit: json['unit'] as String? ?? 'piece',
      isWeightBased: json['isWeightBased'] as bool? ?? false,
      pricePerUnit: json['pricePerUnit'] != null
          ? (json['pricePerUnit'] as num).toDouble()
          : null,
      defaultQuantity: json['defaultQuantity'] != null
          ? (json['defaultQuantity'] as num).toDouble()
          : null,
      modifierGroups: json['modifierGroups'] != null
          ? (json['modifierGroups'] as List<dynamic>)
                .map(
                  (m) => ModifierGroupModel.fromJson(m as Map<String, dynamic>),
                )
                .toList()
          : null,
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
      if (barcode != null) 'barcode': barcode,
      if (itemCode != null) 'itemCode': itemCode,
      'taxRate': taxRate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'unit': unit,
      'isWeightBased': isWeightBased,
      if (pricePerUnit != null) 'pricePerUnit': pricePerUnit,
      if (defaultQuantity != null) 'defaultQuantity': defaultQuantity,
      if (modifierGroups != null)
        'modifierGroups': modifierGroups!.map((m) => m.toJson()).toList(),
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
    String? barcode,
    String? itemCode,
    double? taxRate,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? unit,
    bool? isWeightBased,
    double? pricePerUnit,
    double? defaultQuantity,
    List<ModifierGroupModel>? modifierGroups,
  }) {
    return ItemModel(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      name: name ?? this.name,
      price: price ?? this.price,
      hsn: hsn ?? this.hsn,
      category: category ?? this.category,
      barcode: barcode ?? this.barcode,
      itemCode: itemCode ?? this.itemCode,
      taxRate: taxRate ?? this.taxRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unit: unit ?? this.unit,
      isWeightBased: isWeightBased ?? this.isWeightBased,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      defaultQuantity: defaultQuantity ?? this.defaultQuantity,
      modifierGroups: modifierGroups ?? this.modifierGroups,
    );
  }
}
