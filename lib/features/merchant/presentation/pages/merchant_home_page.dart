import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/device_mode_service.dart';
import '../providers/daily_aggregate_provider.dart';
import '../providers/session_provider.dart';
import 'kitchen_orders_page.dart';

/// Merchant Home Page - Dashboard with navigation to all features
class MerchantHomePage extends StatefulWidget {
  final String merchantId;

  const MerchantHomePage({super.key, required this.merchantId});

  @override
  State<MerchantHomePage> createState() => _MerchantHomePageState();
}

class _MerchantHomePageState extends State<MerchantHomePage> {
  String? _businessType;
  bool _isLoadingBusinessType = true;

  @override
  void initState() {
    super.initState();
    _checkDeviceMode(); // Check if device is in kitchen mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DailyAggregateProvider>().loadTodayAggregate(
        widget.merchantId,
      );
      _loadMerchantBusinessType();
    });
  }

  /// Check device mode and redirect if in kitchen mode
  Future<void> _checkDeviceMode() async {
    final isKitchen = await DeviceModeService.isKitchenMode();
    if (isKitchen && mounted) {
      // Navigate to Kitchen Orders and remove all previous routes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) =>
                  KitchenOrdersPage(merchantId: widget.merchantId),
            ),
            (route) => false, // Remove all previous routes
          );
        }
      });
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
          _businessType = doc.data()?['businessType'] as String?;
          _isLoadingBusinessType = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBusinessType = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Merchant Dashboard'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              context.go('/merchant/${widget.merchantId}/profile');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTodaysSummaryCard(),
            const SizedBox(height: AppDimensions.spacingLG),
            _buildActionButtons(context),
            const SizedBox(height: AppDimensions.spacingLG),
            _buildQuickStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysSummaryCard() {
    return Consumer<DailyAggregateProvider>(
      builder: (context, provider, child) {
        final aggregate = provider.todayAggregate;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today\'s Sales',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Icon(Icons.calendar_today, color: AppColors.primaryBlue),
                  ],
                ),
                const Divider(height: AppDimensions.spacingLG),
                if (provider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (aggregate == null)
                  const Text('No sales yet today')
                else
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat(
                            'Revenue',
                            '₹${aggregate.totalRevenue.toStringAsFixed(2)}',
                            Icons.currency_rupee,
                          ),
                          _buildStat(
                            'Orders',
                            aggregate.totalOrders.toString(),
                            Icons.receipt,
                          ),
                        ],
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

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: AppColors.primaryBlue),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(color: AppColors.lightTextSecondary)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        _buildActionCard(
          context,
          title: 'Start Billing',
          subtitle: 'Create a new billing session',
          icon: Icons.point_of_sale,
          color: Colors.green,
          onTap: () {
            context.go('/merchant/${widget.merchantId}/billing');
          },
        ),
        const SizedBox(height: AppDimensions.spacingMD),
        _buildActionCard(
          context,
          title: 'Item Library',
          subtitle: 'Manage your products',
          icon: Icons.inventory_2,
          color: AppColors.primaryBlue,
          onTap: () {
            context.go('/merchant/${widget.merchantId}/items');
          },
        ),
        const SizedBox(height: AppDimensions.spacingMD),
        _buildActionCard(
          context,
          title: 'Inventory Management',
          subtitle: 'Track stock levels & alerts',
          icon: Icons.warehouse_outlined,
          color: Colors.teal,
          onTap: () {
            context.go('/merchant/${widget.merchantId}/inventory');
          },
        ),
        const SizedBox(height: AppDimensions.spacingMD),
        _buildActionCard(
          context,
          title: 'Daily Summary',
          subtitle: 'View sales reports',
          icon: Icons.analytics,
          color: Colors.orange,
          onTap: () {
            context.go('/merchant/${widget.merchantId}/summary');
          },
        ),
        // Kitchen Orders - Only for restaurants/food businesses
        if (!_isLoadingBusinessType && _isRestaurantBusiness())
          const SizedBox(height: AppDimensions.spacingMD),
        if (!_isLoadingBusinessType && _isRestaurantBusiness())
          _buildActionCard(
            context,
            title: 'Kitchen Orders',
            subtitle: 'View and manage orders',
            icon: Icons.restaurant,
            color: Colors.purple,
            onTap: () {
              context.go('/merchant/${widget.merchantId}/kitchen-orders');
            },
          ),
      ],
    );
  }

  /// Check if merchant is restaurant or food business
  bool _isRestaurantBusiness() {
    if (_businessType == null) return false;

    final restaurantTypes = [
      'restaurant',
      'food',
      'cafe',
      'bakery',
      'food truck',
      'catering',
    ];

    return restaurantTypes.any(
      (type) => _businessType!.toLowerCase().contains(type),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          child: Icon(icon, color: color, size: 32),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildQuickStats() {
    return Consumer<SessionProvider>(
      builder: (context, provider, child) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Session',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppDimensions.spacingSM),
                provider.hasActiveSession
                    ? Text('Session ID: ${provider.currentSession!.id}')
                    : const Text('No active session'),
              ],
            ),
          ),
        );
      },
    );
  }
}
