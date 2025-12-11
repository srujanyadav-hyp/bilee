import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'core/theme/theme_provider.dart';
import 'core/constants/app_strings.dart';
import 'core/di/dependency_injection.dart';
import 'features/splash/presentation/pages/splash_screen.dart';
import 'features/onboarding/view/role_selection.dart';
import 'features/onboarding/view/onboarding_merchant.dart';
import 'features/onboarding/view/onboarding_customer.dart';
import 'features/authentication/view/login_screen.dart';
import 'features/authentication/view/register_screen.dart';
import 'features/authentication/view/otp_screen.dart';
import 'features/authentication/view/forgot_password_screen.dart';
import 'features/merchant/presentation/pages/merchant_home_page.dart';
import 'features/customer/dashboard/view/customer_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Use 'bilee' database instance
    FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'bilee');

    // Setup dependency injection
    setupDependencyInjection();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,

            // Theme Configuration
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,

            // Routes
            routes: {
              '/role_selection': (context) => const RoleSelectionScreen(),
              '/onboarding/merchant': (context) =>
                  const MerchantOnboardingScreen(),
              '/onboarding/customer': (context) =>
                  const CustomerOnboardingScreen(),
              '/auth/login': (context) => const LoginScreen(),
              '/auth/register': (context) => const RegisterScreen(),
              '/auth/otp': (context) => const OTPScreen(),
              '/auth/forgot-password': (context) =>
                  const ForgotPasswordScreen(),
              '/customer/dashboard': (context) =>
                  const CustomerDashboardScreen(),
              '/welcome_slide1': (context) => const WelcomeSlide1Placeholder(),
            },

            // Dynamic route handler for merchant dashboard
            onGenerateRoute: (settings) {
              if (settings.name == '/merchant/dashboard') {
                final merchantId = settings.arguments as String?;
                return MaterialPageRoute(
                  builder: (context) => MerchantHomePage(
                    merchantId: merchantId ?? 'default_merchant',
                  ),
                );
              }
              return null;
            },

            // Home Page
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

// Placeholder for onboarding screen
class WelcomeSlide1Placeholder extends StatelessWidget {
  const WelcomeSlide1Placeholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome Slide 1')),
      body: const Center(child: Text('Onboarding Screen Coming Soon')),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo Placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.qr_code_2, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 32),

            // App Name
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.displayLarge,
            ),
            const SizedBox(height: 8),

            // Tagline
            Text(
              AppStrings.appTagline,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                AppStrings.appDescription,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 48),

            // Get Started Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Theme system ready! 🎨'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text(AppStrings.getStarted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
