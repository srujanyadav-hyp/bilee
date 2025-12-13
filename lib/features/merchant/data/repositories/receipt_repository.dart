import '../datasources/receipt_remote_data_source.dart';
import '../../domain/entities/receipt_entity.dart';

/// Receipt Repository Implementation
class ReceiptRepository {
  final ReceiptRemoteDataSource _remoteDataSource;

  ReceiptRepository({required ReceiptRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  Future<String> saveReceipt(ReceiptEntity receipt) async {
    return await _remoteDataSource.saveReceipt(receipt);
  }

  Future<ReceiptEntity?> getReceipt(String receiptId) async {
    return await _remoteDataSource.getReceipt(receiptId);
  }

  Future<ReceiptEntity?> getReceiptBySessionId(String sessionId) async {
    return await _remoteDataSource.getReceiptBySessionId(sessionId);
  }

  Future<List<ReceiptEntity>> getMerchantReceipts(
    String merchantId, {
    int limit = 50,
  }) async {
    return await _remoteDataSource.getMerchantReceipts(
      merchantId,
      limit: limit,
    );
  }

  Future<void> logAccess(String receiptId, ReceiptAccessLog accessLog) async {
    return await _remoteDataSource.logAccess(receiptId, accessLog);
  }
}
