import '../entities/receipt_entity.dart';
import '../repositories/receipt_repository.dart';

/// Use case: Get all receipts for wallet screen
class GetAllReceiptsUseCase {
  final ReceiptRepository repository;

  GetAllReceiptsUseCase(this.repository);

  Future<List<ReceiptEntity>> call() async {
    try {
      return await repository.getAllReceipts();
    } catch (e) {
      throw Exception('Failed to load receipts: $e');
    }
  }
}
