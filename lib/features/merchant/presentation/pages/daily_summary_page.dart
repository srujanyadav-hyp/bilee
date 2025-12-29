import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/services/pdf_report_service.dart';
import '../providers/daily_aggregate_provider.dart';
import '../providers/merchant_provider.dart';

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
                          'Summary for ${DateFormat('MMMM dd, yyyy').format(DateTime.parse(aggregate.date))}',
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(AppDimensions.paddingMD),
                      backgroundColor: AppColors.primaryBlue,
                    ),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Generate PDF Report'),
                    onPressed: () =>
                        _handleGeneratePDF(context, provider, aggregate),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Generate PDF report using Flutter (NO Cloud Function!)
  /// COST OPTIMIZATION: Saves $50-200/month by avoiding Puppeteer server costs
  Future<void> _handleGeneratePDF(
    BuildContext context,
    DailyAggregateProvider provider,
    dynamic aggregate,
  ) async {
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text('Generating PDF report...'),
          ],
        ),
        duration: Duration(seconds: 5),
      ),
    );

    try {
      // Get merchant profile for business details
      final merchantProvider = context.read<MerchantProvider>();
      final merchantProfile = merchantProvider.profile;

      // Create PDF service
      final pdfService = PDFReportService();

      // Generate PDF locally (no server call!)
      final pdfBytes = await pdfService.generateDailyReport(
        aggregate: aggregate,
        merchantName: merchantProfile?.businessName ?? 'MY BUSINESS',
        merchantAddress: merchantProfile?.businessAddress,
        merchantPhone: merchantProfile?.businessPhone,
        merchantGst: merchantProfile?.gstNumber,
        logoUrl: merchantProfile?.logoUrl,
      );

      if (!mounted) return;

      // Clear loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Generate filename
      final filename = 'bilee_report_${aggregate.date}.pdf';

      // Share PDF (opens share dialog on mobile, downloads on web)
      await pdfService.sharePDF(pdfBytes: pdfBytes, filename: filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('PDF report generated successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: ${e.toString()}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
    }
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
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.lightTextSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
