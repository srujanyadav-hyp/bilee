import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/live_bill_entity.dart';
import '../../domain/repositories/live_bill_repository.dart';
import '../models/live_bill_model.dart';

/// Implementation of LiveBillRepository
class LiveBillRepositoryImpl implements LiveBillRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  LiveBillRepositoryImpl({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<LiveBillEntity> connectToSession(String sessionId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      print('🔗 [LiveBillRepo] Customer connecting to session: $sessionId');
      print('   Customer UID: $currentUserId');

      // Add customer to connectedCustomers array
      await _firestore.collection('billingSessions').doc(sessionId).update({
        'connectedCustomers': FieldValue.arrayUnion([currentUserId]),
        'customerConnected': true,
        'lastConnectedAt': FieldValue.serverTimestamp(),
      });

      print('✅ [LiveBillRepo] Customer added to connectedCustomers array');

      // ⭐ CRITICAL: Update existing receipt with customer info (if one exists)
      // This handles the case where merchant completed payment BEFORE customer scanned QR
      try {
        print('🔍 [LiveBillRepo] Checking for existing receipt for session...');

        final existingReceipts = await _firestore
            .collection('receipts')
            .where('sessionId', isEqualTo: sessionId)
            .limit(1)
            .get();

        if (existingReceipts.docs.isNotEmpty) {
          final receiptDoc = existingReceipts.docs.first;
          final receiptData = receiptDoc.data();
          final currentCustomerId = receiptData['customerId'];

          // Only update if receipt currently has no customer ID
          if (currentCustomerId == null) {
            print(
              '📝 [LiveBillRepo] Found receipt with null customerId, updating...',
            );
            print('   Receipt ID: ${receiptData['receiptId']}');

            // Get user email and name for receipt
            final userEmail = _auth.currentUser?.email;
            final userName = _auth.currentUser?.displayName;

            await _firestore.collection('receipts').doc(receiptDoc.id).update({
              'customerId': currentUserId,
              'customerEmail': userEmail,
              'customerName': userName,
              'updatedAt': FieldValue.serverTimestamp(),
            });

            print('✅ [LiveBillRepo] Receipt updated with customer info');
            print('   Customer ID: $currentUserId');
            print('   Customer Email: $userEmail');
          } else {
            print(
              'ℹ️ [LiveBillRepo] Receipt already has customer ID: $currentCustomerId',
            );
          }
        } else {
          print('ℹ️ [LiveBillRepo] No receipt exists yet for this session');
        }
      } catch (receiptError) {
        print('⚠️ [LiveBillRepo] Error updating receipt: $receiptError');
        // Don't fail connection if receipt update fails
      }

      final doc = await _firestore
          .collection('billingSessions')
          .doc(sessionId)
          .get();

      if (!doc.exists) {
        throw Exception('Session not found');
      }

      final data = doc.data()!;
      final model = LiveBillModel.fromFirestore(data);

      print('✅ [LiveBillRepo] Successfully connected to session');
      return model.toEntity();
    } catch (e) {
      print('❌ [LiveBillRepo] Error connecting to session: $e');
      throw Exception('Failed to connect to session: $e');
    }
  }

  @override
  Stream<LiveBillEntity> watchLiveBill(String sessionId) {
    return _firestore
        .collection('billingSessions')
        .doc(sessionId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            throw Exception('Session not found');
          }
          final model = LiveBillModel.fromFirestore(snapshot.data()!);
          return model.toEntity();
        });
  }

  @override
  Future<void> disconnectFromSession(String sessionId) async {
    // Remove customer from connectedCustomers array
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId != null) {
        await _firestore.collection('billingSessions').doc(sessionId).update({
          'connectedCustomers': FieldValue.arrayRemove([currentUserId]),
          'customerConnected': false,
          'disconnectedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  @override
  Future<bool> initiateUpiPayment({
    required String sessionId,
    required String upiString,
    required double amount,
  }) async {
    try {
      await _firestore.collection('billingSessions').doc(sessionId).update({
        'paymentInitiated': true,
        'paymentMethod': 'upi',
        'paymentAmount': amount,
        'upiString': upiString,
        'paymentTime': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      throw Exception('Failed to initiate payment: $e');
    }
  }

  @override
  Future<bool> confirmCashPayment({
    required String sessionId,
    required double amount,
  }) async {
    try {
      await _firestore.collection('billingSessions').doc(sessionId).update({
        'paymentConfirmed': true,
        'paymentMethod': 'cash',
        'paymentAmount': amount,
        'paymentTime': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      throw Exception('Failed to confirm payment: $e');
    }
  }

  @override
  Future<BillStatus> getSessionStatus(String sessionId) async {
    try {
      final doc = await _firestore
          .collection('billingSessions')
          .doc(sessionId)
          .get();

      if (!doc.exists) {
        throw Exception('Session not found');
      }

      final status = doc.data()?['status'] ?? 'pending';
      return _parseBillStatus(status);
    } catch (e) {
      throw Exception('Failed to get session status: $e');
    }
  }

  BillStatus _parseBillStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return BillStatus.active;
      case 'completed':
        return BillStatus.completed;
      case 'cancelled':
        return BillStatus.cancelled;
      default:
        return BillStatus.pending;
    }
  }
}
