import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';

/// Barcode Scanner Page Widget
/// Scans product barcodes/QR codes and returns the scanned value
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final String? code = barcode.rawValue;

    if (code != null && code.isNotEmpty) {
      setState(() => _isScanned = true);

      // Return the scanned barcode value
      Navigator.of(context).pop(code);
    }
  }

  void _toggleFlash() {
    _controller.toggleTorch();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Scan Barcode',
          style: AppTypography.h3.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: _toggleFlash,
            tooltip: 'Toggle Flash',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(controller: _controller, onDetect: _onBarcodeDetect),

          // Overlay with scanning frame
          CustomPaint(painter: ScannerOverlay(), child: Container()),

          // Instructions
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.paddingLG),
              margin: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingXL,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: AppColors.primaryBlue,
                    size: 40,
                  ),
                  const SizedBox(height: AppDimensions.spacingMD),
                  Text(
                    'Position barcode within the frame',
                    style: AppTypography.body1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    'Scanning will happen automatically',
                    style: AppTypography.body2.copyWith(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for scanner overlay with frame
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
    final cornerRadius = 8.0;

    // Top-left corner
    canvas.drawRRect(
      RRect.fromLTRBR(
        left,
        top,
        left + cornerLength,
        top + cornerLength,
        Radius.circular(cornerRadius),
      ),
      framePaint,
    );

    // Top-right corner
    canvas.drawRRect(
      RRect.fromLTRBR(
        left + scanAreaWidth - cornerLength,
        top,
        left + scanAreaWidth,
        top + cornerLength,
        Radius.circular(cornerRadius),
      ),
      framePaint,
    );

    // Bottom-left corner
    canvas.drawRRect(
      RRect.fromLTRBR(
        left,
        top + scanAreaHeight - cornerLength,
        left + cornerLength,
        top + scanAreaHeight,
        Radius.circular(cornerRadius),
      ),
      framePaint,
    );

    // Bottom-right corner
    canvas.drawRRect(
      RRect.fromLTRBR(
        left + scanAreaWidth - cornerLength,
        top + scanAreaHeight - cornerLength,
        left + scanAreaWidth,
        top + scanAreaHeight,
        Radius.circular(cornerRadius),
      ),
      framePaint,
    );

    // Draw scanning line animation
    final linePaint = Paint()
      ..color = AppColors.primaryBlue.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(left, top + scanAreaHeight / 2),
      Offset(left + scanAreaWidth, top + scanAreaHeight / 2),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
