import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/entities/inventory_transaction_entity.dart';
import '../providers/inventory_provider.dart';
import '../providers/item_provider.dart';
import '../widgets/stock_indicator_widgets.dart';
import 'package:intl/intl.dart';

/// Inventory Management Page
/// Beautiful, comprehensive inventory dashboard
class InventoryManagementPage extends StatefulWidget {
  final String merchantId;

  const InventoryManagementPage({super.key, required this.merchantId});

  @override
  State<InventoryManagementPage> createState() =>
      _InventoryManagementPageState();
}

class _InventoryManagementPageState extends State<InventoryManagementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Schedule data loading after the first frame to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    final inventoryProvider = context.read<InventoryProvider>();
    final itemProvider = context.read<ItemProvider>();

    // Load both inventory data and items
    await Future.wait([
      inventoryProvider.refreshInventory(widget.merchantId),
      itemProvider.loadItems(widget.merchantId),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Inventory Management'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.warning_amber_rounded), text: 'Alerts'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'All Items'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOverviewTab(), _buildAlertsTab(), _buildAllItemsTab()],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer2<InventoryProvider, ItemProvider>(
      builder: (context, inventoryProvider, itemProvider, child) {
        final lowStockItems = inventoryProvider.lowStockItems;
        final outOfStockItems = inventoryProvider.outOfStockItems;
        final allItems = itemProvider.items;
        final inventoryEnabledItems = allItems
            .where((item) => item.inventoryEnabled)
            .toList();

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingLG),
            children: [
              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Items',
                      value: inventoryEnabledItems.length.toString(),
                      icon: Icons.inventory_2,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingMD),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Low Stock',
                      value: lowStockItems.length.toString(),
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMD),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Out of Stock',
                      value: outOfStockItems.length.toString(),
                      icon: Icons.remove_circle_outline,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacingMD),
                  Expanded(
                    child: _buildStatCard(
                      title: 'In Stock',
                      value:
                          (inventoryEnabledItems.length -
                                  lowStockItems.length -
                                  outOfStockItems.length)
                              .toString(),
                      icon: Icons.check_circle_outline,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacing2XL),

              // Recent Low Stock Items
              if (lowStockItems.isNotEmpty) ...[
                Text(
                  'Low Stock Items',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.lightTextPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                ...lowStockItems.take(5).map((item) => _buildItemCard(item)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertsTab() {
    return Consumer<InventoryProvider>(
      builder: (context, inventoryProvider, child) {
        final lowStockItems = inventoryProvider.lowStockItems;
        final outOfStockItems = inventoryProvider.outOfStockItems;

        if (lowStockItems.isEmpty && outOfStockItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: AppColors.success.withOpacity(0.5),
                ),
                const SizedBox(height: AppDimensions.spacingLG),
                Text(
                  'No Stock Alerts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  'All items are well stocked!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(AppDimensions.paddingLG),
            children: [
              if (outOfStockItems.isNotEmpty) ...[
                _buildAlertSection(
                  title: 'Out of Stock',
                  icon: Icons.remove_circle_outline,
                  color: AppColors.error,
                  items: outOfStockItems,
                ),
                const SizedBox(height: AppDimensions.spacing2XL),
              ],
              if (lowStockItems.isNotEmpty) ...[
                _buildAlertSection(
                  title: 'Low Stock',
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  items: lowStockItems,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAllItemsTab() {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, child) {
        final items = itemProvider.items
            .where((item) => item.inventoryEnabled)
            .toList();

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: AppColors.lightTextSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: AppDimensions.spacingLG),
                Text(
                  'No Items with Inventory Tracking',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  'Enable inventory tracking for items',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await itemProvider.loadItems(widget.merchantId);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(AppDimensions.paddingLG),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildItemCard(items[index]),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<ItemEntity> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: AppDimensions.spacingXS),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.lightTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingXS),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingXS,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              ),
              child: Text(
                items.length.toString(),
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingMD),
        ...items.map((item) => _buildItemCard(item)),
      ],
    );
  }

  Widget _buildItemCard(ItemEntity item) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.lightBorder.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showItemDetails(item),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMD),
            child: Row(
              children: [
                // Item Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryBlue.withOpacity(0.2),
                        AppColors.primaryBlueLight.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingMD),

                // Item Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StockIndicatorBadge(
                        currentStock: item.currentStock,
                        lowStockThreshold: item.lowStockThreshold,
                        stockUnit: item.stockUnit,
                        inventoryEnabled: item.inventoryEnabled,
                        compact: true,
                      ),
                    ],
                  ),
                ),

                // Action Button
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showStockAdjustmentDialog(item),
                  color: AppColors.primaryBlue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showItemDetails(ItemEntity item) async {
    final inventoryProvider = context.read<InventoryProvider>();
    await inventoryProvider.loadTransactionHistory(item.id);

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimensions.radiusXL),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(
                  vertical: AppDimensions.spacingMD,
                ),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLG,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: AppColors.lightTextPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          StockIndicatorBadge(
                            currentStock: item.currentStock,
                            lowStockThreshold: item.lowStockThreshold,
                            stockUnit: item.stockUnit,
                            inventoryEnabled: item.inventoryEnabled,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Stock Progress
              if (item.currentStock != null && item.lowStockThreshold != null)
                Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingLG),
                  child: StockProgressBar(
                    currentStock: item.currentStock!,
                    lowStockThreshold: item.lowStockThreshold!,
                  ),
                ),

              // Transaction History
              Expanded(
                child: Consumer<InventoryProvider>(
                  builder: (context, provider, child) {
                    final transactions = provider.transactionHistory;

                    if (transactions.isEmpty) {
                      return const Center(
                        child: Text('No transaction history'),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(AppDimensions.paddingLG),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) =>
                          _buildTransactionTile(transactions[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionTile(InventoryTransactionEntity transaction) {
    IconData icon;
    Color color;

    switch (transaction.type) {
      case TransactionType.sale:
        icon = Icons.shopping_cart_outlined;
        color = AppColors.error;
        break;
      case TransactionType.purchase:
        icon = Icons.add_shopping_cart_outlined;
        color = AppColors.success;
        break;
      case TransactionType.adjustment:
        icon = Icons.tune_outlined;
        color = AppColors.warning;
        break;
      case TransactionType.returned:
        icon = Icons.keyboard_return_outlined;
        color = AppColors.info;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingXS),
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.lightBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppDimensions.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.type.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                if (transaction.notes != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    transaction.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  DateFormat(
                    'MMM dd, yyyy • hh:mm a',
                  ).format(transaction.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${transaction.quantityChange >= 0 ? '+' : ''}${transaction.quantityChange.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Stock: ${transaction.stockAfter.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showStockAdjustmentDialog(ItemEntity item) {
    final controller = TextEditingController(
      text: item.currentStock?.toStringAsFixed(0) ?? '0',
    );
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Stock: ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'New Stock Level',
                suffixText: item.stockUnit ?? 'units',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingMD),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newStock = double.tryParse(controller.text);
              if (newStock == null) return;

              final inventoryProvider = context.read<InventoryProvider>();
              await inventoryProvider.adjustStock(
                itemId: item.id,
                merchantId: widget.merchantId,
                newStock: newStock,
                currentStock: item.currentStock ?? 0,
                notes: notesController.text.isEmpty
                    ? null
                    : notesController.text,
              );

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Stock adjusted successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
                await _loadData();
              }
            },
            child: const Text('Adjust'),
          ),
        ],
      ),
    );
  }
}
