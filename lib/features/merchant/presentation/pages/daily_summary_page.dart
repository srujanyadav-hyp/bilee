import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../providers/daily_aggregate_provider.dart';

/// Daily Summary Page - View daily sales analytics
class DailySummaryPage extends StatefulWidget {
  final String merchantId;

  const DailySummaryPage({super.key, required this.merchantId});

  @override
  State<DailySummaryPage> createState() => _DailySummaryPageState();
}

class _DailySummaryPageState extends State<DailySummaryPage> {
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DailyAggregateProvider>().loadAggregateForDate(
        widget.merchantId,
        selectedDate,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Daily Summary'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2024),
                lastDate: DateTime.now(),
              );
              if (date != null && mounted) {
                setState(() => selectedDate = date);
                context.read<DailyAggregateProvider>().loadAggregateForDate(
                  widget.merchantId,
                  date,
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<DailyAggregateProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final aggregate = provider.selectedDateAggregate;

          if (aggregate == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.analytics_outlined, size: 64),
                  const SizedBox(height: AppDimensions.spacingMD),
                  const Text('No data for selected date'),
                  const SizedBox(height: AppDimensions.spacingMD),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Select Date'),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                      );
                      if (date != null && mounted) {
                        setState(() => selectedDate = date);
                        provider.loadAggregateForDate(widget.merchantId, date);
                      }
                    },
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingLG),
                    child: Column(
                      children: [
                        Text(
                          'Summary for ${aggregate.date}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: AppDimensions.spacingLG),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMetric(
                              'Revenue',
                              '₹${aggregate.totalRevenue.toStringAsFixed(2)}',
                              Icons.currency_rupee,
                            ),
                            _buildMetric(
                              'Orders',
                              aggregate.totalOrders.toString(),
                              Icons.receipt,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLG),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.paddingLG),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Items Sold',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(),
                        if (aggregate.items.isEmpty)
                          const Text('No items sold')
                        else
                          ...aggregate.items.map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${item.name} × ${item.quantity}'),
                                  Text('₹${item.revenue.toStringAsFixed(2)}'),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLG),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Export PDF'),
                        onPressed: () {
                          provider.generateReport(
                            widget.merchantId,
                            selectedDate,
                            'pdf',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Generating PDF report...'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spacingMD),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.table_chart),
                        label: const Text('Export CSV'),
                        onPressed: () {
                          provider.generateReport(
                            widget.merchantId,
                            selectedDate,
                            'csv',
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Generating CSV report...'),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetric(String label, String value, IconData icon) {
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
}
