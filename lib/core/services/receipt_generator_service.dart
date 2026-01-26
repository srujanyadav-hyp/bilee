import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../features/merchant/domain/entities/session_entity.dart';
import 'performance_service.dart';

/// Service for generating receipts client-side (Phase 3 optimization)
/// Replaces Cloud Function receipt generation to save costs
class ReceiptGeneratorService {
  final FirebaseFirestore _firestore;

  ReceiptGeneratorService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Generate receipt for completed session
  /// This replaces the Cloud Function onPaymentConfirmed trigger
  Future<String?> generateReceiptForSession({
    required SessionEntity session,
    required String merchantName,
    String? merchantLogo,
    String? merchantAddress,
    String? merchantPhone,
    String? merchantGst,
    String? businessCategory,
  }) async {
    // Track receipt generation performance
    final generationStartTime = DateTime.now();

    try {
      debugPrint('========================================');
      debugPrint('📝 [ReceiptGen] STARTING RECEIPT GENERATION');
      debugPrint('   Session ID: ${session.id}');
      debugPrint('   Merchant: $merchantName');
      debugPrint('   Session isPaid: ${session.isPaid}');
      debugPrint('   Connected Customers: ${session.connectedCustomers}');
      debugPrint('========================================');

      // Validation: Ensure session is paid
      if (!session.isPaid) {
        debugPrint(
          '⚠️ [ReceiptGen] Session not paid yet, skipping receipt generation',
        );
        return null;
      }

      // Check if receipt already exists
      debugPrint('🔍 [ReceiptGen] Checking for existing receipt...');
      try {
        final existingReceipts = await _firestore
            .collection('receipts')
            .where('sessionId', isEqualTo: session.id)
            .limit(1)
            .get();

        if (existingReceipts.docs.isNotEmpty) {
          final existingReceiptId = existingReceipts.docs.first
              .data()['receiptId'];
          debugPrint(
            '✅ [ReceiptGen] Receipt already exists: $existingReceiptId',
          );
          return existingReceiptId;
        }
        debugPrint(
          '✅ [ReceiptGen] No existing receipt found, creating new one',
        );
      } catch (e) {
        debugPrint('❌ [ReceiptGen] Error checking existing receipts: $e');
        // Continue with generation anyway
      }

      // Generate receipt ID (same format as Cloud Function)
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final receiptId = 'RC$timestamp';
      debugPrint('🆔 [ReceiptGen] Generated receipt ID: $receiptId');

      // Normalize business category
      String normalizedCategory = businessCategory ?? 'Other';
      final categoryMap = {
        'restaurant': 'Restaurant',
        'food': 'Restaurant',
        'retail': 'Retail',
        'grocery': 'Grocery',
        'groceries': 'Grocery',
        'pharmacy': 'Pharmacy',
        'healthcare': 'Pharmacy',
        'electronics': 'Electronics',
        'clothing': 'Clothing',
        'fashion': 'Clothing',
        'services': 'Services',
        'entertainment': 'Entertainment',
        'other': 'Other',
      };

      normalizedCategory =
          categoryMap[normalizedCategory.toLowerCase()] ?? normalizedCategory;
      debugPrint('📂 [ReceiptGen] Business category: $normalizedCategory');

      // Get customer ID (first connected customer or null for walk-in)
      final customerId = session.connectedCustomers.isNotEmpty
          ? session.connectedCustomers.first
          : null;

      debugPrint(
        '👤 [ReceiptGen] Customer ID: ${customerId ?? "Walk-in customer (null)"}',
      );

      // Map session items to receipt items
      debugPrint('🛒 [ReceiptGen] Mapping ${session.items.length} items...');
      final receiptItems = session.items.map((item) {
        return {
          'name': item.name,
          'quantity': item.qty,
          'price': item.price,
          'total': item.total,
          'category': null, // Not in session entity
          'hsnCode': item.hsnCode,
        };
      }).toList();

      debugPrint(
        '✅ [ReceiptGen] Mapped ${receiptItems.length} items successfully',
      );

      // Create receipt data (matching Cloud Function structure)
      debugPrint('📦 [ReceiptGen] Creating receipt data object...');
      final receiptData = {
        'receiptId': receiptId,
        'sessionId': session.id,
        'merchantId': session.merchantId,
        'merchantName': merchantName,
        'merchantLogo': merchantLogo,
        'merchantAddress': merchantAddress,
        'merchantPhone': merchantPhone,
        'merchantGst': merchantGst,
        'businessCategory': normalizedCategory,
        'customerId': customerId,
        'customerName': null,
        'customerPhone': null,
        'customerEmail': null,
        'items': receiptItems,
        'subtotal': session.subtotal,
        'tax': session.tax,
        'discount': 0.0, // Not tracked in current session entity
        'total': session.total,
        'paidAmount': session.total,
        'pendingAmount': 0.0,
        'paymentMethod': session.paymentMethod?.toLowerCase() ?? 'cash',
        'transactionId': session.paymentTxnId,
        'paymentTime': FieldValue.serverTimestamp(),
        'paymentStatus': 'pending', // Customer confirms when they complete
        'upiTransactionRef': null,
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': true, // Merchant-generated receipts are verified
        'notes': null,
        'tags': null,
        'signatureUrl': null,
      };

      debugPrint('✅ [ReceiptGen] Receipt data created successfully');
      debugPrint('💾 [ReceiptGen] Attempting to save to Firestore...');
      debugPrint('   Collection: receipts');
      debugPrint('   Document ID: $receiptId');

      // Save receipt to Firestore
      try {
        await _firestore.collection('receipts').doc(receiptId).set(receiptData);
        debugPrint('✅ [ReceiptGen] Firestore save SUCCESSFUL!');
      } catch (firestoreError) {
        debugPrint('❌ [ReceiptGen] FIRESTORE SAVE FAILED!');
        debugPrint('   Error: $firestoreError');
        throw Exception('Firestore save failed: $firestoreError');
      }

      debugPrint('🔗 [ReceiptGen] Updating session with receipt reference...');
      try {
        await _firestore.collection('billingSessions').doc(session.id).update({
          'receiptGenerated': true,
          'receiptId': receiptId,
        });
        debugPrint('✅ [ReceiptGen] Session updated successfully');
      } catch (sessionUpdateError) {
        debugPrint(
          '⚠️ [ReceiptGen] Session update failed: $sessionUpdateError',
        );
        // Don't throw - receipt is created, this is just metadata
      }

      debugPrint('========================================');
      debugPrint('🎉 [ReceiptGen] RECEIPT GENERATION COMPLETE!');
      debugPrint('✅ [ReceiptGen] Receipt created successfully: $receiptId');
      debugPrint('========================================');

      // Track receipt generation performance
      final generationDuration = DateTime.now().difference(generationStartTime);
      await PerformanceService.trackReceiptGeneration(
        receiptId: receiptId,
        itemCount: session.items.length,
        duration: generationDuration,
      );

      return receiptId;
    } catch (e, stackTrace) {
      debugPrint('❌ [ReceiptGen] Error generating receipt: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Check if receipt exists for session
  Future<bool> receiptExistsForSession(String sessionId) async {
    try {
      final receipts = await _firestore
          .collection('receipts')
          .where('sessionId', isEqualTo: sessionId)
          .limit(1)
          .get();

      return receipts.docs.isNotEmpty;
    } catch (e) {
      debugPrint('❌ [ReceiptGen] Error checking receipt existence: $e');
      return false;
    }
  }

  /// Get receipt ID for session (if exists)
  Future<String?> getReceiptIdForSession(String sessionId) async {
    try {
      final receipts = await _firestore
          .collection('receipts')
          .where('sessionId', isEqualTo: sessionId)
          .limit(1)
          .get();

      if (receipts.docs.isEmpty) return null;

      return receipts.docs.first.data()['receiptId'];
    } catch (e) {
      debugPrint('❌ [ReceiptGen] Error getting receipt ID: $e');
      return null;
    }
  }
}
