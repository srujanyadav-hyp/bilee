import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

/// Theme Provider for BILEE
/// Manages theme mode (light/dark) and persists user preference
class ThemeProvider extends ChangeNotifier {
  static const String _themePreferenceKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider() {
    _loadThemePreference();
  }

  /// Current theme mode
  ThemeMode get themeMode => _themeMode;

  /// Check if dark mode is active
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Check if light mode is active
  bool get isLightMode => _themeMode == ThemeMode.light;

  /// Check if system mode is active
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Get light theme data
  ThemeData get lightTheme => AppTheme.lightTheme;

  /// Get dark theme data
  // ThemeData get darkTheme => AppTheme.darkTheme;

  /// Load theme preference from storage
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themePreferenceKey);

      if (savedTheme != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (mode) => mode.toString() == savedTheme,
          orElse: () => ThemeMode.system,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }

  /// Save theme preference to storage
  Future<void> _saveThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePreferenceKey, _themeMode.toString());
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _saveThemePreference();
      notifyListeners();
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  /// Set light theme
  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  /// Set dark theme
  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }

  /// Set system theme (follow system settings)
  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  /// Get theme brightness for current context
  Brightness getThemeBrightness(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness;
    }
    return _themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;
  }
}
