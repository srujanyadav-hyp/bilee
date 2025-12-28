import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';
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

/// List of popular UPI apps and their package names
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
  // Add more as needed
];

/// Service to launch UPI apps with required parameters
class CustomUpiLauncher {
  /// Show a dialog to let the user pick a UPI app
  static Future<UpiAppInfo?> showAppChooser(BuildContext context) async {
    return showDialog<UpiAppInfo>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select UPI App'),
        children: upiApps
            .map(
              (app) => ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: Text(app.name),
                onTap: () => Navigator.of(context).pop(app),
              ),
            )
            .toList(),
      ),
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
