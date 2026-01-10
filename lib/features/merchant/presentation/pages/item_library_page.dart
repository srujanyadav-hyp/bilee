import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/item_entity.dart';
import '../providers/item_provider.dart';
import 'voice_item_add_page.dart';

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
    final itemCodeController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'e.g., Rice, Dal, Oil',
                ),
                autofocus: true,
              ),
              const SizedBox(height: AppDimensions.spacingMD),
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please enter item name')),
                );
                return;
              }

              if (priceController.text.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please enter price')),
                );
                return;
              }

              final item = ItemEntity(
                id: '',
                merchantId: widget.merchantId,
                name: nameController.text,
                hsnCode: null, // Auto-set to null
                itemCode: itemCodeController.text.isEmpty
                    ? null
                    : itemCodeController.text,
                price: double.tryParse(priceController.text) ?? 0,
                taxRate: 18.0, // Auto-set to 18%
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              final success = await context.read<ItemProvider>().createItem(
                item,
              );
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item added successfully')),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, ItemEntity item) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toString());
    final itemCodeController = TextEditingController(text: item.itemCode ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Item Name *'),
                autofocus: true,
              ),
              const SizedBox(height: AppDimensions.spacingMD),
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please enter item name')),
                );
                return;
              }

              if (priceController.text.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Please enter price')),
                );
                return;
              }

              final updatedItem = item.copyWith(
                name: nameController.text,
                itemCode: itemCodeController.text.isEmpty
                    ? null
                    : itemCodeController.text,
                price: double.tryParse(priceController.text) ?? item.price,
                updatedAt: DateTime.now(),
              );

              final success = await context.read<ItemProvider>().updateItem(
                updatedItem,
              );
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Item updated successfully')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
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
