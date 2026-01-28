/// Domain Entity - Merchant Profile
class MerchantEntity {
  final String id; // Same as Firebase Auth UID
  final String businessName;
  final String? businessPhone;
  final String? businessAddress;
  final String? businessEmail;
  final String? gstNumber;
  final String? panNumber;
  final String?
  upiId; // ENCRYPTED UPI ID for receiving payments (e.g., merchant@upi)
  final String? logoUrl;
  final String businessType; // Restaurant, Retail, etc.
  final bool isActive;

  // UPI Payment Automation Fields
  final bool isUpiEnabled; // Whether UPI automation is enabled
  final bool isUpiVerified; // Whether UPI ID has been verified
  final String?
  upiProvider; // UPI provider name (e.g., "PayTM", "PhonePe", "Google Pay")

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
    this.isUpiEnabled = false,
    this.isUpiVerified = false,
    this.upiProvider,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy with updated fields
  MerchantEntity copyWith({
    String? id,
    String? businessName,
    String? businessPhone,
    String? businessAddress,
    String? businessEmail,
    String? gstNumber,
    String? panNumber,
    String? upiId,
    String? logoUrl,
    String? businessType,
    bool? isActive,
    bool? isUpiEnabled,
    bool? isUpiVerified,
    String? upiProvider,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MerchantEntity(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      businessPhone: businessPhone ?? this.businessPhone,
      businessAddress: businessAddress ?? this.businessAddress,
      businessEmail: businessEmail ?? this.businessEmail,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      upiId: upiId ?? this.upiId,
      logoUrl: logoUrl ?? this.logoUrl,
      businessType: businessType ?? this.businessType,
      isActive: isActive ?? this.isActive,
      isUpiEnabled: isUpiEnabled ?? this.isUpiEnabled,
      isUpiVerified: isUpiVerified ?? this.isUpiVerified,
      upiProvider: upiProvider ?? this.upiProvider,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
