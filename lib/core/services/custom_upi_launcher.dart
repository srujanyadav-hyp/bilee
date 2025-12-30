import 'dart:typed_data';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Represents a UPI app with its display name and package name
class UpiAppInfo {
  final String name;
  final String packageName;
  final bool requiresParams;

  UpiAppInfo({
    required this.name,
    required this.packageName,
    this.requiresParams = true,
  });
}

/// List of popular UPI apps and their package names (including wallet apps)
final List<UpiAppInfo> upiApps = [
  UpiAppInfo(
    name: 'PhonePe',
    packageName: 'com.phonepe.app',
    requiresParams: true,
  ),
  UpiAppInfo(
    name: 'Google Pay',
    packageName: 'com.google.android.apps.nbu.paisa.user',
    requiresParams: true,
  ),
  UpiAppInfo(
    name: 'Paytm',
    packageName: 'net.one97.paytm',
    requiresParams: true,
  ),
  UpiAppInfo(
    name: 'Amazon Pay',
    packageName: 'in.amazon.mShop.android.shopping',
    requiresParams: true,
  ),
  UpiAppInfo(
    name: 'BHIM',
    packageName: 'in.org.npci.upiapp',
    requiresParams: true,
  ),
  UpiAppInfo(
    name: 'Samsung Pay',
    packageName: 'com.samsung.android.spay',
    requiresParams: true,
  ),
  UpiAppInfo(
    name: 'Samsung Wallet',
    packageName: 'com.samsung.android.spaymini',
    requiresParams: true,
  ),
  UpiAppInfo(
    name: 'Mobikwik',
    packageName: 'com.mobikwik_new',
    requiresParams: true,
  ),
  UpiAppInfo(
    name: 'Freecharge',
    packageName: 'com.freecharge.android',
    requiresParams: true,
  ),
  // Add more as needed
];

/// Service to launch UPI apps with required parameters
class CustomUpiLauncher {
  /// Get list of installed UPI apps dynamically
  static Future<List<UpiAppInfo>> getInstalledUpiApps() async {
    final List<UpiAppInfo> installedApps = [];

    for (final app in upiApps) {
      try {
        final isInstalled = await LaunchApp.isAppInstalled(
          androidPackageName: app.packageName,
        );
        if (isInstalled ?? false) {
          installedApps.add(app);
        }
      } catch (e) {
        // App not installed or error checking, skip it
        debugPrint('Error checking if ${app.name} is installed: $e');
      }
    }

    return installedApps;
  }

  /// Show bottom sheet to let the user pick a UPI app (only shows installed apps)
  static Future<UpiAppInfo?> showAppChooser(BuildContext context) async {
    // Get installed apps first
    final installedApps = await getInstalledUpiApps();

    if (installedApps.isEmpty) {
      // No UPI apps installed, show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No UPI apps found. Please install a UPI app.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return null;
    }

    // Show bottom sheet with installed apps
    if (!context.mounted) return null;

    return showModalBottomSheet<UpiAppInfo>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _UpiAppBottomSheet(apps: installedApps),
    );
  }

  /// Launch the selected UPI app with the correct URI
  static Future<void> launchUpiApp({
    required UpiAppInfo app,
    required String upiId,
    required double amount,
    required String merchantName,
    String transactionNote = 'Payment via Bilee',
    // If true, only open the target UPI app (no prefilled params / no UPI URI)
    bool openOnly = false,
  }) async {
    String uri;
    if (app.requiresParams) {
      // Build full UPI URI
      uri =
          'upi://pay?pa=$upiId&pn=$merchantName&am=${amount.toStringAsFixed(2)}&cu=INR&tn=$transactionNote';
    } else {
      // Open app home screen
      uri = 'upi://pay';
    }
    // If caller only wants to open the app (no prefilled details), do that and return.
    if (openOnly) {
      await LaunchApp.openApp(
        androidPackageName: app.packageName,
        openStore: false,
      );
      return;
    }

    // Try to open the specific app package (opens app if installed)
    await LaunchApp.openApp(
      androidPackageName: app.packageName,
      openStore: false,
    );

    // Also try launching the UPI URI so the payment params are passed to the app
    try {
      final upiUri = Uri.parse(uri);
      final canLaunch = await canLaunchUrl(upiUri);
      if (canLaunch) {
        await launchUrl(upiUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // ignore errors here; opening the app package above is the primary action
    }
  }
}

/// Bottom sheet widget to display installed UPI apps with their actual icons
class _UpiAppBottomSheet extends StatefulWidget {
  final List<UpiAppInfo> apps;

  const _UpiAppBottomSheet({required this.apps});
  @override
  State<_UpiAppBottomSheet> createState() => _UpiAppBottomSheetState();
}

class _UpiAppBottomSheetState extends State<_UpiAppBottomSheet> {
  static const platform = MethodChannel('com.example.bilee/app_icon');
  final Map<String, Uint8List?> _appIcons = {};

  @override
  void initState() {
    super.initState();
    _loadAppIcons();
  }

  /// Fetch actual app icons from Android
  Future<void> _loadAppIcons() async {
    for (final app in widget.apps) {
      try {
        final Uint8List? iconBytes = await platform.invokeMethod('getAppIcon', {
          'packageName': app.packageName,
        });
        if (mounted) {
          setState(() {
            _appIcons[app.packageName] = iconBytes;
          });
        }
      } catch (e) {
        debugPrint('Error loading icon for ${app.name}: $e');
      }
    }
  }

  /// Get app icon widget - either real icon or fallback
  Widget _getAppIcon(UpiAppInfo app, {bool isTapped = false}) {
    final iconBytes = _appIcons[app.packageName];

    if (iconBytes != null) {
      // Show actual app icon - LARGE SIZE
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: isTapped
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.memory(
            iconBytes,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Fallback while loading
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        Icons.account_balance_wallet,
        color: Colors.grey[400],
        size: 32,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              'Select UPI App',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),

          const Divider(height: 1),

          const SizedBox(height: 16),

          // Grid of app icons (3 columns, icon-only, no text)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // 3 icons per row
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1, // Square items
              ),
              itemCount: widget.apps.length,
              itemBuilder: (context, index) {
                final app = widget.apps[index];
                return GestureDetector(
                  onTap: () => Navigator.pop(context, app),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Just the icon, centered
                      _getAppIcon(app),
                      // No text - icon only!
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
