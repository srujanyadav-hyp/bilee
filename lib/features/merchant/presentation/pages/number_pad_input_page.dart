import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/repositories/i_merchant_repository.dart';
import '../providers/session_provider.dart';
import '../widgets/custom_number_pad.dart';

/// Number Pad Input Page
/// Fast item entry using 3-4 digit codes
/// Perfect for restaurants and businesses with frequently ordered items
///
/// Features:
/// - Large number pad (one-hand operation)
/// - Real-time item preview as you type
/// - Quantity multiplication (101×2 = 2 Biryani)
/// - Running total of added items
/// - Instant feedback
class NumberPadInputPage extends StatefulWidget {
  final String merchantId;

  const NumberPadInputPage({super.key, required this.merchantId});

  @override
  State<NumberPadInputPage> createState() => _NumberPadInputPageState();
}

class _NumberPadInputPageState extends State<NumberPadInputPage> {
  final _repository = getIt<IMerchantRepository>();

  String _currentInput = '';
  ItemEntity? _previewItem;
  bool _isSearching = false;
  final List<_AddedItemRecord> _addedItems = [];
  double _runningTotal = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Number Pad Entry',
          style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        actions: [
          if (_addedItems.isNotEmpty)
            TextButton.icon(
              onPressed: _finishAndClose,
              icon: const Icon(Icons.check_circle),
              label: const Text('Done'),
              style: TextButton.styleFrom(foregroundColor: AppColors.success),
            ),
        ],
      ),
      body: Column(
        children: [
          // Preview area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Item preview card
                  _buildPreviewCard(),

                  // Added items list
                  if (_addedItems.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(AppDimensions.paddingMD),
                      child: Divider(),
                    ),
                    _buildAddedItemsList(),

                    // Running total
                    _buildRunningTotal(),
                  ],
                ],
              ),
            ),
          ),

          // Number pad at bottom
          CustomNumberPad(
            currentInput: _currentInput,
            onDigitPressed: _handleDigitPressed,
            onClear: _handleClear,
            onMultiply: _handleMultiply,
            onEnter: _handleEnter,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingMD),
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading
          Text(
            'Item Preview',
            style: AppTypography.body2.copyWith(
              color: AppColors.lightTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingMD),

          // Preview content
          if (_isSearching)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppDimensions.paddingXL),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_previewItem != null)
            _buildItemPreview(_previewItem!)
          else
            _buildEmptyPreviewState(),
        ],
      ),
    );
  }

  Widget _buildItemPreview(ItemEntity item) {
    // Parse quantity from input (e.g., "101×2" → quantity = 2)
    int quantity = 1;
    if (_currentInput.contains('×')) {
      final parts = _currentInput.split('×');
      quantity = int.tryParse(parts[1]) ?? 1;
    }

    final subtotal = item.price * quantity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Item name
        Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 24),
            const SizedBox(width: AppDimensions.spacingXS),
            Expanded(
              child: Text(
                item.name,
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingSM),

        // Details
        _buildDetailRow('Code', item.itemCode ?? 'N/A'),
        _buildDetailRow('Price', '₹${item.price.toStringAsFixed(2)}'),
        if (quantity > 1) _buildDetailRow('Quantity', '$quantity'),

        const Divider(height: 24),

        // Subtotal
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subtotal',
              style: AppTypography.body1.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '₹${subtotal.toStringAsFixed(2)}',
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body2.copyWith(
              color: AppColors.lightTextSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.body2.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPreviewState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          children: [
            Icon(Icons.dialpad, size: 64, color: AppColors.lightTextTertiary),
            const SizedBox(height: AppDimensions.spacingMD),
            Text(
              _currentInput.isEmpty
                  ? 'Enter item code'
                  : 'Item not found for code: $_currentInput',
              style: AppTypography.body1.copyWith(
                color: AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (_currentInput.isNotEmpty && !_currentInput.contains('×'))
              Padding(
                padding: const EdgeInsets.only(top: AppDimensions.spacingSM),
                child: Text(
                  'Try a different code or press ×\nto add quantity',
                  style: AppTypography.body3.copyWith(
                    color: AppColors.lightTextTertiary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddedItemsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingMD),
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: AppColors.success.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recently Added (${_addedItems.length})',
            style: AppTypography.body2.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingSM),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _addedItems.length,
            separatorBuilder: (_, __) => const Divider(height: 12),
            itemBuilder: (context, index) {
              final record = _addedItems[index];
              return Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: AppDimensions.spacingXS),
                  Expanded(
                    flex: 3,
                    child: Text(record.itemName, style: AppTypography.body3),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${record.quantity}x ₹${record.price.toStringAsFixed(2)}',
                      style: AppTypography.body3.copyWith(
                        color: AppColors.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${record.subtotal.toStringAsFixed(2)}',
                      style: AppTypography.body3.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRunningTotal() {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingMD),
      padding: const EdgeInsets.all(AppDimensions.paddingLG),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Amount',
            style: AppTypography.h5.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '₹${_runningTotal.toStringAsFixed(2)}',
            style: AppTypography.h3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== INPUT HANDLERS ====================

  void _handleDigitPressed(String digit) {
    setState(() {
      _currentInput += digit;
    });

    // Auto-search when 3+ digits (and no ×)
    if (_currentInput.length >= 3 && !_currentInput.contains('×')) {
      _searchItem(_currentInput);
    }
  }

  void _handleClear() {
    setState(() {
      _currentInput = '';
      _previewItem = null;
      _isSearching = false;
    });
  }

  void _handleMultiply() {
    // Only add × if we have a code and don't already have ×
    if (_currentInput.isNotEmpty && !_currentInput.contains('×')) {
      setState(() {
        _currentInput += '×';
        // Keep the preview item
      });
    }
  }

  void _handleEnter() {
    if (_previewItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid item code'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Add to cart
    _addItemToCart(_previewItem!);
  }

  // ==================== BUSINESS LOGIC ====================

  Future<void> _searchItem(String code) async {
    setState(() {
      _isSearching = true;
      _previewItem = null;
    });

    try {
      final item = await _repository.searchItemByCode(widget.merchantId, code);

      if (mounted) {
        setState(() {
          _previewItem = item;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _addItemToCart(ItemEntity item) {
    // Parse quantity from input
    int quantity = 1;
    if (_currentInput.contains('×')) {
      final parts = _currentInput.split('×');
      quantity = int.tryParse(parts[1]) ?? 1;

      if (quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quantity must be greater than 0'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    final subtotal = item.price * quantity;

    // Add to session provider
    final sessionProvider = context.read<SessionProvider>();
    for (int i = 0; i < quantity; i++) {
      sessionProvider.addToCart(item);
    }

    // Record for display
    setState(() {
      _addedItems.add(
        _AddedItemRecord(
          itemName: item.name,
          quantity: quantity,
          price: item.price,
          subtotal: subtotal,
        ),
      );
      _runningTotal += subtotal;

      // Reset for next item
      _currentInput = '';
      _previewItem = null;
    });

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text('✅ Added $quantity x ${item.name}')),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _finishAndClose() {
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Added ${_addedItems.length} items to cart (₹${_runningTotal.toStringAsFixed(2)})',
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Internal record for tracking added items
class _AddedItemRecord {
  final String itemName;
  final int quantity;
  final double price;
  final double subtotal;

  _AddedItemRecord({
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });
}
