import 'package:shared_preferences/shared_preferences.dart';

/// Device Mode Service - manages whether device is in COUNTER or KITCHEN mode
class DeviceModeService {
  static const String _deviceModeKey = 'device_mode';

  // Device modes
  static const String modeCounter = 'COUNTER';
  static const String modeKitchen = 'KITCHEN';

  /// Get current device mode
  static Future<String> getDeviceMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceModeKey) ?? modeCounter; // Default to counter
  }

  /// Set device mode
  static Future<void> setDeviceMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceModeKey, mode);
  }

  /// Check if device is in kitchen mode
  static Future<bool> isKitchenMode() async {
    final mode = await getDeviceMode();
    return mode == modeKitchen;
  }

  /// Check if device is in counter mode
  static Future<bool> isCounterMode() async {
    final mode = await getDeviceMode();
    return mode == modeCounter;
  }
}
