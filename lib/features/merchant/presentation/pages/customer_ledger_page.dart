import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../providers/customer_ledger_provider.dart';
import '../../domain/entities/customer_ledger_entity.dart';
import '../../domain/entities/payment_entity.dart';

/// Customer Ledger Page - View and manage customer credits
class CustomerLedgerPage extends StatefulWidget {
  final String merchantId;

  const CustomerLedgerPage({super.key, required this.merchantId});

  @override
  State<CustomerLedgerPage> createState() => _CustomerLedgerPageState();
}

class _CustomerLedgerPageState extends State<CustomerLedgerPage> {
  String _filterStatus = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerLedgerProvider>().loadLedger(widget.merchantId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: _buildAppBar(),
      body: Consumer<CustomerLedgerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return _buildError(provider.error!);
          }

          final summaries = provider.summaries.values.toList();

          if (summaries.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildFilterBar(),
              Expanded(child: _buildSummaryList(summaries)),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.lightSurface,
      elevation: 0,
      title: Text(
        'Customer Ledger',
        style: AppTypography.h2.copyWith(color: AppColors.lightTextPrimary),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.lightBorder.withAlpha((0.1 * 255).toInt()),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      color: AppColors.lightSurface,
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by customer name or phone...',
              hintStyle: AppTypography.body2.copyWith(
                color: AppColors.lightTextSecondary.withAlpha(
                  (0.5 * 255).toInt(),
                ),
              ),
              suffixIcon: Icon(
                Icons.search,
                color: AppColors.lightTextSecondary.withAlpha(
                  (0.5 * 255).toInt(),
                ),
              ),
              filled: true,
              fillColor: AppColors.lightBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingLG,
                vertical: AppDimensions.paddingMD,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          // Filter chips
          Row(
            children: [
              _buildFilterChip('All'),
              const SizedBox(width: AppDimensions.spacingSM),
              _buildFilterChip('Pending'),
              const SizedBox(width: AppDimensions.spacingSM),
              _buildFilterChip('Overdue'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filterStatus == label;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = label;
        });
      },
      backgroundColor: AppColors.lightBackground,
      selectedColor: AppColors.primaryBlue.withAlpha((0.2 * 255).toInt()),
      labelStyle: AppTypography.body2.copyWith(
        color: isSelected
            ? AppColors.primaryBlue
            : AppColors.lightTextSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        side: BorderSide(
          color: isSelected
              ? AppColors.primaryBlue
              : AppColors.lightBorder.withAlpha((0.3 * 255).toInt()),
        ),
      ),
    );
  }

  Widget _buildSummaryList(List<CustomerLedgerSummary> summaries) {
    // Apply filters
    var filtered = summaries.where((summary) {
      // Search filter
      final searchQuery = _searchController.text.toLowerCase();
      if (searchQuery.isNotEmpty) {
        final nameMatch = summary.customerName.toLowerCase().contains(
          searchQuery,
        );
        final phoneMatch =
            summary.customerPhone?.toLowerCase().contains(searchQuery) ?? false;
        if (!nameMatch && !phoneMatch) return false;
      }

      // Status filter
      if (_filterStatus == 'Pending') {
        return summary.hasPending;
      } else if (_filterStatus == 'Overdue') {
        return summary.hasOverdue;
      }

      return true;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildSummaryCard(filtered[index]);
      },
    );
  }

  Widget _buildSummaryCard(CustomerLedgerSummary summary) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingLG),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () => _showCustomerDetails(summary),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    backgroundColor: AppColors.primaryBlue.withAlpha(
                      (0.2 * 255).toInt(),
                    ),
                    child: Text(
                      summary.customerName[0].toUpperCase(),
                      style: AppTypography.h3.copyWith(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingMD),
                  // Name and phone
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.customerName,
                          style: AppTypography.body1.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (summary.customerPhone != null)
                          Text(
                            summary.customerPhone!,
                            style: AppTypography.body2.copyWith(
                              color: AppColors.lightTextSecondary.withAlpha(
                                (0.6 * 255).toInt(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Overdue badge
                  if (summary.hasOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingMD,
                        vertical: AppDimensions.paddingSM,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha((0.2 * 255).toInt()),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMD,
                        ),
                      ),
                      child: Text(
                        'OVERDUE',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingLG),
              // Total credit
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingMD),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha((0.1 * 255).toInt()),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Credit',
                      style: AppTypography.body2.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '₹${summary.totalCredit.toStringAsFixed(2)}',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMD),
              // Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Pending Bills',
                      summary.pendingBillsCount.toString(),
                      Icons.receipt_long,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingMD),
                  Expanded(
                    child: _buildStatItem(
                      'Overdue Bills',
                      summary.overdueBillsCount.toString(),
                      Icons.warning_rounded,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.lightTextSecondary.withAlpha((0.6 * 255).toInt()),
          ),
          const SizedBox(width: AppDimensions.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.lightTextSecondary.withAlpha(
                      (0.6 * 255).toInt(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: AppColors.lightTextSecondary.withAlpha((0.3 * 255).toInt()),
          ),
          const SizedBox(height: AppDimensions.spacingLG),
          Text(
            'No Credit Records',
            style: AppTypography.h3.copyWith(
              color: AppColors.lightTextSecondary.withAlpha(
                (0.6 * 255).toInt(),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            'Partial payments will appear here',
            style: AppTypography.body2.copyWith(
              color: AppColors.lightTextSecondary.withAlpha(
                (0.5 * 255).toInt(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppColors.error.withAlpha((0.6 * 255).toInt()),
          ),
          const SizedBox(height: AppDimensions.spacingLG),
          Text(
            'Error Loading Ledger',
            style: AppTypography.h3.copyWith(color: AppColors.error),
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            error,
            style: AppTypography.body2.copyWith(
              color: AppColors.lightTextSecondary.withAlpha(
                (0.6 * 255).toInt(),
              ),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingXL),
          ElevatedButton(
            onPressed: () {
              context.read<CustomerLedgerProvider>().loadLedger(
                widget.merchantId,
              );
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetails(CustomerLedgerSummary summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CustomerDetailsSheet(
        summary: summary,
        merchantId: widget.merchantId,
      ),
    );
  }
}

/// Customer Details Bottom Sheet
class _CustomerDetailsSheet extends StatelessWidget {
  final CustomerLedgerSummary summary;
  final String merchantId;

  const _CustomerDetailsSheet({
    required this.summary,
    required this.merchantId,
  });

  @override
  Widget build(BuildContext context) {
    final entries = summary.entries;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusXL),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(
                  vertical: AppDimensions.paddingMD,
                ),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightTextSecondary.withAlpha(
                    (0.3 * 255).toInt(),
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingLG),
                child: Column(
                  children: [
                    Text(summary.customerName, style: AppTypography.h2),
                    if (summary.customerPhone != null)
                      Text(
                        summary.customerPhone!,
                        style: AppTypography.body2.copyWith(
                          color: AppColors.lightTextSecondary.withAlpha(
                            (0.6 * 255).toInt(),
                          ),
                        ),
                      ),
                    const SizedBox(height: AppDimensions.spacingLG),
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingLG),
                      decoration: BoxDecoration(
                        color: AppColors.error.withAlpha((0.1 * 255).toInt()),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusLG,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text('Total Outstanding', style: AppTypography.body2),
                          const SizedBox(height: AppDimensions.spacingSM),
                          Text(
                            '₹${summary.totalCredit.toStringAsFixed(2)}',
                            style: AppTypography.h1.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Entries list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(AppDimensions.paddingLG),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    return _buildEntryCard(context, entries[index]);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEntryCard(BuildContext context, CustomerLedgerEntry entry) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        side: BorderSide(
          color: entry.isOverdue
              ? AppColors.error
              : AppColors.lightBorder.withAlpha((0.3 * 255).toInt()),
          width: entry.isOverdue ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bill #${entry.sessionId.substring(0, 8)}',
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (entry.isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.paddingMD,
                      vertical: AppDimensions.paddingSM,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha((0.2 * 255).toInt()),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMD,
                      ),
                    ),
                    child: Text(
                      '${entry.daysOverdue} days overdue',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Bill Amount',
                    '₹${entry.billAmount.toStringAsFixed(2)}',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Paid',
                    '₹${entry.paidAmount.toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Pending',
                    '₹${entry.pendingAmount.toStringAsFixed(2)}',
                    isHighlight: true,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Due Date',
                    entry.dueDate != null
                        ? dateFormat.format(entry.dueDate!)
                        : 'Not set',
                  ),
                ),
              ],
            ),
            if (entry.partialPayments.isNotEmpty) ...[
              const SizedBox(height: AppDimensions.spacingMD),
              const Divider(),
              const SizedBox(height: AppDimensions.spacingMD),
              Text(
                'Payment History',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              ...entry.partialPayments.map((payment) {
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.spacingSM,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${payment.method.displayName} ${payment.transactionId != null ? '(${payment.transactionId})' : ''}',
                        style: AppTypography.caption,
                      ),
                      Text(
                        '₹${payment.amount.toStringAsFixed(2)}',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: AppDimensions.spacingMD),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showRecordPaymentDialog(context, entry),
                icon: const Icon(Icons.payment),
                label: const Text('Record Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.lightTextSecondary.withAlpha((0.6 * 255).toInt()),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.body2.copyWith(
            fontWeight: FontWeight.w600,
            color: isHighlight ? AppColors.error : null,
          ),
        ),
      ],
    );
  }

  void _showRecordPaymentDialog(
    BuildContext context,
    CustomerLedgerEntry entry,
  ) {
    final amountController = TextEditingController();
    final txnController = TextEditingController();
    PaymentMethodType selectedMethod = PaymentMethodType.cash;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Record Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pending Amount: ₹${entry.pendingAmount.toStringAsFixed(2)}',
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLG),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Payment Amount',
                    prefixText: '₹',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                DropdownButtonFormField<PaymentMethodType>(
                  initialValue: selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(),
                  ),
                  items: PaymentMethodType.values.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method.displayName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedMethod = value;
                      });
                    }
                  },
                ),
                if (selectedMethod != PaymentMethodType.cash) ...[
                  const SizedBox(height: AppDimensions.spacingMD),
                  TextField(
                    controller: txnController,
                    decoration: const InputDecoration(
                      labelText: 'Transaction ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount'),
                    ),
                  );
                  return;
                }

                if (amount > entry.pendingAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Amount exceeds pending balance'),
                    ),
                  );
                  return;
                }

                final payment = PaymentEntry(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  method: selectedMethod,
                  amount: amount,
                  transactionId: txnController.text.isNotEmpty
                      ? txnController.text
                      : null,
                  timestamp: DateTime.now(),
                );

                Navigator.of(dialogContext).pop();

                final provider = context.read<CustomerLedgerProvider>();
                final success = await provider.addPayment(entry.id, payment);

                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment recorded successfully'),
                    ),
                  );
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop(); // Close details sheet
                }
              },
              child: const Text('Record'),
            ),
          ],
        ),
      ),
    );
  }
}
