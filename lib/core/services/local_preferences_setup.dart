import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_preferences_service.dart';

/// Service Locator Setup
/// Add this to your existing service locator initialization
Future<void> setupLocalPreferences() async {
  final sl = GetIt.instance;

  // Register SharedPreferences instance
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // Register LocalPreferencesService
  sl.registerSingleton<LocalPreferencesService>(
    LocalPreferencesService(sl<SharedPreferences>()),
  );
}

/// USAGE EXAMPLE:
/// 
/// // In your theme provider or settings page:
/// class ThemeProvider with ChangeNotifier {
///   final LocalPreferencesService _localPrefs;
///   
///   ThemeProvider(this._localPrefs);
///   
///   String get theme => _localPrefs.getTheme();
///   
///   Future<void> setTheme(String theme) async {
///     await _localPrefs.setTheme(theme);
///     notifyListeners();
///     // NO Firestore write! Saves $$$
///   }
/// }
/// 
/// // BEFORE (Firestore write on every theme change):
/// await _firestore.collection('userPreferences').doc(merchantId).set({
///   'theme': 'dark',  // ❌ Costs money on every change
/// }, SetOptions(merge: true));
/// 
/// // AFTER (Local storage only):
/// await _localPrefs.setTheme('dark');  // ✅ Free, instant, offline
