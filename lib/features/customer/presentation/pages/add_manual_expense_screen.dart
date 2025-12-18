import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/receipt_entity.dart';
import '../providers/receipt_provider.dart';
import '../../data/services/upi_payment_service.dart';

/// Screen for adding manual expense entry
class AddManualExpenseScreen extends StatefulWidget {
  const AddManualExpenseScreen({super.key});

  @override
  State<AddManualExpenseScreen> createState() => _AddManualExpenseScreenState();
}

class _AddManualExpenseScreenState extends State<AddManualExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _upiIdController = TextEditingController();

  String? _selectedCategory;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isProcessing = false;
  String? _scannedMerchantName; // Store merchant name from QR code
  String? _scannedMerchantCode; // Store merchant category code from QR
  String? _scannedMode; // Store transaction mode from QR
  String? _originalQrData; // Store complete original QR URI

  final List<String> _categories = [
    'Grocery',
    'Restaurant',
    'Pharmacy',
    'Electronics',
    'Clothing',
    'Transport',
    'Entertainment',
    'Services',
    'Other',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_paymentMethod == PaymentMethod.upi) {
      await _processUpiPayment();
    } else {
      await _saveManualReceipt();
    }
  }

  Future<void> _processUpiPayment() async {
    setState(() => _isProcessing = true);

    try {
      debugPrint('═══════════════════════════════════════════');
      debugPrint('🆕 MANUAL EXPENSE UPI PAYMENT FLOW STARTED');
      debugPrint('═══════════════════════════════════════════');

      final amount = double.parse(_amountController.text);
      final upiId = _upiIdController.text.trim();

      debugPrint('📋 Input data:');
      debugPrint('   • Amount: ₹$amount');
      debugPrint('   • UPI ID: $upiId');
      debugPrint('   • Category: $_selectedCategory');
      debugPrint('   • Widget mounted: $mounted');
      debugPrint('───────────────────────────────────────────');

      // Save receipt BEFORE launching UPI app
      debugPrint('💾 Step 1: Saving receipt before UPI launch...');
      final transactionId = 'BL${DateTime.now().millisecondsSinceEpoch}';
      final merchantName = _scannedMerchantName ?? 'Merchant';
      debugPrint('   • Transaction ID: $transactionId');
      debugPrint('   • Merchant Name: $merchantName');
      await _saveManualReceipt(
        merchantName: merchantName,
        transactionId: transactionId,
        verified: false,
      );
      debugPrint('✅ Step 1 complete: Receipt saved');
      debugPrint('───────────────────────────────────────────');

      // Reset processing state BEFORE launching UPI app
      debugPrint('🔄 Step 2: Resetting UI state...');
      if (mounted) {
        setState(() => _isProcessing = false);
        debugPrint('✅ Step 2 complete: Processing flag reset');
      } else {
        debugPrint('⚠️  Widget not mounted - skipping state reset');
      }
      debugPrint('───────────────────────────────────────────');

      // Show message before opening UPI app
      debugPrint('📱 Step 3: Showing user notification...');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📱 Opening UPI app...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
        debugPrint('✅ Step 3 complete: Snackbar displayed');
      } else {
        debugPrint('⚠️  Widget not mounted - skipping notification');
      }
      debugPrint('───────────────────────────────────────────');

      // Small delay for UI updates
      debugPrint('⏳ Step 4: Waiting 300ms for UI updates...');
      await Future.delayed(const Duration(milliseconds: 300));
      debugPrint('✅ Step 4 complete: Delay finished');
      debugPrint('───────────────────────────────────────────');

      // Now launch UPI app
      debugPrint('🚀 Step 5: Launching UPI app...');
      debugPrint('   • Merchant: ${_scannedMerchantName ?? "Not from QR"}');
      debugPrint('   • Has QR Data: ${_originalQrData != null}');
      debugPrint('   • Widget mounted before launch: $mounted');

      if (mounted) {
        final upiService = UpiPaymentService();

        // 🔧 FIX: Don't pass static merchant QR to payment
        // Static QRs (no amount) cause DISMISS error when amount is added
        // Instead, build complete URI with amount manually
        final bool qrHasAmount = _originalQrData?.contains('&am=') ?? false;

        debugPrint('🔍 QR Analysis:');
        debugPrint('   • Has QR Data: ${_originalQrData != null}');
        debugPrint('   • QR Contains Amount: $qrHasAmount');
        debugPrint(
          '   • Strategy: ${qrHasAmount ? "Use original QR" : "Build URI with amount"}',
        );

        // Commented out payment initiation, now just open UPI app home
        final result = await upiService.openUpiAppHome();

        debugPrint('✅ Step 5 complete: UPI response received');
        debugPrint('   • Success: ${result['success']}');
        debugPrint('   • Status: ${result['status']}');

        // Handle response
        if (result['success'] == true) {
          debugPrint('✅ Payment successful!');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Payment Successful!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
            // Close screen after successful payment
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) {
              context.pop();
            }
          }
        } else if (result['cancelled'] == true) {
          debugPrint('⚠️  Payment cancelled by user');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment cancelled'),
                backgroundColor: Colors.orange,
              ),
            );
            setState(() => _isProcessing = false);
          }
        } else {
          debugPrint('❌ Payment failed: ${result['error']}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment failed: ${result['error']}'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isProcessing = false);
          }
        }
      } else {
        debugPrint('❌ Widget not mounted - cancelling UPI launch');
      }
      debugPrint('───────────────────────────────────────────');
      debugPrint('═══════════════════════════════════════════');
      debugPrint('✅ MANUAL EXPENSE UPI PAYMENT FLOW COMPLETE');
      debugPrint('═══════════════════════════════════════════');
    } catch (e) {
      debugPrint('═══════════════════════════════════════════');
      debugPrint('❌ MANUAL EXPENSE UPI PAYMENT ERROR');
      debugPrint('═══════════════════════════════════════════');
      debugPrint('Error: $e');
      debugPrint('Error Type: ${e.runtimeType}');
      debugPrint('Widget mounted: $mounted');
      debugPrint('═══════════════════════════════════════════');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _saveManualReceipt({
    String? merchantName,
    String? transactionId,
    bool verified = false,
  }) async {
    setState(() => _isProcessing = true);

    try {
      final amount = double.parse(_amountController.text);

      // Create manual receipt (will be handled by repository)
      final provider = context.read<ReceiptProvider>();
      await provider.createManualReceipt(
        category: _selectedCategory!,
        amount: amount,
        paymentMethod: _paymentMethod,
        merchantName: merchantName,
        merchantUpiId: _upiIdController.text.trim().isNotEmpty
            ? _upiIdController.text.trim()
            : null,
        transactionId: transactionId,
        verified: verified,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Expense added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _scanUpiQr() async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => const _UpiQrScannerDialog(),
    );

    if (result != null &&
        result['upiId'] != null &&
        result['upiId']!.isNotEmpty) {
      final upiId = result['upiId']!;
      final merchantName = result['merchantName'];
      final merchantCode = result['merchantCode'];
      final mode = result['mode'];
      final qrData = result['qrData']; // ADDED: Get original QR

      debugPrint(
        '🔍 Before setting: UPI ID field value = ${_upiIdController.text}',
      );

      // Store merchant info from QR
      _scannedMerchantName = merchantName;
      _scannedMerchantCode = merchantCode;
      _scannedMode = mode;
      _originalQrData = qrData; // ADDED: Store original QR
      debugPrint('📝 Stored merchant name: $_scannedMerchantName');
      debugPrint('📝 Stored merchant code: $_scannedMerchantCode');
      debugPrint('📝 Stored mode: $_scannedMode');
      debugPrint('📝 Stored original QR data: $_originalQrData');

      // Parse and display UPI ID details
      final parts = upiId.split('@');
      if (parts.length == 2) {
        final phone = parts[0];
        final handle = parts[1];

        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('📋 SCANNED UPI ID DETAILS:');
        debugPrint('   • Full UPI ID: $result');
        debugPrint('   • Phone/ID: $phone');
        debugPrint('   • Bank Handle: @$handle');

        // Identify bank
        String bankName = 'Unknown Bank';
        if (handle == 'ybl') {
          bankName = 'Yes Bank (PhonePe)';
        } else if (handle == 'ibl')
          bankName = 'IDBI Bank';
        else if (handle == 'paytm')
          bankName = 'Paytm Payments Bank';
        else if (handle == 'okicici' ||
            handle == 'okhdfcbank' ||
            handle == 'okaxis') {
          bankName = 'Google Pay ($handle)';
        }

        debugPrint('   • Identified as: $bankName');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        // Show confirmation dialog with option to edit
        if (mounted) {
          final correctedUpiId = await showDialog<String>(
            context: context,
            barrierDismissible: false,
            builder: (context) => _UpiIdConfirmationDialog(
              scannedUpiId: upiId,
              phone: phone,
              handle: handle,
              bankName: bankName,
            ),
          );

          if (correctedUpiId != null && correctedUpiId.isNotEmpty) {
            setState(() {
              _upiIdController.text = correctedUpiId;
            });
            debugPrint('✅ Final UPI ID set: $correctedUpiId');
          }
        }
      }

      debugPrint(
        '✅ After setting: UPI ID field value = ${_upiIdController.text}',
      );
      debugPrint('✅ QR Scanned: Result received = $upiId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Add Expense',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingLG),
          children: [
            // Category Selector
            _buildCategorySelector(),
            const SizedBox(height: 24),

            // Amount Input
            _buildAmountInput(),
            const SizedBox(height: 24),

            // Payment Method Selector
            _buildPaymentMethodSelector(),
            const SizedBox(height: 24),

            // UPI ID Input (shown only for UPI payment)
            if (_paymentMethod == PaymentMethod.upi) ...[
              _buildUpiIdInput(),
              const SizedBox(height: 32),
            ],

            // Submit Button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          decoration: InputDecoration(
            hintText: 'Select category',
            prefixIcon: const Icon(
              Icons.category_outlined,
              color: AppColors.primaryBlue,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 2,
              ),
            ),
          ),
          items: _categories.map((category) {
            return DropdownMenuItem(value: category, child: Text(category));
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedCategory = value);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a category';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amount',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: 'Enter amount',
            prefixIcon: const Icon(
              Icons.currency_rupee,
              color: AppColors.primaryBlue,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter amount';
            }
            final amount = double.tryParse(value);
            if (amount == null || amount <= 0) {
              return 'Please enter valid amount';
            }
            if (amount > 99999) {
              return 'Amount too large';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PaymentMethodChip(
                label: 'Cash',
                icon: Icons.money,
                isSelected: _paymentMethod == PaymentMethod.cash,
                onTap: () =>
                    setState(() => _paymentMethod = PaymentMethod.cash),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PaymentMethodChip(
                label: 'Card',
                icon: Icons.credit_card,
                isSelected: _paymentMethod == PaymentMethod.card,
                onTap: () =>
                    setState(() => _paymentMethod = PaymentMethod.card),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PaymentMethodChip(
                label: 'UPI',
                icon: Icons.phone_android,
                isSelected: _paymentMethod == PaymentMethod.upi,
                onTap: () => setState(() => _paymentMethod = PaymentMethod.upi),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpiIdInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Merchant UPI ID',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _upiIdController,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            hintText: '9876543210@paytm',
            prefixIcon: const Icon(
              Icons.account_balance_wallet,
              color: AppColors.primaryBlue,
            ),
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.qr_code_scanner,
                color: AppColors.primaryBlue,
              ),
              onPressed: _scanUpiQr,
              tooltip: 'Scan UPI QR',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (_paymentMethod == PaymentMethod.upi) {
              if (value == null || value.isEmpty) {
                return 'Please enter merchant UPI ID';
              }
              if (!value.contains('@')) {
                return 'Invalid UPI ID format';
              }
            }
            return null;
          },
        ),
        // Show detected bank info if UPI ID is present
        if (_upiIdController.text.isNotEmpty &&
            _upiIdController.text.contains('@'))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildUpiIdInfo(_upiIdController.text),
          ),
      ],
    );
  }

  Widget _buildUpiIdInfo(String upiId) {
    final parts = upiId.split('@');
    if (parts.length != 2) return const SizedBox.shrink();

    final handle = parts[1].toLowerCase();
    String bankInfo = '';
    Color color = Colors.grey;
    IconData icon = Icons.info_outline;

    if (handle == 'ybl') {
      bankInfo = 'Yes Bank (PhonePe)';
      color = Colors.purple;
      icon = Icons.phone_android;
    } else if (handle == 'ibl') {
      bankInfo = 'IDBI Bank';
      color = Colors.orange;
      icon = Icons.account_balance;
    } else if (handle == 'paytm') {
      bankInfo = 'Paytm Payments Bank';
      color = Colors.blue;
      icon = Icons.account_balance_wallet;
    } else if (handle.startsWith('ok')) {
      bankInfo = 'Google Pay';
      color = Colors.green;
      icon = Icons.phone_android;
    } else {
      bankInfo = 'Bank: @$handle';
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            bankInfo,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final buttonText = _paymentMethod == PaymentMethod.upi
        ? 'Pay via UPI'
        : 'Save Expense';

    final buttonIcon = _paymentMethod == PaymentMethod.upi
        ? Icons.payment
        : Icons.save;

    return SizedBox(
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _handleSubmit,
        icon: _isProcessing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(buttonIcon, color: Colors.white),
        label: Text(
          _isProcessing ? 'Processing...' : buttonText,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}

// Payment Method Chip Widget
class _PaymentMethodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.lightTextSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.lightTextSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// UPI QR Scanner Dialog
class _UpiQrScannerDialog extends StatefulWidget {
  const _UpiQrScannerDialog();

  @override
  State<_UpiQrScannerDialog> createState() => _UpiQrScannerDialogState();
}

class _UpiQrScannerDialogState extends State<_UpiQrScannerDialog> {
  MobileScannerController? controller;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Map<String, String?>? _parseUpiQr(String qrData) {
    // Parse UPI QR format: upi://pay?pa=9876543210@paytm&pn=Merchant%20Name&...
    debugPrint('🔍 QR Scanner: Raw QR data = $qrData');

    if (qrData.startsWith('upi://')) {
      final uri = Uri.parse(qrData);
      final upiId = uri.queryParameters['pa']; // pa = payee address (UPI ID)
      final merchantName = uri.queryParameters['pn']; // pn = payee name
      final merchantCode =
          uri.queryParameters['mc']; // mc = merchant category code
      final mode = uri.queryParameters['mode']; // mode = transaction mode

      debugPrint('🔍 QR Scanner: Parsed UPI ID = $upiId');
      debugPrint('🔍 QR Scanner: Merchant Name = $merchantName');
      debugPrint('🔍 QR Scanner: Merchant Code = $merchantCode');
      debugPrint('🔍 QR Scanner: Mode = $mode');
      debugPrint('🔍 QR Scanner: Full URI params = ${uri.queryParameters}');

      return {
        'upiId': upiId,
        'merchantName': merchantName,
        'merchantCode': merchantCode,
        'mode': mode,
        'qrData': qrData, // ADDED: Return original QR data
      };
    }

    debugPrint('❌ QR Scanner: Not a valid UPI QR (doesn\'t start with upi://)');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scan UPI QR Code',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: MobileScanner(
                controller: controller,
                onDetect: (capture) {
                  final barcodes = capture.barcodes;
                  debugPrint(
                    '📷 QR Scanner: Detected ${barcodes.length} barcode(s)',
                  );

                  for (final barcode in barcodes) {
                    debugPrint('📷 QR Scanner: Barcode type = ${barcode.type}');
                    debugPrint(
                      '📷 QR Scanner: Raw value = ${barcode.rawValue}',
                    );

                    final upiData = _parseUpiQr(barcode.rawValue ?? '');
                    if (upiData != null && upiData['upiId'] != null) {
                      debugPrint(
                        '✅ QR Scanner: Returning UPI data to form: ${upiData['upiId']}',
                      );
                      Navigator.of(context).pop(upiData);
                      return;
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// UPI ID Confirmation Dialog with Edit Option
class _UpiIdConfirmationDialog extends StatefulWidget {
  final String scannedUpiId;
  final String phone;
  final String handle;
  final String bankName;

  const _UpiIdConfirmationDialog({
    required this.scannedUpiId,
    required this.phone,
    required this.handle,
    required this.bankName,
  });

  @override
  State<_UpiIdConfirmationDialog> createState() =>
      __UpiIdConfirmationDialogState();
}

class __UpiIdConfirmationDialogState extends State<_UpiIdConfirmationDialog> {
  late TextEditingController _editController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.scannedUpiId);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _isEditing ? Icons.edit : Icons.qr_code_scanner,
            color: AppColors.primaryBlue,
          ),
          const SizedBox(width: 8),
          Text(_isEditing ? 'Edit UPI ID' : '✅ QR Scanned'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isEditing) ...[
              const Text(
                'Scanned UPI ID:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      widget.scannedUpiId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('📱 Phone: ${widget.phone}'),
                    Text('🏦 Bank: ${widget.bankName}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Is this the correct UPI ID?\nTap "Edit" if wrong.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Text(
                'Edit UPI ID:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _editController,
                decoration: InputDecoration(
                  hintText: '9876543210@ybl',
                  prefixIcon: const Icon(Icons.edit),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 8),
              Text(
                'Common handles: @ybl (PhonePe), @paytm, @okicici (GPay)',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isEditing) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => setState(() => _isEditing = true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('✏️ Edit'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(widget.scannedUpiId),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('✓ Correct'),
          ),
        ] else ...[
          TextButton(
            onPressed: () => setState(() {
              _isEditing = false;
              _editController.text = widget.scannedUpiId;
            }),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final edited = _editController.text.trim();
              if (edited.isNotEmpty && edited.contains('@')) {
                Navigator.of(context).pop(edited);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('✓ Save'),
          ),
        ],
      ],
    );
  }
}
