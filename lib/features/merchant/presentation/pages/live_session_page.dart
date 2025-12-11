import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../providers/session_provider.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().watchSession(widget.sessionId);
    });
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingLG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bill Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        ...session.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${item.name} × ${item.qty}'),
                                Text('₹${item.total.toStringAsFixed(2)}'),
                              ],
                            ),
                          ),
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal:'),
                            Text('₹${session.subtotal.toStringAsFixed(2)}'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tax:'),
                            Text('₹${session.tax.toStringAsFixed(2)}'),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              '₹${session.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLG),
                if (!session.isPaid)
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
}
