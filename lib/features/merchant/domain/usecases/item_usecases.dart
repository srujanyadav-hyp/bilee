import '../entities/item_entity.dart';
import '../repositories/i_merchant_repository.dart';

/// Use Case - Get items for merchant
class GetMerchantItems {
  final IMerchantRepository repository;

  GetMerchantItems(this.repository);

  Stream<List<ItemEntity>> call(String merchantId) {
    return repository.getItemsStream(merchantId);
  }
}

/// Use Case - Create new item
class CreateItem {
  final IMerchantRepository repository;

  CreateItem(this.repository);

  Future<void> call(ItemEntity item) async {
    // Business validation
    if (item.name.trim().isEmpty) {
      throw Exception('Item name cannot be empty');
    }
    if (item.price < 0) {
      throw Exception('Price cannot be negative');
    }
    if (item.taxRate < 0 || item.taxRate > 100) {
      throw Exception('Tax rate must be between 0 and 100');
    }

    await repository.createItem(item);
  }
}

/// Use Case - Update item
class UpdateItem {
  final IMerchantRepository repository;

  UpdateItem(this.repository);

  Future<void> call(ItemEntity item) async {
    // Business validation
    if (item.name.trim().isEmpty) {
      throw Exception('Item name cannot be empty');
    }
    if (item.price < 0) {
      throw Exception('Price cannot be negative');
    }
    if (item.taxRate < 0 || item.taxRate > 100) {
      throw Exception('Tax rate must be between 0 and 100');
    }

    await repository.updateItem(item);
  }
}

/// Use Case - Delete item
class DeleteItem {
  final IMerchantRepository repository;

  DeleteItem(this.repository);

  Future<void> call(String merchantId, String itemId) async {
    await repository.deleteItem(merchantId, itemId);
  }
}
