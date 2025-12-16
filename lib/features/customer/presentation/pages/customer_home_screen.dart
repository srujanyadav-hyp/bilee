import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../providers/receipt_provider.dart';
import '../widgets/customer_bottom_nav.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceiptProvider>().loadRecentReceipts(limit: 3);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () => context.push('/customer/profile'),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<ReceiptProvider>().loadRecentReceipts(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Recent Receipts Section
              _buildRecentReceiptsSection(context),
            ],
          ),
        ),
      ),
      floatingActionButton: const CustomerFloatingScanButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomerBottomNav(currentRoute: '/customer'),
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
}
