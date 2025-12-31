import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/receipt_entity.dart';
import '../providers/receipt_provider.dart';
import '../../../../core/services/custom_upi_launcher.dart';
import '../../../../core/services/receipt_photo_service.dart';

/// Screen for adding manual expense entry
class AddManualExpenseScreen extends StatefulWidget {
  const AddManualExpenseScreen({super.key});

  @override
  State<AddManualExpenseScreen> createState() => _AddManualExpenseScreenState();
}

class _AddManualExpenseScreenState extends State<AddManualExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantNameController =
      TextEditingController(); // NEW: Optional merchant name

  String? _selectedCategory;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _isProcessing = false;
  File? _selectedPhoto;
  final _photoService = ReceiptPhotoService();

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
    _merchantNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Extract merchant name for all payment methods
    final merchantName = _merchantNameController.text.trim().isNotEmpty
        ? _merchantNameController.text.trim()
        : null; // Will default to "Manual Entry" in repository

    if (_paymentMethod == PaymentMethod.upi) {
      await _processUpiPayment();
    } else {
      // Pass merchant name for Cash/Card payments too
      await _saveManualReceipt(merchantName: merchantName);
    }
  }

  Future<void> _processUpiPayment() async {
    setState(() => _isProcessing = true);

    try {
      debugPrint('═══════════════════════════════════════════');
      debugPrint('🆕 MANUAL EXPENSE UPI PAYMENT FLOW STARTED');
      debugPrint('═══════════════════════════════════════════');

      final amount = double.parse(_amountController.text);
      final merchantName = _merchantNameController.text.trim().isNotEmpty
          ? _merchantNameController.text.trim()
          : 'Merchant';
      final transactionId = 'BL${DateTime.now().millisecondsSinceEpoch}';

      debugPrint('📋 Input data:');
      debugPrint('   • Amount: ₹$amount');
      debugPrint('   • Merchant Name: $merchantName');
      debugPrint('   • Category: $_selectedCategory');
      debugPrint('───────────────────────────────────────────');

      // Save receipt BEFORE launching UPI app
      debugPrint('💾 Step 1: Saving receipt...');
      await _saveManualReceipt(
        merchantName: merchantName,
        transactionId: transactionId,
        verified: false,
      );
      debugPrint('✅ Step 1 complete: Receipt saved');
      debugPrint('───────────────────────────────────────────');

      // Reset processing state
      if (mounted) {
        setState(() => _isProcessing = false);
      }

      // Show message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📱 Opening UPI app...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Small delay
      await Future.delayed(const Duration(milliseconds: 300));

      // Show UPI app chooser (bottom sheet with installed apps only)
      debugPrint('🚀 Showing UPI app chooser...');
      final selectedApp = await CustomUpiLauncher.showAppChooser(context);
      if (selectedApp == null) {
        debugPrint('⚠️  No UPI app selected');
        return;
      }

      debugPrint('✅ UPI app selected: ${selectedApp.name}');
      // Open app in openOnly mode - user scans QR manually in their UPI app
      await CustomUpiLauncher.launchUpiApp(
        app: selectedApp,
        upiId: '', // Not needed in openOnly mode
        amount: amount,
        merchantName: merchantName,
        transactionNote: 'Payment via Bilee',
        openOnly: true,
      );
      debugPrint('✅ UPI app opened successfully');
      debugPrint('═══════════════════════════════════════════');
    } catch (e) {
      debugPrint('❌ Error: $e');
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

      // Save photo first if selected
      String? photoPath;
      if (_selectedPhoto != null) {
        final receiptId = 'MR${DateTime.now().millisecondsSinceEpoch}';
        photoPath = await _photoService.savePhoto(_selectedPhoto!, receiptId);
        debugPrint('📸 Photo saved: $photoPath');
      }

      // Create manual receipt
      final provider = context.read<ReceiptProvider>();
      await provider.createManualReceipt(
        category: _selectedCategory!,
        amount: amount,
        paymentMethod: _paymentMethod,
        merchantName: merchantName,
        merchantUpiId: null,
        transactionId: transactionId,
        verified: verified,
        photoPath: photoPath,
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

  // QR scanner removed - users now enter merchant name directly or leave blank

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Add Manual Expense',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
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

            // Merchant Name Input (shown for all payment methods)
            _buildMerchantNameInput(),
            const SizedBox(height: 24),

            // Photo Preview (if photo selected)
            _buildPhotoPreview(),

            // Photo Attachment Button
            _buildPhotoButton(),
            const SizedBox(height: 24),

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

  Widget _buildMerchantNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Merchant Name (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _merchantNameController,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            hintText: 'e.g., Ram Store, Domino\'s, etc.',
            prefixIcon: const Icon(Icons.store, color: AppColors.primaryBlue),
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
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Optional - helps you remember where you spent',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.lightTextSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
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

  Future<void> _pickPhoto() async {
    final photo = await _photoService.pickPhoto(context);
    if (photo != null) {
      setState(() => _selectedPhoto = photo);
    }
  }

  Widget _buildPhotoButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Receipt Photo (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickPhoto,
          icon: Icon(
            _selectedPhoto == null ? Icons.add_a_photo : Icons.edit,
            color: AppColors.primaryBlue,
          ),
          label: Text(
            _selectedPhoto == null ? 'Add Photo' : 'Change Photo',
            style: const TextStyle(color: AppColors.primaryBlue),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            side: const BorderSide(color: AppColors.primaryBlue, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Attach bill photo for record keeping',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.lightTextSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPreview() {
    if (_selectedPhoto == null) return const SizedBox.shrink();

    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.primaryBlue, width: 2),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            child: Image.file(
              _selectedPhoto!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () => setState(() => _selectedPhoto = null),
              icon: const Icon(Icons.close, color: Colors.white),
              style: IconButton.styleFrom(backgroundColor: Colors.red),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '📸 Receipt Photo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
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
