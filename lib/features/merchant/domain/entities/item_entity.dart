/// Domain Entity - Item (Pure Business Object)
/// No Flutter or Firebase dependencies
class ItemEntity {
  final String id;
  final String merchantId;
  final String name;
  final String? hsnCode;
  final String? barcode; // Barcode for fast scanning
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

  const ItemEntity({
    required this.id,
    required this.merchantId,
    required this.name,
    this.hsnCode,
    this.barcode,
    required this.price,
    required this.taxRate,
    required this.createdAt,
    required this.updatedAt,
    this.unit = 'piece',
    this.isWeightBased = false,
    this.pricePerUnit,
    this.defaultQuantity,
  });

  double get finalPrice => price * (1 + taxRate / 100);

  ItemEntity copyWith({
    String? id,
    String? merchantId,
    String? name,
    String? hsnCode,
    String? barcode,
    double? price,
    double? taxRate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? unit,
    bool? isWeightBased,
    double? pricePerUnit,
    double? defaultQuantity,
  }) {
    return ItemEntity(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      name: name ?? this.name,
      hsnCode: hsnCode ?? this.hsnCode,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      taxRate: taxRate ?? this.taxRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unit: unit ?? this.unit,
      isWeightBased: isWeightBased ?? this.isWeightBased,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      defaultQuantity: defaultQuantity ?? this.defaultQuantity,
    );
  }
}
