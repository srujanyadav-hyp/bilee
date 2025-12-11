import '../entities/session_entity.dart';
import '../repositories/i_merchant_repository.dart';

/// Use Case - Create billing session
class CreateBillingSession {
  final IMerchantRepository repository;

  CreateBillingSession(this.repository);

  Future<String> call(SessionEntity session) async {
    // Business validation
    if (session.items.isEmpty) {
      throw Exception('Session must have at least one item');
    }
    if (session.total <= 0) {
      throw Exception('Session total must be greater than 0');
    }

    return await repository.createSession(session);
  }
}

/// Use Case - Get live session
class GetLiveSession {
  final IMerchantRepository repository;

  GetLiveSession(this.repository);

  Stream<SessionEntity?> call(String sessionId) {
    return repository.getSessionStream(sessionId);
  }
}

/// Use Case - Mark session as paid
class MarkSessionPaid {
  final IMerchantRepository repository;

  MarkSessionPaid(this.repository);

  Future<void> call(
    String sessionId,
    String paymentMethod,
    String txnId,
  ) async {
    // Business validation
    if (paymentMethod.trim().isEmpty) {
      throw Exception('Payment method is required');
    }

    await repository.markSessionPaid(sessionId, paymentMethod, txnId);
  }
}

/// Use Case - Finalize session
class FinalizeSession {
  final IMerchantRepository repository;

  FinalizeSession(this.repository);

  Future<void> call(String sessionId) async {
    await repository.finalizeSession(sessionId);
  }
}
