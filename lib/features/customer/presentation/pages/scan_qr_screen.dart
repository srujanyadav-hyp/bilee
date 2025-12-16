import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/live_bill_provider.dart';

/// Scan QR Screen - Scanner for merchant session QR
class ScanQRScreen extends StatefulWidget {
  const ScanQRScreen({super.key});

  @override
  State<ScanQRScreen> createState() => _ScanQRScreenState();
}

class _ScanQRScreenState extends State<ScanQRScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onQRCodeDetected(BarcodeCapture barcodeCapture) async {
    if (_isProcessing) return;

    final String? code = barcodeCapture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // Extract session ID from QR code
      // Expected format: "bilee://session/{sessionId}"
      final sessionId = _extractSessionId(code);

      if (sessionId == null) {
        _showError('Invalid QR code');
        setState(() => _isProcessing = false);
        return;
      }

      // Connect to session
      final provider = context.read<LiveBillProvider>();
      await provider.connectToSession(sessionId);

      if (!mounted) return;

      // Navigate to live bill screen
      context.pushReplacement('/customer/live-bill/$sessionId');
    } catch (e) {
      _showError('Failed to connect: ${e.toString()}');
      setState(() => _isProcessing = false);
    }
  }

  String? _extractSessionId(String qrCode) {
    // Parse different QR code formats
    if (qrCode.startsWith('bilee://session/')) {
      return qrCode.replaceFirst('bilee://session/', '');
    }
    if (qrCode.startsWith('https://bilee.app/session/')) {
      return qrCode.replaceFirst('https://bilee.app/session/', '');
    }
    // Fallback: assume it's just the session ID
    if (qrCode.length > 10 && !qrCode.contains(' ')) {
      return qrCode;
    }
    return null;
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: _scannerController,
            onDetect: _onQRCodeDetected,
          ),

          // Overlay
          _buildOverlay(),

          // Top Bar
          _buildTopBar(),

          // Bottom Instructions
          _buildBottomInstructions(),

          // Processing Indicator
          if (_isProcessing) _buildProcessingIndicator(),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return CustomPaint(painter: ScannerOverlayPainter(), child: Container());
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back Button
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),

            // Torch Toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Icon(
                  _scannerController.torchEnabled
                      ? Icons.flash_on
                      : Icons.flash_off,
                  color: Colors.white,
                ),
                onPressed: () => _scannerController.toggleTorch(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInstructions() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.qr_code_scanner_outlined,
                size: 48,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Scan merchant QR to view your bill',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Position the QR code within the frame',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Connecting to session...',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final double scanAreaSize = size.width * 0.7;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;

    // Draw dark overlay with transparent square
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
          const Radius.circular(20),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw corner indicators
    final cornerPaint = Paint()
      ..color = AppColors.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(
      Offset(left, top + cornerLength),
      Offset(left, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(left + scanAreaSize - cornerLength, top),
      Offset(left + scanAreaSize, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize, top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(left, top + scanAreaSize - cornerLength),
      Offset(left, top + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left + cornerLength, top + scanAreaSize),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(left + scanAreaSize - cornerLength, top + scanAreaSize),
      Offset(left + scanAreaSize, top + scanAreaSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize - cornerLength),
      Offset(left + scanAreaSize, top + scanAreaSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
