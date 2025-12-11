import 'package:get_it/get_it.dart';
import '../../features/merchant/data/datasources/merchant_firestore_datasource.dart';
import '../../features/merchant/data/repositories/merchant_repository_impl.dart';
import '../../features/merchant/domain/repositories/i_merchant_repository.dart';
import '../../features/merchant/domain/usecases/item_usecases.dart';
import '../../features/merchant/domain/usecases/session_usecases.dart';
import '../../features/merchant/domain/usecases/daily_aggregate_usecases.dart';
import '../../features/merchant/presentation/providers/item_provider.dart';
import '../../features/merchant/presentation/providers/session_provider.dart';
import '../../features/merchant/presentation/providers/daily_aggregate_provider.dart';

final getIt = GetIt.instance;

/// Setup dependency injection for the app
Future<void> setupDependencyInjection() async {
  // ==================== DATA SOURCES ====================

  getIt.registerLazySingleton<MerchantFirestoreDataSource>(
    () => MerchantFirestoreDataSource(),
  );

  // ==================== REPOSITORIES ====================

  getIt.registerLazySingleton<IMerchantRepository>(
    () => MerchantRepositoryImpl(getIt()),
  );

  // ==================== USE CASES ====================

  // Item use cases
  getIt.registerLazySingleton(() => GetMerchantItems(getIt()));
  getIt.registerLazySingleton(() => CreateItem(getIt()));
  getIt.registerLazySingleton(() => UpdateItem(getIt()));
  getIt.registerLazySingleton(() => DeleteItem(getIt()));

  // Session use cases
  getIt.registerLazySingleton(() => CreateBillingSession(getIt()));
  getIt.registerLazySingleton(() => GetLiveSession(getIt()));
  getIt.registerLazySingleton(() => MarkSessionPaid(getIt()));
  getIt.registerLazySingleton(() => FinalizeSession(getIt()));

  // Daily aggregate use cases
  getIt.registerLazySingleton(() => GetDailyAggregate(getIt()));
  getIt.registerLazySingleton(() => UpdateDailyAggregate(getIt()));
  getIt.registerLazySingleton(() => GenerateDailyReport(getIt()));

  // ==================== PROVIDERS ====================

  getIt.registerFactory(
    () => ItemProvider(
      getMerchantItems: getIt(),
      createItem: getIt(),
      updateItem: getIt(),
      deleteItem: getIt(),
    ),
  );

  getIt.registerFactory(
    () => SessionProvider(
      createBillingSession: getIt(),
      getLiveSession: getIt(),
      markSessionPaid: getIt(),
      finalizeSession: getIt(),
    ),
  );

  getIt.registerFactory(
    () => DailyAggregateProvider(
      getDailyAggregate: getIt(),
      updateDailyAggregate: getIt(),
      generateDailyReport: getIt(),
    ),
  );
}
