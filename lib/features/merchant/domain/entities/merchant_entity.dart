/// Domain Entity - Merchant Profile
class MerchantEntity {
  final String id; // Same as Firebase Auth UID
  final String businessName;
  final String? businessPhone;
  final String? businessAddress;
  final String? businessEmail;
  final String? gstNumber;
  final String? panNumber;
  final String? upiId; // UPI ID for receiving payments (e.g., merchant@upi)
  final String? logoUrl;
  final String businessType; // Restaurant, Retail, etc.
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MerchantEntity({
    required this.id,
    required this.businessName,
    this.businessPhone,
    this.businessAddress,
    this.businessEmail,
    this.gstNumber,
    this.panNumber,
    this.upiId,
    this.logoUrl,
    required this.businessType,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
}
