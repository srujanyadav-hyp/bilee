import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../providers/item_provider.dart';
import '../providers/session_provider.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../domain/entities/merchant_entity.dart';
import '../../data/datasources/user_preferences_data_source.dart';
import '../widgets/advanced_checkout_dialog.dart';
import '../widgets/add_item_dialog.dart';
import '../widgets/fast_input_options_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/order_info_dialog.dart';

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
  final bool _isTaxEnabled = false;
  bool _showCartDetails = false; // For expandable cart items view

  final Set<String> _favoriteItems = {};
  final Map<String, DateTime> _recentItems = {};
  late final UserPreferencesDataSource _preferencesDataSource;

  // Restaurant merchant detection
  String? _merchantBusinessType;
  bool _isLoadingBusinessType = true;

  @override
  void initState() {
    super.initState();
    _preferencesDataSource = UserPreferencesDataSource();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadItems(widget.merchantId);
      _loadUserPreferences();
      _loadMerchantBusinessType();
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

  Future<void> _loadMerchantBusinessType() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('merchants')
          .doc(widget.merchantId)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _merchantBusinessType = doc.data()?['businessType'] as String?;
          _isLoadingBusinessType = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load merchant business type: $e');
      if (mounted) {
        setState(() {
          _isLoadingBusinessType = false;
        });
      }
    }
  }

  /// Check if merchant is restaurant or food business
  bool _isRestaurantBusiness() {
    if (_merchantBusinessType == null) return false;

    final restaurantTypes = [
      'restaurant',
      'food',
      'cafe',
      'bakery',
      'food truck',
      'catering',
    ];

    return restaurantTypes.any(
      (type) => _merchantBusinessType!.toLowerCase().contains(type),
    );
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDarkMode
        ? Colors.white
        : Colors.black; // Black in light mode, white in dark mode

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Column(
        children: [
          _buildCompactHeader(titleColor),
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
    );
  }

  // ==================== COMPACT HEADER (extends into status bar) ====================
  Widget _buildCompactHeader(Color titleColor) {
    return Container(
      // Add status bar height to total height
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: AppDimensions.paddingSM,
        right: AppDimensions.paddingSM,
      ),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: [
          // Primary shadow with gradient glow
          BoxShadow(
            color: AppColors.primaryBlue.withOpacity(0.3),
            blurRadius: AppDimensions.elevationLG,
            offset: const Offset(0, 4),
          ),
          // Subtle top highlight
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            // Back button
            IconButton(
              icon: Icon(Icons.arrow_back, color: titleColor),
              onPressed: () => context.pop(),
            ),
            SizedBox(width: AppDimensions.spacingXS),
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
                          color: titleColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${provider.cartItems.length} items • ₹${provider.cartTotal.toStringAsFixed(2)}',
                        style: AppTypography.caption.copyWith(
                          color: titleColor.withOpacity(0.9),
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
                      icon: Icon(Icons.menu, color: titleColor),
                      onPressed: () {
                        _showOptionsMenu();
                      },
                    ),
                    if (parkedCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: AnimatedScale(
                          scale: 1.0,
                          duration: Duration(
                            milliseconds: AppDimensions.animationNormal,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.error.withOpacity(0.4),
                                  blurRadius: AppDimensions.elevationSM,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==================== UNIFIED SEARCH + ACTIONS (50px) ====================
  Widget _buildUnifiedSearchBar() {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingSM,
        vertical: AppDimensions.spacing2XS,
      ),
      color: AppColors.lightSurface,
      child: Row(
        children: [
          // Search field with elevation
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.lightSurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                border: Border.all(color: AppColors.lightBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: AppDimensions.elevationSM,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '🔍 Search items...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingSM,
                    vertical: 10,
                  ),
                  isDense: true,
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
          SizedBox(width: AppDimensions.spacingXS),
          // Category filters (icon only)
          _buildCategoryIcon(Icons.grid_view, 'All', 0),
          _buildCategoryIcon(Icons.star, 'Favorites', 1),
          _buildCategoryIcon(Icons.history, 'Recent', 2),
          // Voice Input - Fast input for users who don't type
          IconButton(
            icon: Icon(
              Icons.mic,
              color: AppColors.primaryBlue,
              size: AppDimensions.iconMD,
            ),
            onPressed: () => _openVoiceInput(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Voice Input',
          ),
          // Quick Add
          IconButton(
            icon: Icon(
              Icons.add_circle,
              color: AppColors.success,
              size: AppDimensions.iconMD,
            ),
            onPressed: () => setState(() => _showQuickAdd = true),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: 'Quick Add',
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
      margin: EdgeInsets.only(right: AppDimensions.spacing2XS),
      decoration: BoxDecoration(
        gradient: isSelected ? AppColors.primaryGradient : null,
        color: isSelected ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        border: Border.all(
          color: isSelected ? Colors.transparent : AppColors.lightBorder,
          width: AppDimensions.borderThin,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                  blurRadius: AppDimensions.elevationSM,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: AppDimensions.iconSM,
          color: isSelected ? Colors.white : AppColors.lightTextSecondary,
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
          // Fast Input Button (for users who don't type)
          ElevatedButton.icon(
            icon: const Icon(Icons.bolt, size: 18),
            label: const Text('Fast Input'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 2,
            ),
            onPressed: () => _showFastInputOptions(),
          ),
          const SizedBox(width: 12),
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
            double quantity = 0;
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
    double quantity,
    bool isInCart,
    SessionProvider provider,
  ) {
    // Format quantity display
    String formatQuantity(double qty) {
      if (qty == qty.toInt()) {
        return qty.toInt().toString();
      }
      return qty.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    }

    // Format price display based on unit type
    String formatPrice() {
      if (item.isWeightBased) {
        final priceToShow = item.pricePerUnit ?? item.price;
        return '₹${priceToShow.toStringAsFixed(2)}/${item.unit}';
      }
      return '₹${item.price.toStringAsFixed(2)}';
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: AppDimensions.animationFast),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(
          color: isInCart ? AppColors.primaryBlue : AppColors.lightBorder,
          width: isInCart
              ? AppDimensions.borderThick
              : AppDimensions.borderThin,
        ),
        boxShadow: isInCart
            ? [
                // Primary glow shadow
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.2),
                  blurRadius: AppDimensions.elevationMD,
                  offset: const Offset(0, 4),
                ),
                // Secondary subtle shadow
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: AppDimensions.elevationSM,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                // Default card shadow
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: AppDimensions.elevationSM,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (!isInCart) {
              HapticFeedback.lightImpact();
              // Show dialog for weight-based items
              if (item.isWeightBased) {
                await showDialog(
                  context: context,
                  builder: (context) => AddItemToCartDialog(
                    item: item,
                    onAdd: (qty, unit) {
                      provider.addToCart(item, quantity: qty);
                      _markAsRecent(item.name);
                    },
                  ),
                );
              } else {
                // Quick add for piece-based items
                provider.addToCart(item);
                _markAsRecent(item.name);
              }
            }
          },
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          child: Padding(
            padding: EdgeInsets.all(AppDimensions.paddingSM),
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
                    SizedBox(width: AppDimensions.spacing2XS),
                    // Favorite star with animation
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _toggleFavorite(item.name);
                      },
                      child: AnimatedSwitcher(
                        duration: Duration(
                          milliseconds: AppDimensions.animationFast,
                        ),
                        child: Icon(
                          _favoriteItems.contains(item.name)
                              ? Icons.star
                              : Icons.star_border,
                          key: ValueKey(_favoriteItems.contains(item.name)),
                          size: AppDimensions.iconXS,
                          color: _favoriteItems.contains(item.name)
                              ? Colors.amber
                              : AppColors.lightTextTertiary,
                        ),
                      ),
                    ),
                    if (isInCart) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${formatQuantity(quantity)} ${item.unit}',
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
                // Price with unit info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatPrice(),
                      style: AppTypography.h4.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.lightTextPrimary,
                        fontSize: 16,
                      ),
                    ),
                    if (item.isWeightBased)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.scale,
                              size: 10,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              'By weight',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Action buttons
                if (isInCart)
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      // Remove button - Compact
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () =>
                            provider.updateCartItemQuantity(item.name, 0),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                        ),
                      ),
                      const SizedBox(width: 4), // Small fixed space
                      // Quantity controls - Very compact
                      Expanded(
                        child: Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              InkWell(
                                onTap: () => provider.updateCartItemQuantity(
                                  item.name,
                                  quantity - 1,
                                ),
                                child: Container(
                                  width: 24,
                                  height: 28,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.remove, size: 14),
                                ),
                              ),
                              Container(
                                constraints: const BoxConstraints(minWidth: 20),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  formatQuantity(quantity),
                                  style: AppTypography.caption.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              InkWell(
                                onTap: () => provider.updateCartItemQuantity(
                                  item.name,
                                  quantity + 1,
                                ),
                                child: Container(
                                  width: 24,
                                  height: 28,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.add, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        item.isWeightBased ? Icons.scale : Icons.add,
                        size: 16,
                      ),
                      label: Text(item.isWeightBased ? 'Select' : 'Add'),
                      onPressed: () async {
                        if (item.isWeightBased) {
                          await showDialog(
                            context: context,
                            builder: (context) => AddItemToCartDialog(
                              item: item,
                              onAdd: (qty, unit) {
                                provider.addToCart(item, quantity: qty);
                                _markAsRecent(item.name);
                              },
                            ),
                          );
                        } else {
                          provider.addToCart(item);
                          _markAsRecent(item.name);
                        }
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
              // Dramatic upward shadow for floating effect
              BoxShadow(
                color: AppColors.shadowDark,
                blurRadius: AppDimensions.elevationXL,
                offset: const Offset(0, -6),
              ),
              // Subtle top highlight
              BoxShadow(
                color: Colors.white.withOpacity(0.5),
                blurRadius: 1,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          padding: EdgeInsets.all(AppDimensions.paddingSM),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Expandable cart items list
                GestureDetector(
                  onTap: () =>
                      setState(() => _showCartDetails = !_showCartDetails),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left: Cart items count
                      Row(
                        children: [
                          Icon(
                            _showCartDetails
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: AppColors.lightTextSecondary,
                          ),
                          SizedBox(width: AppDimensions.spacing2XS),
                          Text(
                            '${provider.cartItems.length} items in cart',
                            style: AppTypography.body2.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      // Right: Tap to expand hint
                      Text(
                        _showCartDetails ? 'Hide' : 'View',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),

                // Cart items detail (expandable)
                if (_showCartDetails) ...[
                  SizedBox(height: AppDimensions.spacingXS),
                  Container(
                    constraints: BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSM,
                      ),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.all(AppDimensions.spacingXS),
                      itemCount: provider.cartItems.length,
                      separatorBuilder: (_, __) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = provider.cartItems[index];

                        // Format quantity with unit
                        String formatCartQuantity(double qty, String unit) {
                          String qtyStr;
                          if (qty == qty.toInt()) {
                            qtyStr = qty.toInt().toString();
                          } else {
                            qtyStr = qty
                                .toStringAsFixed(2)
                                .replaceAll(RegExp(r'\.?0+$'), '');
                          }
                          return '$qtyStr $unit';
                        }

                        // Format price display
                        String formatItemDisplay() {
                          if (item.pricePerUnit != null) {
                            return '₹${item.pricePerUnit!.toStringAsFixed(2)}/${item.unit}';
                          }
                          return '';
                        }

                        return Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppDimensions.spacing2XS,
                            horizontal: AppDimensions.spacingXS,
                          ),
                          child: Row(
                            children: [
                              // Item name
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: AppTypography.body3,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (item.pricePerUnit != null)
                                      Text(
                                        formatItemDisplay(),
                                        style: AppTypography.caption.copyWith(
                                          color: Colors.grey.shade600,
                                          fontSize: 10,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Quantity with unit
                              Expanded(
                                child: Text(
                                  formatCartQuantity(item.qty, item.unit),
                                  style: AppTypography.body3.copyWith(
                                    color: AppColors.lightTextSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              // Price
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '₹${(item.price * item.qty).toStringAsFixed(2)}',
                                  style: AppTypography.body3.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],

                SizedBox(height: AppDimensions.spacingSM),

                // Summary row (total)
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
                SizedBox(height: AppDimensions.paddingSM),
                // Action buttons row
                Row(
                  children: [
                    // Park button
                    Expanded(
                      child: SizedBox(
                        height: AppDimensions.buttonHeightMD,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            provider.parkCurrentCart();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Cart parked successfully'),
                                backgroundColor: AppColors.success,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: Icon(
                            Icons.local_parking,
                            size: AppDimensions.iconSM,
                          ),
                          label: const Text('Park'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            side: BorderSide(
                              color: AppColors.primaryBlue,
                              width: AppDimensions.borderThin,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.buttonRadius,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: AppDimensions.paddingSM),
                    // Complete Billing button with gradient
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: AppDimensions.buttonHeightMD,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.buttonRadius,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.3),
                              blurRadius: AppDimensions.elevationMD,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            _handleCheckout(provider);
                          },
                          icon: Icon(
                            Icons.check_circle_outline,
                            size: AppDimensions.iconSM,
                          ),
                          label: const Text('Complete Billing'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.buttonRadius,
                              ),
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
      final query = _searchController.text.toLowerCase();

      filtered = filtered.where((item) {
        final itemName = item.name.toLowerCase();
        return itemName.contains(query);
      }).toList();
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
                            itemCount += sessionItem.qty
                                .toInt(); // Fixed: use toInt() instead of 'as int'
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

  /// Open voice input for fast item addition (for users who don't type)
  void _openVoiceInput() {
    context.push('/merchant/${widget.merchantId}/voice-add');
  }

  /// Show fast input options dialog (Voice, Barcode, Number Pad)
  void _showFastInputOptions() {
    showDialog(
      context: context,
      builder: (context) =>
          FastInputOptionsDialog(merchantId: widget.merchantId),
    );
  }

  void _handleCheckout(SessionProvider provider) async {
    // Step 1: For restaurant merchants, show OrderInfoDialog first
    OrderInfo? orderInfo;
    if (!_isLoadingBusinessType && _isRestaurantBusiness()) {
      orderInfo = await showOrderInfoDialog(context);

      // User cancelled the dialog
      if (orderInfo == null) return;
    }

    // Step 2: Fetch merchant profile for automated UPI
    MerchantEntity? merchantProfile;
    try {
      final merchantDoc = await FirebaseFirestore.instance
          .collection('merchants')
          .doc(widget.merchantId)
          .get();

      if (merchantDoc.exists) {
        final data = merchantDoc.data()!;
        merchantProfile = MerchantEntity(
          id: merchantDoc.id,
          businessName: data['businessName'] ?? '',
          businessPhone: data['businessPhone'],
          businessAddress: data['businessAddress'],
          businessEmail: data['businessEmail'],
          gstNumber: data['gstNumber'],
          panNumber: data['panNumber'],
          upiId: data['upiId'], // Encrypted UPI ID
          logoUrl: data['logoUrl'],
          businessType: data['businessType'] ?? 'Retail',
          isActive: data['isActive'] ?? true,
          isUpiEnabled: data['isUpiEnabled'] ?? false,
          isUpiVerified: data['isUpiVerified'] ?? false,
          upiProvider: data['upiProvider'],
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          updatedAt:
              (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('Failed to load merchant profile: $e');
      // Continue with null merchant - will use manual UPI flow
    }

    // Step 3: Open advanced checkout dialog
    final result = await showDialog<PaymentDetails>(
      context: context,
      builder: (context) => AdvancedCheckoutDialog(
        billTotal: provider.cartTotal,
        onComplete: (paymentDetails) => Navigator.pop(context, paymentDetails),
        merchant: merchantProfile, // Enables automated UPI if configured
        sessionId: provider.currentSession?.id,
        sessionProvider: provider,
      ),
    );

    if (result != null && mounted) {
      try {
        // Step 3: Create session with payment details and optional orderInfo
        final sessionId = await provider.createSessionWithPayment(
          widget.merchantId,
          result,
          orderInfo: orderInfo, // Pass restaurant order info if available
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
