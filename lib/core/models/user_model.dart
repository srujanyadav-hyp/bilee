/// User model for BILEE app
class UserModel {
  final String uid;
  final String role; // "merchant" or "customer"
  final String displayName;
  final String? email;
  final String? phone;
  final String? category; // For merchant only
  final String kycStatus; // "PENDING" or "VERIFIED"
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.role,
    required this.displayName,
    this.email,
    this.phone,
    this.category,
    this.kycStatus = 'PENDING',
    required this.createdAt,
  });

  /// Create from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] as String,
      role: data['role'] as String,
      displayName: data['display_name'] as String,
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      category: data['category'] as String?,
      kycStatus: data['kyc_status'] as String? ?? 'PENDING',
      createdAt: (data['created_at'] as dynamic).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'role': role,
      'display_name': displayName,
      'email': email,
      'phone': phone,
      'category': category,
      'kyc_status': kycStatus,
      'created_at': createdAt,
    };
  }

  bool get isMerchant => role == 'merchant';
  bool get isCustomer => role == 'customer';
}
