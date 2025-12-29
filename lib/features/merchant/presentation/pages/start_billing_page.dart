import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../providers/item_provider.dart';
import '../providers/session_provider.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../data/datasources/user_preferences_data_source.dart';
import '../widgets/advanced_checkout_dialog.dart';

/// Redesigned Billing Screen - Expert UI/UX
/// Compact, efficient, no overlays, optimized for merchant speed
class StartBillingPage extends StatefulWidget {
  final String merchantId;

  const StartBillingPage({super.key, required this.merchantId});

  @override
  State<StartBillingPage> createState() => _StartBillingPageState();
}

class _StartBillingPageState extends State<StartBillingPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quickNameController = TextEditingController();
  final TextEditingController _quickPriceController = TextEditingController();

  bool _showQuickAdd = false;
  int _selectedCategory = 0; // 0=All, 1=Favorites, 2=Recent
  bool _isTaxEnabled = false;

  final Set<String> _favoriteItems = {};
  final Map<String, DateTime> _recentItems = {};
  late final UserPreferencesDataSource _preferencesDataSource;

  @override
  void initState() {
    super.initState();
    _preferencesDataSource = UserPreferencesDataSource();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadItems(widget.merchantId);
      _loadUserPreferences();
    });
  }

  Future<void> _loadUserPreferences() async {
    try {
      final prefs = await _preferencesDataSource.getUserPreferences(
        widget.merchantId,
      );
      setState(() {
        _favoriteItems.addAll(List<String>.from(prefs['favoriteItems'] ?? []));
        _recentItems.addAll(
          Map<String, DateTime>.from(prefs['recentItems'] ?? {}),
        );
      });
    } catch (e) {
      debugPrint('Failed to load preferences: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quickNameController.dispose();
    _quickPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildCompactHeader(),
            _buildUnifiedSearchBar(),
            _buildQuickSettingsBar(),
            Expanded(
              child: Stack(
                children: [
                  _buildItemsGrid(),
                  if (_showQuickAdd) _buildQuickAddOverlay(),
                ],
              ),
            ),
            _buildCompactCartSummary(),
          ],
        ),
      ),
    );
  }

  // ==================== COMPACT HEADER (60px) ====================
  Widget _buildCompactHeader() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          // Title & Summary
          Expanded(
            child: Consumer<SessionProvider>(
              builder: (context, provider, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New Billing',
                      style: AppTypography.h5.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${provider.cartItems.length} items • ₹${provider.cartTotal.toStringAsFixed(2)}',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Menu (Parked carts + options)
          Consumer<SessionProvider>(
            builder: (context, provider, _) {
              final parkedCount = provider.parkedCarts.length;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {
                      _showOptionsMenu();
                    },
                  ),
                  if (parkedCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$parkedCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ==================== UNIFIED SEARCH + ACTIONS (50px) ====================
  Widget _buildUnifiedSearchBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: AppColors.lightSurface,
      child: Row(
        children: [
          // Search field
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '🔍 Search items...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Category filters (icon only)
          _buildCategoryIcon(Icons.grid_view, 'All', 0),
          _buildCategoryIcon(Icons.star, 'Favorites', 1),
          _buildCategoryIcon(Icons.history, 'Recent', 2),
          // Quick Add
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.success),
            onPressed: () => setState(() => _showQuickAdd = true),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(IconData icon, String label, int index) {
    final isSelected = _selectedCategory == index;
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryBlue.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          width: 2,
        ),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 20,
          color: isSelected
              ? AppColors.primaryBlue
              : AppColors.lightTextSecondary,
        ),
        onPressed: () => setState(() => _selectedCategory = index),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  // ==================== QUICK SETTINGS BAR (40px) ====================
  Widget _buildQuickSettingsBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: AppColors.lightBackground.withOpacity(0.5),
      child: Row(
        children: [
          // Tax toggle
          Text(
            'Apply Tax',
            style: AppTypography.caption.copyWith(
              color: AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: _isTaxEnabled,
            onChanged: (value) {
              setState(() => _isTaxEnabled = value);
              // Update session provider tax state
              context.read<SessionProvider>().setTaxEnabled(value);
            },
            activeColor: AppColors.primaryBlue,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 24, color: AppColors.lightBorder),
          const SizedBox(width: 16),
          // Park indicator
          Consumer<SessionProvider>(
            builder: (context, provider, _) {
              return TextButton.icon(
                icon: const Icon(Icons.local_parking, size: 18),
                label: Text('Park (${provider.parkedCarts.length})'),
                onPressed: () {
                  if (provider.cartItems.isNotEmpty) {
                    provider.parkCurrentCart();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cart parked successfully'),
                        backgroundColor: AppColors.success,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else if (provider.parkedCarts.isNotEmpty) {
                    _showParkedBillsDialog();
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==================== ITEMS GRID (with 110px bottom padding) ====================
  Widget _buildItemsGrid() {
    return Consumer2<ItemProvider, SessionProvider>(
      builder: (context, itemProvider, sessionProvider, _) {
        if (itemProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final allItems = itemProvider.items;
        final filteredItems = _getFilteredItems(allItems);

        if (filteredItems.isEmpty) {
          return _buildEmptyState();
        }

        return GridView.builder(
          padding: const EdgeInsets.only(
            left: 12,
            right: 12,
            top: 12,
            bottom: 110, // CRITICAL: Space for cart summary!
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85, // Fixed aspect ratio
          ),
          itemCount: filteredItems.length,
          itemBuilder: (context, index) {
            final item = filteredItems[index];
            // Get quantity from cart items
            int quantity = 0;
            try {
              final cartItem = sessionProvider.cartItems.firstWhere(
                (ci) => ci.name == item.name,
              );
              quantity = cartItem.qty;
            } catch (e) {
              // Item not in cart, quantity remains 0
            }
            final isInCart = quantity > 0;

            return _buildFixedHeightItemCard(
              item,
              quantity,
              isInCart,
              sessionProvider,
            );
          },
        );
      },
    );
  }

  // ==================== FIXED-HEIGHT ITEM CARD (130px) ====================
  Widget _buildFixedHeightItemCard(
    ItemEntity item,
    int quantity,
    bool isInCart,
    SessionProvider provider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInCart
              ? AppColors.primaryBlue.withOpacity(0.3)
              : AppColors.lightBorder,
          width: isInCart ? 2 : 1,
        ),
        boxShadow: isInCart
            ? [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!isInCart) {
              provider.addToCart(item);
              _markAsRecent(item.name);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row (name + quantity badge)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body2.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Favorite star
                    GestureDetector(
                      onTap: () => _toggleFavorite(item.name),
                      child: Icon(
                        _favoriteItems.contains(item.name)
                            ? Icons.star
                            : Icons.star_border,
                        size: 18,
                        color: _favoriteItems.contains(item.name)
                            ? Colors.amber
                            : AppColors.lightTextTertiary,
                      ),
                    ),
                    if (isInCart) ...[
                      const SizedBox(width: 4),
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: AppColors.primaryBlue,
                        child: Text(
                          '$quantity',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const Spacer(),
                // Price
                Text(
                  '₹${item.price.toStringAsFixed(2)}',
                  style: AppTypography.h4.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                // Action buttons
                if (isInCart)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Remove button
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () =>
                            provider.updateCartItemQuantity(item.name, 0),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                        ),
                      ),
                      // Quantity controls
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: () => provider.updateCartItemQuantity(
                                item.name,
                                quantity - 1,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                            ),
                            Text(
                              '$quantity',
                              style: AppTypography.body2.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: () => provider.updateCartItemQuantity(
                                item.name,
                                quantity + 1,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add'),
                      onPressed: () {
                        provider.addToCart(item);
                        _markAsRecent(item.name);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== COMPACT CART SUMMARY (100px) ====================
  Widget _buildCompactCartSummary() {
    return Consumer<SessionProvider>(
      builder: (context, provider, _) {
        if (provider.cartItems.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.lightSurface,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Summary row (single line)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: Subtotal + Tax
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: AppTypography.body2,
                          children: [
                            const TextSpan(text: 'Subtotal: '),
                            TextSpan(
                              text:
                                  '₹${provider.cartSubtotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_isTaxEnabled) ...[
                              const TextSpan(text: '  •  Tax: '),
                              TextSpan(
                                text: '₹${provider.cartTax.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    // Right: Total
                    Text(
                      'Total: ₹${provider.cartTotal.toStringAsFixed(2)}',
                      style: AppTypography.h4.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action buttons row
                Row(
                  children: [
                    // Park button
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            provider.parkCurrentCart();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cart parked successfully'),
                                backgroundColor: AppColors.success,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.local_parking, size: 20),
                          label: const Text('Park'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            side: const BorderSide(
                              color: AppColors.primaryBlue,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Complete Billing button
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleCheckout(provider),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Complete Billing'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==================== HELPER METHODS ====================

  List<ItemEntity> _getFilteredItems(List<ItemEntity> items) {
    var filtered = items;

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      filtered = filtered
          .where(
            (item) => item.name.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ),
          )
          .toList();
    }

    // Apply category filter
    switch (_selectedCategory) {
      case 1: // Favorites
        filtered = filtered
            .where((item) => _favoriteItems.contains(item.name))
            .toList();
        break;
      case 2: // Recent
        filtered = filtered
            .where((item) => _recentItems.containsKey(item.name))
            .toList();
        filtered.sort((a, b) {
          final aTime = _recentItems[a.name] ?? DateTime(0);
          final bTime = _recentItems[b.name] ?? DateTime(0);
          return bTime.compareTo(aTime);
        });
        break;
    }

    return filtered;
  }

  void _toggleFavorite(String itemName) {
    setState(() {
      if (_favoriteItems.contains(itemName)) {
        _favoriteItems.remove(itemName);
      } else {
        _favoriteItems.add(itemName);
      }
    });
    // saveFavoriteItems expects Set<String>, pass directly
    _preferencesDataSource.saveFavoriteItems(widget.merchantId, _favoriteItems);
  }

  void _markAsRecent(String itemName) {
    setState(() {
      _recentItems[itemName] = DateTime.now();
    });
    _preferencesDataSource.saveRecentItems(widget.merchantId, _recentItems);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: AppColors.lightTextTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No items found',
            style: AppTypography.h5.copyWith(
              color: AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: AppTypography.body2.copyWith(
              color: AppColors.lightTextTertiary,
            ),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    _showParkedBillsDialog();
  }

  void _showParkedBillsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<SessionProvider>(
        builder: (context, provider, _) {
          final parkedCarts = provider.parkedCarts;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Parked Bills',
                        style: AppTypography.h4.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (parkedCarts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: AppColors.lightTextTertiary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No parked bills',
                              style: AppTypography.body1.copyWith(
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: parkedCarts.length,
                        itemBuilder: (context, index) {
                          final entry = parkedCarts.entries.elementAt(index);
                          final cartId = entry.key;
                          final items = entry.value;

                          // Calculate cart total
                          double total = 0;
                          int itemCount = 0;
                          items.forEach((name, sessionItem) {
                            total += sessionItem.subtotal;
                            itemCount += sessionItem.qty;
                          });

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primaryBlue
                                    .withOpacity(0.1),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                '$itemCount items',
                                style: AppTypography.body1.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Total: ₹${total.toStringAsFixed(2)}',
                                style: AppTypography.body2.copyWith(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      provider.deleteParkedCart(cartId);
                                      if (parkedCarts.length == 1) {
                                        Navigator.pop(context);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 80,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        provider.switchToParkedCart(cartId);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Switched to parked cart',
                                            ),
                                            backgroundColor: AppColors.success,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                      child: const Text('Load'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickAddOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 400,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Quick Add Item',
                      style: AppTypography.h5,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _quickNameController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _quickPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () =>
                              setState(() => _showQuickAdd = false),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 80,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _handleQuickAdd,
                            child: const Text('Add'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleQuickAdd() {
    final name = _quickNameController.text.trim();
    final priceText = _quickPriceController.text.trim();

    if (name.isEmpty || priceText.isEmpty) return;

    final price = double.tryParse(priceText);
    if (price == null) return;

    final provider = context.read<SessionProvider>();
    // Create a temporary item entity for quick add with ALL required fields
    final now = DateTime.now();
    final quickItem = ItemEntity(
      id: 'quick_${now.millisecondsSinceEpoch}',
      merchantId: widget.merchantId,
      name: name,
      price: price,
      taxRate: 0,
      hsnCode: '',
      createdAt: now,
      updatedAt: now,
    );
    provider.addToCart(quickItem);

    _quickNameController.clear();
    _quickPriceController.clear();
    setState(() => _showQuickAdd = false);
  }

  void _handleCheckout(SessionProvider provider) async {
    // Open advanced checkout dialog
    final result = await showDialog<PaymentDetails>(
      context: context,
      builder: (context) => AdvancedCheckoutDialog(
        billTotal: provider.cartTotal,
        onComplete: (paymentDetails) => Navigator.pop(context, paymentDetails),
      ),
    );

    if (result != null && mounted) {
      try {
        final sessionId = await provider.createSessionWithPayment(
          widget.merchantId,
          result,
        );

        if (mounted) {
          context.go('/merchant/${widget.merchantId}/session/$sessionId');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
