import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Local storage service using Hive for offline-first architecture
///
/// Provides fast, secure local data storage with:
/// - Receipts cache
/// - Budget settings
/// - Sync queue for pending operations
class LocalStorageService {
  // Box names
  static const String _receiptsBoxName = 'receipts';
  static const String _budgetsBoxName = 'budgets';
  static const String _syncQueueBoxName = 'sync_queue';
  static const String _settingsBoxName = 'settings';

  // Lazy boxes for better performance
  late Box<Map<dynamic, dynamic>> _receiptsBox;
  late Box<Map<dynamic, dynamic>> _budgetsBox;
  late Box<Map<dynamic, dynamic>> _syncQueueBox;
  late Box _settingsBox;

  /// Initialize Hive and open all boxes
  Future<void> initialize() async {
    debugPrint('📦 Initializing local storage...');

    try {
      // Initialize Hive
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        await Hive.initFlutter(appDir.path);
      } else {
        await Hive.initFlutter();
      }

      // Open boxes
      _receiptsBox = await Hive.openBox<Map<dynamic, dynamic>>(
        _receiptsBoxName,
      );
      _budgetsBox = await Hive.openBox<Map<dynamic, dynamic>>(_budgetsBoxName);
      _syncQueueBox = await Hive.openBox<Map<dynamic, dynamic>>(
        _syncQueueBoxName,
      );
      _settingsBox = await Hive.openBox(_settingsBoxName);

      debugPrint('✅ Local storage initialized');
      debugPrint('   - Receipts: ${_receiptsBox.length} cached');
      debugPrint('   - Budgets: ${_budgetsBox.length} cached');
      debugPrint('   - Sync queue: ${_syncQueueBox.length} pending');
    } catch (e, stackTrace) {
      debugPrint('❌ Failed to initialize local storage: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // ==================== RECEIPTS ====================

  /// Save receipt to local cache
  Future<void> saveReceipt(String id, Map<String, dynamic> data) async {
    try {
      await _receiptsBox.put(id, data);
      debugPrint('💾 Saved receipt locally: $id');
    } catch (e) {
      debugPrint('❌ Error saving receipt: $e');
      rethrow;
    }
  }

  /// Get receipt from local cache
  Map<String, dynamic>? getReceipt(String id) {
    try {
      final data = _receiptsBox.get(id);
      return data?.cast<String, dynamic>();
    } catch (e) {
      debugPrint('❌ Error getting receipt: $e');
      return null;
    }
  }

  /// Get all receipts from local cache
  List<Map<String, dynamic>> getAllReceipts() {
    try {
      return _receiptsBox.values
          .map((data) => data.cast<String, dynamic>())
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting all receipts: $e');
      return [];
    }
  }

  /// Get receipts for specific user
  List<Map<String, dynamic>> getUserReceipts(String userId) {
    try {
      return _receiptsBox.values
          .where((data) => data['customerId'] == userId)
          .map((data) => data.cast<String, dynamic>())
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting user receipts: $e');
      return [];
    }
  }

  /// Get receipts for today
  List<Map<String, dynamic>> getTodayReceipts(String userId) {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      return _receiptsBox.values
          .where((data) {
            if (data['customerId'] != userId) return false;

            final createdAt = data['createdAt'];
            if (createdAt == null) return false;

            // Handle both Timestamp and DateTime
            DateTime dateTime;
            if (createdAt is DateTime) {
              dateTime = createdAt;
            } else if (createdAt is Map && createdAt.containsKey('_seconds')) {
              // Firestore Timestamp format
              dateTime = DateTime.fromMillisecondsSinceEpoch(
                createdAt['_seconds'] * 1000,
              );
            } else {
              return false;
            }

            return dateTime.isAfter(todayStart) && dateTime.isBefore(todayEnd);
          })
          .map((data) => data.cast<String, dynamic>())
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting today receipts: $e');
      return [];
    }
  }

  /// Get receipts by category
  List<Map<String, dynamic>> getReceiptsByCategory(
    String userId,
    String category,
  ) {
    try {
      return _receiptsBox.values
          .where(
            (data) =>
                data['customerId'] == userId && data['category'] == category,
          )
          .map((data) => data.cast<String, dynamic>())
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting receipts by category: $e');
      return [];
    }
  }

  /// Delete receipt from local cache
  Future<void> deleteReceipt(String id) async {
    try {
      await _receiptsBox.delete(id);
      debugPrint('🗑️ Deleted receipt locally: $id');
    } catch (e) {
      debugPrint('❌ Error deleting receipt: $e');
      rethrow;
    }
  }

  /// Clear all receipts (use with caution!)
  Future<void> clearAllReceipts() async {
    try {
      await _receiptsBox.clear();
      debugPrint('🗑️ Cleared all local receipts');
    } catch (e) {
      debugPrint('❌ Error clearing receipts: $e');
      rethrow;
    }
  }

  // ==================== BUDGETS ====================

  /// Save budget to local cache
  Future<void> saveBudget(String id, Map<String, dynamic> data) async {
    try {
      await _budgetsBox.put(id, data);
      debugPrint('💾 Saved budget locally: $id');
    } catch (e) {
      debugPrint('❌ Error saving budget: $e');
      rethrow;
    }
  }

  /// Get budget from local cache
  Map<String, dynamic>? getBudget(String id) {
    try {
      final data = _budgetsBox.get(id);
      return data?.cast<String, dynamic>();
    } catch (e) {
      debugPrint('❌ Error getting budget: $e');
      return null;
    }
  }

  /// Get all budgets for user
  List<Map<String, dynamic>> getUserBudgets(String userId) {
    try {
      return _budgetsBox.values
          .where((data) => data['userId'] == userId)
          .map((data) => data.cast<String, dynamic>())
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting user budgets: $e');
      return [];
    }
  }

  /// Delete budget from local cache
  Future<void> deleteBudget(String id) async {
    try {
      await _budgetsBox.delete(id);
      debugPrint('🗑️ Deleted budget locally: $id');
    } catch (e) {
      debugPrint('❌ Error deleting budget: $e');
      rethrow;
    }
  }

  // ==================== SYNC QUEUE ====================

  /// Add operation to sync queue
  Future<void> addToSyncQueue(String id, Map<String, dynamic> operation) async {
    try {
      await _syncQueueBox.put(id, operation);
      debugPrint('📤 Added to sync queue: $id');
    } catch (e) {
      debugPrint('❌ Error adding to sync queue: $e');
      rethrow;
    }
  }

  /// Get all pending sync operations
  List<Map<String, dynamic>> getSyncQueue() {
    try {
      return _syncQueueBox.values
          .map((data) => data.cast<String, dynamic>())
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting sync queue: $e');
      return [];
    }
  }

  /// Remove operation from sync queue
  Future<void> removeFromSyncQueue(String id) async {
    try {
      await _syncQueueBox.delete(id);
      debugPrint('✅ Removed from sync queue: $id');
    } catch (e) {
      debugPrint('❌ Error removing from sync queue: $e');
      rethrow;
    }
  }

  /// Clear sync queue
  Future<void> clearSyncQueue() async {
    try {
      await _syncQueueBox.clear();
      debugPrint('🗑️ Cleared sync queue');
    } catch (e) {
      debugPrint('❌ Error clearing sync queue: $e');
      rethrow;
    }
  }

  // ==================== SETTINGS ====================

  /// Save setting
  Future<void> saveSetting(String key, dynamic value) async {
    try {
      await _settingsBox.put(key, value);
    } catch (e) {
      debugPrint('❌ Error saving setting: $e');
      rethrow;
    }
  }

  /// Get setting
  T? getSetting<T>(String key, {T? defaultValue}) {
    try {
      return _settingsBox.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      debugPrint('❌ Error getting setting: $e');
      return defaultValue;
    }
  }

  /// Delete setting
  Future<void> deleteSetting(String key) async {
    try {
      await _settingsBox.delete(key);
    } catch (e) {
      debugPrint('❌ Error deleting setting: $e');
      rethrow;
    }
  }

  // ==================== UTILITY ====================

  /// Get storage stats
  Map<String, int> getStats() {
    return {
      'receipts': _receiptsBox.length,
      'budgets': _budgetsBox.length,
      'syncQueue': _syncQueueBox.length,
      'settings': _settingsBox.length,
    };
  }

  /// Close all boxes (call on app dispose)
  Future<void> dispose() async {
    try {
      await _receiptsBox.close();
      await _budgetsBox.close();
      await _syncQueueBox.close();
      await _settingsBox.close();
      debugPrint('📦 Local storage closed');
    } catch (e) {
      debugPrint('❌ Error closing local storage: $e');
    }
  }
}
