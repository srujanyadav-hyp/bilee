import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/router/app_router.dart'; // For routeObserver
import '../../domain/entities/receipt_entity.dart';
import '../providers/receipt_provider.dart';
import '../widgets/customer_bottom_nav.dart';
import '../widgets/merchant_status_badge.dart';

/// Receipt List Screen - All receipts wallet
class ReceiptListScreen extends StatefulWidget {
  const ReceiptListScreen({super.key});

  @override
  State<ReceiptListScreen> createState() => _ReceiptListScreenState();
}

class _ReceiptListScreenState extends State<ReceiptListScreen> with RouteAware {
  final TextEditingController _searchController = TextEditingController();

  // Filter state
  String? _selectedCategory;
  DateTimeRange? _dateRange;
  double? _minAmount;
  double? _maxAmount;
  PaymentMethod? _selectedPaymentMethod;
  String _sortBy = 'date'; // 'date', 'amount_high', 'amount_low'

  @override
  void initState() {
    super.initState();
    // Defer loading until after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReceipts();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Register this route with RouteObserver
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      // Will be notified when this screen becomes visible/invisible
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    // Called when a screen is popped and THIS screen becomes visible again
    // This is when user navigates BACK to this screen
    debugPrint(
      '🔄 [ReceiptList] Screen became visible again - reloading receipts',
    );
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    debugPrint('=========================================');
    debugPrint('🧾 ReceiptList: Starting to load receipts...');
    debugPrint('=========================================');

    try {
      await context.read<ReceiptProvider>().loadAllReceipts();
      final provider = context.read<ReceiptProvider>();

      debugPrint('📊 ReceiptList: Load complete!');
      debugPrint('   Total receipts: ${provider.receipts.length}');
      debugPrint('   Has error: ${provider.hasError}');

      if (provider.hasError) {
        debugPrint('❌ ReceiptList: Error: ${provider.error}');
      }

      if (provider.receipts.isNotEmpty) {
        debugPrint('✅ ReceiptList: Found receipts:');
        for (var i = 0; i < provider.receipts.length && i < 5; i++) {
          final receipt = provider.receipts[i];
          debugPrint(
            '   [$i] ${receipt.receiptId} - ${receipt.merchantName} - ₹${receipt.total}',
          );
        }
      } else {
        debugPrint('⚠️ ReceiptList: No receipts found in list');
      }

      debugPrint('=========================================');
    } catch (e, stackTrace) {
      debugPrint('❌ ReceiptList: Exception loading receipts: $e');
      debugPrint('   Stack trace: $stackTrace');
      debugPrint('=========================================');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Unregister from RouteObserver
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('My Receipts'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Filter Chips
          _buildFilterChips(),

          // Receipts List
          Expanded(
            child: Consumer<ReceiptProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!provider.hasReceipts) {
                  return _buildEmptyState();
                }

                // Apply filters
                final filteredReceipts = _applyFilters(provider.receipts);

                if (filteredReceipts.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () => provider.refresh(),
                  child: ListView.builder(
                    padding: EdgeInsets.only(
                      left: AppDimensions.paddingMD,
                      right: AppDimensions.paddingMD,
                      top: AppDimensions.paddingMD,
                      bottom: 60 + MediaQuery.of(context).padding.bottom + 16,
                    ),
                    itemCount: filteredReceipts.length,
                    itemBuilder: (context, index) {
                      final receipt = filteredReceipts[index];
                      return _buildReceiptCard(context, receipt);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: CustomerFloatingScanButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomerBottomNav(
        currentRoute: '/customer/receipts',
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          context.read<ReceiptProvider>().searchReceipts(value);
        },
        decoration: InputDecoration(
          hintText: 'Search receipts...',
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            color: AppColors.lightTextTertiary,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppColors.lightTextSecondary,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: AppColors.lightTextSecondary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    context.read<ReceiptProvider>().clearSearch();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Category filter
          FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedCategory != null)
                  Text(ReceiptProvider.getCategoryIcon(_selectedCategory!)),
                if (_selectedCategory != null) const SizedBox(width: 4),
                Text(_selectedCategory ?? 'Category'),
              ],
            ),
            selected: _selectedCategory != null,
            onSelected: (_) => _showCategoryPicker(),
            selectedColor: AppColors.primaryBlue.withOpacity(0.2),
            backgroundColor: AppColors.lightCardBackground,
            checkmarkColor: AppColors.primaryBlue,
            labelStyle: TextStyle(
              color: _selectedCategory != null
                  ? AppColors.primaryBlue
                  : AppColors.lightTextPrimary,
              fontWeight: _selectedCategory != null
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 8),

          // Date filter
          FilterChip(
            label: Text(
              _dateRange != null
                  ? '${DateFormat.MMMd().format(_dateRange!.start)}-${DateFormat.MMMd().format(_dateRange!.end)}'
                  : 'Date',
            ),
            selected: _dateRange != null,
            onSelected: (_) => _showDateRangePicker(),
            selectedColor: AppColors.primaryBlue.withOpacity(0.2),
            backgroundColor: AppColors.lightCardBackground,
            checkmarkColor: AppColors.primaryBlue,
            labelStyle: TextStyle(
              color: _dateRange != null
                  ? AppColors.primaryBlue
                  : AppColors.lightTextPrimary,
              fontWeight: _dateRange != null
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 8),

          // Amount filter
          FilterChip(
            label: Text(_getAmountLabel()),
            selected: _minAmount != null || _maxAmount != null,
            onSelected: (_) => _showAmountPicker(),
            selectedColor: AppColors.primaryBlue.withOpacity(0.2),
            backgroundColor: AppColors.lightCardBackground,
            checkmarkColor: AppColors.primaryBlue,
            labelStyle: TextStyle(
              color: _minAmount != null || _maxAmount != null
                  ? AppColors.primaryBlue
                  : AppColors.lightTextPrimary,
              fontWeight: _minAmount != null || _maxAmount != null
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 8),

          // Payment method
          FilterChip(
            label: Text(
              _selectedPaymentMethod != null
                  ? _selectedPaymentMethod!.name.toUpperCase()
                  : 'Payment',
            ),
            selected: _selectedPaymentMethod != null,
            onSelected: (_) => _showPaymentMethodPicker(),
            selectedColor: AppColors.primaryBlue.withOpacity(0.2),
            backgroundColor: AppColors.lightCardBackground,
            checkmarkColor: AppColors.primaryBlue,
            labelStyle: TextStyle(
              color: _selectedPaymentMethod != null
                  ? AppColors.primaryBlue
                  : AppColors.lightTextPrimary,
              fontWeight: _selectedPaymentMethod != null
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
          const SizedBox(width: 8),

          // Sort
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _sortBy = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'date', child: Text('Latest First')),
              const PopupMenuItem(
                value: 'amount_high',
                child: Text('Highest Amount'),
              ),
              const PopupMenuItem(
                value: 'amount_low',
                child: Text('Lowest Amount'),
              ),
            ],
            child: Chip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _sortBy == 'date'
                        ? 'Latest'
                        : _sortBy == 'amount_high'
                        ? 'High'
                        : 'Low',
                  ),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
              backgroundColor: AppColors.lightCardBackground,
              labelStyle: const TextStyle(
                color: AppColors.lightTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Clear filters
          if (_hasActiveFilters()) ...[
            const SizedBox(width: 8),
            ActionChip(
              label: const Text('Clear'),
              avatar: const Icon(Icons.close, size: 18),
              onPressed: _clearFilters,
              backgroundColor: AppColors.lightCardBackground,
              labelStyle: const TextStyle(
                color: AppColors.lightTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiptCard(BuildContext context, receipt) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/customer/receipt/${receipt.id}'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Merchant Icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.store_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Receipt Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  receipt.merchantName,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              MerchantStatusBadge(
                                status: receipt.merchantStatus,
                                isCompact: true,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(receipt.createdAt),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeFormat.format(receipt.createdAt),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.lightTextTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Amount
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${receipt.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          PaymentMethodHelper.getIcon(receipt.paymentMethod),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Receipt ID & Verified Badge
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          receipt.receiptId,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ),
                    if (receipt.isVerified) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              size: 14,
                              color: AppColors.success,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.lightBorder,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 60,
                color: AppColors.lightTextTertiary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No receipts found',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your receipts will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: AppColors.lightTextTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Filter pickers
  void _showCategoryPicker() {
    final categories = [
      'Grocery',
      'Food',
      'Restaurant',
      'Transport',
      'Healthcare',
      'Pharmacy',
      'Entertainment',
      'Shopping',
      'Electronics',
      'Clothing',
      'Services',
      'Other',
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((category) {
                return ChoiceChip(
                  label: Text(category),
                  selected: _selectedCategory == category,
                  labelStyle: TextStyle(
                    color: _selectedCategory == category
                        ? AppColors.primaryBlue
                        : AppColors.lightTextPrimary,
                    fontWeight: _selectedCategory == category
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  selectedColor: AppColors.primaryBlue.withOpacity(0.1),
                  backgroundColor: AppColors.lightCardBackground,
                  onSelected: (selected) {
                    setState(
                      () => _selectedCategory = selected ? category : null,
                    );
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _showAmountPicker() {
    final minController = TextEditingController(
      text: _minAmount?.toInt().toString() ?? '',
    );
    final maxController = TextEditingController(
      text: _maxAmount?.toInt().toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Amount'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minimum Amount (₹)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: maxController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Maximum Amount (₹)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _minAmount = minController.text.isNotEmpty
                    ? double.tryParse(minController.text)
                    : null;
                _maxAmount = maxController.text.isNotEmpty
                    ? double.tryParse(maxController.text)
                    : null;
              });
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...PaymentMethod.values.map(
              (method) => ListTile(
                title: Text(method.name.toUpperCase()),
                selected: _selectedPaymentMethod == method,
                onTap: () {
                  setState(() => _selectedPaymentMethod = method);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Filter logic
  List<ReceiptEntity> _applyFilters(List<ReceiptEntity> receipts) {
    var filtered = receipts;

    // Category filter
    if (_selectedCategory != null) {
      filtered = filtered
          .where(
            (r) =>
                r.businessCategory?.toLowerCase() ==
                _selectedCategory!.toLowerCase(),
          )
          .toList();
    }

    // Date range filter
    if (_dateRange != null) {
      filtered = filtered
          .where(
            (r) =>
                r.createdAt.isAfter(_dateRange!.start) &&
                r.createdAt.isBefore(
                  _dateRange!.end.add(const Duration(days: 1)),
                ),
          )
          .toList();
    }

    // Amount filter
    if (_minAmount != null) {
      filtered = filtered.where((r) => r.total >= _minAmount!).toList();
    }
    if (_maxAmount != null) {
      filtered = filtered.where((r) => r.total <= _maxAmount!).toList();
    }

    // Payment method filter
    if (_selectedPaymentMethod != null) {
      filtered = filtered
          .where((r) => r.paymentMethod == _selectedPaymentMethod)
          .toList();
    }

    // Sort
    if (_sortBy == 'date') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'amount_high') {
      filtered.sort((a, b) => b.total.compareTo(a.total));
    } else if (_sortBy == 'amount_low') {
      filtered.sort((a, b) => a.total.compareTo(b.total));
    }

    return filtered;
  }

  bool _hasActiveFilters() {
    return _selectedCategory != null ||
        _dateRange != null ||
        _minAmount != null ||
        _maxAmount != null ||
        _selectedPaymentMethod != null;
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _dateRange = null;
      _minAmount = null;
      _maxAmount = null;
      _selectedPaymentMethod = null;
      _sortBy = 'date';
    });
  }

  String _getAmountLabel() {
    if (_minAmount != null && _maxAmount != null) {
      return '₹${_minAmount!.toInt()}-₹${_maxAmount!.toInt()}';
    } else if (_minAmount != null) {
      return '> ₹${_minAmount!.toInt()}';
    } else if (_maxAmount != null) {
      return '< ₹${_maxAmount!.toInt()}';
    }
    return 'Amount';
  }
}
