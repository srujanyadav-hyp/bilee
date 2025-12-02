import 'package:flutter/material.dart';
import 'package:bilee/features/onboarding/view/welcome_slide1.dart';
import 'package:bilee/features/onboarding/view/welcome_slide2.dart';
import 'package:bilee/features/onboarding/view/welcome_slide3.dart';
import 'package:bilee/features/auth/view/role_selection.dart';
import 'package:bilee/features/auth/view/login_screen.dart';
import 'package:bilee/features/auth/view/register_screen.dart';
import 'package:bilee/features/merchant/view/merchant_home_screen.dart';
import 'package:bilee/features/merchant/view/start_billing_screen.dart';
import 'package:bilee/features/merchant/view/edit_item_screen.dart';
import 'package:bilee/features/merchant/view/live_qr_screen.dart';
import 'package:bilee/features/merchant/view/daily_summary_screen.dart';
import 'package:bilee/features/customer/view/customer_home_screen.dart';
import 'package:bilee/features/customer/view/scan_qr_screen.dart';
import 'package:bilee/features/customer/view/live_bill_screen.dart';
import 'package:bilee/features/customer/view/receipt_list_screen.dart';
import 'package:bilee/features/customer/view/receipt_detail_screen.dart';

/// Application route definitions
class AppRouter {
  // Route names
  static const String welcomeSlide1 = '/welcome_slide1';
  static const String welcomeSlide2 = '/welcome_slide2';
  static const String welcomeSlide3 = '/welcome_slide3';
  static const String roleSelection = '/role_selection';
  static const String login = '/login';
  static const String register = '/register';
  static const String merchantHome = '/merchant_home';
  static const String startBilling = '/start_billing';
  static const String editItem = '/edit_item';
  static const String liveQr = '/live_qr';
  static const String dailySummary = '/daily_summary';
  static const String customerHome = '/customer_home';
  static const String scanQr = '/scan_qr';
  static const String liveBill = '/live_bill';
  static const String receiptList = '/receipt_list';
  static const String receiptDetail = '/receipt_detail';

  /// Route map
  static Map<String, WidgetBuilder> get routes => {
    welcomeSlide1: (context) => const WelcomeSlide1(),
    welcomeSlide2: (context) => const WelcomeSlide2(),
    welcomeSlide3: (context) => const WelcomeSlide3(),
    roleSelection: (context) => const RoleSelection(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    merchantHome: (context) => const MerchantHomeScreen(),
    startBilling: (context) => const StartBillingScreen(),
    editItem: (context) => const EditItemScreen(),
    liveQr: (context) => const LiveQrScreen(),
    dailySummary: (context) => const DailySummaryScreen(),
    customerHome: (context) => const CustomerHomeScreen(),
    scanQr: (context) => const ScanQrScreen(),
    liveBill: (context) => const LiveBillScreen(),
    receiptList: (context) => const ReceiptListScreen(),
    receiptDetail: (context) => const ReceiptDetailScreen(),
  };

  /// Generate route for unknown routes
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        body: Center(child: Text('Route not found: ${settings.name}')),
      ),
    );
  }
}
