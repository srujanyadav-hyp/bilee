import '../entities/live_bill_entity.dart';
import '../repositories/live_bill_repository.dart';

/// Use case: Watch live bill updates in real-time
class WatchLiveBillUseCase {
  final LiveBillRepository repository;

  WatchLiveBillUseCase(this.repository);

  Stream<LiveBillEntity> call(String sessionId) {
    return repository.watchLiveBill(sessionId);
  }
}
