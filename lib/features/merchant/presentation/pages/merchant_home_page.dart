import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../providers/daily_aggregate_provider.dart';
import '../providers/session_provider.dart';

/// Merchant Home Page - Dashboard with navigation to all features
class MerchantHomePage extends StatefulWidget {
  final String merchantId;

  const MerchantHomePage({super.key, required this.merchantId});

  @override
  State<MerchantHomePage> createState() => _MerchantHomePageState();
}

class _MerchantHomePageState extends State<MerchantHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DailyAggregateProvider>().loadTodayAggregate(
        widget.merchantId,
      );
    });
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
          title: 'Daily Summary',
          subtitle: 'View sales reports',
          icon: Icons.analytics,
          color: Colors.orange,
          onTap: () {
            context.go('/merchant/${widget.merchantId}/summary');
          },
        ),
      ],
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
