import '../../data/repositories/receipt_repository.dart';
import '../entities/receipt_entity.dart';

/// Create Receipt Use Case
class CreateReceipt {
  final ReceiptRepository _repository;

  CreateReceipt(this._repository);

  Future<String> call(ReceiptEntity receipt) async {
    return await _repository.saveReceipt(receipt);
  }
}

/// Get Receipt Use Case
class GetReceipt {
  final ReceiptRepository _repository;

  GetReceipt(this._repository);

  Future<ReceiptEntity?> call(String receiptId) async {
    return await _repository.getReceipt(receiptId);
  }
}

/// Get Receipt by Session ID
class GetReceiptBySession {
  final ReceiptRepository _repository;

  GetReceiptBySession(this._repository);

  Future<ReceiptEntity?> call(String sessionId) async {
    return await _repository.getReceiptBySessionId(sessionId);
  }
}

/// Log Receipt Access
class LogReceiptAccess {
  final ReceiptRepository _repository;

  LogReceiptAccess(this._repository);

  Future<void> call(String receiptId, ReceiptAccessLog accessLog) async {
    return await _repository.logAccess(receiptId, accessLog);
  }
}
