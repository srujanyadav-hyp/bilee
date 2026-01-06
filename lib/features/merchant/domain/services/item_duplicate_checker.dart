import '../../domain/entities/item_entity.dart';

/// Simple duplicate detection service
/// Checks if a similar item already exists in merchant's inventory
class ItemDuplicateChecker {
  /// Normalize text for comparison by removing all spaces and converting to lowercase
  /// This helps detect duplicates like "పార్లే జి" and "పార్లేజీ" as the same
  /// Note: This is only used for COMPARISON, not for storing the actual item name
  String _normalizeForComparison(String text) {
    return text.toLowerCase().trim().replaceAll(
      RegExp(r'\s+'),
      '',
    ); // Remove all whitespace
  }

  /// Check if an item with similar name already exists
  /// Returns the existing item if found, null otherwise
  ///
  /// 🔥 SMART LOGIC to avoid false positives:
  /// - Exact match only (with/without spaces)
  /// - NO substring matching (prevents "బియ్యం" matching "సగ్గుబియ్యం")
  ItemEntity? findSimilarItem(
    String newItemName,
    List<ItemEntity> existingItems,
  ) {
    if (newItemName.trim().isEmpty || existingItems.isEmpty) {
      return null;
    }

    // Normalize for comparison - removes all spaces
    final searchTermNormalized = _normalizeForComparison(newItemName);
    final searchTermOriginal = newItemName.toLowerCase().trim();

    for (final item in existingItems) {
      final existingNameNormalized = _normalizeForComparison(item.name);
      final existingNameOriginal = item.name.toLowerCase().trim();

      // Method 1: Exact match after removing spaces
      // ✅ Catches: "పార్లే జి" vs "పార్లేజీ", "rice 1kg" vs "rice1kg"
      if (existingNameNormalized == searchTermNormalized) {
        return item;
      }

      // Method 2: Exact match with spaces (case-insensitive)
      // ✅ Catches: "Rice" vs "rice", "Parle G" vs "parle g"
      if (existingNameOriginal == searchTermOriginal) {
        return item;
      }

      // 🚫 REMOVED Method 3 & 4: Contains matching
      // ❌ Was causing false positives: "బియ్యం" matching "సగ్గుబియ్యం"
      // ❌ Was causing: "Parle" matching "Parle G", "milk" matching "milk powder"
    }

    return null;
  }

  /// Check if item name is too short or invalid
  bool isValidItemName(String name) {
    final trimmed = name.trim();
    return trimmed.length >= 2; // At least 2 characters
  }
}
