import '../entities/live_bill_entity.dart';
import '../repositories/live_bill_repository.dart';

/// Use case: Connect to merchant session by scanning QR
class ConnectToSessionUseCase {
  final LiveBillRepository repository;

  ConnectToSessionUseCase(this.repository);

  Future<LiveBillEntity> call(String sessionId) async {
    try {
      return await repository.connectToSession(sessionId);
    } catch (e) {
      throw Exception('Failed to connect to session: $e');
    }
  }
}
