import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for handling UPI payments using url_launcher
class UpiPaymentService {
  static const _platform = MethodChannel('com.example.bilee/upi_chooser');

  /// Initiate UPI payment with QR data preservation
  Future<Map<String, dynamic>> initiatePayment({
    required String upiId,
    required double amount,
    required String merchantName,
    String transactionNote = 'Payment via Bilee',
    String? qrData, // Original QR data to preserve encoding
  }) async {
    try {
      debugPrint('═══════════════════════════════════════════');
      debugPrint('🔵 UPI PAYMENT STARTED');
      debugPrint('🎯 SERVICE: CUSTOMER UPI SERVICE (url_launcher)');
      debugPrint('═══════════════════════════════════════════');
      debugPrint('📋 Payment Details:');
      debugPrint('   • UPI ID: $upiId');
      debugPrint('   • Merchant: $merchantName');
      debugPrint('   • Amount: ₹$amount');
      debugPrint('   • Note: $transactionNote');
      debugPrint('   • Has QR Data: ${qrData != null}');
      debugPrint('───────────────────────────────────────────');

      // Validate UPI ID
      if (!upiId.contains('@')) {
        throw Exception('Invalid UPI ID format');
      }

      // Validate amount
      if (amount <= 0) {
        throw Exception('Invalid amount');
      }

      String finalUri;

      if (qrData != null && qrData.startsWith('upi://')) {
        debugPrint('✅ Using original QR data (preserves encoding)...');
        debugPrint('📤 Original QR URI: $qrData');
        finalUri = qrData;
      } else {
        debugPrint('✅ Building UPI URI manually...');

        // Clean merchant name - remove extra spaces and special characters
        final cleanMerchant = merchantName.trim().replaceAll(
          RegExp(r'\s+'),
          ' ',
        );

        // Simple transaction note for better compatibility
        final simpleNote = 'Payment from Bilee';

        // Build minimal URI without currency parameter (better compatibility)
        // Some UPI apps reject transactions with cu= parameter or complex encoding
        finalUri =
            'upi://pay?pa=$upiId&pn=$cleanMerchant&am=${amount.toStringAsFixed(2)}&tn=$simpleNote';

        debugPrint('📤 UPI URI (manual): $finalUri');
      }

      debugPrint('✅ Launching UPI app with chooser...');

      final launchUri = Uri.parse(finalUri);

      try {
        // Try to use platform channel to show chooser (Android only)
        // Method name MUST match MainActivity: 'launchUpiChooser'
        await _platform.invokeMethod('launchUpiChooser', {'upiUri': finalUri});
        debugPrint('✅ UPI app chooser displayed via platform channel');
      } on PlatformException catch (e) {
        debugPrint('⚠️  Platform channel error: ${e.message}');
        debugPrint('   Falling back to url_launcher...');

        // Fallback to url_launcher if platform channel fails
        final canLaunch = await canLaunchUrl(launchUri);
        if (canLaunch) {
          await launchUrl(launchUri, mode: LaunchMode.externalApplication);
          debugPrint('✅ UPI app launched (default, no chooser)');
        } else {
          throw Exception('No UPI app found to handle payment');
        }
      } on MissingPluginException {
        debugPrint('⚠️  Platform channel not available');
        debugPrint('   Falling back to url_launcher...');

        // Fallback for iOS or if platform channel is not set up
        final canLaunch = await canLaunchUrl(launchUri);
        if (canLaunch) {
          await launchUrl(launchUri, mode: LaunchMode.externalApplication);
          debugPrint('✅ UPI app launched (default, no chooser)');
        } else {
          throw Exception('No UPI app found to handle payment');
        }
      }

      debugPrint('═══════════════════════════════════════════');

      // Return success since we can't track payment status with url_launcher
      return {
        'success': true,
        'status': 'LAUNCHED',
        'message': 'UPI app launched successfully',
      };
    } catch (e, stackTrace) {
      debugPrint('═══════════════════════════════════════════');
      debugPrint('❌ UPI PAYMENT ERROR');
      debugPrint('═══════════════════════════════════════════');
      debugPrint('Error: $e');
      debugPrint('Type: ${e.runtimeType}');
      debugPrint('Stack: $stackTrace');
      debugPrint('═══════════════════════════════════════════');

      return {'success': false, 'status': 'ERROR', 'error': e.toString()};
    }
  }
}
