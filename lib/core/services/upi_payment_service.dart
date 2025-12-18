import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// UPI Payment Service (Core/Legacy)
/// Handles UPI payment transactions with url_launcher
class CoreUpiPaymentService {
  /// Launch only the UPI app home screen (no payment params)
  Future<void> openUpiAppHome() async {
    try {
      debugPrint('═══════════════════════════════════════════');
      debugPrint('🔵 OPEN UPI APP HOME (no params)');
      debugPrint('🎯 SERVICE: CORE/LEGACY UPI SERVICE (open app only)');
      debugPrint('═══════════════════════════════════════════');
      final uri = Uri.parse('upi://pay');
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('✅ UPI app home opened');
      } else {
        throw Exception('No UPI app found to open');
      }
    } catch (e, stackTrace) {
      debugPrint('═══════════════════════════════════════════');
      debugPrint('❌ UPI APP OPEN ERROR');
      debugPrint('═══════════════════════════════════════════');
      debugPrint('Error: $e');
      debugPrint('Type: ${e.runtimeType}');
      debugPrint('Stack: $stackTrace');
      debugPrint('═══════════════════════════════════════════');
      rethrow;
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initiate UPI payment
  Future<void> initiatePayment({
    required String receiptId,
    required String merchantName,
    required String merchantUpiId,
    required double amount,
  }) async {
    try {
      debugPrint('═══════════════════════════════════════════');
      debugPrint('🔵 UPI PAYMENT STARTED');
      debugPrint('🎯 SERVICE: CORE/LEGACY UPI SERVICE');
      debugPrint('═══════════════════════════════════════════');
      debugPrint('   UPI ID: $merchantUpiId');
      debugPrint('   Amount: ₹$amount');
      debugPrint('   Transaction Note: Payment via Bilee - $merchantName');

      // Build UPI payment URI
      final upiUri = Uri(
        scheme: 'upi',
        host: 'pay',
        queryParameters: {
          'pa': merchantUpiId,
          'pn': merchantName,
          'am': amount.toStringAsFixed(2),
          'cu': 'INR',
          'tn': 'Payment via Bilee - $merchantName',
        },
      );

      debugPrint('📤 UPI URI: $upiUri');

      // Launch UPI app
      final canLaunch = await canLaunchUrl(upiUri);
      if (canLaunch) {
        await launchUrl(upiUri, mode: LaunchMode.externalApplication);
        debugPrint('📱 UPI app launched');
      } else {
        throw Exception('No UPI app found');
      }
    } catch (e) {
      debugPrint('❌ Error initiating payment: $e');
      throw Exception('Payment initiation failed: $e');
    }
  }

  /// Update receipt payment status in Firestore
  Future<void> updateReceiptPaymentStatus({
    required String receiptId,
    required String status,
    String? transactionId,
  }) async {
    try {
      await _firestore.collection('receipts').doc(receiptId).update({
        'paymentStatus': status,
        if (transactionId != null) 'transactionId': transactionId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Receipt payment status updated: $status');
    } catch (e) {
      debugPrint('❌ Error updating payment status: $e');
      throw Exception('Failed to update payment status: $e');
    }
  }

  /// Verify payment status with merchant
  /// Merchant confirms the payment on their end
  Future<void> merchantConfirmPayment({
    required String receiptId,
    required bool isConfirmed,
  }) async {
    try {
      await _firestore.collection('receipts').doc(receiptId).update({
        'paymentStatus': isConfirmed ? 'paid' : 'failed',
        'merchantConfirmedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error confirming payment: $e');
      throw Exception('Failed to confirm payment: $e');
    }
  }

  /// Listen to payment status changes in real-time
  Stream<String> listenToPaymentStatus(String receiptId) {
    return _firestore.collection('receipts').doc(receiptId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return 'pending';
      final data = snapshot.data();
      return data?['paymentStatus'] ?? 'pending';
    });
  }
}
