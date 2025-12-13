import 'package:cloud_firestore/cloud_firestore.dart';

/// User Preferences Data Source - Stores favorites and recent items
class UserPreferencesDataSource {
  final FirebaseFirestore _firestore;

  UserPreferencesDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get user preferences for a merchant
  Future<Map<String, dynamic>> getUserPreferences(String merchantId) async {
    try {
      final doc = await _firestore
          .collection('userPreferences')
          .doc(merchantId)
          .get();

      if (!doc.exists) {
        return {
          'favoriteItems': <String>[],
          'recentItems': <String, DateTime>{},
        };
      }

      final data = doc.data()!;
      return {
        'favoriteItems': List<String>.from(data['favoriteItems'] ?? []),
        'recentItems':
            (data['recentItems'] as Map<String, dynamic>?)?.map(
              (key, value) => MapEntry(key, (value as Timestamp).toDate()),
            ) ??
            {},
      };
    } catch (e) {
      throw Exception('Failed to get user preferences: $e');
    }
  }

  /// Save favorite items
  Future<void> saveFavoriteItems(
    String merchantId,
    Set<String> favoriteItems,
  ) async {
    try {
      await _firestore.collection('userPreferences').doc(merchantId).set({
        'favoriteItems': favoriteItems.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save favorite items: $e');
    }
  }

  /// Save recent items
  Future<void> saveRecentItems(
    String merchantId,
    Map<String, DateTime> recentItems,
  ) async {
    try {
      final recentItemsMap = recentItems.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      );

      await _firestore.collection('userPreferences').doc(merchantId).set({
        'recentItems': recentItemsMap,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save recent items: $e');
    }
  }

  /// Add a single favorite item
  Future<void> addFavoriteItem(String merchantId, String itemName) async {
    try {
      await _firestore.collection('userPreferences').doc(merchantId).update({
        'favoriteItems': FieldValue.arrayUnion([itemName]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // If document doesn't exist, create it
      await _firestore.collection('userPreferences').doc(merchantId).set({
        'favoriteItems': [itemName],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  /// Remove a favorite item
  Future<void> removeFavoriteItem(String merchantId, String itemName) async {
    try {
      await _firestore.collection('userPreferences').doc(merchantId).update({
        'favoriteItems': FieldValue.arrayRemove([itemName]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to remove favorite item: $e');
    }
  }

  /// Add a recent item
  Future<void> addRecentItem(
    String merchantId,
    String itemName,
    DateTime timestamp,
  ) async {
    try {
      await _firestore.collection('userPreferences').doc(merchantId).set({
        'recentItems.$itemName': Timestamp.fromDate(timestamp),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to add recent item: $e');
    }
  }
}
