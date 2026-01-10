import 'package:flutter/material.dart';
import '../../domain/entities/modifier_entity.dart';

/// Result of modifier selection
class ModifierSelectionResult {
  final List<SelectedModifierEntity> selectedModifiers;
  final String? specialInstructions;
  final double additionalCost;

  ModifierSelectionResult({
    required this.selectedModifiers,
    this.specialInstructions,
    required this.additionalCost,
  });
}

/// Dialog for selecting modifiers when adding item to cart
/// Shows modifier groups and allows customer customization
class ItemCustomizationDialog extends StatefulWidget {
  final String itemName;
  final List<ModifierGroupEntity> modifierGroups;

  const ItemCustomizationDialog({
    Key? key,
    required this.itemName,
    required this.modifierGroups,
  }) : super(key: key);

  @override
  State<ItemCustomizationDialog> createState() =>
      _ItemCustomizationDialogState();
}

class _ItemCustomizationDialogState extends State<ItemCustomizationDialog> {
  final Map<String, List<ModifierEntity>> _selectedModifiers = {};
  final _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize with default selections
    for (final group in widget.modifierGroups) {
      final defaults = group.modifiers.where((m) => m.isDefault).toList();
      if (defaults.isNotEmpty) {
        _selectedModifiers[group.id] = defaults;
      }
    }
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalAdditional = _calculateAdditionalCost();

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customize ${widget.itemName}'),
          if (totalAdditional > 0)
            Text(
              '+₹${totalAdditional.toStringAsFixed(0)} additional',
              style: TextStyle(
                fontSize: 14,
                color: Colors.green.shade700,
                fontWeight: FontWeight.normal,
              ),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modifier Groups
              ...widget.modifierGroups.map(
                (group) => _buildModifierGroup(group),
              ),

              const SizedBox(height: 16),

              // Special Instructions
              TextField(
                controller: _instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Special Instructions',
                  hintText: 'e.g., Less oil, Extra plate',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _confirmSelection,
          child: Text(
            totalAdditional > 0
                ? 'Add (+₹${totalAdditional.toStringAsFixed(0)})'
                : 'Add to Cart',
          ),
        ),
      ],
    );
  }

  Widget _buildModifierGroup(ModifierGroupEntity group) {
    final selectedInGroup = _selectedModifiers[group.id] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group Title
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (group.required)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Required',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Modifiers List
            ...group.modifiers.map((modifier) {
              final isSelected = selectedInGroup.contains(modifier);

              return CheckboxListTile(
                value: isSelected,
                onChanged: (_) => _toggleModifier(group, modifier),
                title: Row(
                  children: [
                    Expanded(child: Text(modifier.name)),
                    if (modifier.price > 0)
                      Text(
                        '+₹${modifier.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }

  void _toggleModifier(ModifierGroupEntity group, ModifierEntity modifier) {
    setState(() {
      final selectedInGroup = _selectedModifiers[group.id] ?? [];

      if (selectedInGroup.contains(modifier)) {
        // Deselect
        _selectedModifiers[group.id] = selectedInGroup
            .where((m) => m.id != modifier.id)
            .toList();
      } else {
        // Select
        if (group.type == ModifierType.SINGLE) {
          // Single selection - replace
          _selectedModifiers[group.id] = [modifier];
        } else {
          // Multiple selection - add
          final maxReached =
              group.maxSelection != null &&
              selectedInGroup.length >= group.maxSelection!;
          if (!maxReached) {
            _selectedModifiers[group.id] = [...selectedInGroup, modifier];
          }
        }
      }
    });
  }

  double _calculateAdditionalCost() {
    double total = 0.0;
    for (final selections in _selectedModifiers.values) {
      for (final modifier in selections) {
        total += modifier.price;
      }
    }
    return total;
  }

  void _confirmSelection() {
    // Convert to SelectedModifierEntity
    final List<SelectedModifierEntity> selected = [];
    for (final entry in _selectedModifiers.entries) {
      final groupId = entry.key;
      final modifiers = entry.value;
      final group = widget.modifierGroups.firstWhere((g) => g.id == groupId);

      for (final modifier in modifiers) {
        selected.add(
          SelectedModifierEntity(
            groupName: group.name,
            modifierName: modifier.name,
            price: modifier.price,
          ),
        );
      }
    }

    final instructions = _instructionsController.text.trim();

    Navigator.pop(
      context,
      ModifierSelectionResult(
        selectedModifiers: selected,
        specialInstructions: instructions.isNotEmpty ? instructions : null,
        additionalCost: _calculateAdditionalCost(),
      ),
    );
  }
}

/// Helper function to show customization dialog
Future<ModifierSelectionResult?> showItemCustomizationDialog(
  BuildContext context,
  String itemName,
  List<ModifierGroupEntity> modifierGroups,
) {
  return showDialog<ModifierSelectionResult>(
    context: context,
    builder: (context) => ItemCustomizationDialog(
      itemName: itemName,
      modifierGroups: modifierGroups,
    ),
  );
}
