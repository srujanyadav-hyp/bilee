import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for managing role persistence
/// Uses flutter_secure_storage for secure key-value storage
class RoleStorageService {
  static const String _roleKey = 'selected_role';
  static const String _merchantRole = 'merchant';
  static const String _customerRole = 'customer';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Save the selected role
  /// @param role: 'merchant' or 'customer'
  Future<void> saveRole(String role) async {
    if (role != _merchantRole && role != _customerRole) {
      throw ArgumentError(
        'Invalid role: $role. Must be "merchant" or "customer"',
      );
    }
    await _storage.write(key: _roleKey, value: role);
  }

  /// Get the saved role
  /// @return 'merchant', 'customer', or null if not set
  Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  /// Clear the saved role
  Future<void> clearRole() async {
    await _storage.delete(key: _roleKey);
  }

  /// Check if role is merchant
  Future<bool> isMerchant() async {
    final role = await getRole();
    return role == _merchantRole;
  }

  /// Check if role is customer
  Future<bool> isCustomer() async {
    final role = await getRole();
    return role == _customerRole;
  }

  /// Check if role is set
  Future<bool> hasRole() async {
    final role = await getRole();
    return role != null;
  }
}
