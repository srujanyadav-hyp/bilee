/// Authentication result wrapper
class AuthResult {
  final bool success;
  final String? errorMessage;
  final String? uid;
  final bool isNewUser;

  AuthResult({
    required this.success,
    this.errorMessage,
    this.uid,
    this.isNewUser = false,
  });

  factory AuthResult.success(String uid, {bool isNewUser = false}) {
    return AuthResult(success: true, uid: uid, isNewUser: isNewUser);
  }

  factory AuthResult.failure(String errorMessage) {
    return AuthResult(success: false, errorMessage: errorMessage);
  }
}

/// Auth method enum
enum AuthMethod { email, phone, google }

/// Registration data DTO
class RegistrationData {
  final String role; // "merchant" or "customer"
  final AuthMethod method;
  final String? email;
  final String? password;
  final String? phone;
  final String? countryCode;
  final String displayName; // username or business name
  final String? category; // For merchant only

  RegistrationData({
    required this.role,
    required this.method,
    this.email,
    this.password,
    this.phone,
    this.countryCode = '+91',
    required this.displayName,
    this.category,
  });
}
