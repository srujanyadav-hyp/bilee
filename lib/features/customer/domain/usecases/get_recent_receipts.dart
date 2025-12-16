import '../entities/receipt_entity.dart';
import '../repositories/receipt_repository.dart';

/// Use case: Get recent receipts for home screen
class GetRecentReceiptsUseCase {
  final ReceiptRepository repository;

  GetRecentReceiptsUseCase(this.repository);

  Future<List<ReceiptEntity>> call({int limit = 3}) async {
    try {
      return await repository.getRecentReceipts(limit: limit);
    } catch (e) {
      throw Exception('Failed to load recent receipts: $e');
    }
  }
}
