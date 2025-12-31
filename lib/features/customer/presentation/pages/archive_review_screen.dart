import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/receipt_entity.dart';
import '../../domain/entities/monthly_summary_entity.dart';
import '../providers/receipt_provider.dart';
import '../providers/monthly_archive_provider.dart';

/// Screen to review and select receipts for archival
class ArchiveReviewScreen extends StatefulWidget {
  final int year;
  final int month;

  const ArchiveReviewScreen({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  State<ArchiveReviewScreen> createState() => _ArchiveReviewScreenState();
}

class _ArchiveReviewScreenState extends State<ArchiveReviewScreen> {
  List<ReceiptEntity> _receipts = [];
  Set<String> _selectedToArchive = {};
  Set<String> _selectedToKeep = {};
  bool _isLoading = true;
  String _filter = 'all'; // all, important, high_amount

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() => _isLoading = true);

    try {
      final provider = context.read<ReceiptProvider>();
      final receipts = await provider.getReceiptsForMonth(
        year: widget.year,
        month: widget.month,
      );

      // Get important receipt IDs
      final importantIds = provider.getImportantReceiptIds(receipts);

      setState(() {
        _receipts = receipts;
        _selectedToKeep = importantIds.toSet();
        _selectedToArchive = receipts
            .where((r) => !importantIds.contains(r.id))
            .map((r) => r.id)
            .toSet();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading receipts: $e')));
    }
  }

  List<ReceiptEntity> _getFilteredReceipts() {
    switch (_filter) {
      case 'important':
        return _receipts.where((r) => _selectedToKeep.contains(r.id)).toList();
      case 'high_amount':
        return _receipts.where((r) => r.total >= 10000).toList();
      default:
        return _receipts;
    }
  }

  void _toggleReceipt(String receiptId) {
    setState(() {
      if (_selectedToKeep.contains(receiptId)) {
        _selectedToKeep.remove(receiptId);
        _selectedToArchive.add(receiptId);
      } else {
        _selectedToArchive.remove(receiptId);
        _selectedToKeep.add(receiptId);
      }
    });
  }

  Future<void> _archive() async {
    if (_selectedToArchive.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No receipts selected for archival')),
      );
      return;
    }

    // Show confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Archive'),
        content: Text(
          'Archive ${_selectedToArchive.length} receipts and keep ${_selectedToKeep.length}?\n\nThis cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
            ),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final receiptProvider = context.read<ReceiptProvider>();
      final archiveProvider = context.read<MonthlyArchiveProvider>();

      // Calculate category summaries
      final categories = receiptProvider.calculateCategorySummaries(_receipts);

      // Create monthly summary
      final monthStr =
          '${widget.year}-${widget.month.toString().padLeft(2, '0')}';
      final grandTotal = _receipts.fold(0.0, (sum, r) => sum + r.total);

      // Get current user ID with extensive debugging
      final currentUser = FirebaseAuth.instance.currentUser;
      debugPrint('🔐 Current User: $currentUser');
      debugPrint('🔐 User ID: ${currentUser?.uid}');
      debugPrint('🔐 User Email: ${currentUser?.email}');
      debugPrint('🔐 Is Anonymous: ${currentUser?.isAnonymous}');

      final userId = currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('✅ Using userId for summary: $userId');

      final summary = MonthlySummaryEntity(
        id: 'MS_${widget.year}_${widget.month}',
        userId: userId,
        month: monthStr,
        year: widget.year,
        monthNumber: widget.month,
        categories: categories
            .map(
              (cat) => CategorySummary(
                name: cat['name'] as String,
                icon: cat['icon'] as String,
                total: cat['total'] as double,
                count: cat['count'] as int,
                percentage: cat['percentage'] as double,
              ),
            )
            .toList(),
        grandTotal: grandTotal,
        totalReceipts: _receipts.length,
        archivedCount: _selectedToArchive.length,
        keptCount: _selectedToKeep.length,
        createdAt: DateTime.now(),
      );

      // Archive
      await archiveProvider.archiveMonth(
        year: widget.year,
        month: widget.month,
        receiptIdsToArchive: _selectedToArchive.toList(),
        receiptIdsToKeep: _selectedToKeep.toList(),
        summary: summary,
      );

      if (!mounted) return;

      // Reload summaries so banner will hide on home screen
      await archiveProvider.loadSummaries();

      // Close loading
      Navigator.pop(context);

      // Navigate back to home
      context.pop();

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Archived ${_selectedToArchive.length} receipts successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Close loading
      Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error archiving: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthName = DateFormat(
      'MMMM yyyy',
    ).format(DateTime(widget.year, widget.month));

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: Text('Archive $monthName'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filter chips
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text(
                            'All',
                            style: TextStyle(color: AppColors.lightTextPrimary),
                          ),
                          selected: _filter == 'all',
                          onSelected: (_) => setState(() => _filter = 'all'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(
                            'Important (${_selectedToKeep.length})',
                            style: const TextStyle(
                              color: AppColors.lightTextPrimary,
                            ),
                          ),
                          selected: _filter == 'important',
                          onSelected: (_) =>
                              setState(() => _filter = 'important'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text(
                            '> ₹10k',
                            style: TextStyle(color: AppColors.lightTextPrimary),
                          ),
                          selected: _filter == 'high_amount',
                          onSelected: (_) =>
                              setState(() => _filter = 'high_amount'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Receipt list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _getFilteredReceipts().length,
                    itemBuilder: (context, index) {
                      final receipt = _getFilteredReceipts()[index];
                      final isKeep = _selectedToKeep.contains(receipt.id);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: CheckboxListTile(
                          value: isKeep,
                          onChanged: (_) => _toggleReceipt(receipt.id),
                          title: Text(
                            receipt.merchantName,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                receipt.businessCategory ?? 'Other',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                DateFormat(
                                  'MMM dd, yyyy',
                                ).format(receipt.createdAt),
                                style: const TextStyle(fontSize: 11),
                              ),
                              if (receipt.notes?.isNotEmpty == true)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[100],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '📝 Has notes',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                            ],
                          ),
                          secondary: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${receipt.total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                isKeep ? 'Keep' : 'Archive',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isKeep ? Colors.green : Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Bottom bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Archive: ${_selectedToArchive.length}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Keep: ${_selectedToKeep.length}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.pop(),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _archive,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                'Archive ${_selectedToArchive.length} Receipts',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
