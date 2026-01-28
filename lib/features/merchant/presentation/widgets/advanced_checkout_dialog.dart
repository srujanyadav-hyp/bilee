import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/merchant_entity.dart';
import '../providers/session_provider.dart';
import '../../../../core/services/enhanced_upi_payment_service.dart';
import '../../../../core/services/upi_payment_service.dart';

/// Advanced Checkout Dialog with Split Payment, Discounts, and Partial Payment support
class AdvancedCheckoutDialog extends StatefulWidget {
  final double billTotal;
  final Function(PaymentDetails) onComplete;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final MerchantEntity? merchant; // For automated UPI
  final String? sessionId; // For automated UPI
  final SessionProvider? sessionProvider; // For automated UPI

  const AdvancedCheckoutDialog({
    super.key,
    required this.billTotal,
    required this.onComplete,
    this.customerId,
    this.customerName,
    this.customerPhone,
    this.merchant,
    this.sessionId,
    this.sessionProvider,
  });

  @override
  State<AdvancedCheckoutDialog> createState() => _AdvancedCheckoutDialogState();
}

class _AdvancedCheckoutDialogState extends State<AdvancedCheckoutDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Discount state
  DiscountEntry? _appliedDiscount;
  double _discountAmount = 0;
  final TextEditingController _customDiscountController =
      TextEditingController();
  DiscountType _customDiscountType = DiscountType.percentage;

  // Payment state
  final List<PaymentEntry> _payments = [];
  final TextEditingController _amountController = TextEditingController();
  PaymentMethodType _selectedMethod = PaymentMethodType.cash;
  final TextEditingController _txnIdController = TextEditingController();

  // Customer state (for credit)
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  int _dueDays = 7;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _customerNameController.text = widget.customerName ?? '';
    _customerPhoneController.text = widget.customerPhone ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _txnIdController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customDiscountController.dispose();
    super.dispose();
  }

  double get _finalAmount => widget.billTotal - _discountAmount;
  double get _totalPaid => _payments.fold(0.0, (sum, p) => sum + p.amount);
  double get _remaining => _finalAmount - _totalPaid;
  bool get _canComplete => (_remaining.abs() < 0.01) || _isPartialPayment;
  bool get _isPartialPayment => _remaining > 0.01;

  @override
  Widget build(BuildContext context) {
    // Get keyboard height to adjust dialog
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    // Reduce max height when keyboard is visible
    final maxHeight = keyboardHeight > 0
        ? screenHeight - keyboardHeight - 40
        : 700.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: keyboardHeight > 0 ? 20 : 20,
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: 600, maxHeight: maxHeight),
        decoration: BoxDecoration(
          color: AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCompactHeader(),
            _buildCompactBillSummary(),
            Expanded(
              child: Column(
                children: [
                  _buildTabs(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDiscountTab(),
                        _buildPaymentTab(),
                        _buildSummaryTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // Compact header - reduced padding and size
  Widget _buildCompactHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: AppDimensions.paddingSM,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusXL),
          topRight: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.shopping_cart_checkout,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Checkout',
            style: AppTypography.h4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // Compact bill summary - reduced padding and size
  Widget _buildCompactBillSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: AppDimensions.paddingSM,
      ),
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Bill Total', style: AppTypography.body2),
              Text(
                '₹${widget.billTotal.toStringAsFixed(2)}',
                style: AppTypography.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Final Amount',
                style: AppTypography.body1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '₹${_finalAmount.toStringAsFixed(2)}',
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          if (_remaining > 0.01) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remaining',
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                Text(
                  '₹${_remaining.toStringAsFixed(2)}',
                  style: AppTypography.h4.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isLarge = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isLarge
              ? AppTypography.h4.copyWith(fontWeight: FontWeight.bold)
              : AppTypography.body1,
        ),
        Text(
          '₹${amount.abs().toStringAsFixed(2)}',
          style: isLarge
              ? AppTypography.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                )
              : AppTypography.h4.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primaryBlue,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.primaryBlue,
        labelStyle: AppTypography.body2.copyWith(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: '💰 Discount', height: 36),
          Tab(text: '💳 Payment', height: 36),
          Tab(text: '✓ Summary', height: 36),
        ],
      ),
    );
  }

  Widget _buildDiscountTab() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      children: [
        Text('Quick Discounts', style: AppTypography.h4),
        const SizedBox(height: AppDimensions.spacingMD),
        ...DiscountPreset.defaultPresets.map(
          (preset) => _buildDiscountPresetTile(preset),
        ),
        const SizedBox(height: AppDimensions.spacingLG),
        _buildCustomDiscountSection(),
      ],
    );
  }

  Widget _buildDiscountPresetTile(DiscountPreset preset) {
    final isSelected = _appliedDiscount?.name == preset.name;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? AppColors.primaryBlue.withOpacity(0.1) : null,
      child: ListTile(
        leading: Icon(
          isSelected ? Icons.check_circle : Icons.local_offer,
          color: isSelected ? AppColors.primaryBlue : Colors.grey,
        ),
        title: Text(
          preset.name,
          style: AppTypography.body1.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(preset.description ?? ''),
        trailing: Text(
          preset.type == DiscountType.percentage
              ? '${preset.value}%'
              : '₹${preset.value}',
          style: AppTypography.h4.copyWith(color: AppColors.primaryBlue),
        ),
        onTap: () => _applyDiscount(preset.toEntry()),
      ),
    );
  }

  Widget _buildCustomDiscountSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custom Discount',
              style: AppTypography.body1.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customDiscountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Amount/Percentage',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      // Apply custom discount
                      final discountValue = double.tryParse(value);
                      if (discountValue != null && discountValue > 0) {
                        final customDiscount = DiscountEntry(
                          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                          type: _customDiscountType,
                          value: discountValue,
                          name: 'Custom Discount',
                          appliedAt: DateTime.now(),
                        );
                        setState(() {
                          _appliedDiscount = customDiscount;
                          _discountAmount = customDiscount.calculateDiscount(
                            widget.billTotal,
                          );
                        });
                      } else {
                        setState(() {
                          _appliedDiscount = null;
                          _discountAmount = 0;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SegmentedButton<DiscountType>(
                  segments: const [
                    ButtonSegment(
                      value: DiscountType.percentage,
                      label: Text('%'),
                    ),
                    ButtonSegment(value: DiscountType.fixed, label: Text('₹')),
                  ],
                  selected: {_customDiscountType},
                  onSelectionChanged: (Set<DiscountType> newSelection) {
                    setState(() {
                      _customDiscountType = newSelection.first;
                      // Recalculate discount if value exists
                      final value = double.tryParse(
                        _customDiscountController.text,
                      );
                      if (value != null &&
                          value > 0 &&
                          _appliedDiscount != null) {
                        final customDiscount = DiscountEntry(
                          id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                          type: _customDiscountType,
                          value: value,
                          name: 'Custom Discount',
                          appliedAt: DateTime.now(),
                        );
                        _appliedDiscount = customDiscount;
                        _discountAmount = customDiscount.calculateDiscount(
                          widget.billTotal,
                        );
                      }
                    });
                  },
                ),
              ],
            ),
            if (_appliedDiscount != null) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('Remove Discount'),
                onPressed: () => setState(() {
                  _appliedDiscount = null;
                  _discountAmount = 0;
                  _customDiscountController.clear();
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTab() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      children: [
        if (_payments.isNotEmpty) ...[
          Text('Payments Added', style: AppTypography.h4),
          const SizedBox(height: 8),
          ..._payments.map((p) => _buildPaymentTile(p)),
          const Divider(height: 24),
        ],
        Text('Add Payment', style: AppTypography.h4),
        const SizedBox(height: AppDimensions.spacingMD),
        _buildPaymentMethodSelector(),
        const SizedBox(height: AppDimensions.spacingMD),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Amount',
            prefixText: '₹ ',
            border: const OutlineInputBorder(),
            suffixIcon: TextButton(
              child: const Text('Full'),
              onPressed: () {
                _amountController.text = _remaining.toStringAsFixed(2);
              },
            ),
          ),
        ),
        if (_selectedMethod != PaymentMethodType.cash) ...[
          const SizedBox(height: AppDimensions.spacingMD),
          TextField(
            controller: _txnIdController,
            decoration: const InputDecoration(
              labelText: 'Transaction ID (optional)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: AppDimensions.spacingMD),
        ElevatedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Payment'),
          onPressed: _addPayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(AppDimensions.paddingMD),
          ),
        ),
        if (_isPartialPayment) ...[
          const SizedBox(height: AppDimensions.spacingLG),
          _buildPartialPaymentSection(),
        ],
      ],
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Row(
      children: [
        // Cash button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                setState(() => _selectedMethod = PaymentMethodType.cash),
            icon: Icon(
              Icons.payments,
              color: _selectedMethod == PaymentMethodType.cash
                  ? Colors.white
                  : AppColors.primaryBlue,
            ),
            label: Text('Cash'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.all(AppDimensions.paddingMD),
              backgroundColor: _selectedMethod == PaymentMethodType.cash
                  ? AppColors.primaryBlue
                  : Colors.transparent,
              foregroundColor: _selectedMethod == PaymentMethodType.cash
                  ? Colors.white
                  : AppColors.primaryBlue,
              side: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
          ),
        ),
        SizedBox(width: AppDimensions.spacingSM),
        // UPI button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () =>
                setState(() => _selectedMethod = PaymentMethodType.upi),
            icon: Icon(
              Icons.qr_code_2,
              color: _selectedMethod == PaymentMethodType.upi
                  ? Colors.white
                  : AppColors.primaryBlue,
            ),
            label: Text('UPI'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.all(AppDimensions.paddingMD),
              backgroundColor: _selectedMethod == PaymentMethodType.upi
                  ? AppColors.primaryBlue
                  : Colors.transparent,
              foregroundColor: _selectedMethod == PaymentMethodType.upi
                  ? Colors.white
                  : AppColors.primaryBlue,
              side: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getPaymentIcon(PaymentMethodType method) {
    switch (method) {
      case PaymentMethodType.cash:
        return Icons.payments;
      case PaymentMethodType.card:
        return Icons.credit_card;
      case PaymentMethodType.upi:
        return Icons.qr_code_2;
      case PaymentMethodType.netbanking:
        return Icons.account_balance;
      case PaymentMethodType.wallet:
        return Icons.account_balance_wallet;
      case PaymentMethodType.credit:
        return Icons.schedule;
    }
  }

  Widget _buildPaymentTile(PaymentEntry payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
          child: Icon(
            _getPaymentIcon(payment.method),
            color: AppColors.primaryBlue,
          ),
        ),
        title: Text(payment.method.displayName),
        subtitle: payment.transactionId != null
            ? Text('TXN: ${payment.transactionId}')
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${payment.amount.toStringAsFixed(2)}',
              style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () => _removePayment(payment),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartialPaymentSection() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Partial Payment - Credit',
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Customer owes ₹${_remaining.toStringAsFixed(2)}',
              style: AppTypography.body1,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name *',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customerPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text('Due in:', style: AppTypography.body2),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [3, 7, 15, 30].map((days) {
                final isSelected = _dueDays == days;
                return ChoiceChip(
                  label: Text('$days days'),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _dueDays = days);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      children: [
        _buildSummarySection('Bill Details', [
          ('Original Amount', widget.billTotal),
          if (_discountAmount > 0) ('Discount', -_discountAmount),
          ('Final Amount', _finalAmount),
        ]),
        const SizedBox(height: 16),
        _buildSummarySection('Payment Details', [
          ..._payments.map(
            (p) => (
              '${p.method.displayName}${p.transactionId != null ? " (${p.transactionId})" : ""}',
              p.amount,
            ),
          ),
          ('Total Paid', _totalPaid),
          if (_remaining > 0.01) ('Pending', _remaining),
        ]),
        if (_isPartialPayment && _customerNameController.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            color: Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMD),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Credit Account',
                    style: AppTypography.body1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Customer: ${_customerNameController.text}'),
                  if (_customerPhoneController.text.isNotEmpty)
                    Text('Phone: ${_customerPhoneController.text}'),
                  Text('Amount: ₹${_remaining.toStringAsFixed(2)}'),
                  Text(
                    'Due: ${DateTime.now().add(Duration(days: _dueDays)).toString().split(' ')[0]}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummarySection(String title, List<(String, double)> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.h4),
            const Divider(),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.$1),
                    Text(
                      '₹${item.$2.abs().toStringAsFixed(2)}',
                      style: AppTypography.body1.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.radiusXL),
          bottomRight: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingMD),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _canComplete ? _completeCheckout : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(AppDimensions.paddingMD),
              ),
              child: Text(
                _isPartialPayment ? 'Complete (Partial)' : 'Complete Payment',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _applyDiscount(DiscountEntry discount) {
    setState(() {
      _appliedDiscount = discount;
      _discountAmount = discount.calculateDiscount(widget.billTotal);
    });
  }

  void _addPayment() async {
    // Special handling for UPI - use automated flow if available
    if (_selectedMethod == PaymentMethodType.upi) {
      await _handleAutomatedUpiPayment();
      return;
    }

    // Regular payment flow for other methods
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Enter valid amount');
      return;
    }

    if (amount > _remaining + 0.01) {
      _showError('Amount exceeds remaining balance');
      return;
    }

    final payment = PaymentEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      method: _selectedMethod,
      amount: amount,
      transactionId: _txnIdController.text.isNotEmpty
          ? _txnIdController.text
          : null,
      timestamp: DateTime.now(),
      verified: _selectedMethod == PaymentMethodType.cash,
    );

    setState(() {
      _payments.add(payment);
      _amountController.clear();
      _txnIdController.clear();
    });

    HapticFeedback.lightImpact();
    _tabController.animateTo(2); // Go to summary
  }

  void _removePayment(PaymentEntry payment) {
    setState(() {
      _payments.remove(payment);
    });
  }

  /// Handle automated UPI payment (if merchant has UPI configured)
  /// Falls back to manual UPI flow if not configured
  Future<void> _handleAutomatedUpiPayment() async {
    final merchant = widget.merchant;
    final sessionProvider = widget.sessionProvider;
    final sessionId = widget.sessionId;

    // Check if automated UPI is available
    if (merchant != null &&
        merchant.isUpiEnabled &&
        merchant.upiId != null &&
        sessionProvider != null &&
        sessionId != null) {
      // AUTOMATED UPI FLOW
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Processing UPI payment...'),
                  ],
                ),
              ),
            ),
          ),
        );

        // Call automated UPI payment
        final result = await sessionProvider.handleUpiPayment(
          merchant: merchant,
          sessionId: sessionId,
          amount: _remaining,
        );

        // Close loading dialog
        if (mounted) Navigator.pop(context);

        // Handle result
        if (result.status == UpiPaymentResultStatus.success) {
          // Payment successful!
          final payment = PaymentEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            method: PaymentMethodType.upi,
            amount: _remaining,
            transactionId: result.txnId,
            timestamp: DateTime.now(),
            verified: true,
          );

          setState(() {
            _payments.add(payment);
          });

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Payment successful! Session auto-closed.'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }

          // Auto-complete checkout
          _completeCheckout();
        } else if (result.status == UpiPaymentResultStatus.pending) {
          // Payment pending
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⏳ ${result.message}'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          // Payment failed or error - fallback to manual
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${result.message}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          // Fallback to manual UPI
          await _handleManualUpiPayment();
        }
      } catch (e) {
        // Close loading if still open
        if (mounted) Navigator.pop(context);

        // Error - fallback to manual
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
        await _handleManualUpiPayment();
      }
    } else {
      // MANUAL UPI FLOW (merchant doesn't have UPI configured)
      await _handleManualUpiPayment();
    }
  }

  /// Handle manual UPI payment (opens UPI app without parameters)
  Future<void> _handleManualUpiPayment() async {
    try {
      final upiService = CoreUpiPaymentService();
      await upiService.openUpiAppHome();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '📱 UPI app opened. Please confirm payment after customer pays.',
            ),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to open UPI app: $e');
      }
    }
  }

  void _completeCheckout() {
    if (_isPartialPayment && _customerNameController.text.trim().isEmpty) {
      _showError('Customer name required for credit');
      return;
    }

    final paymentDetails = PaymentDetails(
      sessionId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      billTotal: widget.billTotal,
      discountAmount: _discountAmount,
      finalAmount: _finalAmount,
      payments: _payments,
      status: _isPartialPayment ? PaymentStatus.partial : PaymentStatus.paid,
      pendingAmount: _isPartialPayment ? _remaining : null,
      customerId: widget.customerId,
      customerName: _isPartialPayment ? _customerNameController.text : null,
      customerPhone: _isPartialPayment ? _customerPhoneController.text : null,
      createdAt: DateTime.now(),
      completedAt: _isPartialPayment ? null : DateTime.now(),
      notes: _appliedDiscount != null
          ? ['Discount: ${_appliedDiscount!.name}']
          : [],
    );

    // Call onComplete which will close the dialog from parent
    widget.onComplete(paymentDetails);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }
}
