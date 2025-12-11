import 'package:flutter/foundation.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/usecases/item_usecases.dart';

/// Item Provider - State management for merchant items
class ItemProvider with ChangeNotifier {
  final GetMerchantItems _getMerchantItems;
  final CreateItem _createItem;
  final UpdateItem _updateItem;
  final DeleteItem _deleteItem;

  ItemProvider({
    required GetMerchantItems getMerchantItems,
    required CreateItem createItem,
    required UpdateItem updateItem,
    required DeleteItem deleteItem,
  }) : _getMerchantItems = getMerchantItems,
       _createItem = createItem,
       _updateItem = updateItem,
       _deleteItem = deleteItem;

  List<ItemEntity> _items = [];
  bool _isLoading = false;
  String? _error;
  String? _searchQuery;

  List<ItemEntity> get items {
    if (_searchQuery == null || _searchQuery!.isEmpty) {
      return _items;
    }
    final query = _searchQuery!.toLowerCase();
    return _items.where((item) {
      return item.name.toLowerCase().contains(query) ||
          (item.hsnCode?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasItems => _items.isNotEmpty;

  /// Load items for a merchant
  Future<void> loadItems(String merchantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _getMerchantItems(merchantId).listen(
        (itemsList) {
          _items = itemsList;
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          _error = e.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a new item
  Future<bool> createItem(ItemEntity item) async {
    _error = null;
    notifyListeners();

    try {
      await _createItem(item);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Update an existing item
  Future<bool> updateItem(ItemEntity item) async {
    _error = null;
    notifyListeners();

    try {
      await _updateItem(item);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Delete an item
  Future<bool> deleteItem(String merchantId, String itemId) async {
    _error = null;
    notifyListeners();

    try {
      await _deleteItem(merchantId, itemId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Search items by name or HSN code
  void searchItems(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = null;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _items = [];
    super.dispose();
  }
}
