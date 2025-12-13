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
import '../../features/merchant/presentation/pages/merchant_home_page.dart';
import '../../features/merchant/presentation/pages/merchant_dashboard_page.dart';
import '../../features/merchant/presentation/pages/start_billing_page.dart';
import '../../features/merchant/presentation/pages/item_library_page.dart';
import '../../features/merchant/presentation/pages/daily_summary_page.dart';
import '../../features/merchant/presentation/pages/merchant_profile_page.dart';
import '../../features/merchant/presentation/pages/live_session_page.dart';
import '../../features/merchant/presentation/pages/staff_management_page.dart';
import '../../features/merchant/presentation/pages/customer_ledger_page.dart';
import '../../features/customer/dashboard/view/customer_dashboard.dart';

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
            path: 'dashboard',
            name: 'merchant-dashboard',
            builder: (context, state) {
              final merchantId = state.pathParameters['merchantId']!;
              return MerchantDashboardPage(merchantId: merchantId);
            },
          ),
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
            path: 'staff',
            name: 'staff-management',
            builder: (context, state) {
              final merchantId = state.pathParameters['merchantId']!;
              return StaffManagementPage(merchantId: merchantId);
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
        name: 'customer-dashboard',
        builder: (context, state) => const CustomerDashboardScreen(),
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
              onPressed: () => context.go('/'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
}
