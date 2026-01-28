import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encryption Service for securing sensitive merchant data
/// Uses AES-256 encryption with secure key storage
class EncryptionService {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'upi_encryption_key_v1';

  /// Initialize encryption key (call once on app startup)
  /// Generates and stores a new key if one doesn't exist
  static Future<void> initializeKey() async {
    try {
      final existingKey = await _storage.read(key: _keyName);
      if (existingKey == null) {
        // Generate new 256-bit (32-byte) key
        final key = Key.fromSecureRandom(32);
        await _storage.write(key: _keyName, value: key.base64);
      }
    } catch (e) {
      throw Exception('Failed to initialize encryption key: $e');
    }
  }

  /// Encrypt UPI ID before saving to Firestore
  /// Returns encrypted string in format: "IV:EncryptedData"
  static Future<String> encryptUpiId(String upiId) async {
    try {
      // Validate UPI ID format first
      if (!isValidUpiId(upiId)) {
        throw Exception('Invalid UPI ID format. Expected: username@bankname');
      }

      // Get encryption key
      final keyString = await _storage.read(key: _keyName);
      if (keyString == null) {
        throw Exception(
          'Encryption key not initialized. Call initializeKey() first.',
        );
      }

      // Create encrypter with AES-256
      final key = Key.fromBase64(keyString);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

      // Generate random IV (Initialization Vector) for each encryption
      final iv = IV.fromSecureRandom(16);

      // Encrypt the UPI ID
      final encrypted = encrypter.encrypt(upiId, iv: iv);

      // Return IV and encrypted data together (needed for decryption)
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      throw Exception('Failed to encrypt UPI ID: $e');
    }
  }

  /// Decrypt UPI ID when needed for payment processing
  /// Input format: "IV:EncryptedData"
  static Future<String> decryptUpiId(String encryptedData) async {
    try {
      // Parse IV and encrypted data
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        throw Exception(
          'Invalid encrypted data format. Expected: IV:EncryptedData',
        );
      }

      // Get encryption key
      final keyString = await _storage.read(key: _keyName);
      if (keyString == null) {
        throw Exception('Encryption key not found. Cannot decrypt.');
      }

      // Create decrypter
      final key = Key.fromBase64(keyString);
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));

      // Decrypt and return
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Failed to decrypt UPI ID: $e');
    }
  }

  /// Validate UPI ID format
  /// Valid format: username@bankname (e.g., merchant@paytm, shop@ybl)
  static bool isValidUpiId(String upiId) {
    if (upiId.isEmpty) return false;

    // UPI ID format: alphanumeric + dots/hyphens/underscores @ alphanumeric
    // Examples: merchant@paytm, shop.name@ybl, user_123@oksbi
    final regex = RegExp(r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9]+$');

    if (!regex.hasMatch(upiId)) return false;

    // Additional validation: must have @ symbol and parts on both sides
    final parts = upiId.split('@');
    if (parts.length != 2) return false;
    if (parts[0].isEmpty || parts[1].isEmpty) return false;

    // Username part should be at least 3 characters
    if (parts[0].length < 3) return false;

    // Bank/provider part should be at least 2 characters
    if (parts[1].length < 2) return false;

    return true;
  }

  /// Get common UPI provider from UPI ID
  /// Returns provider name (e.g., "PayTM", "PhonePe", "Google Pay")
  static String? getUpiProvider(String upiId) {
    if (!isValidUpiId(upiId)) return null;

    final domain = upiId.split('@')[1].toLowerCase();

    // Map common UPI handles to provider names
    final providers = {
      'paytm': 'PayTM',
      'ptm': 'PayTM',
      'ybl': 'PhonePe',
      'ibl': 'PhonePe',
      'axl': 'PhonePe',
      'okaxis': 'Google Pay',
      'oksbi': 'Google Pay',
      'okicici': 'Google Pay',
      'okhdfcbank': 'Google Pay',
      'upi': 'BHIM UPI',
      'bhim': 'BHIM UPI',
    };

    return providers[domain] ?? 'UPI';
  }

  /// Clear encryption key (use with caution - will make existing encrypted data unreadable)
  static Future<void> clearEncryptionKey() async {
    await _storage.delete(key: _keyName);
  }
}
