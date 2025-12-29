import 'package:shared_preferences/shared_preferences.dart';

/// Local Preferences Service - For UI-only settings (theme, language, etc.)
/// COST OPTIMIZATION: Uses local storage instead of Firestore for frequent UI changes
///
/// This saves 400+ Firestore writes/month per user by storing non-critical
/// preferences locally instead of syncing to cloud on every change.
class LocalPreferencesService {
  final SharedPreferences _prefs;

  LocalPreferencesService(this._prefs);

  // ==================== THEME PREFERENCES ====================

  /// Get selected theme ('light', 'dark', 'system')
  String getTheme() {
    return _prefs.getString('theme') ?? 'system';
  }

  /// Set theme preference (LOCAL ONLY - no Firestore write)
  Future<bool> setTheme(String theme) async {
    return await _prefs.setString('theme', theme);
  }

  // ==================== LANGUAGE PREFERENCES ====================

  /// Get selected language code ('en', 'hi', 'ta', etc.)
  String getLanguage() {
    return _prefs.getString('language') ?? 'en';
  }

  /// Set language preference (LOCAL ONLY)
  Future<bool> setLanguage(String languageCode) async {
    return await _prefs.setString('language', languageCode);
  }

  // ==================== UI PREFERENCES ====================

  /// Get if onboarding was completed
  bool getOnboardingCompleted() {
    return _prefs.getBool('onboarding_completed') ?? false;
  }

  /// Mark onboarding as completed
  Future<bool> setOnboardingCompleted(bool completed) async {
    return await _prefs.setBool('onboarding_completed', completed);
  }

  /// Get default tax enabled state
  bool getTaxEnabled() {
    return _prefs.getBool('tax_enabled') ?? true;
  }

  /// Set default tax enabled state
  Future<bool> setTaxEnabled(bool enabled) async {
    return await _prefs.setBool('tax_enabled', enabled);
  }

  /// Get last merchant ID (for auto-login)
  String? getLastMerchantId() {
    return _prefs.getString('last_merchant_id');
  }

  /// Set last merchant ID
  Future<bool> setLastMerchantId(String merchantId) async {
    return await _prefs.setString('last_merchant_id', merchantId);
  }

  /// Get if user prefers compact view
  bool getCompactView() {
    return _prefs.getBool('compact_view') ?? false;
  }

  /// Set compact view preference
  Future<bool> setCompactView(bool compact) async {
    return await _prefs.setBool('compact_view', compact);
  }

  /// Get if sound effects are enabled
  bool getSoundEnabled() {
    return _prefs.getBool('sound_enabled') ?? true;
  }

  /// Set sound effects preference
  Future<bool> setSoundEnabled(bool enabled) async {
    return await _prefs.setBool('sound_enabled', enabled);
  }

  /// Get if haptic feedback is enabled
  bool getHapticEnabled() {
    return _prefs.getBool('haptic_enabled') ?? true;
  }

  /// Set haptic feedback preference
  Future<bool> setHapticEnabled(bool enabled) async {
    return await _prefs.setBool('haptic_enabled', enabled);
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Clear all local preferences (useful for logout)
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }

  /// Clear only UI preferences (keep auth data)
  Future<void> clearUIPreferences() async {
    await _prefs.remove('theme');
    await _prefs.remove('language');
    await _prefs.remove('compact_view');
    await _prefs.remove('sound_enabled');
    await _prefs.remove('haptic_enabled');
  }
}
