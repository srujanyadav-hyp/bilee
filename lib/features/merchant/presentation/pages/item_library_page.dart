import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/item_entity.dart';
import '../providers/item_provider.dart';
import 'voice_item_add_page.dart';
import '../widgets/barcode_scanner_page.dart';

/// Item Library Page - CRUD operations for merchant items
class ItemLibraryPage extends StatefulWidget {
  final String merchantId;

  const ItemLibraryPage({super.key, required this.merchantId});

  @override
  State<ItemLibraryPage> createState() => _ItemLibraryPageState();
}

class _ItemLibraryPageState extends State<ItemLibraryPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadItems(widget.merchantId);
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
      appBar: AppBar(
        title: const Text('Item Library'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildItemList()),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Voice Add Button
          FloatingActionButton(
            heroTag: 'voice_add',
            onPressed: () => _openVoiceAddPage(context),
            backgroundColor: AppColors.success,
            child: const Icon(Icons.mic),
          ),
          const SizedBox(height: AppDimensions.spacingSM),
          // Manual Add Button
          FloatingActionButton.extended(
            heroTag: 'manual_add',
            onPressed: () => _showAddItemDialog(context),
            label: const Text('Add Item'),
            icon: const Icon(Icons.add),
            backgroundColor: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      color: AppColors.lightSurface,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search items by name or HSN...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<ItemProvider>().clearSearch();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
        ),
        onChanged: (value) {
          context.read<ItemProvider>().searchItems(value);
        },
      ),
    );
  }

  Widget _buildItemList() {
    return Consumer<ItemProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: AppDimensions.spacingMD),
                Text(provider.error!),
                const SizedBox(height: AppDimensions.spacingMD),
                ElevatedButton(
                  onPressed: () => provider.loadItems(widget.merchantId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!provider.hasItems) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: AppColors.lightTextTertiary,
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                Text(
                  'No items yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppDimensions.spacingXS),
                Text(
                  'Tap + to add your first item',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          itemCount: provider.items.length,
          itemBuilder: (context, index) {
            final item = provider.items[index];
            return _buildItemCard(context, item);
          },
        );
      },
    );
  }

  Widget _buildItemCard(BuildContext context, ItemEntity item) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingMD),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          child: const Icon(Icons.inventory_2, color: Colors.white),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('₹${item.price.toStringAsFixed(2)}'),
            if (item.itemCode != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.dialpad, size: 12, color: AppColors.primaryBlue),
                    const SizedBox(width: 4),
                    Text(
                      'Code: ${item.itemCode}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            if (item.inventoryEnabled)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.teal.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warehouse_outlined,
                      size: 12,
                      color: Colors.teal,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Stock: ${item.currentStock?.toStringAsFixed(0) ?? '0'} ${item.stockUnit ?? 'units'}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),
            if (item.hsnCode != null) Text('HSN: ${item.hsnCode}'),
            Text('Tax: ${item.taxRate}%'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditItemDialog(context, item),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmation(context, item),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final barcodeController = TextEditingController();
    final itemCodeController = TextEditingController();
    String selectedUnit = 'piece';

    // Inventory tracking values
    bool inventoryEnabled = false;
    double? initialStock;
    double? lowStockThreshold;
    String? stockUnit;

    // Prevent duplicate submissions
    bool isSubmitting = false;

    // Helper to determine if unit is weight-based
    bool _isWeightBasedUnit(String unit) {
      return ['kg', 'gram', 'liter', 'ml'].contains(unit);
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Item'),
          content: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    hintText: 'e.g., Rice, Dal, Oil',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                // Barcode Field with Scanner
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barcode (Optional)',
                          hintText: 'Scan or enter barcode',
                          helperText: 'For fast barcode scanning',
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                        readOnly: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(
                        bottom: 20,
                      ), // Align with text field
                      child: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, size: 28),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue.withOpacity(
                            0.1,
                          ),
                          foregroundColor: AppColors.primaryBlue,
                        ),
                        tooltip: 'Scan Barcode',
                        onPressed: () async {
                          // Open barcode scanner
                          final barcode = await Navigator.push<String>(
                            dialogContext,
                            MaterialPageRoute(
                              builder: (context) => const BarcodeScannerPage(),
                            ),
                          );
                          if (barcode != null && barcode.isNotEmpty) {
                            barcodeController.text = barcode;
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                // Item Code for manual number pad entry
                TextField(
                  controller: itemCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Item Code (Optional)',
                    hintText: 'e.g., 101',
                    helperText: '3-4 digits for fast number pad entry',
                    prefixIcon: Icon(Icons.dialpad),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                // Unit Dropdown
                DropdownButtonFormField<String>(
                  value: selectedUnit,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    helperText: 'Unit of measurement',
                    prefixIcon: Icon(Icons.straighten),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'piece', child: Text('Piece')),
                    DropdownMenuItem(value: 'dozen', child: Text('Dozen')),
                    DropdownMenuItem(value: 'kg', child: Text('Kilogram (kg)')),
                    DropdownMenuItem(value: 'gram', child: Text('Gram')),
                    DropdownMenuItem(value: 'liter', child: Text('Liter')),
                    DropdownMenuItem(
                      value: 'ml',
                      child: Text('Milliliter (ml)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedUnit = value;
                        // Auto-fill stock unit when inventory is enabled
                        if (inventoryEnabled) {
                          stockUnit = value;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (₹) *',
                    hintText: 'Enter selling price',
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppDimensions.spacingSM),
                Text(
                  'Tax: 18% (GST) - Auto-applied',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLG),
                const Divider(),
                const SizedBox(height: AppDimensions.spacingMD),
                // Inventory Tracking Section
                _InventoryTrackingFields(
                  onChanged: (enabled, stock, threshold, unit) {
                    setState(() {
                      inventoryEnabled = enabled;
                      initialStock = stock;
                      lowStockThreshold = threshold;
                      // Auto-fill stock unit from selected unit when enabling
                      if (enabled &&
                          (unit == null || unit.isEmpty || unit == 'units')) {
                        stockUnit = selectedUnit;
                      } else {
                        stockUnit = unit;
                      }
                    });
                  },
                  prefilledUnit:
                      selectedUnit, // Always pass selectedUnit for auto-fill
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      // Prevent duplicate submissions
                      if (isSubmitting) return;

                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter item name'),
                          ),
                        );
                        return;
                      }

                      if (priceController.text.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Please enter price')),
                        );
                        return;
                      }

                      // Mark as submitting to prevent duplicate clicks
                      setState(() {
                        isSubmitting = true;
                      });

                      final price = double.tryParse(priceController.text) ?? 0;
                      final isWeightBased = _isWeightBasedUnit(selectedUnit);

                      final item = ItemEntity(
                        id: '',
                        merchantId: widget.merchantId,
                        name: nameController.text,
                        hsnCode: null, // Auto-set to null
                        barcode: barcodeController.text.isEmpty
                            ? null
                            : barcodeController.text,
                        itemCode: itemCodeController.text.isEmpty
                            ? null
                            : itemCodeController.text,
                        unit: selectedUnit,
                        price: price,
                        taxRate: 18.0, // Auto-set to 18%
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        // Weight-based fields (like voice-added items)
                        isWeightBased: isWeightBased,
                        pricePerUnit: isWeightBased ? price : null,
                        // Inventory tracking fields
                        inventoryEnabled: inventoryEnabled,
                        currentStock: inventoryEnabled
                            ? (initialStock ?? 0.0)
                            : null, // Ensure 0.0 if enabled
                        lowStockThreshold: lowStockThreshold,
                        stockUnit: inventoryEnabled
                            ? (stockUnit ?? selectedUnit)
                            : null,
                        lastStockUpdate: inventoryEnabled
                            ? DateTime.now()
                            : null,
                      );

                      try {
                        final success = await context
                            .read<ItemProvider>()
                            .createItem(item);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Item added successfully'),
                              ),
                            );
                          }
                        }
                      } finally {
                        // Reset submitting state if dialog is still mounted
                        if (dialogContext.mounted) {
                          setState(() {
                            isSubmitting = false;
                          });
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, ItemEntity item) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toString());
    final barcodeController = TextEditingController(text: item.barcode ?? '');
    final itemCodeController = TextEditingController(text: item.itemCode ?? '');
    String selectedUnit = item.unit;

    // Inventory tracking values - initialize from existing item
    bool inventoryEnabled = item.inventoryEnabled;
    double? currentStock = item.currentStock;
    double? lowStockThreshold = item.lowStockThreshold;
    String? stockUnit = item.stockUnit;

    // Prevent duplicate submissions
    bool isSubmitting = false;

    // Helper to determine if unit is weight-based
    bool _isWeightBasedUnit(String unit) {
      return ['kg', 'gram', 'liter', 'ml'].contains(unit);
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Item'),
          content: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name *',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                // Barcode Field with Scanner
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barcode (Optional)',
                          hintText: 'Scan or enter barcode',
                          helperText: 'For fast barcode scanning',
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                        readOnly: false,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      margin: const EdgeInsets.only(
                        bottom: 20,
                      ), // Align with text field
                      child: IconButton(
                        icon: const Icon(Icons.qr_code_scanner, size: 28),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue.withOpacity(
                            0.1,
                          ),
                          foregroundColor: AppColors.primaryBlue,
                        ),
                        tooltip: 'Scan Barcode',
                        onPressed: () async {
                          // Open barcode scanner
                          final barcode = await Navigator.push<String>(
                            dialogContext,
                            MaterialPageRoute(
                              builder: (context) => const BarcodeScannerPage(),
                            ),
                          );
                          if (barcode != null && barcode.isNotEmpty) {
                            barcodeController.text = barcode;
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                // Item Code for manual number pad entry
                TextField(
                  controller: itemCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Item Code (Optional)',
                    hintText: 'e.g., 101',
                    helperText: '3-4 digits for fast number pad entry',
                    prefixIcon: Icon(Icons.dialpad),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                // Unit Dropdown
                DropdownButtonFormField<String>(
                  value: selectedUnit,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    helperText: 'Unit of measurement',
                    prefixIcon: Icon(Icons.straighten),
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'piece', child: Text('Piece')),
                    DropdownMenuItem(value: 'dozen', child: Text('Dozen')),
                    DropdownMenuItem(value: 'kg', child: Text('Kilogram (kg)')),
                    DropdownMenuItem(value: 'gram', child: Text('Gram')),
                    DropdownMenuItem(value: 'liter', child: Text('Liter')),
                    DropdownMenuItem(
                      value: 'ml',
                      child: Text('Milliliter (ml)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedUnit = value;
                        // Auto-fill stock unit when inventory is enabled
                        if (inventoryEnabled) {
                          stockUnit = value;
                        }
                      });
                    }
                  },
                ),
                const SizedBox(height: AppDimensions.spacingMD),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (₹) *',
                    prefixText: '₹ ',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppDimensions.spacingSM),
                Text(
                  'Tax: ${item.taxRate}% (GST)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLG),
                const Divider(),
                const SizedBox(height: AppDimensions.spacingMD),
                // Inventory Tracking Section with existing values
                _InventoryTrackingFields(
                  initialEnabled: item.inventoryEnabled,
                  initialStock: item.currentStock,
                  initialThreshold: item.lowStockThreshold,
                  initialUnit: item.stockUnit,
                  onChanged: (enabled, stock, threshold, unit) {
                    setState(() {
                      inventoryEnabled = enabled;
                      currentStock = stock;
                      lowStockThreshold = threshold;
                      // Auto-fill stock unit from selected unit when enabling
                      if (enabled &&
                          (unit == null || unit.isEmpty || unit == 'units')) {
                        stockUnit = selectedUnit;
                      } else {
                        stockUnit = unit;
                      }
                    });
                  },
                  prefilledUnit:
                      selectedUnit, // Always pass selectedUnit for auto-fill
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      // Prevent duplicate submissions
                      if (isSubmitting) return;

                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter item name'),
                          ),
                        );
                        return;
                      }

                      if (priceController.text.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Please enter price')),
                        );
                        return;
                      }

                      // Mark as submitting to prevent duplicate clicks
                      setState(() {
                        isSubmitting = true;
                      });

                      final price =
                          double.tryParse(priceController.text) ?? item.price;
                      final isWeightBased = _isWeightBasedUnit(selectedUnit);

                      final updatedItem = item.copyWith(
                        name: nameController.text,
                        barcode: barcodeController.text.isEmpty
                            ? null
                            : barcodeController.text,
                        itemCode: itemCodeController.text.isEmpty
                            ? null
                            : itemCodeController.text,
                        unit: selectedUnit,
                        price: price,
                        updatedAt: DateTime.now(),
                        // Weight-based fields (like voice-added items)
                        isWeightBased: isWeightBased,
                        pricePerUnit: isWeightBased ? price : null,
                        // Update inventory tracking fields
                        inventoryEnabled: inventoryEnabled,
                        currentStock: inventoryEnabled
                            ? (currentStock ?? item.currentStock ?? 0.0)
                            : null, // Preserve existing or default to 0
                        lowStockThreshold: lowStockThreshold,
                        stockUnit: inventoryEnabled
                            ? (stockUnit ?? selectedUnit)
                            : null,
                        lastStockUpdate: inventoryEnabled
                            ? DateTime.now()
                            : null,
                      );

                      try {
                        final success = await context
                            .read<ItemProvider>()
                            .updateItem(updatedItem);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Item updated successfully'),
                              ),
                            );
                          }
                        }
                      } finally {
                        // Reset submitting state if dialog is still mounted
                        if (dialogContext.mounted) {
                          setState(() {
                            isSubmitting = false;
                          });
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ItemEntity item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await context.read<ItemProvider>().deleteItem(
                widget.merchantId,
                item.id,
              );
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item deleted successfully')),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _openVoiceAddPage(BuildContext context) async {
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceItemAddPage(merchantId: widget.merchantId),
      ),
    );

    if (result != null && result > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Successfully added $result items using voice!'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
      // Reload items
      context.read<ItemProvider>().loadItems(widget.merchantId);
    }
  }
}

/// Inventory Tracking Fields Widget
/// Reusable widget for inventory tracking configuration
class _InventoryTrackingFields extends StatefulWidget {
  final bool initialEnabled;
  final double? initialStock;
  final double? initialThreshold;
  final String? initialUnit;
  final String? prefilledUnit; // Unit to prefill when toggling on
  final Function(bool enabled, double? stock, double? threshold, String? unit)
  onChanged;

  const _InventoryTrackingFields({
    this.initialEnabled = false,
    this.initialStock,
    this.initialThreshold,
    this.initialUnit,
    this.prefilledUnit,
    required this.onChanged,
  });

  @override
  State<_InventoryTrackingFields> createState() =>
      _InventoryTrackingFieldsState();
}

class _InventoryTrackingFieldsState extends State<_InventoryTrackingFields> {
  late bool _trackInventory;
  late TextEditingController _stockController;
  late TextEditingController _thresholdController;
  late TextEditingController _unitController;

  @override
  void initState() {
    super.initState();
    _trackInventory = widget.initialEnabled;
    _stockController = TextEditingController(
      text: widget.initialStock?.toString() ?? '',
    );
    _thresholdController = TextEditingController(
      text: widget.initialThreshold?.toString() ?? '',
    );
    _unitController = TextEditingController(
      text: widget.initialUnit ?? 'units',
    );
  }

  @override
  void dispose() {
    _stockController.dispose();
    _thresholdController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _notifyChanges() {
    widget.onChanged(
      _trackInventory,
      _trackInventory
          ? (double.tryParse(_stockController.text) ??
                0.0) // Default to 0 if empty
          : null,
      _trackInventory ? double.tryParse(_thresholdController.text) : null,
      _trackInventory && _unitController.text.isNotEmpty
          ? _unitController.text
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Track Inventory Toggle
        Row(
          children: [
            Icon(
              Icons.warehouse_outlined,
              color: AppColors.primaryBlue,
              size: 20,
            ),
            const SizedBox(width: AppDimensions.spacingXS),
            Text(
              'Inventory Tracking',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Switch(
              value: _trackInventory,
              onChanged: (value) {
                setState(() {
                  _trackInventory = value;
                  // Auto-fill unit when toggling ON
                  if (value && widget.prefilledUnit != null) {
                    _unitController.text = widget.prefilledUnit!;
                  }
                });
                _notifyChanges();
              },
            ),
          ],
        ),
        if (_trackInventory) ...[
          const SizedBox(height: AppDimensions.spacingMD),
          Text(
            'Enable automatic stock tracking and low stock alerts',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          // Initial Stock
          TextField(
            controller: _stockController,
            decoration: const InputDecoration(
              labelText: 'Initial Stock *',
              hintText: 'e.g., 100',
              helperText: 'Starting quantity in inventory',
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => _notifyChanges(),
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          // Low Stock Threshold
          TextField(
            controller: _thresholdController,
            decoration: const InputDecoration(
              labelText: 'Low Stock Alert Level *',
              hintText: 'e.g., 20',
              helperText: 'Get notified when stock falls below this',
              prefixIcon: Icon(Icons.warning_amber_rounded),
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => _notifyChanges(),
          ),
          const SizedBox(height: AppDimensions.spacingMD),
          // Stock Unit
          TextField(
            controller: _unitController,
            decoration: const InputDecoration(
              labelText: 'Stock Unit *',
              hintText: 'e.g., kg, pieces, liters',
              helperText: 'Unit of measurement',
              prefixIcon: Icon(Icons.straighten),
            ),
            onChanged: (_) => _notifyChanges(),
          ),
        ],
      ],
    );
  }
}
