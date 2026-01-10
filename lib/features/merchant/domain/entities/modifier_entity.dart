/// Domain Entity - Modifier (e.g., "Extra Spicy", "No Onion")
class ModifierEntity {
  final String id;
  final String name; // "Extra Spicy", "Boiled Egg", "No Onion"
  final double price; // Additional cost (0.0 for free modifiers)
  final bool isDefault; // Auto-selected by default

  const ModifierEntity({
    required this.id,
    required this.name,
    required this.price,
    this.isDefault = false,
  });

  ModifierEntity copyWith({
    String? id,
    String? name,
    double? price,
    bool? isDefault,
  }) {
    return ModifierEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// Domain Entity - Modifier Group (e.g., "Spice Level", "Add-ons")
class ModifierGroupEntity {
  final String id;
  final String name; // "Spice Level", "Add-ons", "Customize"
  final ModifierType type; // SINGLE or MULTIPLE selection
  final bool required; // Must customer choose at least one?
  final List<ModifierEntity> modifiers;
  final int?
  maxSelection; // For MULTIPLE type: max selections allowed (null = unlimited)

  const ModifierGroupEntity({
    required this.id,
    required this.name,
    required this.type,
    this.required = false,
    required this.modifiers,
    this.maxSelection,
  });

  ModifierGroupEntity copyWith({
    String? id,
    String? name,
    ModifierType? type,
    bool? required,
    List<ModifierEntity>? modifiers,
    int? maxSelection,
  }) {
    return ModifierGroupEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      required: required ?? this.required,
      modifiers: modifiers ?? this.modifiers,
      maxSelection: maxSelection ?? this.maxSelection,
    );
  }
}

/// Modifier Type - Single choice or Multiple choices
enum ModifierType {
  SINGLE, // Radio button - choose one (e.g., spice level)
  MULTIPLE, // Checkbox - choose multiple (e.g., add-ons)
}

/// Domain Entity - Selected Modifier (in cart/session)
class SelectedModifierEntity {
  final String groupName; // "Spice Level"
  final String modifierName; // "Extra Spicy"
  final double price; // 10.0

  const SelectedModifierEntity({
    required this.groupName,
    required this.modifierName,
    required this.price,
  });

  SelectedModifierEntity copyWith({
    String? groupName,
    String? modifierName,
    double? price,
  }) {
    return SelectedModifierEntity(
      groupName: groupName ?? this.groupName,
      modifierName: modifierName ?? this.modifierName,
      price: price ?? this.price,
    );
  }
}
