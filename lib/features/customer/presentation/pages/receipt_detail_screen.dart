import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
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
  TextEditingController? _notesController;
  String? _currentReceiptId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceiptProvider>().loadReceiptById(widget.receiptId);
    });
  }

  @override
  void dispose() {
    _notesController?.dispose();
    super.dispose();
  }

  void _initializeNotesController(ReceiptEntity receipt) {
    // Initialize or update controller when receipt changes
    if (_currentReceiptId != receipt.id) {
      _notesController?.dispose();
      _notesController = TextEditingController(text: receipt.notes ?? '');
      _currentReceiptId = receipt.id;
    }
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
          Consumer<ReceiptProvider>(
            builder: (context, provider, child) {
              final receipt = provider.selectedReceipt;
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.receiptText),
                onSelected: (value) {
                  if (value == 'delete' && receipt != null) {
                    _showDeleteConfirmation(context, receipt);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Delete Receipt',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
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
                    // ignore: deprecated_member_use
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

                  // Receipt Photo (if exists) - Shows items for manual entries
                  if (receipt.receiptPhotoPath != null)
                    _buildReceiptPhoto(receipt),

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

                  // Notes Section
                  _buildNotesSection(receipt),

                  // Tags Section
                  _buildTagsSection(receipt),

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
          // Category Badge (for manual entries)
          if (receipt.businessCategory != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  // ignore: deprecated_member_use
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getCategoryIcon(receipt.businessCategory!),
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    receipt.businessCategory!.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildReceiptPhoto(ReceiptEntity receipt) {
    final photoPath = receipt.receiptPhotoPath;
    if (photoPath == null) return const SizedBox.shrink();

    final photoFile = File(photoPath);
    if (!photoFile.existsSync()) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: AppColors.receiptBorder),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📸 Receipt Photo',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  // Show fullscreen photo dialog
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: Stack(
                        children: [
                          Center(
                            child: InteractiveViewer(
                              child: Image.file(photoFile, fit: BoxFit.contain),
                            ),
                          ),
                          Positioned(
                            top: 40,
                            right: 20,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 30,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primaryBlue, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      photoFile,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap to view fullscreen',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.lightTextSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
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

  /// Generate and share receipt as PDF (NO Cloud Function needed!)
  /// COST OPTIMIZATION: Client-side generation = FREE
  Future<void> _shareReceipt(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Generating PDF receipt...'),
            ],
          ),
        ),
      );

      final receipt = context.read<ReceiptProvider>().selectedReceipt;
      if (receipt == null) return;

      // Generate PDF using pdf package
      final pdfBytes = await _generateReceiptPDF(receipt);

      if (!mounted) return;

      // Clear loading indicator
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Share PDF
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'receipt_${receipt.receiptId}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Receipt PDF ready to share!'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating receipt: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Download receipt as PDF
  Future<void> _downloadReceipt(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Generating PDF receipt...'),
            ],
          ),
        ),
      );

      final receipt = context.read<ReceiptProvider>().selectedReceipt;
      if (receipt == null) return;

      // Generate PDF
      final pdfBytes = await _generateReceiptPDF(receipt);

      if (!mounted) return;

      // Clear loading
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Share (on mobile/web this triggers download)
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'receipt_${receipt.receiptId}.pdf',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.download_done, color: Colors.white),
                SizedBox(width: 12),
                Text('Receipt downloaded!'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading receipt: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Generate receipt PDF (local, instant, FREE!)
  Future<Uint8List> _generateReceiptPDF(ReceiptEntity receipt) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final currencyFormat = NumberFormat.currency(
      symbol: 'Rs.',
      decimalDigits: 2,
    );

    // Load ALL Indian language fonts for comprehensive script support
    // This enables proper rendering of Telugu, Hindi, Tamil, Kannada, Malayalam,
    // Marathi, Gujarati, Punjabi, Bengali, Odia, and English text in customer receipts

    // Devanagari script (Hindi, Marathi, Sanskrit)
    final devanagariData = await rootBundle.load(
      'assets/fonts/NotoSansDevanagari/NotoSansDevanagari-Variable.ttf',
    );
    final devanagariFont = pw.Font.ttf(devanagariData);

    // Telugu script
    final teluguData = await rootBundle.load(
      'assets/fonts/NotoSansTelugu/NotoSansTelugu-Variable.ttf',
    );
    final teluguFont = pw.Font.ttf(teluguData);

    // Tamil script
    final tamilData = await rootBundle.load(
      'assets/fonts/NotoSansTamil/NotoSansTamil-Variable.ttf',
    );
    final tamilFont = pw.Font.ttf(tamilData);

    // Kannada script
    final kannadaData = await rootBundle.load(
      'assets/fonts/NotoSansKannada/NotoSansKannada-Variable.ttf',
    );
    final kannadaFont = pw.Font.ttf(kannadaData);

    // Malayalam script
    final malayalamData = await rootBundle.load(
      'assets/fonts/NotoSansMalayalam/NotoSansMalayalam-Variable.ttf',
    );
    final malayalamFont = pw.Font.ttf(malayalamData);

    // Gujarati script
    final gujaratiData = await rootBundle.load(
      'assets/fonts/NotoSansGujarati/NotoSansGujarati-Variable.ttf',
    );
    final gujaratiFont = pw.Font.ttf(gujaratiData);

    // Gurmukhi script (Punjabi)
    final gurmukhiData = await rootBundle.load(
      'assets/fonts/NotoSansGurmukhi/NotoSansGurmukhi-Variable.ttf',
    );
    final gurmukhiFont = pw.Font.ttf(gurmukhiData);

    // Bengali script
    final bengaliData = await rootBundle.load(
      'assets/fonts/NotoSansBengali/NotoSansBengali-Variable.ttf',
    );
    final bengaliFont = pw.Font.ttf(bengaliData);

    // Odia script (Oriya)
    final odiaData = await rootBundle.load(
      'assets/fonts/NotoSansOriya/NotoSansOriya-Variable.ttf',
    );
    final odiaFont = pw.Font.ttf(odiaData);

    // Font fallback list - PDF library will try fonts in order until it finds
    // one that supports the characters being rendered
    final fontFallbacks = [
      devanagariFont, // Hindi, Marathi, English, numbers
      teluguFont, // Telugu
      tamilFont, // Tamil
      kannadaFont, // Kannada
      malayalamFont, // Malayalam
      gujaratiFont, // Gujarati
      gurmukhiFont, // Punjabi
      bengaliFont, // Bengali
      odiaFont, // Odia
    ];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Header with logo placeholder
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      receipt.merchantName,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (receipt.merchantAddress != null) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        receipt.merchantAddress!,
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                    if (receipt.merchantPhone != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Phone: ${receipt.merchantPhone}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                    if (receipt.merchantGst != null) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'GSTIN: ${receipt.merchantGst}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ],
                ),
                pw.Container(
                  width: 80,
                  height: 80,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(40),
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      receipt.merchantName.substring(0, 1).toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 36,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 30),
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 20),

            // Receipt Title
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    receipt.receiptId,
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Date: ${dateFormat.format(receipt.createdAt)}',
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 30),

            // Items Table
            pw.Table.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                font:
                    fontFallbacks[0], // Devanagari for headers (includes Latin)
                fontFallback: fontFallbacks,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              cellStyle: pw.TextStyle(
                fontSize: 11,
                font:
                    fontFallbacks[0], // Base font (Devanagari - includes Latin/English)
                fontFallback:
                    fontFallbacks, // Fallback for other Indian scripts
              ),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.all(8),
              headers: ['Item', 'Qty', 'Price', 'Amount'],
              data: receipt.items
                  .map(
                    (item) => [
                      item.name,
                      item.quantity.toString(),
                      currencyFormat.format(item.price),
                      currencyFormat.format(item.total),
                    ],
                  )
                  .toList(),
            ),

            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),

            // Summary
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Subtotal: ${currencyFormat.format(receipt.subtotal)}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    if (receipt.tax > 0) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Tax: ${currencyFormat.format(receipt.tax)}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                    if (receipt.discount > 0) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Discount: ${currencyFormat.format(receipt.discount)}',
                        style: const pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.green700,
                        ),
                      ),
                    ],
                    pw.SizedBox(height: 8),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Text(
                        'TOTAL: ${currencyFormat.format(receipt.total)}',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            pw.SizedBox(height: 30),
            pw.Divider(),

            // Payment Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Payment Method: ${PaymentMethodHelper.getDisplayName(receipt.paymentMethod)}',
                  style: const pw.TextStyle(fontSize: 11),
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    color: receipt.paymentStatus == PaymentStatus.paid
                        ? PdfColors.green50
                        : PdfColors.orange50,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(12),
                    ),
                  ),
                  child: pw.Text(
                    receipt.paymentStatus == PaymentStatus.paid
                        ? 'PAID'
                        : 'PENDING',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: receipt.paymentStatus == PaymentStatus.paid
                          ? PdfColors.green900
                          : PdfColors.orange900,
                    ),
                  ),
                ),
              ],
            ),

            if (receipt.transactionId != null) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                'Transaction ID: ${receipt.transactionId}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],

            pw.Spacer(),

            // Footer
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Column(
                children: [
                  if (receipt.isVerified)
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Icon(
                          const pw.IconData(0xe86c),
                          size: 14,
                          color: PdfColors.green700,
                        ),
                        pw.SizedBox(width: 4),
                        pw.Text(
                          'Verified & Authentic',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green700,
                          ),
                        ),
                      ],
                    ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Thank you for your business!',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Powered by BILEE - Paperless Billing System',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated at ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
                    style: const pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'grocery':
      case 'groceries':
        return '🛒';
      case 'restaurant':
      case 'food':
        return '🍽️';
      case 'pharmacy':
      case 'healthcare':
        return '💊';
      case 'electronics':
        return '📱';
      case 'clothing':
      case 'fashion':
        return '👕';
      case 'transport':
        return '🚌';
      case 'entertainment':
        return '🎬';
      case 'services':
        return '🔧';
      default:
        return '💰';
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    ReceiptEntity receipt,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Receipt?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReceiptSummary(receipt),
            const SizedBox(height: 16),
            const Text(
              '⚠️ This action cannot be undone.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Receipt will be permanently deleted from all devices.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Delete receipt
        await context.read<ReceiptProvider>().deleteReceipt(receipt.id);

        if (!context.mounted) return;

        // Close loading dialog
        Navigator.pop(context);

        // Navigate back to list
        context.pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt deleted successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (!context.mounted) return;

        // Close loading dialog
        Navigator.pop(context);

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting receipt: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildReceiptSummary(ReceiptEntity receipt) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Receipt #${receipt.receiptId}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            receipt.merchantName,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (receipt.businessCategory != null) ...[
            const SizedBox(height: 2),
            Text(
              receipt.businessCategory!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Amount:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '₹${receipt.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Date:',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                DateFormat('MMM dd, yyyy').format(receipt.createdAt),
                style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build Notes Section
  Widget _buildNotesSection(ReceiptEntity receipt) {
    _initializeNotesController(receipt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.note_outlined,
                size: 20,
                color: AppColors.lightTextPrimary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Notes',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'Add notes (warranty info, return policy, etc.)',
              hintStyle: const TextStyle(
                color: AppColors.lightTextSecondary,
                fontSize: 13,
                fontFamily: 'Inter',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.lightBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.lightBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.all(12),
              filled: true,
              fillColor: AppColors.lightSurface,
            ),
            maxLines: 3,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.lightTextPrimary,
            ),
            onChanged: (value) => _saveNotes(receipt, value),
          ),
        ],
      ),
    );
  }

  /// Build Tags Section
  Widget _buildTagsSection(ReceiptEntity receipt) {
    final tags = receipt.tags ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_offer_outlined,
                size: 20,
                color: AppColors.lightTextPrimary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Tags',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...tags.map(
                (tag) => Chip(
                  label: Text(
                    tag,
                    style: const TextStyle(fontSize: 12, fontFamily: 'Inter'),
                  ),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => _removeTag(receipt, tag),
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  labelStyle: const TextStyle(color: AppColors.primaryBlue),
                  deleteIconColor: AppColors.primaryBlue,
                ),
              ),
              ActionChip(
                label: const Text(
                  '+ Add Tag',
                  style: TextStyle(fontSize: 12, fontFamily: 'Inter'),
                ),
                onPressed: () => _showAddTagDialog(receipt),
                backgroundColor: AppColors.lightDivider,
                labelStyle: const TextStyle(color: AppColors.lightTextPrimary),
              ),
            ],
          ),
          if (tags.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No tags yet. Add tags like #warranty, #business, #tax',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.lightTextSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Save notes
  void _saveNotes(ReceiptEntity receipt, String notes) {
    final provider = context.read<ReceiptProvider>();
    final updatedReceipt = receipt.copyWith(
      notes: notes.isEmpty ? null : notes,
    );
    provider.updateReceipt(updatedReceipt);
  }

  /// Remove tag
  void _removeTag(ReceiptEntity receipt, String tag) {
    final provider = context.read<ReceiptProvider>();
    final newTags = List<String>.from(receipt.tags ?? [])..remove(tag);
    final updatedReceipt = receipt.copyWith(
      tags: newTags.isEmpty ? null : newTags,
    );
    provider.updateReceipt(updatedReceipt);
  }

  /// Show add tag dialog
  void _showAddTagDialog(ReceiptEntity receipt) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Tag'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: '#warranty',
                prefixText: '#',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(
              'Suggestions:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  ['warranty', 'business', 'personal', 'tax', 'reimbursable']
                      .map(
                        (tag) => ActionChip(
                          label: Text(
                            '#$tag',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.lightTextPrimary,
                            ),
                          ),
                          onPressed: () {
                            controller.text = tag;
                          },
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              var tag = controller.text.trim();
              if (tag.startsWith('#')) tag = tag.substring(1);
              if (tag.isNotEmpty) {
                _addTag(receipt, '#$tag');
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Add tag
  void _addTag(ReceiptEntity receipt, String tag) {
    final provider = context.read<ReceiptProvider>();
    final newTags = List<String>.from(receipt.tags ?? []);
    if (!newTags.contains(tag)) {
      newTags.add(tag);
      final updatedReceipt = receipt.copyWith(tags: newTags);
      provider.updateReceipt(updatedReceipt);
    }
  }
}
