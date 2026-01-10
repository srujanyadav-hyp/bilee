import '../../domain/entities/modifier_entity.dart';

/// Data Model - Modifier (Firestore Representation)
class ModifierModel {
  final String id;
  final String name;
  final double price;
  final bool isDefault;

  const ModifierModel({
    required this.id,
    required this.name,
    required this.price,
    this.isDefault = false,
  });

  /// Convert to domain entity
  ModifierEntity toEntity() {
    return ModifierEntity(
      id: id,
      name: name,
      price: price,
      isDefault: isDefault,
    );
  }

  /// Create from domain entity
  factory ModifierModel.fromEntity(ModifierEntity entity) {
    return ModifierModel(
      id: entity.id,
      name: entity.name,
      price: entity.price,
      isDefault: entity.isDefault,
    );
  }

  /// Create from JSON map
  factory ModifierModel.fromJson(Map<String, dynamic> json) {
    return ModifierModel(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  /// Convert to JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'price': price, 'isDefault': isDefault};
  }
}

/// Data Model - Modifier Group (Firestore Representation)
class ModifierGroupModel {
  final String id;
  final String name;
  final String type; // 'SINGLE' or 'MULTIPLE'
  final bool required;
  final List<ModifierModel> modifiers;
  final int? maxSelection;

  const ModifierGroupModel({
    required this.id,
    required this.name,
    required this.type,
    this.required = false,
    required this.modifiers,
    this.maxSelection,
  });

  /// Convert to domain entity
  ModifierGroupEntity toEntity() {
    return ModifierGroupEntity(
      id: id,
      name: name,
      type: type == 'SINGLE' ? ModifierType.SINGLE : ModifierType.MULTIPLE,
      required: required,
      modifiers: modifiers.map((m) => m.toEntity()).toList(),
      maxSelection: maxSelection,
    );
  }

  /// Create from domain entity
  factory ModifierGroupModel.fromEntity(ModifierGroupEntity entity) {
    return ModifierGroupModel(
      id: entity.id,
      name: entity.name,
      type: entity.type == ModifierType.SINGLE ? 'SINGLE' : 'MULTIPLE',
      required: entity.required,
      modifiers: entity.modifiers
          .map((m) => ModifierModel.fromEntity(m))
          .toList(),
      maxSelection: entity.maxSelection,
    );
  }

  /// Create from JSON map
  factory ModifierGroupModel.fromJson(Map<String, dynamic> json) {
    return ModifierGroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      required: json['required'] as bool? ?? false,
      modifiers: (json['modifiers'] as List<dynamic>? ?? [])
          .map((m) => ModifierModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      maxSelection: json['maxSelection'] as int?,
    );
  }

  /// Convert to JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'required': required,
      'modifiers': modifiers.map((m) => m.toJson()).toList(),
      if (maxSelection != null) 'maxSelection': maxSelection,
    };
  }
}

/// Data Model - Selected Modifier (in cart/session)
class SelectedModifierModel {
  final String groupName;
  final String modifierName;
  final double price;

  const SelectedModifierModel({
    required this.groupName,
    required this.modifierName,
    required this.price,
  });

  /// Convert to domain entity
  SelectedModifierEntity toEntity() {
    return SelectedModifierEntity(
      groupName: groupName,
      modifierName: modifierName,
      price: price,
    );
  }

  /// Create from domain entity
  factory SelectedModifierModel.fromEntity(SelectedModifierEntity entity) {
    return SelectedModifierModel(
      groupName: entity.groupName,
      modifierName: entity.modifierName,
      price: entity.price,
    );
  }

  /// Create from JSON map
  factory SelectedModifierModel.fromJson(Map<String, dynamic> json) {
    return SelectedModifierModel(
      groupName: json['groupName'] as String,
      modifierName: json['modifierName'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  /// Convert to JSON map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'groupName': groupName,
      'modifierName': modifierName,
      'price': price,
    };
  }
}
