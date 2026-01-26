import 'modifier_entity.dart';

/// Domain Entity - Item (Pure Business Object)
/// No Flutter or Firebase dependencies
class ItemEntity {
  final String id;
  final String merchantId;
  final String name;
  final String? hsnCode;
  final String? barcode; // Barcode for fast scanning
  final String?
  itemCode; // 3-4 digit code for number pad fast input (e.g., "101", "205")
  final double price;
  final double taxRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Unit support for weight-based billing
  final String unit; // 'piece', 'kg', 'gram', 'liter', 'ml'
  final bool
  isWeightBased; // true for variable weight items (kg, gram, liter, ml)
  final double? pricePerUnit; // Price per kg/liter (null for piece-based items)
  final double?
  defaultQuantity; // Default quantity for quick add (e.g., 1, 0.5, 0.25)

  // Modifiers support for food customization (restaurants)
  final List<ModifierGroupEntity>?
  modifierGroups; // Optional: Spice levels, add-ons, etc.

  // Inventory Management fields
  final bool inventoryEnabled; // Whether to track inventory for this item
  final double? currentStock; // Current stock quantity (null if not tracked)
  final double?
  lowStockThreshold; // Alert when stock falls below this (null if not tracked)
  final String?
  stockUnit; // Unit of measurement (pieces, kg, liters, boxes, etc.)
  final DateTime? lastStockUpdate; // When stock was last updated

  const ItemEntity({
    required this.id,
    required this.merchantId,
    required this.name,
    this.hsnCode,
    this.barcode,
    this.itemCode,
    required this.price,
    required this.taxRate,
    required this.createdAt,
    required this.updatedAt,
    this.unit = 'piece',
    this.isWeightBased = false,
    this.pricePerUnit,
    this.defaultQuantity,
    this.modifierGroups,
    this.inventoryEnabled = false,
    this.currentStock,
    this.lowStockThreshold,
    this.stockUnit,
    this.lastStockUpdate,
  });

  double get finalPrice => price * (1 + taxRate / 100);

  // Inventory computed properties
  bool get isLowStock =>
      inventoryEnabled &&
      currentStock != null &&
      lowStockThreshold != null &&
      currentStock! <= lowStockThreshold!;

  bool get isOutOfStock =>
      inventoryEnabled && currentStock != null && currentStock! <= 0;

  bool get hasStock =>
      !inventoryEnabled || (currentStock != null && currentStock! > 0);

  ItemEntity copyWith({
    String? id,
    String? merchantId,
    String? name,
    String? hsnCode,
    String? barcode,
    String? itemCode,
    double? price,
    double? taxRate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? unit,
    bool? isWeightBased,
    double? pricePerUnit,
    double? defaultQuantity,
    List<ModifierGroupEntity>? modifierGroups,
    bool? inventoryEnabled,
    double? currentStock,
    double? lowStockThreshold,
    String? stockUnit,
    DateTime? lastStockUpdate,
  }) {
    return ItemEntity(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      name: name ?? this.name,
      hsnCode: hsnCode ?? this.hsnCode,
      barcode: barcode ?? this.barcode,
      itemCode: itemCode ?? this.itemCode,
      price: price ?? this.price,
      taxRate: taxRate ?? this.taxRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unit: unit ?? this.unit,
      isWeightBased: isWeightBased ?? this.isWeightBased,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      defaultQuantity: defaultQuantity ?? this.defaultQuantity,
      modifierGroups: modifierGroups ?? this.modifierGroups,
      inventoryEnabled: inventoryEnabled ?? this.inventoryEnabled,
      currentStock: currentStock ?? this.currentStock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      stockUnit: stockUnit ?? this.stockUnit,
      lastStockUpdate: lastStockUpdate ?? this.lastStockUpdate,
    );
  }
}
