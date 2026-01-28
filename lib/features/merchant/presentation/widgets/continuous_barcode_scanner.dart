import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/dependency_injection.dart';
import '../../domain/repositories/i_merchant_repository.dart';
import '../../domain/entities/item_entity.dart';
import '../providers/session_provider.dart';

/// Continuous Barcode Scanner Page
/// Allows scanning multiple items without closing the scanner
/// Features: Auto-add, sound/haptic feedback, mini cart preview
class ContinuousBarcodeScannerPage extends StatefulWidget {
  final String merchantId;

  const ContinuousBarcodeScannerPage({super.key, required this.merchantId});

  @override
  State<ContinuousBarcodeScannerPage> createState() =>
      _ContinuousBarcodeScannerPageState();
}

class _ContinuousBarcodeScannerPageState
    extends State<ContinuousBarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  final bool _isContinuousMode = true;
  bool _showMiniCart = true;
  bool _isProcessing = false;
  String? _lastScannedBarcode;
  DateTime? _lastScanTime;

  // Track scanned items for display
  final List<ScannedItemInfo> _scannedItems = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final String? code = barcode.rawValue;

    if (code == null || code.isEmpty) return;

    // Prevent duplicate scans within 2 seconds
    if (_lastScannedBarcode == code &&
        _lastScanTime != null &&
        DateTime.now().difference(_lastScanTime!) <
            const Duration(seconds: 2)) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _lastScannedBarcode = code;
      _lastScanTime = DateTime.now();
    });

    await _processBarcode(code);

    if (_isContinuousMode) {
      // In continuous mode, keep scanning
      setState(() => _isProcessing = false);
    } else {
      // In single mode, close after scan
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _processBarcode(String barcode) async {
    try {
      // Search for item by barcode
      final repository = getIt<IMerchantRepository>();
      final item = await repository.searchItemByBarcode(
        widget.merchantId,
        barcode,
      );

      if (!mounted) return;

      if (item != null) {
        // Check if item is already in cart (duplicate scan detection)
        final sessionProvider = context.read<SessionProvider>();
        final existingItemIndex = sessionProvider.cartItems.indexWhere(
          (cartItem) => cartItem.name == item.name,
        );

        if (existingItemIndex != -1) {
          // Item already in cart - increment quantity
          final existingItem = sessionProvider.cartItems[existingItemIndex];
          final currentQty = existingItem.qty;
          sessionProvider.addToCart(item, quantity: 1);

          // Success feedback
          _playSuccessSound();
          HapticFeedback.mediumImpact();

          // Show increment message
          _showQuantityIncrementOverlay(item.name, currentQty + 1);
        } else {
          // New item - add to cart
          sessionProvider.addToCart(item);

          // Success feedback
          _playSuccessSound();
          HapticFeedback.mediumImpact();

          // Show success indicator
          _showSuccessOverlay(item.name);
        }

        // Add/update scanned items list
        setState(() {
          final existingScannedIndex = _scannedItems.indexWhere(
            (scanned) => scanned.name == item.name,
          );

          if (existingScannedIndex != -1) {
            // Update existing scanned item
            _scannedItems[existingScannedIndex] = ScannedItemInfo(
              name: item.name,
              price: item.price,
              barcode: barcode,
              timestamp: DateTime.now(),
              quantity: sessionProvider.cartItems
                  .firstWhere((ci) => ci.name == item.name)
                  .qty
                  .toInt(),
            );
          } else {
            // Add new scanned item
            _scannedItems.insert(
              0,
              ScannedItemInfo(
                name: item.name,
                price: item.price,
                barcode: barcode,
                timestamp: DateTime.now(),
                quantity: 1,
              ),
            );
          }
        });
      } else {
        // Item not found
        _playErrorSound();
        HapticFeedback.heavyImpact();
        _showNotFoundDialog(barcode);
      }
    } catch (e) {
      if (mounted) {
        _playErrorSound();
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  void _playSuccessSound() {
    // Use system sound for success
    SystemSound.play(SystemSoundType.click);
  }

  void _playErrorSound() {
    // Use system sound for error
    SystemSound.play(SystemSoundType.alert);
  }

  void _showQuantityIncrementOverlay(String itemName, double newQty) {
    // Show a brief blue flash overlay for quantity increment
    if (!mounted) return;

    final overlay = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: AnimatedOpacity(
            opacity: 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              color: AppColors.primaryBlue.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        '$itemName: ${newQty.toInt()}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlay);
    Future.delayed(const Duration(milliseconds: 500), () {
      overlay.remove();
    });
  }

  void _showSuccessOverlay(String itemName) {
    // Show a brief green flash overlay
    if (!mounted) return;

    final overlay = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: AnimatedOpacity(
            opacity: 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              color: AppColors.success.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Added: $itemName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlay);
    Future.delayed(const Duration(milliseconds: 500), () {
      overlay.remove();
    });
  }

  void _showNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Item Not Found'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Barcode: $barcode'),
            const SizedBox(height: 16),
            const Text('This item is not in your library.'),
            const Text('Would you like to add it?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() => _isProcessing = false);
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showAddItemDialog(barcode);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(String barcode) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
                prefixText: '₹',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() => _isProcessing = false);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final priceText = priceController.text.trim();

              if (name.isEmpty || priceText.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final price = double.tryParse(priceText);
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid price'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);
              _addTemporaryItem(name, price, barcode);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }

  void _addTemporaryItem(String name, double price, String barcode) {
    final sessionProvider = context.read<SessionProvider>();
    sessionProvider.addTemporaryItemToCart(
      name: name,
      price: price,
      barcode: barcode,
    );

    setState(() {
      _scannedItems.insert(
        0,
        ScannedItemInfo(
          name: name,
          price: price,
          barcode: barcode,
          timestamp: DateTime.now(),
        ),
      );
      _isProcessing = false;
    });

    _playSuccessSound();
    HapticFeedback.mediumImpact();
    _showSuccessOverlay(name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera view
          MobileScanner(controller: _controller, onDetect: _onBarcodeDetect),

          // Overlay with scanning frame
          CustomPaint(painter: ScannerOverlay(), child: Container()),

          // Top bar
          _buildTopBar(),

          // Mini cart (bottom)
          if (_showMiniCart) _buildMiniCart(),

          // Processing indicator
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Close button
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () =>
                    Navigator.pop(context, _scannedItems.isNotEmpty),
              ),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Scan Barcodes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_scannedItems.length} items scanned',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Torch toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: ValueListenableBuilder(
                  valueListenable: _controller,
                  builder: (context, state, child) {
                    return Icon(
                      state.torchState == TorchState.on
                          ? Icons.flash_on
                          : Icons.flash_off,
                      color: Colors.white,
                    );
                  },
                ),
                onPressed: () => _controller.toggleTorch(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCart() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Consumer<SessionProvider>(
          builder: (context, provider, _) {
            if (provider.cartItems.isEmpty) {
              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Scan items to add to cart',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cart summary header
                  InkWell(
                    onTap: () => setState(() => _showMiniCart = !_showMiniCart),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shopping_cart,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${provider.cartItems.length} items',
                                  style: AppTypography.body1.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${provider.cartTotal.toStringAsFixed(2)}',
                                  style: AppTypography.h4.copyWith(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Scanner overlay painter
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaWidth = size.width * 0.7;
    final double scanAreaHeight = size.height * 0.3;
    final double left = (size.width - scanAreaWidth) / 2;
    final double top = (size.height - scanAreaHeight) / 2;

    // Draw semi-transparent overlay
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), backgroundPaint);
    canvas.drawRect(
      Rect.fromLTWH(0, top, left, scanAreaHeight),
      backgroundPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(left + scanAreaWidth, top, left, scanAreaHeight),
      backgroundPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, top + scanAreaHeight, size.width, size.height),
      backgroundPaint,
    );

    // Draw corner brackets
    final framePaint = Paint()
      ..color = AppColors.primaryBlue
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final cornerLength = 30.0;

    // Top-left
    canvas.drawLine(
      Offset(left, top + cornerLength),
      Offset(left, top),
      framePaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      framePaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(left + scanAreaWidth - cornerLength, top),
      Offset(left + scanAreaWidth, top),
      framePaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaWidth, top),
      Offset(left + scanAreaWidth, top + cornerLength),
      framePaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(left, top + scanAreaHeight - cornerLength),
      Offset(left, top + scanAreaHeight),
      framePaint,
    );
    canvas.drawLine(
      Offset(left, top + scanAreaHeight),
      Offset(left + cornerLength, top + scanAreaHeight),
      framePaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(left + scanAreaWidth - cornerLength, top + scanAreaHeight),
      Offset(left + scanAreaWidth, top + scanAreaHeight),
      framePaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaWidth, top + scanAreaHeight - cornerLength),
      Offset(left + scanAreaWidth, top + scanAreaHeight),
      framePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Model for scanned item info
class ScannedItemInfo {
  final String name;
  final double price;
  final String barcode;
  final DateTime timestamp;
  final int quantity;

  ScannedItemInfo({
    required this.name,
    required this.price,
    required this.barcode,
    required this.timestamp,
    this.quantity = 1,
  });
}
