import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service responsible for complete account deletion with data cleanup
///
/// This service handles:
/// - Deleting all user data from Firestore collections
/// - Deleting Firebase Auth account
/// - Using batch writes for atomic operations
class AccountDeletionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AccountDeletionService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Delete merchant account and all related data
  ///
  /// Deletes:
  /// - Merchant profile from merchants collection
  /// - All items in merchant's items sub-collection
  /// - All billing sessions where merchantId matches
  /// - User document from users collection
  /// - Firebase Auth account
  ///
  /// Anonymizes (does NOT delete):
  /// - Receipts - removes merchant personal info but preserves for customers
  Future<void> deleteMerchantAccount(String merchantId) async {
    debugPrint('🗑️ Starting merchant account deletion: $merchantId');

    try {
      // Step 1: Query all data that needs to be deleted or anonymized
      debugPrint('📋 Querying merchant data...');

      // Get merchant items
      final itemsSnapshot = await _firestore
          .collection('merchants')
          .doc(merchantId)
          .collection('items')
          .get();

      // Get receipts created by this merchant (will be anonymized, not deleted)
      final receiptsSnapshot = await _firestore
          .collection('receipts')
          .where('merchantId', isEqualTo: merchantId)
          .get();

      // Get billing sessions created by this merchant
      final sessionsSnapshot = await _firestore
          .collection('billingSessions')
          .where('merchantId', isEqualTo: merchantId)
          .get();

      // Get daily aggregates for this merchant
      final aggregatesSnapshot = await _firestore
          .collection('dailyAggregates')
          .where('merchantId', isEqualTo: merchantId)
          .get();

      debugPrint('📊 Found data to process:');
      debugPrint('   - Items: ${itemsSnapshot.docs.length}');
      debugPrint(
        '   - Receipts (will anonymize): ${receiptsSnapshot.docs.length}',
      );
      debugPrint('   - Sessions: ${sessionsSnapshot.docs.length}');
      debugPrint('   - Daily Aggregates: ${aggregatesSnapshot.docs.length}');

      // Step 2: Process deletions and anonymizations using batch writes
      final batches = <WriteBatch>[];
      var currentBatch = _firestore.batch();
      var operationCount = 0;

      // Helper to add operation to batch
      void addOperation(void Function(WriteBatch) operation) {
        if (operationCount >= 499) {
          batches.add(currentBatch);
          currentBatch = _firestore.batch();
          operationCount = 0;
        }
        operation(currentBatch);
        operationCount++;
      }

      // Delete all items
      for (final doc in itemsSnapshot.docs) {
        addOperation((batch) => batch.delete(doc.reference));
      }

      // ANONYMIZE receipts (preserve for customers, remove merchant PII)
      // IMPORTANT: Keep merchant name for warranty/returns!
      debugPrint('🔒 Anonymizing ${receiptsSnapshot.docs.length} receipts...');
      for (final doc in receiptsSnapshot.docs) {
        addOperation((batch) {
          // Get existing merchant name before update
          final existingName = doc.data()['merchantName'] as String?;
          
          batch.update(doc.reference, {
            // KEEP merchant name (customer needs it for warranty/returns)
            // 'merchantName': existingName, // Don't change!
            
            // Remove PII only
            'merchantEmail': null,
            'merchantPhone': null,
            'merchantAddress': null,
            'merchantGst': null,
            'merchantLogo': null,
            
            // Add status field to indicate merchant deleted account
            'merchantStatus': 'closed',
            
            // Mark merchant as deleted with special ID
            'merchantId': 'DELETED_MERCHANT',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });
      }

      // Delete all billing sessions
      for (final doc in sessionsSnapshot.docs) {
        addOperation((batch) => batch.delete(doc.reference));
      }

      // Delete all daily aggregates
      for (final doc in aggregatesSnapshot.docs) {
        addOperation((batch) => batch.delete(doc.reference));
      }

      // Delete merchant profile
      addOperation(
        (batch) =>
            batch.delete(_firestore.collection('merchants').doc(merchantId)),
      );

      // Delete user document
      addOperation(
        (batch) => batch.delete(_firestore.collection('users').doc(merchantId)),
      );

      // Add final batch
      batches.add(currentBatch);

      // Step 3: Commit all batches
      debugPrint('💾 Committing ${batches.length} batch(es)...');
      for (var i = 0; i < batches.length; i++) {
        await batches[i].commit();
        debugPrint('   ✅ Batch ${i + 1}/${batches.length} committed');
      }

      // Step 4: Delete Firebase Auth account
      debugPrint('🔐 Deleting Firebase Auth account...');
      final user = _auth.currentUser;
      if (user != null && user.uid == merchantId) {
        await user.delete();
        debugPrint('   ✅ Auth account deleted');
      }

      debugPrint('✅ Merchant account deletion completed successfully');
      debugPrint(
        '   - Deleted: ${itemsSnapshot.docs.length} items, ${sessionsSnapshot.docs.length} sessions, ${aggregatesSnapshot.docs.length} aggregates, profile, auth',
      );
      debugPrint('   - Anonymized: ${receiptsSnapshot.docs.length} receipts');
    } catch (e, stackTrace) {
      debugPrint('❌ Error deleting merchant account: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Delete customer account and all related data
  ///
  /// Deletes:
  /// - All receipts where customerId matches
  /// - User document from users collection
  /// - Firebase Auth account
  ///
  /// Note: Merchants don't view individual receipts (only daily aggregates),
  /// so deleting customer receipts doesn't impact merchant functionality.
  Future<void> deleteCustomerAccount(String customerId) async {
    debugPrint('🗑️ Starting customer account deletion: $customerId');

    try {
      // Step 1: Query all data that needs to be deleted
      debugPrint('📋 Querying customer data...');

      // Get all receipts for this customer
      final receiptsSnapshot = await _firestore
          .collection('receipts')
          .where('customerId', isEqualTo: customerId)
          .get();

      debugPrint('📊 Found data to delete:');
      debugPrint('   - Receipts: ${receiptsSnapshot.docs.length}');

      // Step 2: Delete all data using batch writes
      final batches = <WriteBatch>[];
      var currentBatch = _firestore.batch();
      var operationCount = 0;

      // Helper to add deletion to batch
      void addDeletion(DocumentReference ref) {
        if (operationCount >= 499) {
          batches.add(currentBatch);
          currentBatch = _firestore.batch();
          operationCount = 0;
        }
        currentBatch.delete(ref);
        operationCount++;
      }

      // DELETE all receipts (merchant doesn't see individual receipts anyway)
      debugPrint('🗑️ Deleting ${receiptsSnapshot.docs.length} receipts...');
      for (final doc in receiptsSnapshot.docs) {
        addDeletion(doc.reference);
      }

      // Delete user document
      addDeletion(_firestore.collection('users').doc(customerId));

      // Add final batch
      batches.add(currentBatch);

      // Step 3: Commit all batches
      debugPrint('💾 Committing ${batches.length} batch(es)...');
      for (var i = 0; i < batches.length; i++) {
        await batches[i].commit();
        debugPrint('   ✅ Batch ${i + 1}/${batches.length} committed');
      }

      // Step 4: Delete Firebase Auth account
      debugPrint('🔐 Deleting Firebase Auth account...');
      final user = _auth.currentUser;
      if (user != null && user.uid == customerId) {
        await user.delete();
        debugPrint('   ✅ Auth account deleted');
      }

      debugPrint('✅ Customer account deletion completed successfully');
      debugPrint(
        '   - Deleted: ${receiptsSnapshot.docs.length} receipts, user profile, auth',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error deleting customer account: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Check if re-authentication is needed
  ///
  /// Firebase requires recent authentication to delete account
  /// Returns true if user needs to re-authenticate
  bool requiresRecentAuth() {
    final user = _auth.currentUser;
    if (user == null) return false;

    final metadata = user.metadata;
    final lastSignIn = metadata.lastSignInTime;
    if (lastSignIn == null) return true;

    // Require re-auth if last sign-in was more than 5 minutes ago
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
    return lastSignIn.isBefore(fiveMinutesAgo);
  }

  /// Re-authenticate user with their credentials
  ///
  /// Required before account deletion if session is old
  Future<void> reauthenticateWithCredential(
    String email,
    String password,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user signed in');
    }

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await user.reauthenticateWithCredential(credential);
    debugPrint('✅ User re-authenticated successfully');
  }
}
