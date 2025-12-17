import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../providers/item_provider.dart';
import '../providers/session_provider.dart';
import '../providers/customer_ledger_provider.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/entities/payment_entity.dart';
import '../../data/datasources/user_preferences_data_source.dart';
import '../widgets/advanced_checkout_dialog.dart';
import '../widgets/barcode_scanner_page.dart';

/// BILEE Merchant Billing Screen
/// Premium, modern, merchant-friendly UI supporting all business types
/// Designed for speed, clarity, and elegance
class StartBillingPage extends StatefulWidget {
  final String merchantId;

  const StartBillingPage({super.key, required this.merchantId});

  @override
  State<StartBillingPage> createState() => _StartBillingPageState();
}

class _StartBillingPageState extends State<StartBillingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quickNameController = TextEditingController();
  final TextEditingController _quickPriceController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _showQuickAdd = false;
  int _selectedBillingMethod = 0; // 0=All Items, 1=Favorites, 2=Recent
  bool _isTaxEnabled = false; // Toggle for tax calculation

  // User preferences - synced with database
  final Set<String> _favoriteItems = {};
  final Map<String, DateTime> _recentItems = {};

  // Preferences data source
  late final UserPreferencesDataSource _preferencesDataSource;

  @override
  void initState() {
    super.initState();
    _preferencesDataSource = UserPreferencesDataSource();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _selectedBillingMethod = _tabController.index);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadItems(widget.merchantId);
      _loadUserPreferences();
    });
  }

  /// Load user preferences from database
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
    _tabController.dispose();
    _searchController.dispose();
    _quickNameController.dispose();
    _quickPriceController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // Check if platform is desktop (Windows, macOS, Linux)
  bool get _isDesktop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            if (_isDesktop) _buildKeyboardShortcutsHint(),
            _buildBillingMethodTabs(),
            Expanded(
              child: Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          children: [
                            _buildSearchBar(),
                            _buildTaxToggle(),
                            SizedBox(
                              height:
                                  constraints.maxHeight -
                                  80, // Approximate search bar height
                              child: _buildItemsContent(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_showQuickAdd) _buildQuickAddOverlay(),
                ],
              ),
            ),
            _buildCartSummary(),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActions(),
    );

    // Only enable keyboard shortcuts on desktop platforms
    if (_isDesktop) {
      return KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        autofocus: true,
        onKeyEvent: _handleKeyPress,
        child: scaffold,
      );
    }

    return scaffold;
  }

  // ==================== KEYBOARD SHORTCUTS ====================
  void _handleKeyPress(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    // F1 - Focus search
    if (event.logicalKey == LogicalKeyboardKey.f1) {
      _searchFocusNode.requestFocus();
      return;
    }

    // F2 - Quick Add
    if (event.logicalKey == LogicalKeyboardKey.f2) {
      setState(() => _showQuickAdd = true);
      return;
    }

    // F3 - Show cart details
    if (event.logicalKey == LogicalKeyboardKey.f3) {
      _showCartDetails();
      return;
    }

    // F4 - Park current bill
    if (event.logicalKey == LogicalKeyboardKey.f4) {
      _parkCurrentBill();
      return;
    }

    // F5 - Show parked bills
    if (event.logicalKey == LogicalKeyboardKey.f5) {
      _showParkedCartsDialog();
      return;
    }

    // F12 - Checkout
    if (event.logicalKey == LogicalKeyboardKey.f12) {
      final provider = context.read<SessionProvider>();
      if (provider.cartItems.isNotEmpty) {
        _handleCheckout(provider);
      }
      return;
    }

    // Ctrl+1/2/3 - Switch tabs
    final isControlPressed = HardwareKeyboard.instance.isControlPressed;
    if (isControlPressed && event.logicalKey == LogicalKeyboardKey.digit1) {
      _tabController.animateTo(0);
      return;
    }
    if (isControlPressed && event.logicalKey == LogicalKeyboardKey.digit2) {
      _tabController.animateTo(1);
      return;
    }
    if (isControlPressed && event.logicalKey == LogicalKeyboardKey.digit3) {
      _tabController.animateTo(2);
      return;
    }
  }

  Widget _buildKeyboardShortcutsHint() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: 4,
      ),
      color: Colors.blue.shade50,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.keyboard, size: 14, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            _buildShortcutChip('F1', 'Search'),
            _buildShortcutChip('F2', 'Quick Add'),
            _buildShortcutChip('F3', 'Cart'),
            _buildShortcutChip('F4', 'Park'),
            _buildShortcutChip('F5', 'Parked'),
            _buildShortcutChip('F12', 'Checkout'),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutChip(String key, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              key,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.blue.shade700),
          ),
        ],
      ),
    );
  }

  // ==================== TOP BAR ====================
  Widget _buildTopBar() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        child: Row(
          children: [
            // Back Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_outlined,
                  color: Colors.white,
                ),
                onPressed: () => context.pop(),
                iconSize: AppDimensions.iconMD,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingMD),
            // Parked Carts Button
            Consumer<SessionProvider>(
              builder: (context, provider, _) {
                final parkedCount = provider.parkedCartsCount;
                if (parkedCount == 0) return const SizedBox.shrink();

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMD,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                        ),
                        onPressed: _showParkedCartsDialog,
                        iconSize: AppDimensions.iconMD,
                      ),
                    ),
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
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
            const SizedBox(width: AppDimensions.spacingMD),
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Billing',
                    style: AppTypography.h4.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Consumer<SessionProvider>(
                    builder: (context, provider, _) {
                      return Text(
                        '${provider.cartItems.length} items • ₹${provider.cartTotal.toStringAsFixed(2)}',
                        style: AppTypography.body3.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== BILLING METHOD TABS ====================
  Widget _buildBillingMethodTabs() {
    return Container(
      color: AppColors.lightSurface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: AppDimensions.paddingSM,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.lightTextSecondary,
          labelStyle: AppTypography.body2.copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTypography.body2.copyWith(
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(
              icon: Icon(
                Icons.inventory_2_outlined,
                size: AppDimensions.iconSM,
              ),
              text: 'All Items',
            ),
            Tab(
              icon: Icon(Icons.star_outline, size: AppDimensions.iconSM),
              text: 'Favorites',
            ),
            Tab(
              icon: Icon(Icons.history_outlined, size: AppDimensions.iconSM),
              text: 'Recent',
            ),
          ],
        ),
      ),
    );
  }

  // ==================== SEARCH BAR ====================
  Widget _buildSearchBar() {
    return Container(
      color: AppColors.lightSurface,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingMD,
        AppDimensions.paddingSM,
        AppDimensions.paddingMD,
        AppDimensions.paddingMD,
      ),
      child: Row(
        children: [
          // Search Field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: AppTypography.body2,
                decoration: InputDecoration(
                  hintText: 'Search items by name...',
                  hintStyle: AppTypography.body2.copyWith(
                    color: AppColors.lightTextTertiary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_outlined,
                    color: AppColors.lightTextSecondary,
                    size: AppDimensions.iconMD,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.close_outlined,
                            size: AppDimensions.iconSM,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            context.read<ItemProvider>().clearSearch();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppDimensions.paddingSM,
                  ),
                ),
                onChanged: (value) {
                  context.read<ItemProvider>().searchItems(value);
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacingSM),
          // Barcode Scan Button
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.qr_code_scanner_outlined,
                color: Colors.white,
              ),
              onPressed: _handleBarcodeScan,
              iconSize: AppDimensions.iconMD,
              tooltip: 'Scan Barcode',
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TAX TOGGLE ====================
  Widget _buildTaxToggle() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.paddingMD,
        0,
        AppDimensions.paddingMD,
        AppDimensions.paddingSM,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMD,
        vertical: AppDimensions.paddingSM,
      ),
      decoration: BoxDecoration(
        color: _isTaxEnabled
            ? AppColors.success.withOpacity(0.05)
            : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(
          color: _isTaxEnabled
              ? AppColors.success.withOpacity(0.3)
              : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: AppDimensions.iconMD,
            color: _isTaxEnabled
                ? AppColors.success
                : AppColors.lightTextTertiary,
          ),
          const SizedBox(width: AppDimensions.spacingSM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apply Tax Separately',
                  style: AppTypography.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  _isTaxEnabled
                      ? 'Tax will be added to item prices'
                      : 'Items priced at MRP (tax included)',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isTaxEnabled,
            onChanged: (value) {
              setState(() {
                _isTaxEnabled = value;
                // Notify session provider about tax setting change
                final provider = context.read<SessionProvider>();
                provider.setTaxEnabled(_isTaxEnabled);
              });
              HapticFeedback.lightImpact();
            },
            activeThumbColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  // ==================== ITEMS CONTENT ====================
  Widget _buildItemsContent() {
    return Consumer<ItemProvider>(
      builder: (context, itemProvider, _) {
        if (itemProvider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(strokeWidth: 3),
                const SizedBox(height: AppDimensions.spacingMD),
                Text(
                  'Loading items...',
                  style: AppTypography.body2.copyWith(
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        if (!itemProvider.hasItems) {
          return _buildEmptyState();
        }

        final items = _getFilteredItems(itemProvider.items);

        if (items.isEmpty) {
          return _buildNoResultsState();
        }

        return _buildItemsGrid(items);
      },
    );
  }

  List<ItemEntity> _getFilteredItems(List<ItemEntity> items) {
    // Filter items based on selected billing method tab
    switch (_selectedBillingMethod) {
      case 0:
        // All Items - return everything
        return items;
      case 1:
        // Favorites - filter items marked as favorites
        if (_favoriteItems.isEmpty) {
          return items; // Show all if no favorites yet
        }
        return items
            .where((item) => _favoriteItems.contains(item.name))
            .toList();
      case 2:
        // Recent - filter recently used items (last 7 days)
        if (_recentItems.isEmpty) {
          return items; // Show all if no recent items yet
        }
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        final recentNames = _recentItems.entries
            .where((entry) => entry.value.isAfter(sevenDaysAgo))
            .map((entry) => entry.key)
            .toSet();
        return items.where((item) => recentNames.contains(item.name)).toList();
      default:
        return items;
    }
  }

  // Toggle favorite status for an item and sync to database
  void _toggleFavorite(String itemName) {
    setState(() {
      if (_favoriteItems.contains(itemName)) {
        _favoriteItems.remove(itemName);
        _preferencesDataSource
            .removeFavoriteItem(widget.merchantId, itemName)
            .catchError((e) {
              debugPrint('Failed to remove favorite: $e');
            });
      } else {
        _favoriteItems.add(itemName);
        _preferencesDataSource
            .addFavoriteItem(widget.merchantId, itemName)
            .catchError((e) {
              debugPrint('Failed to add favorite: $e');
            });
      }
    });
  }

  // Track item as recently used and sync to database
  void _markAsRecent(String itemName) {
    final timestamp = DateTime.now();
    setState(() {
      _recentItems[itemName] = timestamp;
    });
    _preferencesDataSource
        .addRecentItem(widget.merchantId, itemName, timestamp)
        .catchError((e) {
          debugPrint('Failed to add recent item: $e');
        });
  }

  Widget _buildItemsGrid(List<ItemEntity> items) {
    return Consumer<SessionProvider>(
      builder: (context, sessionProvider, _) {
        return GridView.builder(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.1,
            crossAxisSpacing: AppDimensions.spacingMD,
            mainAxisSpacing: AppDimensions.spacingMD,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            // Find cart item safely - return 0 quantity if not in cart
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

            return _buildItemCard(item, quantity, isInCart, sessionProvider);
          },
        );
      },
    );
  }

  // ==================== ITEM CARD ====================
  Widget _buildItemCard(
    ItemEntity item,
    int quantity,
    bool isInCart,
    SessionProvider provider,
  ) {
    final isFavorite = _favoriteItems.contains(item.name);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        provider.addToCart(item);
        _markAsRecent(item.name);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isInCart
              ? AppColors.success.withOpacity(0.05)
              : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          border: Border.all(
            color: isInCart ? AppColors.success : AppColors.lightBorder,
            width: isInCart ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isInCart
                  ? AppColors.success.withOpacity(0.15)
                  : AppColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Favorite Button (Top Right)
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _toggleFavorite(item.name);
                },
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingSM),
                  child: Icon(
                    isFavorite ? Icons.star : Icons.star_outline,
                    color: isFavorite
                        ? Colors.amber
                        : AppColors.lightTextTertiary,
                    size: AppDimensions.iconMD,
                  ),
                ),
              ),
            ),
            // Item Header
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.paddingMD,
                  0,
                  AppDimensions.paddingMD,
                  AppDimensions.paddingSM,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Item Name
                    Flexible(
                      child: Text(
                        item.name,
                        style: AppTypography.body1.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightTextPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    // Price
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingSM,
                        vertical: AppDimensions.paddingXS,
                      ),
                      decoration: BoxDecoration(
                        gradient: isInCart
                            ? AppColors.primaryGradient
                            : LinearGradient(
                                colors: [
                                  AppColors.lightBackground,
                                  AppColors.lightBackground.withOpacity(0.5),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSM,
                        ),
                      ),
                      child: Text(
                        '₹${item.price.toStringAsFixed(2)}',
                        style: AppTypography.h5.copyWith(
                          color: isInCart
                              ? Colors.white
                              : AppColors.primaryBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Add to Cart / Quantity Controls
            if (!isInCart)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppDimensions.cardRadius),
                    bottomRight: Radius.circular(AppDimensions.cardRadius),
                  ),
                ),
                padding: const EdgeInsets.all(AppDimensions.paddingSM),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: AppDimensions.iconSM,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: AppDimensions.spacingXS),
                    Text(
                      'Add',
                      style: AppTypography.body2.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppDimensions.cardRadius),
                    bottomRight: Radius.circular(AppDimensions.cardRadius),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingSM,
                  vertical: AppDimensions.paddingXS,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Decrease Button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        if (quantity > 1) {
                          provider.updateCartItemQuantity(
                            item.name,
                            quantity - 1,
                          );
                        } else {
                          provider.removeFromCart(item.name);
                        }
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowLight,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          quantity == 1 ? Icons.delete_outline : Icons.remove,
                          size: AppDimensions.iconSM,
                          color: quantity == 1
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ),
                    ),
                    // Quantity
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.paddingMD,
                        vertical: AppDimensions.paddingXS,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusSM,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadowLight,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        '$quantity',
                        style: AppTypography.h5.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // Increase Button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        provider.updateCartItemQuantity(
                          item.name,
                          quantity + 1,
                        );
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowLight,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          size: AppDimensions.iconSM,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== EMPTY STATES ====================
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.padding2XL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.padding2XL),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: AppDimensions.icon3XL,
                color: AppColors.lightTextTertiary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingXL),
            Text(
              'No Items Yet',
              style: AppTypography.h3.copyWith(
                color: AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSM),
            Text(
              'Add items to your inventory to start billing',
              style: AppTypography.body2.copyWith(
                color: AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacing2XL),
            ElevatedButton.icon(
              onPressed: () => context.push('/merchant/items'),
              icon: const Icon(Icons.add_outlined),
              label: const Text('Add Items'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingXL,
                  vertical: AppDimensions.paddingMD,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.padding2XL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_outlined,
              size: AppDimensions.icon3XL,
              color: AppColors.lightTextTertiary,
            ),
            const SizedBox(height: AppDimensions.spacingXL),
            Text(
              'No Items Found',
              style: AppTypography.h4.copyWith(
                color: AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: AppDimensions.spacingSM),
            Text(
              'Try a different search term',
              style: AppTypography.body2.copyWith(
                color: AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== QUICK ADD OVERLAY ====================
  Widget _buildQuickAddOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _showQuickAdd = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        color: Colors.black54,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent dismissal when tapping inside
            child: Container(
              margin: const EdgeInsets.all(AppDimensions.paddingXL),
              padding: const EdgeInsets.all(AppDimensions.paddingXL),
              decoration: BoxDecoration(
                color: AppColors.lightSurface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowDark,
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(
                            AppDimensions.paddingSM,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMD,
                            ),
                          ),
                          child: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.white,
                            size: AppDimensions.iconMD,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacingMD),
                        Expanded(
                          child: Text(
                            'Quick Add Item',
                            style: AppTypography.h4.copyWith(
                              color: AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_outlined),
                          onPressed: () =>
                              setState(() => _showQuickAdd = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingXL),
                    // Item Name Field
                    Text(
                      'Item Name',
                      style: AppTypography.body2.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingSM),
                    TextField(
                      controller: _quickNameController,
                      style: AppTypography.body1,
                      decoration: InputDecoration(
                        hintText: 'e.g., Coffee, T-Shirt, Medicine',
                        hintStyle: AppTypography.body2.copyWith(
                          color: AppColors.lightTextTertiary,
                        ),
                        prefixIcon: const Icon(Icons.label_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.inputRadius,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.lightBackground,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingLG),
                    // Price Field
                    Text(
                      'Price',
                      style: AppTypography.body2.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingSM),
                    TextField(
                      controller: _quickPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: AppTypography.body1,
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: AppTypography.body2.copyWith(
                          color: AppColors.lightTextTertiary,
                        ),
                        prefixIcon: const Icon(Icons.currency_rupee_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.inputRadius,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.lightBackground,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing2XL),
                    // Add Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _handleQuickAdd,
                        icon: const Icon(Icons.done_outline),
                        label: const Text('Add to Cart'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppDimensions.paddingLG,
                          ),
                        ),
                      ),
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

  // ==================== CART SUMMARY ====================
  Widget _buildCartSummary() {
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
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingMD),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Subtotal, Tax, Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: AppTypography.body2.copyWith(
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                      Text(
                        '₹${provider.cartSubtotal.toStringAsFixed(2)}',
                        style: AppTypography.body1.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  if (_isTaxEnabled) ...[
                    // CGST (half of total tax)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CGST',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          '₹${(provider.cartTax / 2).toStringAsFixed(2)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // SGST (half of total tax)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SGST',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          '₹${(provider.cartTax / 2).toStringAsFixed(2)}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                  ],
                  const Divider(height: AppDimensions.spacingLG),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: AppTypography.h4.copyWith(
                          color: AppColors.lightTextPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingMD,
                          vertical: AppDimensions.paddingSM,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusMD,
                          ),
                        ),
                        child: Text(
                          '₹${provider.cartTotal.toStringAsFixed(2)}',
                          style: AppTypography.h3.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingMD),
                  // Checkout Button
                  SizedBox(
                    width: double.infinity,
                    height: AppDimensions.buttonHeightLG,
                    child: ElevatedButton.icon(
                      onPressed: () => _handleCheckout(provider),
                      icon: const Icon(
                        Icons.check_circle_outline,
                        size: AppDimensions.iconMD,
                      ),
                      label: Text(
                        'Complete Billing',
                        style: AppTypography.body1.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.buttonRadius,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== FLOATING ACTIONS ====================
  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Park Bill Button (only if cart has items)
        Consumer<SessionProvider>(
          builder: (context, provider, _) {
            if (provider.cartItems.isEmpty) return const SizedBox.shrink();

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  onPressed: _parkCurrentBill,
                  backgroundColor: Colors.orange,
                  icon: const Icon(Icons.local_parking, color: Colors.white),
                  label: Text(
                    'Park',
                    style: AppTypography.body2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  heroTag: 'park_bill',
                ),
                const SizedBox(height: AppDimensions.spacingMD),
              ],
            );
          },
        ),
        // Quick Add Button
        FloatingActionButton.extended(
          onPressed: () => setState(() => _showQuickAdd = true),
          backgroundColor: AppColors.success,
          icon: const Icon(Icons.add_outlined, color: Colors.white),
          label: Text(
            'Quick Add',
            style: AppTypography.body2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          heroTag: 'quick_add',
        ),
        const SizedBox(height: AppDimensions.spacingMD),
        // View Cart Button (if items exist)
        Consumer<SessionProvider>(
          builder: (context, provider, _) {
            if (provider.cartItems.isEmpty) return const SizedBox.shrink();

            return FloatingActionButton(
              onPressed: _showCartDetails,
              backgroundColor: AppColors.primaryBlue,
              heroTag: 'view_cart',
              child: Badge(
                label: Text('${provider.cartItems.length}'),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.white,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ==================== HANDLERS ====================
  /// Handle barcode scanning for quick item addition
  Future<void> _handleBarcodeScan() async {
    HapticFeedback.mediumImpact();

    try {
      // Open barcode scanner page
      final String? scannedCode = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
      );

      if (scannedCode == null || !mounted) return;

      // Search for item by barcode in item library
      final items = context.read<ItemProvider>().items;

      // Try to find item by HSN code (used as barcode)
      ItemEntity? foundItem;
      try {
        foundItem = items.firstWhere(
          (item) => item.hsnCode == scannedCode.toLowerCase().trim(),
        );
      } catch (_) {
        // Item not found by HSN, try searching by name contains
        try {
          foundItem = items.firstWhere(
            (item) =>
                item.name.toLowerCase().contains(scannedCode.toLowerCase()),
          );
        } catch (_) {
          // Still not found
        }
      }

      if (foundItem != null) {
        // Add item to cart
        context.read<SessionProvider>().addToCart(foundItem);
        _markAsRecent(foundItem.name);

        HapticFeedback.mediumImpact();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${foundItem.name} added to cart',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Item not found - show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Item with code "$scannedCode" not found in library',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              ),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Add Manually',
                textColor: Colors.white,
                onPressed: () {
                  setState(() => _showQuickAdd = true);
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Barcode scan error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning barcode: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
          ),
        );
      }
    }
  }

  void _handleQuickAdd() {
    final name = _quickNameController.text.trim();
    final priceText = _quickPriceController.text.trim();

    if (name.isEmpty || priceText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter both name and price'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
        ),
      );
      return;
    }

    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a valid price'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
        ),
      );
      return;
    }

    // Create temporary item with default values and add to cart
    final now = DateTime.now();
    final tempItem = ItemEntity(
      id: 'temp_${now.millisecondsSinceEpoch}', // Temporary unique ID
      merchantId: widget.merchantId,
      name: name,
      price: price,
      taxRate: 0.0, // Default: no tax for quick add items
      hsnCode: '', // No HSN code for quick add items
      createdAt: now,
      updatedAt: now,
    );

    HapticFeedback.mediumImpact();

    // Add item to cart
    context.read<SessionProvider>().addToCart(tempItem);
    _markAsRecent(name);

    _quickNameController.clear();
    _quickPriceController.clear();
    setState(() => _showQuickAdd = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name added to cart'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _parkCurrentBill() {
    HapticFeedback.mediumImpact();
    final provider = context.read<SessionProvider>();

    if (provider.cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cart is empty. Nothing to park.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cartId = provider.parkCurrentCart();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bill parked! Cart ID: ${cartId.substring(cartId.length - 6)}',
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: _showParkedCartsDialog,
        ),
      ),
    );
  }

  void _showParkedCartsDialog() {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      builder: (context) => Consumer<SessionProvider>(
        builder: (context, provider, _) {
          final parkedCarts = provider.parkedCarts;

          if (parkedCarts.isEmpty) {
            return AlertDialog(
              title: const Text('Parked Bills'),
              content: const Text('No parked bills'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          }

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Parked Bills'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: parkedCarts.length,
                itemBuilder: (context, index) {
                  final cartId = parkedCarts.keys.elementAt(index);
                  final summary = provider.getParkedCartSummary(cartId);
                  final timestamp = cartId.substring(cartId.length - 13);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        'Bill #${timestamp.substring(timestamp.length - 6)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${summary['items']} items • ₹${summary['total'].toStringAsFixed(2)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              provider.deleteParkedCart(cartId);
                              if (provider.parkedCartsCount == 0) {
                                Navigator.pop(context);
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.open_in_new,
                              color: AppColors.primaryBlue,
                            ),
                            onPressed: () {
                              provider.switchToParkedCart(cartId);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Switched to Bill #${timestamp.substring(timestamp.length - 6)}',
                                  ),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CLOSE'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCartDetails() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildCartBottomSheet(),
    );
  }

  Widget _buildCartBottomSheet() {
    return Consumer<SessionProvider>(
      builder: (context, provider, _) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: AppColors.lightSurface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppDimensions.modalRadius),
              topRight: Radius.circular(AppDimensions.modalRadius),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(
                  vertical: AppDimensions.paddingMD,
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
                  horizontal: AppDimensions.paddingXL,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingSM),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMD,
                        ),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                        size: AppDimensions.iconMD,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingMD),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cart Items',
                            style: AppTypography.h4.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${provider.cartItems.length} items',
                            style: AppTypography.body3.copyWith(
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_outlined),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Cart Items List
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppDimensions.paddingMD),
                  shrinkWrap: true,
                  itemCount: provider.cartItems.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppDimensions.spacingSM),
                  itemBuilder: (context, index) {
                    final item = provider.cartItems[index];
                    return Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingMD),
                      decoration: BoxDecoration(
                        color: AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMD,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: AppTypography.body1.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${item.price.toStringAsFixed(2)} × ${item.qty}',
                                  style: AppTypography.body3.copyWith(
                                    color: AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${item.total.toStringAsFixed(2)}',
                            style: AppTypography.h5.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleCheckout(SessionProvider provider) async {
    HapticFeedback.mediumImpact();

    // Show advanced checkout dialog and get payment details
    final paymentDetails = await showDialog<PaymentDetails>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AdvancedCheckoutDialog(
        billTotal: provider.cartTotal,
        onComplete: (details) {
          Navigator.of(
            dialogContext,
          ).pop(details); // Close dialog and return payment details
        },
      ),
    );

    // If dialog was cancelled (no payment details returned)
    if (paymentDetails == null) {
      print('🟣 [CHECKOUT] Payment cancelled by user');
      return;
    }

    // Check if widget is still mounted before proceeding
    if (!mounted) {
      print('🔴 [CHECKOUT ERROR] Widget unmounted after dialog, aborting');
      return;
    }

    // Show processing indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.padding2XL),
          decoration: BoxDecoration(
            color: AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: AppDimensions.spacingXL),
              Text(
                'Processing...',
                style: AppTypography.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      print('🟣 [CHECKOUT] Starting session creation...');
      // Create session with payment details
      final sessionId = await provider.createSessionWithPayment(
        widget.merchantId,
        paymentDetails,
      );

      print('🟣 [CHECKOUT] Session created: $sessionId');

      // Create ledger entry if partial payment
      if (paymentDetails.hasCredit && mounted) {
        print('🟣 [CHECKOUT] Creating ledger entry for partial payment...');
        final ledgerProvider = context.read<CustomerLedgerProvider>();
        await ledgerProvider.createEntry(paymentDetails);
        print('🟣 [CHECKOUT] Ledger entry created');
      }

      if (!mounted) {
        print('🔴 [CHECKOUT ERROR] Widget not mounted after processing');
        return;
      }

      print('🟣 [CHECKOUT] Closing processing dialog...');
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop(); // Close processing dialog
      }

      if (sessionId != null && mounted) {
        // Small delay to ensure dialog is fully closed before navigation
        await Future.delayed(const Duration(milliseconds: 100));

        if (!mounted) return;

        final route = '/merchant/${widget.merchantId}/session/$sessionId';
        print('🟣 [CHECKOUT] Navigating to: $route');
        context.push(route);
        print('🟣 [CHECKOUT] Navigation completed');
      } else if (sessionId == null && mounted) {
        print('🔴 [CHECKOUT ERROR] Session ID is null');
        _showError('Failed to create billing session');
      }
    } catch (e) {
      print('🔴 [CHECKOUT ERROR] Exception caught: $e');
      if (!mounted) return;
      Navigator.of(context).pop(); // Close processing dialog
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        ),
      ),
    );
  }
}
