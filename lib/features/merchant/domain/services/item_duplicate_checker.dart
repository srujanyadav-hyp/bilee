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
      // This catches: "పార్లే జి" vs "పార్లేజీ", "rice 1kg" vs "rice1kg"
      if (existingNameNormalized == searchTermNormalized) {
        return item;
      }

      // Method 2: Exact match with spaces (original behavior)
      if (existingNameOriginal == searchTermOriginal) {
        return item;
      }

      // Method 3: Contains match (one contains the other) with normalized text
      if (existingNameNormalized.contains(searchTermNormalized) ||
          searchTermNormalized.contains(existingNameNormalized)) {
        // Avoid false positives for very short words
        if (searchTermNormalized.length >= 3) {
          return item;
        }
      }

      // Method 4: Contains match with original spacing (fallback)
      if (existingNameOriginal.contains(searchTermOriginal) ||
          searchTermOriginal.contains(existingNameOriginal)) {
        // Avoid false positives for very short words
        if (searchTermOriginal.length >= 3) {
          return item;
        }
      }
    }

    return null;
  }

  /// Check if item name is too short or invalid
  bool isValidItemName(String name) {
    final trimmed = name.trim();
    return trimmed.length >= 2; // At least 2 characters
  }
}
