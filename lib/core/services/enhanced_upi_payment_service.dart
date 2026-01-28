import 'package:flutter/services.dart';
import 'dart:async';
import '../security/encryption_service.dart';

/// Enhanced UPI Payment Service using Platform Channels
/// Directly invokes UPI intents on Android/iOS for automated payments
/// This replaces third-party packages with custom native implementation
class UpiPaymentService {
  static const MethodChannel _channel = MethodChannel('com.bilee.upi/payment');

  /// Check if device has UPI apps installed
  Future<bool> hasUpiApps() async {
    try {
      final bool hasApps = await _channel.invokeMethod('hasUpiApps');
      return hasApps;
    } on PlatformException catch (e) {
      print('Platform error checking UPI apps: ${e.message}');
      return false;
    } catch (e) {
      print('Error checking UPI apps: $e');
      return false;
    }
  }

  /// Get list of installed UPI apps
  Future<List<UpiApp>> getInstalledUpiApps() async {
    try {
      final List<dynamic> apps = await _channel.invokeMethod('getUpiApps');
      return apps
          .map((app) => UpiApp.fromMap(Map<String, dynamic>.from(app)))
          .toList();
    } on PlatformException catch (e) {
      print('Platform error getting UPI apps: ${e.message}');
      return [];
    } catch (e) {
      print('Error getting UPI apps: $e');
      return [];
    }
  }

  /// Initiate UPI payment with encrypted merchant UPI ID
  /// Returns UpiPaymentResponse with transaction status
  Future<UpiPaymentResponse> initiatePayment({
    required String encryptedMerchantUpiId,
    required String merchantName,
    required String transactionId,
    required String transactionNote,
    required double amount,
    String?
    preferredApp, // Package name like 'com.google.android.apps.nbu.paisa.user'
  }) async {
    try {
      // Decrypt merchant UPI ID
      final merchantUpiId = await EncryptionService.decryptUpiId(
        encryptedMerchantUpiId,
      );

      final Map<String, dynamic> params = {
        'pa': merchantUpiId, // Payee address (UPI ID)
        'pn': merchantName, // Payee name
        'tr': transactionId, // Transaction reference ID
        'tn': transactionNote, // Transaction note
        'am': amount.toStringAsFixed(2), // Amount
        'cu': 'INR', // Currency
        'preferredApp': preferredApp,
      };

      print(
        '🔵 Initiating UPI payment: ₹${amount.toStringAsFixed(2)} to $merchantName',
      );

      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'initiatePayment',
        params,
      );
      final response = UpiPaymentResponse.fromMap(
        Map<String, dynamic>.from(result),
      );

      print('✅ UPI payment response: ${response.status}');
      return response;
    } on PlatformException catch (e) {
      print('❌ Platform error during UPI payment: ${e.message}');
      return UpiPaymentResponse(
        status: UpiPaymentStatus.failed,
        error: e.message ?? 'Platform error',
      );
    } catch (e) {
      print('❌ Error initiating UPI payment: $e');
      return UpiPaymentResponse(
        status: UpiPaymentStatus.failed,
        error: e.toString(),
      );
    }
  }

  /// Verify transaction status (placeholder for backend integration)
  /// In production, this should call your backend API to verify with UPI gateway
  Future<bool> verifyTransaction(String txnId) async {
    // TODO: Implement backend verification
    // This should call a Firebase Cloud Function or your backend API
    // to verify the transaction with the UPI gateway

    // For now, we trust the UPI app response
    return true;
  }
}

/// UPI App information
class UpiApp {
  final String packageName;
  final String appName;
  final String? icon; // Base64 encoded icon (optional)

  UpiApp({required this.packageName, required this.appName, this.icon});

  factory UpiApp.fromMap(Map<String, dynamic> map) {
    return UpiApp(
      packageName: map['packageName'] ?? '',
      appName: map['appName'] ?? '',
      icon: map['icon'],
    );
  }

  // Common UPI app package names for Android
  static const String googlePay = 'com.google.android.apps.nbu.paisa.user';
  static const String phonePe = 'com.phonepe.app';
  static const String paytm = 'net.one97.paytm';
  static const String bhim = 'in.org.npci.upiapp';
  static const String amazonPay = 'in.amazon.mShop.android.shopping';
  static const String mobikwik = 'com.mobikwik_new';
  static const String freecharge = 'com.freecharge.android';
}

/// UPI Payment Response from native platform
class UpiPaymentResponse {
  final UpiPaymentStatus status;
  final String? transactionId;
  final String? transactionRefId;
  final String? approvalRefNo;
  final String? error;

  UpiPaymentResponse({
    required this.status,
    this.transactionId,
    this.transactionRefId,
    this.approvalRefNo,
    this.error,
  });

  factory UpiPaymentResponse.fromMap(Map<String, dynamic> map) {
    return UpiPaymentResponse(
      status: _parseStatus(map['status']),
      transactionId: map['txnId'],
      transactionRefId: map['txnRef'],
      approvalRefNo: map['approvalRefNo'],
      error: map['error'],
    );
  }

  static UpiPaymentStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'success':
        return UpiPaymentStatus.success;
      case 'submitted':
        return UpiPaymentStatus.submitted;
      case 'failure':
      case 'failed':
        return UpiPaymentStatus.failed;
      default:
        return UpiPaymentStatus.failed;
    }
  }

  bool get isSuccess => status == UpiPaymentStatus.success;
  bool get isSubmitted => status == UpiPaymentStatus.submitted;
  bool get isFailed => status == UpiPaymentStatus.failed;
}

/// UPI Payment Status
enum UpiPaymentStatus {
  success, // Payment successful
  submitted, // Payment submitted (pending confirmation)
  failed, // Payment failed
}

/// UPI Payment Result for SessionProvider
class UpiPaymentResult {
  final UpiPaymentResultStatus status;
  final String? txnId;
  final String message;

  UpiPaymentResult.success({this.txnId, required this.message})
    : status = UpiPaymentResultStatus.success;

  UpiPaymentResult.failed({required this.message})
    : status = UpiPaymentResultStatus.failed,
      txnId = null;

  UpiPaymentResult.pending({required this.message})
    : status = UpiPaymentResultStatus.pending,
      txnId = null;

  UpiPaymentResult.error({required this.message})
    : status = UpiPaymentResultStatus.error,
      txnId = null;
}

enum UpiPaymentResultStatus { success, failed, pending, error }
