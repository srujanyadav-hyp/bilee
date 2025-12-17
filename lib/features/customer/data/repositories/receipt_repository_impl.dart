import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/receipt_entity.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../models/receipt_model.dart';

/// Implementation of ReceiptRepository
class ReceiptRepositoryImpl implements ReceiptRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ReceiptRepositoryImpl({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  @override
  Future<List<ReceiptEntity>> getAllReceipts() async {
    try {
      if (_currentUserId == null) {
        debugPrint('❌ ReceiptRepo: No user logged in');
        return [];
      }

      debugPrint('👤 ReceiptRepo: Current user UID: $_currentUserId');
      debugPrint(
        '👤 ReceiptRepo: Current user email: ${_auth.currentUser?.email}',
      );
      debugPrint(
        '🔍 ReceiptRepo: Querying receipts for customerId: $_currentUserId',
      );

      // FIRST: Try to get receipts with customerId filter
      var querySnapshot = await _firestore
          .collection('receipts')
          .where('customerId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      debugPrint(
        '✅ ReceiptRepo: Found ${querySnapshot.docs.length} receipts with customerId',
      );

      // FALLBACK: If no receipts found, also check for null customerId (legacy receipts)
      // This helps with backward compatibility for receipts created before customerId was enforced
      if (querySnapshot.docs.isEmpty) {
        debugPrint(
          '⚠️ ReceiptRepo: No receipts with customerId, checking for legacy receipts...',
        );
        final allReceipts = await _firestore
            .collection('receipts')
            .orderBy('createdAt', descending: true)
            .limit(50) // Limit for safety
            .get();

        debugPrint(
          '📊 ReceiptRepo: Total receipts in collection: ${allReceipts.docs.length}',
        );
        for (var doc in allReceipts.docs.take(5)) {
          debugPrint(
            '   Receipt ${doc.id}: customerId=${doc.data()['customerId']}',
          );
        }
      }

      return querySnapshot.docs
          .map(
            (doc) => ReceiptModel.fromFirestore(doc.data(), doc.id).toEntity(),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ ReceiptRepo: Error loading receipts: $e');
      throw Exception('Failed to load receipts: $e');
    }
  }

  @override
  Future<List<ReceiptEntity>> getRecentReceipts({int limit = 3}) async {
    try {
      if (_currentUserId == null) return [];

      final querySnapshot = await _firestore
          .collection('receipts')
          .where('customerId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => ReceiptModel.fromFirestore(doc.data(), doc.id).toEntity(),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load recent receipts: $e');
    }
  }

  @override
  Future<ReceiptEntity?> getReceiptById(String receiptId) async {
    try {
      final doc = await _firestore.collection('receipts').doc(receiptId).get();

      if (!doc.exists) return null;

      return ReceiptModel.fromFirestore(doc.data()!, doc.id).toEntity();
    } catch (e) {
      throw Exception('Failed to load receipt: $e');
    }
  }

  @override
  Future<ReceiptEntity?> getReceiptBySessionId(String sessionId) async {
    try {
      if (_currentUserId == null) {
        debugPrint('❌ ReceiptRepo: Cannot query receipt - no user logged in');
        return null;
      }

      debugPrint('🔍 ReceiptRepo: Searching receipt by sessionId: $sessionId');

      final querySnapshot = await _firestore
          .collection('receipts')
          .where('sessionId', isEqualTo: sessionId)
          .where('customerId', isEqualTo: _currentUserId)
          .limit(1)
          .get();

      debugPrint(
        '📊 ReceiptRepo: Query returned ${querySnapshot.docs.length} documents',
      );

      if (querySnapshot.docs.isEmpty) {
        debugPrint(
          '⚠️ ReceiptRepo: No receipt found for sessionId: $sessionId',
        );
        return null;
      }

      final receipt = ReceiptModel.fromFirestore(
        querySnapshot.docs.first.data(),
        querySnapshot.docs.first.id,
      ).toEntity();

      debugPrint(
        '✅ ReceiptRepo: Receipt found! receiptId: ${receipt.receiptId}',
      );

      return receipt;
    } catch (e) {
      debugPrint('❌ ReceiptRepo: Error getting receipt by sessionId: $e');
      throw Exception('Failed to get receipt by session ID: $e');
    }
  }

  @override
  Future<List<ReceiptEntity>> searchReceipts(String query) async {
    try {
      if (_currentUserId == null) return [];

      final lowerQuery = query.toLowerCase();

      final querySnapshot = await _firestore
          .collection('receipts')
          .where('customerId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      // Client-side filtering for text search
      final filtered = querySnapshot.docs.where((doc) {
        final data = doc.data();
        final merchantName = (data['merchantName'] ?? '')
            .toString()
            .toLowerCase();
        final receiptId = (data['receiptId'] ?? '').toString().toLowerCase();
        return merchantName.contains(lowerQuery) ||
            receiptId.contains(lowerQuery);
      }).toList();

      return filtered
          .map(
            (doc) => ReceiptModel.fromFirestore(doc.data(), doc.id).toEntity(),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to search receipts: $e');
    }
  }

  @override
  Future<List<ReceiptEntity>> getReceiptsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      if (_currentUserId == null) return [];

      final querySnapshot = await _firestore
          .collection('receipts')
          .where('customerId', isEqualTo: _currentUserId)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => ReceiptModel.fromFirestore(doc.data(), doc.id).toEntity(),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load receipts by date: $e');
    }
  }

  @override
  Future<List<ReceiptEntity>> getReceiptsByMerchant(String merchantId) async {
    try {
      if (_currentUserId == null) return [];

      final querySnapshot = await _firestore
          .collection('receipts')
          .where('customerId', isEqualTo: _currentUserId)
          .where('merchantId', isEqualTo: merchantId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map(
            (doc) => ReceiptModel.fromFirestore(doc.data(), doc.id).toEntity(),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to load receipts by merchant: $e');
    }
  }

  @override
  Future<void> saveReceipt(ReceiptEntity receipt) async {
    try {
      final model = ReceiptModel.fromEntity(receipt);
      await _firestore
          .collection('receipts')
          .doc(receipt.id)
          .set(model.toFirestore());
    } catch (e) {
      throw Exception('Failed to save receipt: $e');
    }
  }

  @override
  Future<void> createManualReceipt({
    required String category,
    required double amount,
    required PaymentMethod paymentMethod,
    String? merchantName,
    String? merchantUpiId,
    String? transactionId,
    bool verified = false,
  }) async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not logged in');
      }

      // Generate manual receipt ID
      final receiptId = 'MR${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('📝 Creating manual receipt: $receiptId');
      debugPrint('   Category: $category');
      debugPrint('   Amount: ₹$amount');
      debugPrint('   Payment: $paymentMethod');
      debugPrint('   Verified: $verified');

      // Create receipt data
      final receiptData = {
        'receiptId': receiptId,
        'type': 'manual', // Flag to identify manual entries
        'customerId': _currentUserId,
        'merchantName': merchantName ?? 'Manual Entry',
        'merchantUpiId': merchantUpiId,
        'businessCategory': category,
        'items': [], // Empty for manual entries
        'subtotal': amount,
        'tax': 0.0,
        'discount': 0.0,
        'total': amount,
        'paidAmount': amount,
        'pendingAmount': 0.0,
        'paymentMethod': paymentMethod.toString().split('.').last,
        'transactionId': transactionId,
        'paymentTime': FieldValue.serverTimestamp(),
        'paymentStatus': 'paid',
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': verified,
        'manualEntry': true,
        'notes': null,
      };

      // Save to Firestore
      await _firestore.collection('receipts').doc(receiptId).set(receiptData);

      debugPrint('✅ Manual receipt created successfully');
    } catch (e) {
      debugPrint('❌ Error creating manual receipt: $e');
      throw Exception('Failed to create manual receipt: $e');
    }
  }

  @override
  Future<void> updateReceiptNotes({
    required String receiptId,
    required String notes,
  }) async {
    try {
      await _firestore.collection('receipts').doc(receiptId).update({
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update receipt notes: $e');
    }
  }

  @override
  Future<void> deleteReceipt(String receiptId) async {
    try {
      await _firestore.collection('receipts').doc(receiptId).delete();
    } catch (e) {
      throw Exception('Failed to delete receipt: $e');
    }
  }

  @override
  Future<String?> downloadReceiptPdf(String receiptId) async {
    // TODO: Implement PDF generation
    // This will require pdf package and file storage
    throw UnimplementedError('PDF download not yet implemented');
  }

  @override
  Future<bool> shareReceipt(String receiptId) async {
    // TODO: Implement share functionality
    // This will require share_plus package
    throw UnimplementedError('Share not yet implemented');
  }

  @override
  Stream<List<ReceiptEntity>> watchReceipts() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('receipts')
        .where('customerId', isEqualTo: _currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    ReceiptModel.fromFirestore(doc.data(), doc.id).toEntity(),
              )
              .toList(),
        );
  }
}
