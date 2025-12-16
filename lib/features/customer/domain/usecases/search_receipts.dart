import '../entities/receipt_entity.dart';
import '../repositories/receipt_repository.dart';

/// Use case: Search receipts by query
class SearchReceiptsUseCase {
  final ReceiptRepository repository;

  SearchReceiptsUseCase(this.repository);

  Future<List<ReceiptEntity>> call(String query) async {
    try {
      if (query.isEmpty) {
        return await repository.getAllReceipts();
      }
      return await repository.searchReceipts(query);
    } catch (e) {
      throw Exception('Failed to search receipts: $e');
    }
  }
}
