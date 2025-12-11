/// Domain Entity - Item (Pure Business Object)
/// No Flutter or Firebase dependencies
class ItemEntity {
  final String id;
  final String merchantId;
  final String name;
  final String? hsnCode;
  final double price;
  final double taxRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ItemEntity({
    required this.id,
    required this.merchantId,
    required this.name,
    this.hsnCode,
    required this.price,
    required this.taxRate,
    required this.createdAt,
    required this.updatedAt,
  });

  double get finalPrice => price * (1 + taxRate / 100);

  ItemEntity copyWith({
    String? id,
    String? merchantId,
    String? name,
    String? hsnCode,
    double? price,
    double? taxRate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItemEntity(
      id: id ?? this.id,
      merchantId: merchantId ?? this.merchantId,
      name: name ?? this.name,
      hsnCode: hsnCode ?? this.hsnCode,
      price: price ?? this.price,
      taxRate: taxRate ?? this.taxRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
