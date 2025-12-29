import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/upi_payment_service.dart';
import '../providers/session_provider.dart';
import '../providers/merchant_provider.dart';

/// Live Session Page - Display QR code and handle payment
class LiveSessionPage extends StatefulWidget {
  final String merchantId;
  final String sessionId;

  const LiveSessionPage({
    super.key,
    required this.merchantId,
    required this.sessionId,
  });

  @override
  State<LiveSessionPage> createState() => _LiveSessionPageState();
}

class _LiveSessionPageState extends State<LiveSessionPage> {
  final CoreUpiPaymentService _upiService = CoreUpiPaymentService();
  SessionProvider? _sessionProvider; // Cache provider reference

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Cache provider reference for use in dispose
      _sessionProvider = context.read<SessionProvider>();
      _sessionProvider!.watchSession(widget.sessionId);
      context.read<MerchantProvider>().loadProfile(widget.merchantId);
    });
  }

  @override
  void dispose() {
    // Stop watching session when page is disposed
    _sessionProvider?.stopWatchingSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Live Session'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: Consumer<SessionProvider>(
        builder: (context, provider, child) {
          final session = provider.currentSession;

          if (provider.isLoading || session == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Show error if session expired or validation failed
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: AppDimensions.spacingLG),
                  Text(
                    provider.error!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spacingMD),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingLG),
            child: Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingLG),
                    child: Column(
                      children: [
                        const Text(
                          'Scan to Pay',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingLG),
                        QrImageView(
                          data: 'bilee://session/${widget.sessionId}',
                          version: QrVersions.auto,
                          size: 200.0,
                          eyeStyle: QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                          ),
                          embeddedImageStyle: const QrEmbeddedImageStyle(
                            size: Size(40, 40),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingLG),
                        Text(
                          'Session ID: ${widget.sessionId}',
                          style: TextStyle(color: AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLG),
                // Receipt-style Bill Details
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadowMedium,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingXL),
                    child: Consumer<MerchantProvider>(
                      builder: (context, merchantProvider, _) {
                        final merchantProfile = merchantProvider.profile;

                        return Column(
                          children: [
                            // Receipt Header - Business Name
                            Text(
                              merchantProfile?.businessName.toUpperCase() ??
                                  'BUSINESS',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.black87,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              merchantProfile?.businessType ?? 'General Store',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.lightTextSecondary,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacingLG),

                            // Dotted line separator
                            Row(
                              children: List.generate(
                                150 ~/ 3,
                                (index) => Expanded(
                                  child: Container(
                                    color: index % 2 == 0
                                        ? AppColors.lightBorder
                                        : Colors.transparent,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacingMD),

                            // Date and Session ID
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Date: ${session.createdAt.day}/${session.createdAt.month}/${session.createdAt.year}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.lightTextSecondary,
                                  ),
                                ),
                                Text(
                                  'Time: ${session.createdAt.hour}:${session.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppDimensions.spacingMD),

                            // Dotted line separator
                            Row(
                              children: List.generate(
                                150 ~/ 3,
                                (index) => Expanded(
                                  child: Container(
                                    color: index % 2 == 0
                                        ? AppColors.lightBorder
                                        : Colors.transparent,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacingMD),

                            // Items list - Receipt style single line format
                            ...session.items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Item details on left
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Qty: ${item.qty}  Price: ₹${item.price.toStringAsFixed(2)}  Tax: ${item.taxRate.toStringAsFixed(1)}%',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  AppColors.lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Total on right
                                    Text(
                                      '₹${item.total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: AppDimensions.spacingSM),

                            // Dotted line separator
                            Row(
                              children: List.generate(
                                150 ~/ 3,
                                (index) => Expanded(
                                  child: Container(
                                    color: index % 2 == 0
                                        ? AppColors.lightBorder
                                        : Colors.transparent,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppDimensions.spacingMD),

                            // Subtotal
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'SUBTOTAL',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.lightTextSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  '₹${session.subtotal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.lightTextPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Tax
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'TAX',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.lightTextSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  '₹${session.tax.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.lightTextPrimary,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: AppDimensions.spacingMD),

                            // Bold line separator
                            Container(height: 2, color: AppColors.lightBorder),
                            const SizedBox(height: AppDimensions.spacingMD),

                            // Total
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'TOTAL',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  '₹${session.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: AppDimensions.spacingLG),

                            // Payment Status
                            if (session.isPaid)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.paddingMD,
                                  vertical: AppDimensions.paddingSM,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSM,
                                  ),
                                  border: Border.all(
                                    color: AppColors.success,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: AppColors.success,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'PAID - ${session.paymentMethod ?? "CASH"}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.success,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppDimensions.paddingMD,
                                  vertical: AppDimensions.paddingSM,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusSM,
                                  ),
                                  border: Border.all(
                                    color: AppColors.warning,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.pending,
                                      color: AppColors.warning,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'PAYMENT PENDING',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.warning,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: AppDimensions.spacingLG),

                            // Footer
                            Text(
                              'Thank you for your purchase!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: AppColors.lightTextTertiary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Powered by ',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.lightTextTertiary,
                                  ),
                                ),
                                Text(
                                  'BILEE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryBlue,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLG),
                if (!session.isPaid) ...[
                  // If payment method is UPI, show confirm UPI payment button
                  if (session.paymentMethod?.toUpperCase() == 'UPI')
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(
                                AppDimensions.paddingMD,
                              ),
                              backgroundColor: AppColors.primaryBlue,
                            ),
                            onPressed: () => _confirmUpiPayment(session.id),
                            icon: const Icon(Icons.account_balance_wallet),
                            label: const Text(
                              'Confirm UPI Payment Received',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingSM),
                        const Text(
                          'Confirm after verifying UPI payment',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingMD),
                        const Divider(),
                        const SizedBox(height: AppDimensions.spacingSM),
                      ],
                    ),
                  // Regular mark as paid button for other payment methods
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(AppDimensions.paddingMD),
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => _showPaymentDialog(context),
                      child: const Text(
                        'Mark as Paid',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
                if (session.isPaid)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(AppDimensions.paddingMD),
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      onPressed: () async {
                        final success = await provider.completeSession(
                          widget.sessionId,
                        );
                        if (success && mounted) {
                          context.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Session completed successfully'),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Complete Session',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    String paymentMethod = 'CASH';
    final txnIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: paymentMethod,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: ['CASH', 'UPI', 'CARD', 'OTHER']
                  .map(
                    (method) =>
                        DropdownMenuItem(value: method, child: Text(method)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) paymentMethod = value;
              },
            ),
            const SizedBox(height: AppDimensions.spacingSM),
            TextField(
              controller: txnIdController,
              decoration: const InputDecoration(
                labelText: 'Transaction ID (optional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<SessionProvider>().markAsPaid(
                widget.sessionId,
                paymentMethod,
                txnIdController.text.isEmpty ? 'MANUAL' : txnIdController.text,
              );
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment recorded successfully'),
                    ),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmUpiPayment(String sessionId) async {
    try {
      // Get the receipt ID from the session
      final session = context.read<SessionProvider>().currentSession;
      if (session == null) {
        _showErrorSnackBar('Session not found');
        return;
      }

      // Fetch receipt document to get receiptId
      // The Cloud Function creates a receipt and stores receiptId in the session
      final sessionDoc = await FirebaseFirestore.instance
          .collection('billingSessions')
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        _showErrorSnackBar('Session document not found');
        return;
      }

      final sessionData = sessionDoc.data();
      final receiptId = sessionData?['receiptId'] as String?;

      if (receiptId == null || receiptId.isEmpty) {
        _showErrorSnackBar('Receipt not generated yet. Please try again.');
        return;
      }

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Confirm UPI Payment'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Have you received the UPI payment from the customer?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Please verify the payment in your UPI app before confirming',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.check_circle, size: 20),
              label: const Text('Yes, Confirm Payment'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      // Confirm payment via UPI service using the actual receipt ID
      await _upiService.merchantConfirmPayment(
        receiptId: receiptId,
        isConfirmed: true,
      );

      // Mark session as paid
      final success = await context.read<SessionProvider>().markAsPaid(
        sessionId,
        'UPI',
        'UPI_CONFIRMED_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('UPI payment confirmed successfully'),
              ],
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        _showErrorSnackBar('Failed to confirm payment');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error confirming payment: ${e.toString()}');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }
}
