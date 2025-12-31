import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/receipt_provider.dart';

/// Payment Status Screen - Success/Failure feedback
class PaymentStatusScreen extends StatefulWidget {
  final String sessionId;

  const PaymentStatusScreen({super.key, required this.sessionId});

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();

    // Wait for receipt to be generated, then navigate
    _waitAndNavigateToReceipt();
  }

  Future<void> _waitAndNavigateToReceipt() async {
    if (_isNavigating) return;
    _isNavigating = true;

    // Wait a bit for Cloud Function to generate receipt
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Try to fetch receipt by sessionId (retry up to 5 times)
    final provider = context.read<ReceiptProvider>();
    String? receiptId;

    debugPrint(
      '🔍 PaymentStatus: Searching for receipt with sessionId: ${widget.sessionId}',
    );

    for (int i = 0; i < 5; i++) {
      try {
        debugPrint('🔍 PaymentStatus: Attempt ${i + 1}/5 to find receipt');
        final receipt = await provider.getReceiptBySessionId(widget.sessionId);
        if (receipt != null) {
          receiptId = receipt.receiptId;
          debugPrint('✅ PaymentStatus: Receipt found! ID: $receiptId');
          break;
        } else {
          debugPrint('⚠️ PaymentStatus: No receipt found on attempt ${i + 1}');
        }
      } catch (e) {
        // Receipt not ready yet
        debugPrint('❌ PaymentStatus: Error on attempt ${i + 1}: $e');
      }

      // Wait before retry
      if (i < 4) {
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    if (!mounted) return;

    if (receiptId != null) {
      // Navigate to receipt detail
      debugPrint('📱 PaymentStatus: Navigating to receipt detail: $receiptId');
      context.pushReplacement('/customer/receipt/$receiptId');
    } else {
      // Receipt not found, navigate to receipts list
      debugPrint(
        '📱 PaymentStatus: Receipt not found, navigating to receipts list',
      );
      context.pushReplacement('/customer/receipts');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success Animation
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Success Text
                  const Text(
                    'Payment Successful!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Your receipt is ready',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Loading Indicator
                  const CircularProgressIndicator(),

                  const SizedBox(height: 16),

                  const Text(
                    'Redirecting to receipt...',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.lightTextTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
