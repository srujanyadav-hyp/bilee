import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/item_entity.dart';
import '../providers/item_provider.dart';

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context),
        label: const Text('Add Item'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primaryBlue,
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
    final hsnController = TextEditingController();
    final taxController = TextEditingController(text: '18');

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
                decoration: const InputDecoration(labelText: 'Item Name *'),
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price (₹) *'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              TextField(
                controller: hsnController,
                decoration: const InputDecoration(
                  labelText: 'HSN Code (Optional)',
                  hintText: 'Leave empty if not required',
                  helperText: 'Optional - Only needed for GST filing',
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              TextField(
                controller: taxController,
                decoration: const InputDecoration(labelText: 'Tax Rate (%) *'),
                keyboardType: TextInputType.number,
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
              final item = ItemEntity(
                id: '',
                merchantId: widget.merchantId,
                name: nameController.text,
                hsnCode: hsnController.text.isEmpty ? null : hsnController.text,
                price: double.tryParse(priceController.text) ?? 0,
                taxRate: double.tryParse(taxController.text) ?? 18,
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
    final hsnController = TextEditingController(text: item.hsnCode ?? '');
    final taxController = TextEditingController(text: item.taxRate.toString());

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
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price (₹) *'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              TextField(
                controller: hsnController,
                decoration: const InputDecoration(
                  labelText: 'HSN Code (Optional)',
                  hintText: 'Leave empty if not required',
                  helperText: 'Optional - Only needed for GST filing',
                ),
              ),
              const SizedBox(height: AppDimensions.spacingSM),
              TextField(
                controller: taxController,
                decoration: const InputDecoration(labelText: 'Tax Rate (%) *'),
                keyboardType: TextInputType.number,
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
              final updatedItem = item.copyWith(
                name: nameController.text,
                hsnCode: hsnController.text.isEmpty ? null : hsnController.text,
                price: double.tryParse(priceController.text) ?? item.price,
                taxRate: double.tryParse(taxController.text) ?? item.taxRate,
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
}
