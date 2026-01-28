import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'core/theme/theme_provider.dart';
import 'core/di/dependency_injection.dart';
import 'core/router/app_router.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/local_database_service.dart';
import 'core/services/local_storage_service.dart'; // NEW
import 'core/services/crashlytics_service.dart';
import 'core/services/performance_service.dart';
import 'core/security/encryption_service.dart'; // UPI encryption
import 'features/merchant/presentation/providers/daily_aggregate_provider.dart';
import 'features/merchant/presentation/providers/item_provider.dart';
import 'features/merchant/presentation/providers/session_provider.dart';
import 'features/merchant/presentation/providers/merchant_provider.dart';
import 'features/merchant/presentation/providers/customer_ledger_provider.dart';
import 'features/merchant/presentation/providers/inventory_provider.dart';
import 'features/customer/customer_providers.dart';

final getIt = GetIt.instance;

void main() {
  // Run app in error zone to catch all errors
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      try {
        // Initialize Firebase
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        // Initialize Crashlytics (must be done early to catch all errors)
        debugPrint('🔧 Initializing Crashlytics...');
        await CrashlyticsService.initialize();
        debugPrint('✅ Crashlytics initialized');

        // Initialize Performance Monitoring
        debugPrint('🔧 Initializing Performance Monitoring...');
        await PerformanceService.initialize();
        debugPrint('✅ Performance Monitoring initialized');

        // Use default Firestore database
        FirebaseFirestore.instance;

        // Initialize local storage (Hive) BEFORE dependency injection
        debugPrint('🔧 Initializing local storage...');
        final localStorage = LocalStorageService();
        await localStorage.initialize();
        debugPrint('✅ Local storage initialized');

        // Register local storage as singleton
        getIt.registerSingleton<LocalStorageService>(localStorage);

        // Initialize encryption service for UPI payment automation
        debugPrint('🔧 Initializing encryption service...');
        await EncryptionService.initializeKey();
        debugPrint('✅ Encryption service initialized');

        // Setup dependency injection (must be done before creating providers)
        setupDependencyInjection();

        // Initialize local database for offline mode (existing)
        await LocalDatabaseService().database;
      } catch (e, stackTrace) {
        debugPrint('❌ Initialization error: $e');
        debugPrint('Stack trace: $stackTrace');

        // Log initialization errors to Crashlytics
        await CrashlyticsService.recordError(
          e,
          stackTrace,
          reason: 'App initialization failed',
          fatal: true,
        );
      }

      runApp(const MyApp());
    },
    (error, stackTrace) {
      debugPrint('❌ Uncaught error: $error');
      CrashlyticsService.recordError(
        error,
        stackTrace,
        reason: 'Uncaught error in app',
        fatal: true,
      );
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProxyProvider<ConnectivityService, SyncService>(
          create: (context) => SyncService(context.read<ConnectivityService>()),
          update: (context, connectivity, previous) =>
              previous ?? SyncService(connectivity),
        ),
        ChangeNotifierProvider(create: (_) => getIt<DailyAggregateProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<ItemProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<SessionProvider>()),
        ChangeNotifierProvider(create: (_) => getIt<MerchantProvider>()),
        ChangeNotifierProvider(create: (_) => CustomerLedgerProvider()),
        ChangeNotifierProvider(create: (_) => getIt<InventoryProvider>()),

        // Customer providers (includes BudgetProvider)
        ...CustomerProviders.getProviders(),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'BILEE',
            debugShowCheckedModeBanner: false,

            // Theme Configuration
            theme: themeProvider.lightTheme,
            // darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,

            // Router Configuration
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
