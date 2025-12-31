import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user preferences related to monthly archival prompts
class ArchivePreferencesService {
  static const String _dismissedMonthsKey = 'archive_dismissed_months';
  static const String _globalDismissalKey = 'archive_globally_dismissed';

  /// Check if user has dismissed the archive prompt for a specific month
  Future<bool> hasUserDismissedMonth(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedMonths = prefs.getStringList(_dismissedMonthsKey) ?? [];
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';
    return dismissedMonths.contains(monthKey);
  }

  /// Mark a specific month as dismissed (user clicked "Never" for this month)
  Future<void> dismissMonth(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedMonths = prefs.getStringList(_dismissedMonthsKey) ?? [];
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';

    if (!dismissedMonths.contains(monthKey)) {
      dismissedMonths.add(monthKey);
      await prefs.setStringList(_dismissedMonthsKey, dismissedMonths);
    }
  }

  /// Check if user has globally dismissed all archive prompts
  Future<bool> hasGloballyDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_globalDismissalKey) ?? false;
  }

  /// Set global dismissal preference (user never wants to see archive prompts)
  Future<void> setGlobalDismissal(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_globalDismissalKey, value);
  }

  /// Clear dismissal for a specific month (for testing purposes)
  Future<void> clearMonthDismissal(int year, int month) async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedMonths = prefs.getStringList(_dismissedMonthsKey) ?? [];
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';

    dismissedMonths.remove(monthKey);
    await prefs.setStringList(_dismissedMonthsKey, dismissedMonths);
  }

  /// Clear all dismissals (for testing purposes)
  Future<void> clearAllDismissals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dismissedMonthsKey);
    await prefs.remove(_globalDismissalKey);
  }
}
