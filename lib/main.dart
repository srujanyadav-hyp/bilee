import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'firebase_options.dart';
import 'core/theme/theme_provider.dart';
import 'core/di/dependency_injection.dart';
import 'core/router/app_router.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/local_database_service.dart';
import 'features/merchant/presentation/providers/daily_aggregate_provider.dart';
import 'features/merchant/presentation/providers/item_provider.dart';
import 'features/merchant/presentation/providers/session_provider.dart';
import 'features/merchant/presentation/providers/merchant_provider.dart';
import 'features/merchant/presentation/providers/staff_provider.dart';
import 'features/merchant/presentation/providers/customer_ledger_provider.dart';
import 'features/customer/customer_providers.dart';

final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Use default Firestore database
    FirebaseFirestore.instance;

    // Setup dependency injection (must be done before creating providers)
    setupDependencyInjection();

    // Initialize local database for offline mode
    await LocalDatabaseService().database;
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => StaffProvider()),
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

        // Customer providers
        ...CustomerProviders.getProviders(),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp.router(
            title: 'BILEE',
            debugShowCheckedModeBanner: false,

            // Theme Configuration
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.themeMode,

            // Router Configuration
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
