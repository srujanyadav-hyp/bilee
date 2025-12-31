import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/monthly_archive_provider.dart';
import '../widgets/customer_bottom_nav.dart';

/// Screen to view all monthly summaries
class MonthlySummariesListScreen extends StatefulWidget {
  const MonthlySummariesListScreen({super.key});

  @override
  State<MonthlySummariesListScreen> createState() =>
      _MonthlySummariesListScreenState();
}

class _MonthlySummariesListScreenState
    extends State<MonthlySummariesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MonthlyArchiveProvider>().loadSummaries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Monthly Reports'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: Consumer<MonthlyArchiveProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading summaries',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => provider.loadSummaries(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final summaries = provider.summaries;

          if (summaries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.archive_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Monthly Reports Yet',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Text(
                      'Archive your receipts to create monthly summaries and track your spending over time',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: summaries.length,
            itemBuilder: (context, index) {
              final summary = summaries[index];
              final monthDate = DateTime(summary.year, summary.monthNumber);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () =>
                      context.push('/customer/monthly-summary/${summary.id}'),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('MMMM yyyy').format(monthDate),
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.lightTextPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('MMM d').format(monthDate) +
                                        ' - ' +
                                        DateFormat('MMM d, yyyy').format(
                                          DateTime(
                                            summary.year,
                                            summary.monthNumber + 1,
                                            0,
                                          ),
                                        ),
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey[400]),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Total Amount
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Spending',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                              Text(
                                '₹${summary.grandTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Stats
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.receipt_outlined,
                                label: 'Receipts',
                                value: '${summary.totalReceipts}',
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.archive_outlined,
                                label: 'Archived',
                                value: '${summary.archivedCount}',
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.bookmark_outline,
                                label: 'Kept',
                                value: '${summary.keptCount}',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Top Categories Preview
                        if (summary.categories.isNotEmpty) ...[
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            'Top Categories',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...summary.categories.take(3).map((category) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Text(
                                    category.icon,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      category.name,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₹${category.total.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.lightTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const CustomerBottomNav(currentRoute: '/customer'),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryBlue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.lightTextPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
