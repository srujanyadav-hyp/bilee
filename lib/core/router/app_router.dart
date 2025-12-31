import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/splash/presentation/pages/splash_screen.dart';
import '../../features/onboarding/view/role_selection.dart';
import '../../features/onboarding/view/onboarding_merchant.dart';
import '../../features/onboarding/view/onboarding_customer.dart';
import '../../features/authentication/view/login_screen.dart';
import '../../features/authentication/view/register_screen.dart';
import '../../features/authentication/view/otp_screen.dart';
import '../../features/authentication/view/forgot_password_screen.dart';
import '../models/auth_models.dart';
import '../../features/merchant/presentation/pages/merchant_home_page.dart';
import '../../features/merchant/presentation/pages/start_billing_page.dart';
import '../../features/merchant/presentation/pages/item_library_page.dart';
import '../../features/merchant/presentation/pages/daily_summary_page.dart';
import '../../features/merchant/presentation/pages/merchant_profile_page.dart';
import '../../features/merchant/presentation/pages/live_session_page.dart';
import '../../features/merchant/presentation/pages/customer_ledger_page.dart';
import '../../features/customer/presentation/pages/customer_home_screen.dart';
import '../../features/customer/presentation/pages/scan_qr_screen.dart';
import '../../features/customer/presentation/pages/live_bill_screen.dart';
import '../../features/customer/presentation/pages/payment_status_screen.dart';
import '../../features/customer/presentation/pages/receipt_detail_screen.dart';
import '../../features/customer/presentation/pages/receipt_list_screen.dart';
import '../../features/customer/presentation/pages/customer_profile_screen.dart';
import '../../features/customer/presentation/pages/add_manual_expense_screen.dart';
import '../../features/customer/presentation/pages/budget_settings_screen.dart';
import '../../features/customer/presentation/pages/archive_review_screen.dart';
import '../../features/customer/domain/entities/monthly_summary_entity.dart';
import '../../features/customer/presentation/pages/monthly_summary_detail_screen.dart';
import '../../features/customer/presentation/pages/monthly_summaries_list_screen.dart';

/// Global RouteObserver for tracking route lifecycle
/// Used to detect when screens become visible again (e.g., when navigating back)
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

/// App Router Configuration using GoRouter
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      // Splash Screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding Routes
      GoRoute(
        path: '/role-selection',
        name: 'role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/merchant',
        name: 'onboarding-merchant',
        builder: (context, state) => const MerchantOnboardingScreen(),
      ),
      GoRoute(
        path: '/onboarding/customer',
        name: 'onboarding-customer',
        builder: (context, state) => const CustomerOnboardingScreen(),
      ),

      // Authentication Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OTPScreen(
            phoneNumber: extra?['phoneNumber'] as String?,
            verificationId: extra?['verificationId'] as String?,
            countryCode: extra?['countryCode'] as String?,
            isRegistration: extra?['isRegistration'] as bool?,
            registrationData: extra?['registrationData'] as RegistrationData?,
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Merchant Routes
      GoRoute(
        path: '/merchant/:merchantId',
        name: 'merchant-home',
        builder: (context, state) {
          final merchantId = state.pathParameters['merchantId']!;
          return MerchantHomePage(merchantId: merchantId);
        },
        routes: [
          GoRoute(
            path: 'billing',
            name: 'start-billing',
            builder: (context, state) {
              final merchantId = state.pathParameters['merchantId']!;
              return StartBillingPage(merchantId: merchantId);
            },
          ),
          GoRoute(
            path: 'items',
            name: 'item-library',
            builder: (context, state) {
              final merchantId = state.pathParameters['merchantId']!;
              return ItemLibraryPage(merchantId: merchantId);
            },
          ),
          GoRoute(
            path: 'summary',
            name: 'daily-summary',
            builder: (context, state) {
              final merchantId = state.pathParameters['merchantId']!;
              return DailySummaryPage(merchantId: merchantId);
            },
          ),
          GoRoute(
            path: 'profile',
            name: 'merchant-profile',
            builder: (context, state) {
              final merchantId = state.pathParameters['merchantId']!;
              return MerchantProfilePage(merchantId: merchantId);
            },
          ),
          GoRoute(
            path: 'ledger',
            name: 'customer-ledger',
            builder: (context, state) {
              final merchantId = state.pathParameters['merchantId']!;
              return CustomerLedgerPage(merchantId: merchantId);
            },
          ),
          GoRoute(
            path: 'session/:sessionId',
            name: 'live-session',
            builder: (context, state) {
              final merchantId = state.pathParameters['merchantId']!;
              final sessionId = state.pathParameters['sessionId']!;
              return LiveSessionPage(
                merchantId: merchantId,
                sessionId: sessionId,
              );
            },
          ),
        ],
      ),

      // Customer Routes
      GoRoute(
        path: '/customer',
        name: 'customer-home',
        builder: (context, state) => const CustomerHomeScreen(),
        routes: [
          GoRoute(
            path: 'scan-qr',
            name: 'customer-scan-qr',
            builder: (context, state) => const ScanQRScreen(),
          ),
          GoRoute(
            path: 'live-bill/:sessionId',
            name: 'customer-live-bill',
            builder: (context, state) {
              final sessionId = state.pathParameters['sessionId']!;
              return LiveBillScreen(sessionId: sessionId);
            },
          ),
          GoRoute(
            path: 'payment-status/:sessionId',
            name: 'customer-payment-status',
            builder: (context, state) {
              final sessionId = state.pathParameters['sessionId']!;
              return PaymentStatusScreen(sessionId: sessionId);
            },
          ),
          GoRoute(
            path: 'receipt/:receiptId',
            name: 'customer-receipt-detail',
            builder: (context, state) {
              final receiptId = state.pathParameters['receiptId']!;
              return ReceiptDetailScreen(receiptId: receiptId);
            },
          ),
          GoRoute(
            path: 'receipts',
            name: 'customer-receipts',
            builder: (context, state) => const ReceiptListScreen(),
          ),
          GoRoute(
            path: 'profile',
            name: 'customer-profile',
            builder: (context, state) => const CustomerProfileScreen(),
          ),
          GoRoute(
            path: 'add-expense',
            name: 'customer-add-expense',
            builder: (context, state) => const AddManualExpenseScreen(),
          ),
          GoRoute(
            path: 'budget-settings',
            name: 'customer-budget-settings',
            builder: (context, state) => const BudgetSettingsScreen(),
          ),
          GoRoute(
            path: 'archive-review',
            name: 'customer-archive-review',
            builder: (context, state) {
              final year = int.parse(state.uri.queryParameters['year'] ?? '0');
              final month = int.parse(
                state.uri.queryParameters['month'] ?? '0',
              );
              return ArchiveReviewScreen(year: year, month: month);
            },
          ),
          GoRoute(
            path: 'monthly-summaries',
            name: 'customer-monthly-summaries',
            builder: (context, state) => const MonthlySummariesListScreen(),
          ),
          GoRoute(
            path: 'monthly-summary/:summaryId',
            name: 'customer-monthly-summary',
            builder: (context, state) {
              final summary = state.extra as MonthlySummaryEntity;
              return MonthlySummaryDetailScreen(summary: summary);
            },
          ),
        ],
      ),
    ],

    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.error.toString()),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Infer user role from failed route to navigate directly
                final location = state.matchedLocation;

                if (location.startsWith('/customer')) {
                  context.go('/customer');
                } else if (location.startsWith('/merchant')) {
                  context.go('/merchant');
                } else {
                  // Fallback to splash for unknown routes
                  context.go('/');
                }
              },
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
