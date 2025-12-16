import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
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
