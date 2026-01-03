import '../entities/item_entity.dart';
import '../entities/session_entity.dart';
import '../entities/daily_aggregate_entity.dart';
import '../entities/merchant_entity.dart';

/// Repository Interface (Contract) - Domain Layer
/// Defines what operations are available, not how they work
abstract class IMerchantRepository {
  // Merchant profile operations
  Future<MerchantEntity?> getMerchantProfile(String merchantId);
  Future<void> saveMerchantProfile(MerchantEntity merchant);

  // Item operations
  Stream<List<ItemEntity>> getItemsStream(String merchantId);
  Future<void> createItem(ItemEntity item);
  Future<void> updateItem(ItemEntity item);
  Future<void> deleteItem(String merchantId, String itemId);

  // Session operations
  Stream<SessionEntity?> getSessionStream(String sessionId);
  Future<String> createSession(SessionEntity session);
  Future<void> markSessionPaid(
    String sessionId,
    String paymentMethod,
    String txnId,
  );
  Future<void> finalizeSession(String sessionId);

  // Daily aggregate operations
  Stream<DailyAggregateEntity?> getDailyAggregateStream(
    String merchantId,
    String date,
  );
  Future<void> updateDailyAggregate(
    String merchantId,
    String date,
    double revenue,
    List<SessionItemEntity> items,
  );

  // Cloud function calls
  Future<String> callFinalizeSession(String sessionId);
}
