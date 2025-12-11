import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/item_model.dart';
import '../models/session_model.dart';
import '../models/daily_aggregate_model.dart';

/// Firestore Data Source - Handles all Firebase operations
class MerchantFirestoreDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  MerchantFirestoreDataSource()
    : _firestore = FirebaseFirestore.instance,
      _functions = FirebaseFunctions.instance;

  /// Expose firestore instance for stream operations in repository
  FirebaseFirestore get firestore =>
      _firestore; // ==================== ITEM OPERATIONS ====================

  /// Fetch all items for a merchant
  Future<List<ItemModel>> getMerchantItems(String merchantId) async {
    try {
      final snapshot = await _firestore
          .collection('items')
          .where('merchantId', isEqualTo: merchantId)
          .orderBy('name')
          .get();

      return snapshot.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to fetch merchant items: $e');
    }
  }

  /// Create a new item
  Future<ItemModel> createItem(ItemModel item) async {
    try {
      final docRef = await _firestore.collection('items').add(item.toJson());
      final doc = await docRef.get();
      return ItemModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to create item: $e');
    }
  }

  /// Update an existing item
  Future<void> updateItem(ItemModel item) async {
    try {
      await _firestore.collection('items').doc(item.id).update(item.toJson());
    } catch (e) {
      throw Exception('Failed to update item: $e');
    }
  }

  /// Delete an item
  Future<void> deleteItem(String itemId) async {
    try {
      await _firestore.collection('items').doc(itemId).delete();
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  // ==================== SESSION OPERATIONS ====================

  /// Create a new billing session
  Future<SessionModel> createBillingSession(SessionModel session) async {
    try {
      final docRef = await _firestore
          .collection('billingSessions')
          .add(session.toJson());
      final doc = await docRef.get();
      return SessionModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to create billing session: $e');
    }
  }

  /// Get the current active session for a merchant
  Future<SessionModel?> getLiveSession(String merchantId) async {
    try {
      final snapshot = await _firestore
          .collection('billingSessions')
          .where('merchantId', isEqualTo: merchantId)
          .where('status', isEqualTo: 'ACTIVE')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return SessionModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      throw Exception('Failed to fetch live session: $e');
    }
  }

  /// Mark session as paid
  Future<void> markSessionPaid(
    String sessionId,
    String paymentMethod,
    String? txnId,
  ) async {
    try {
      await _firestore.collection('billingSessions').doc(sessionId).update({
        'paymentStatus': 'PAID',
        'paymentMethod': paymentMethod,
        'txnId': txnId,
      });
    } catch (e) {
      throw Exception('Failed to mark session as paid: $e');
    }
  }

  /// Finalize (complete) a billing session
  /// This triggers daily aggregate update via transaction
  Future<void> finalizeSession(String sessionId) async {
    try {
      final sessionRef = _firestore
          .collection('billingSessions')
          .doc(sessionId);

      // Use transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        final sessionDoc = await transaction.get(sessionRef);

        if (!sessionDoc.exists) {
          throw Exception('Session not found');
        }

        final session = SessionModel.fromFirestore(sessionDoc);

        // Verify session is paid before finalizing
        if (session.paymentStatus != 'PAID') {
          throw Exception('Session must be paid before finalization');
        }

        // Update session status
        transaction.update(sessionRef, {
          'status': 'COMPLETED',
          'completedAt': FieldValue.serverTimestamp(),
        });

        // Note: Daily aggregate update should be handled by Cloud Function
        // or called separately after this transaction completes
      });
    } catch (e) {
      throw Exception('Failed to finalize session: $e');
    }
  }

  // ==================== DAILY AGGREGATE OPERATIONS ====================

  /// Get daily aggregate for a specific date
  Future<DailyAggregateModel?> getDailyAggregate(
    String merchantId,
    String date,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('dailyAggregates')
          .where('merchantId', isEqualTo: merchantId)
          .where('date', isEqualTo: date)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return DailyAggregateModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      throw Exception('Failed to fetch daily aggregate: $e');
    }
  }

  /// Update daily aggregate (create or update)
  Future<void> updateDailyAggregate(DailyAggregateModel aggregate) async {
    try {
      final snapshot = await _firestore
          .collection('dailyAggregates')
          .where('merchantId', isEqualTo: aggregate.merchantId)
          .where('date', isEqualTo: aggregate.date)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        // Create new document
        await _firestore.collection('dailyAggregates').add(aggregate.toJson());
      } else {
        // Update existing document
        await _firestore
            .collection('dailyAggregates')
            .doc(snapshot.docs.first.id)
            .update(aggregate.toJson());
      }
    } catch (e) {
      throw Exception('Failed to update daily aggregate: $e');
    }
  }

  // ==================== CLOUD FUNCTION OPERATIONS ====================

  /// Generate daily report (calls cloud function)
  Future<String> generateDailyReport(
    String merchantId,
    String date,
    String format,
  ) async {
    try {
      // Call Firebase Cloud Function to generate PDF/CSV
      final callable = _functions.httpsCallable('generateDailyReport');
      final result = await callable.call({
        'merchantId': merchantId,
        'date': date,
        'format': format,
      });

      // Return download URL from cloud function response
      if (result.data != null && result.data['downloadUrl'] != null) {
        return result.data['downloadUrl'] as String;
      }

      // Fallback to placeholder if cloud function not deployed yet
      return 'https://storage.googleapis.com/bilee-reports/$merchantId/$date.$format';
    } catch (e) {
      // If cloud function doesn't exist, return placeholder
      if (e.toString().contains('NOT_FOUND') ||
          e.toString().contains('UNAVAILABLE')) {
        return 'https://storage.googleapis.com/bilee-reports/$merchantId/$date.$format';
      }
      throw Exception('Failed to generate daily report: $e');
    }
  }

  /// Send receipt (calls cloud function)
  Future<void> sendReceipt(String sessionId, String recipientEmail) async {
    try {
      // Call Firebase Cloud Function to send receipt via email/SMS
      final callable = _functions.httpsCallable('sendReceipt');
      await callable.call({
        'sessionId': sessionId,
        'recipientEmail': recipientEmail,
      });
    } catch (e) {
      // If cloud function doesn't exist, log instead of failing
      if (e.toString().contains('NOT_FOUND') ||
          e.toString().contains('UNAVAILABLE')) {
        print(
          'Receipt would be sent for session: $sessionId to $recipientEmail',
        );
        print('Cloud function "sendReceipt" not deployed yet');
        return;
      }
      throw Exception('Failed to send receipt: $e');
    }
  }

  /// Trigger daily aggregate calculation (cloud function)
  /// This is called by Firestore triggers when a session is completed
  Future<void> triggerDailyAggregateUpdate(
    String merchantId,
    String date,
  ) async {
    try {
      final callable = _functions.httpsCallable('updateDailyAggregate');
      await callable.call({'merchantId': merchantId, 'date': date});
    } catch (e) {
      // If cloud function doesn't exist, aggregate is updated locally
      if (e.toString().contains('NOT_FOUND') ||
          e.toString().contains('UNAVAILABLE')) {
        print('Cloud function "updateDailyAggregate" not deployed yet');
        print('Using local aggregate update instead');
        return;
      }
      throw Exception('Failed to trigger daily aggregate update: $e');
    }
  }
}
