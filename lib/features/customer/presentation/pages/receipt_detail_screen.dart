import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/upi_payment_service.dart';
import '../../domain/entities/receipt_entity.dart';
import '../providers/receipt_provider.dart';

/// Receipt Detail Screen - Full receipt display
class ReceiptDetailScreen extends StatefulWidget {
  final String receiptId;

  const ReceiptDetailScreen({super.key, required this.receiptId});

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  final CoreUpiPaymentService _upiService = CoreUpiPaymentService();
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceiptProvider>().loadReceiptById(widget.receiptId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.receiptPaper,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.receiptText),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Receipt',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: AppColors.receiptText,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              color: AppColors.receiptText,
            ),
            onPressed: () => _shareReceipt(context),
          ),
          IconButton(
            icon: const Icon(
              Icons.download_outlined,
              color: AppColors.receiptText,
            ),
            onPressed: () => _downloadReceipt(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<ReceiptProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.selectedReceipt == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: AppColors.lightTextTertiary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Receipt not found',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This receipt may have been deleted\nor is not available',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final receipt = provider.selectedReceipt!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.receiptBorder, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Receipt Header
                  _buildReceiptHeader(receipt),

                  // Verified Badge
                  if (receipt.isVerified) _buildVerifiedBadge(),

                  const Divider(height: 1, color: AppColors.receiptBorder),

                  // Merchant Info
                  _buildMerchantInfo(receipt),

                  const Divider(height: 1, color: AppColors.receiptBorder),

                  // Items List
                  _buildItemsList(receipt),

                  const Divider(height: 1, color: AppColors.receiptBorder),

                  // Summary
                  _buildSummary(receipt),

                  const Divider(height: 1, color: AppColors.receiptBorder),

                  // Pay Now Button (if payment is pending and method is UPI)
                  if (receipt.paymentStatus == PaymentStatus.pending &&
                      receipt.paymentMethod == PaymentMethod.upi)
                    _buildPayNowButton(receipt),

                  // Payment Info
                  _buildPaymentInfo(receipt),

                  // Receipt Footer
                  _buildReceiptFooter(receipt),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceiptHeader(ReceiptEntity receipt) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            'DIGITAL RECEIPT',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            receipt.receiptId,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: AppColors.success.withOpacity(0.1),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified, size: 20, color: AppColors.success),
          SizedBox(width: 8),
          Text(
            'Verified & Authentic',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMerchantInfo(ReceiptEntity receipt) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            receipt.merchantName,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.receiptText,
            ),
          ),
          if (receipt.merchantAddress != null) ...[
            const SizedBox(height: 8),
            Text(
              receipt.merchantAddress!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.lightTextSecondary,
              ),
            ),
          ],
          if (receipt.merchantPhone != null) ...[
            const SizedBox(height: 4),
            Text(
              'Phone: ${receipt.merchantPhone}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.lightTextSecondary,
              ),
            ),
          ],
          if (receipt.merchantGst != null) ...[
            const SizedBox(height: 4),
            Text(
              'GST: ${receipt.merchantGst}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.lightTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Date: ${DateFormat('MMM dd, yyyy • hh:mm a').format(receipt.createdAt)}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.receiptText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(ReceiptEntity receipt) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ITEMS',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.lightTextSecondary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          ...receipt.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.quantity}x',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.receiptText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.receiptText,
                          ),
                        ),
                        Text(
                          '₹${item.price.toStringAsFixed(2)} each',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${item.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.receiptText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(ReceiptEntity receipt) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal', receipt.subtotal),
          if (receipt.tax > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Tax', receipt.tax),
          ],
          if (receipt.discount > 0) ...[
            const SizedBox(height: 8),
            _buildSummaryRow('Discount', -receipt.discount, isDiscount: true),
          ],
          const SizedBox(height: 12),
          Container(height: 2, color: AppColors.receiptBorder),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.receiptText,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '₹${receipt.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.receiptText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.lightTextSecondary,
          ),
        ),
        Text(
          '₹${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDiscount ? AppColors.success : AppColors.receiptText,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentInfo(ReceiptEntity receipt) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppColors.lightBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PAYMENT DETAILS',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextSecondary,
                  letterSpacing: 1,
                ),
              ),
              _buildPaymentStatusBadge(receipt.paymentStatus),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                PaymentMethodHelper.getIcon(receipt.paymentMethod),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                PaymentMethodHelper.getDisplayName(receipt.paymentMethod),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.receiptText,
                ),
              ),
            ],
          ),
          if (receipt.transactionId != null) ...[
            const SizedBox(height: 8),
            Text(
              'Transaction ID: ${receipt.transactionId}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiptFooter(ReceiptEntity receipt) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          if (receipt.notes != null) ...[
            Text(
              receipt.notes!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.lightTextSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Thank you for your business!',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.receiptText,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Powered by BILEE',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusBadge(PaymentStatus status) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (status) {
      case PaymentStatus.paid:
        badgeColor = AppColors.success;
        badgeText = 'PAID';
        badgeIcon = Icons.check_circle;
        break;
      case PaymentStatus.pending:
        badgeColor = Colors.orange;
        badgeText = 'PENDING';
        badgeIcon = Icons.access_time;
        break;
      case PaymentStatus.failed:
        badgeColor = AppColors.error;
        badgeText = 'FAILED';
        badgeIcon = Icons.error;
        break;
      case PaymentStatus.cancelled:
        badgeColor = AppColors.lightTextTertiary;
        badgeText = 'CANCELLED';
        badgeIcon = Icons.cancel;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: badgeColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayNowButton(ReceiptEntity receipt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1, color: AppColors.receiptBorder),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryBlue.withOpacity(0.1),
                  AppColors.primaryBlueLight.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.payment,
                        color: AppColors.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Complete Payment',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            'Pay ₹${receipt.total.toStringAsFixed(2)} via UPI',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isProcessingPayment
                      ? null
                      : () => _handlePayNow(receipt),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessingPayment
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.account_balance_wallet, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Pay Now with UPI',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePayNow(ReceiptEntity receipt) async {
    try {
      debugPrint('═══════════════════════════════════════════');
      debugPrint('💳 RECEIPT PAYMENT FLOW STARTED');
      debugPrint('═══════════════════════════════════════════');
      debugPrint('📋 Receipt ID: ${receipt.id}');
      debugPrint('📋 Receipt Number: ${receipt.receiptId}');
      debugPrint('💰 Amount: ₹${receipt.total}');
      debugPrint('🏪 Merchant: ${receipt.merchantName}');
      debugPrint('🆔 Merchant ID: ${receipt.merchantId}');
      debugPrint('───────────────────────────────────────────');

      debugPrint('🔄 Setting processing state to true...');
      setState(() => _isProcessingPayment = true);
      debugPrint('✅ Processing state updated');
      debugPrint('───────────────────────────────────────────');

      // Fetch merchant UPI ID from merchant profile
      debugPrint('🔍 Step 1: Fetching merchant UPI ID...');
      debugPrint('   • Querying Firestore for merchant: ${receipt.merchantId}');
      final merchantDoc = await FirebaseFirestore.instance
          .collection('merchants')
          .doc(receipt.merchantId)
          .get();

      final merchantUpiId = merchantDoc.data()?['upiId'] as String?;
      debugPrint(
        '   • Merchant UPI ID from Firestore: ${merchantUpiId ?? "NOT FOUND"}',
      );

      if (merchantUpiId == null || merchantUpiId.isEmpty) {
        debugPrint('❌ Merchant UPI ID not configured');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Merchant has not configured UPI ID. Please contact merchant.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isProcessingPayment = false);
        }
        return;
      }
      debugPrint('✅ Step 1 complete: Merchant UPI ID retrieved');
      debugPrint('───────────────────────────────────────────');

      // Mark payment as initiated BEFORE launching UPI app
      debugPrint('💾 Step 2: Updating receipt payment status...');
      final transactionId =
          'BILEE${receipt.receiptId}${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('   • Transaction ID: $transactionId');
      debugPrint('   • Status: pending');
      await _upiService.updateReceiptPaymentStatus(
        receiptId: receipt.id,
        status: 'pending',
        transactionId: transactionId,
      );
      debugPrint('✅ Step 2 complete: Payment status updated in Firestore');
      debugPrint('───────────────────────────────────────────');

      // Reload receipt to reflect updated payment status
      debugPrint('🔄 Step 3: Reloading receipt data...');
      if (mounted) {
        await context.read<ReceiptProvider>().loadReceiptById(receipt.id);
        debugPrint('✅ Step 3 complete: Receipt data reloaded');
      }
      debugPrint('───────────────────────────────────────────');

      // Reset processing state BEFORE launching UPI app
      debugPrint('🔄 Step 4: Resetting processing state...');
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        debugPrint('✅ Step 4 complete: Processing flag reset to false');
      }
      debugPrint('───────────────────────────────────────────');

      // Show message that payment is being initiated
      debugPrint('📢 Step 5: Showing user notification...');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📱 Opening UPI app...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
        debugPrint('✅ Step 5 complete: Snackbar displayed');
      }
      debugPrint('───────────────────────────────────────────');

      // Small delay to ensure UI updates
      debugPrint('⏳ Step 6: Waiting 300ms for UI updates...');
      await Future.delayed(const Duration(milliseconds: 300));
      debugPrint('✅ Step 6 complete: Delay finished');
      debugPrint('───────────────────────────────────────────');

      // Now initiate payment
      debugPrint('🚀 Step 7: Launching UPI app...');
      debugPrint('   • UPI ID: $merchantUpiId');
      debugPrint('   • Amount: ₹${receipt.total}');
      if (mounted) {
        // Commented out payment initiation, now just open UPI app home
        await _upiService.openUpiAppHome();
        debugPrint('✅ Step 7 complete: UPI app home opened');
      }
      debugPrint('───────────────────────────────────────────');

      debugPrint('═══════════════════════════════════════════');
      debugPrint('✅ RECEIPT PAYMENT FLOW COMPLETE');
      debugPrint('═══════════════════════════════════════════');
    } catch (e, stackTrace) {
      debugPrint('═══════════════════════════════════════════');
      debugPrint('❌ RECEIPT PAYMENT ERROR');
      debugPrint('═══════════════════════════════════════════');
      debugPrint('Error: $e');
      debugPrint('Error Type: ${e.runtimeType}');
      debugPrint('Widget mounted: $mounted');
      debugPrint('Stack trace:');
      debugPrint('$stackTrace');
      debugPrint('═══════════════════════════════════════════');
      if (mounted) {
        setState(() => _isProcessingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showPaymentResult(String? status) {
    String message;
    Color backgroundColor;
    IconData icon;

    switch (status) {
      case 'SUCCESS':
        message = 'Payment successful! ✓';
        backgroundColor = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'FAILURE':
        message = 'Payment failed. Please try again.';
        backgroundColor = AppColors.error;
        icon = Icons.error;
        break;
      case 'SUBMITTED':
        message = 'Payment submitted. Waiting for confirmation...';
        backgroundColor = Colors.orange;
        icon = Icons.access_time;
        break;
      default:
        message = 'Payment cancelled.';
        backgroundColor = AppColors.lightTextTertiary;
        icon = Icons.cancel;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: backgroundColor),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  void _shareReceipt(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Share feature coming soon')));
  }

  void _downloadReceipt(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download feature coming soon')),
    );
  }
}
