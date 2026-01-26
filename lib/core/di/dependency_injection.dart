import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/local_database_service.dart';
import '../../features/merchant/data/datasources/merchant_firestore_datasource.dart';
import '../../features/merchant/data/datasources/receipt_remote_data_source.dart';
import '../../features/merchant/data/repositories/merchant_repository_impl.dart';
import '../../features/merchant/data/repositories/receipt_repository.dart';
import '../../features/merchant/data/repositories/inventory_repository_impl.dart';
import '../../features/merchant/domain/repositories/i_merchant_repository.dart';
import '../../features/merchant/domain/repositories/inventory_repository.dart';
import '../../features/merchant/domain/usecases/merchant_usecases.dart';
import '../../features/merchant/domain/usecases/item_usecases.dart';
import '../../features/merchant/domain/usecases/session_usecases.dart';
import '../../features/merchant/domain/usecases/receipt_usecases.dart';
import '../../features/merchant/domain/usecases/daily_aggregate_usecases.dart';
import '../../features/merchant/presentation/providers/item_provider.dart';
import '../../features/merchant/presentation/providers/session_provider.dart';
import '../../features/merchant/presentation/providers/daily_aggregate_provider.dart';
import '../../features/merchant/presentation/providers/merchant_provider.dart';
import '../../features/merchant/presentation/providers/inventory_provider.dart';

final getIt = GetIt.instance;

/// Setup dependency injection for the app
void setupDependencyInjection() {
  // ==================== DATA SOURCES ====================

  getIt.registerLazySingleton<MerchantFirestoreDataSource>(
    () => MerchantFirestoreDataSource(),
  );

  getIt.registerLazySingleton<ReceiptRemoteDataSource>(
    () => ReceiptRemoteDataSource(),
  );

  // ==================== REPOSITORIES ====================

  getIt.registerLazySingleton<IMerchantRepository>(
    () => MerchantRepositoryImpl(getIt()),
  );

  getIt.registerLazySingleton<ReceiptRepository>(
    () => ReceiptRepository(remoteDataSource: getIt()),
  );

  // Inventory repository
  getIt.registerLazySingleton<LocalDatabaseService>(
    () => LocalDatabaseService(),
  );

  getIt.registerLazySingleton<IInventoryRepository>(
    () => InventoryRepositoryImpl(
      localDb: getIt(),
      firestore: FirebaseFirestore.instance,
    ),
  );

  // ==================== USE CASES ====================

  // Merchant profile use cases
  getIt.registerLazySingleton(() => GetMerchantProfile(getIt()));
  getIt.registerLazySingleton(() => SaveMerchantProfile(getIt()));

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

  // Receipt use cases
  getIt.registerLazySingleton(() => CreateReceipt(getIt()));
  getIt.registerLazySingleton(() => GetReceipt(getIt()));
  getIt.registerLazySingleton(() => GetReceiptBySession(getIt()));
  getIt.registerLazySingleton(() => LogReceiptAccess(getIt()));

  // Daily aggregate use cases
  getIt.registerLazySingleton(() => GetDailyAggregate(getIt()));
  getIt.registerLazySingleton(() => UpdateDailyAggregate(getIt()));

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
      logReceiptAccess: getIt(),
      getMerchantProfile: getIt(),
      inventoryProvider: getIt(),
    ),
  );

  getIt.registerFactory(
    () => DailyAggregateProvider(
      getDailyAggregate: getIt(),
      updateDailyAggregate: getIt(),
    ),
  );

  getIt.registerFactory(
    () => MerchantProvider(
      getMerchantProfile: getIt(),
      saveMerchantProfile: getIt(),
    ),
  );

  getIt.registerFactory(() => InventoryProvider(repository: getIt()));
}
