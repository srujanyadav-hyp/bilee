import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../providers/receipt_provider.dart';
import '../providers/budget_provider.dart';
import '../widgets/customer_bottom_nav.dart';
import '../widgets/budget_progress_card.dart';
import 'package:intl/intl.dart';

/// Customer Home Screen - Entry point for customers
class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('🏠 [CustomerHome] initState - loading receipts');
    // Use post-frame callback to ensure context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReceipts();
    });
  }

  Future<void> _loadReceipts() async {
    debugPrint('📱 [CustomerHome] Loading receipts...');
    await context.read<ReceiptProvider>().loadRecentReceipts(limit: 3);
    await context
        .read<ReceiptProvider>()
        .loadAllReceipts(); // Load all for analytics
    debugPrint('✅ [CustomerHome] Receipts loaded');

    // Load budgets for the current user
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      debugPrint('💰 [CustomerHome] Loading budgets for user: $userId');
      await context.read<BudgetProvider>().loadBudgets(userId);
      debugPrint('✅ [CustomerHome] Budgets loaded');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 24),
            onPressed: () => context.push('/customer/budget-settings'),
            tooltip: 'Budget Settings',
          ),
          IconButton(
            icon: const Icon(Icons.person, size: 28),
            onPressed: () => context.push('/customer/profile'),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ReceiptProvider>().loadRecentReceipts();
          await context.read<ReceiptProvider>().loadAllReceipts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: AppDimensions.paddingMD,
            right: AppDimensions.paddingMD,
            top: AppDimensions.paddingMD,
            bottom: 60 + MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Monthly Spending Analytics
              _buildMonthlySpendingSection(context),
              const SizedBox(height: 24),

              // Budget Alerts Section
              _buildBudgetAlertsSection(context),
              const SizedBox(height: 24),

              // Recent Receipts Section
              _buildRecentReceiptsSection(context),
            ],
          ),
        ),
      ),
      floatingActionButton: CustomerFloatingScanButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomerBottomNav(currentRoute: '/customer'),
    );
  }

  Widget _buildRecentReceiptsSection(BuildContext context) {
    return Consumer<ReceiptProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!provider.hasRecentReceipts) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Receipts',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/customer/receipts'),
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...provider.recentReceipts.map(
              (receipt) => _buildReceiptCard(context, receipt),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReceiptCard(BuildContext context, receipt) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingSM),
      decoration: BoxDecoration(
        color: AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.lightBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/customer/receipt/${receipt.id}'),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMD),
            child: Row(
              children: [
                // Merchant Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
                  ),
                  child: const Icon(
                    Icons.store_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Receipt Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receipt.merchantName,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.lightTextPrimary,
                        ),
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
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                    if (receipt.isVerified)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_outlined,
                              size: 12,
                              color: AppColors.success,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ),
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
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
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
              'No receipts yet',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan a bill to get started',
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

  Widget _buildMonthlySpendingSection(BuildContext context) {
    return Consumer<ReceiptProvider>(
      builder: (context, provider, child) {
        final categorySpending = provider.getMonthlySpendingByCategory();
        final totalSpending = provider.getTotalMonthlySpending();

        if (categorySpending.isEmpty) {
          return const SizedBox.shrink();
        }

        final topCategories = categorySpending.entries.take(6).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with total
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'This Month',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${totalSpending.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Donut Chart
                  SizedBox(
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 60,
                        sections: _buildPieChartSections(
                          topCategories,
                          totalSpending,
                        ),
                        pieTouchData: PieTouchData(enabled: false),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Legend - Explain what percentages mean
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: topCategories.asMap().entries.map((entry) {
                      final index = entry.key;
                      final category = entry.value.key;
                      final color = _getCategoryColor(category, index);

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Category Cards Grid - Responsive
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate optimal cross axis count based on screen width
                final screenWidth = constraints.maxWidth;
                final crossAxisCount = screenWidth > 400
                    ? 2
                    : 2; // Always 2 for phones
                final cardWidth =
                    (screenWidth - 12) / crossAxisCount; // Subtract spacing
                final cardHeight = cardWidth * 0.7; // Height is 70% of width
                final aspectRatio = cardWidth / cardHeight;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: aspectRatio,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: topCategories.length,
                  itemBuilder: (context, index) {
                    final entry = topCategories[index];
                    final category = entry.key;
                    final amount = entry.value;
                    final icon = ReceiptProvider.getCategoryIcon(category);
                    final color = _getCategoryColor(category, index);

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    icon,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.lightTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹${amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    List<MapEntry<String, double>> categories,
    double total,
  ) {
    return categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value.key;
      final amount = entry.value.value;
      final percentage = (amount / total) * 100;
      final color = _getCategoryColor(category, index);

      return PieChartSectionData(
        color: color,
        value: amount,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 35,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: 'Inter',
        ),
      );
    }).toList();
  }

  Color _getCategoryColor(String category, int index) {
    // Use theme colors (teal to blue gradient) with variations
    final themeColors = [
      AppColors.primaryBlue, // #00D4AA - Teal-Green
      AppColors.primaryBlueLight, // #1E5BFF - Blue
      const Color(0xFF00B894), // Darker Teal
      const Color(0xFF0095E8), // Light Blue
      const Color(0xFF00A8A8), // Cyan
      const Color(0xFF5570FF), // Lighter Blue
    ];

    // Return color based on index, cycling through theme colors
    return themeColors[index % themeColors.length];
  }

  /// Budget Alerts Section - Show budget progress and alerts
  Widget _buildBudgetAlertsSection(BuildContext context) {
    return Consumer<BudgetProvider>(
      builder: (context, budgetProvider, child) {
        // Don't show section if no budgets or alerts
        if (budgetProvider.budgets.isEmpty) {
          return const SizedBox.shrink();
        }

        // Show only budgets that need attention (>=80% or exceeded)
        final budgetsToShow = budgetProvider.budgetsNeedingAlert;

        // If no alerts, don't show section
        if (budgetsToShow.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: Colors.orange,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Budget Alerts',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.push('/customer/budget-settings'),
                  child: const Text(
                    'Manage',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...budgetsToShow.map(
              (progress) => BudgetProgressCard(
                progress: progress,
                onTap: () => context.push('/customer/budget-settings'),
              ),
            ),
          ],
        );
      },
    );
  }
}
