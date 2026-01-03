/// Model for parsed voice input
/// Stores item with unit information for smart billing
class ParsedItem {
  final String name;
  final double price; // Total price mentioned by merchant
  final String? unit; // Full unit string (e.g., "1 kg", "500 ml")
  final double? quantity; // Numeric quantity (1, 0.5, 2.5, etc.)
  final String? unitType; // Unit type only (kg, liter, piece, etc.)
  final double? pricePerUnit; // Calculated price per unit for billing

  ParsedItem({
    required this.name,
    required this.price,
    this.unit,
    this.quantity,
    this.unitType,
    this.pricePerUnit,
  });

  @override
  String toString() {
    return 'ParsedItem(name: $name, price: ₹$price${unit != null ? ', unit: $unit' : ''}${pricePerUnit != null ? ', per unit: ₹$pricePerUnit/$unitType' : ''})';
  }
}
