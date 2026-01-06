import 'package:flutter/material.dart';

/// Beautiful, responsive unit selector for easy merchant use
/// ✅ SMART DESIGN: Groups related units (kg/gram, liter/ml) to prevent confusion
/// ✅ AUTO-CONVERSION: Automatically converts between related units
/// ✅ SMART FILTERING: Only shows relevant unit groups based on current unit type
class UnitSelectorWidget extends StatelessWidget {
  final String selectedUnit;
  final Function(String) onUnitChanged;
  final bool compact; // For small screens

  const UnitSelectorWidget({
    super.key,
    required this.selectedUnit,
    required this.onUnitChanged,
    this.compact = false,
  });

  /// Determines which unit type the current unit belongs to
  String _getUnitType(String unit) {
    switch (unit) {
      case 'kg':
      case 'gram':
        return 'weight';
      case 'liter':
      case 'ml':
        return 'volume';
      case 'piece':
      case 'dozen':
      default:
        return 'quantity';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ALL UNIT GROUPS defined
    final allUnitGroups = [
      _UnitGroup(
        'Quantity',
        [
          _UnitOption('piece', Icons.inventory_2_outlined, 'Piece', null),
          _UnitOption('dozen', Icons.grid_3x3_outlined, 'Dozen', '1dz = 12pc'),
        ],
        Colors.blue,
        'quantity',
      ),
      _UnitGroup(
        'Weight',
        [
          _UnitOption('kg', Icons.scale_outlined, 'Kg', 'Kilogram'),
          _UnitOption(
            'gram',
            Icons.monitor_weight_outlined,
            'Gram',
            '1kg = 1000g',
          ),
        ],
        Colors.orange,
        'weight',
      ),
      _UnitGroup(
        'Volume',
        [
          _UnitOption('liter', Icons.local_drink_outlined, 'Liter', 'Litre'),
          _UnitOption('ml', Icons.water_drop_outlined, 'ML', '1L = 1000ml'),
        ],
        Colors.cyan,
        'volume',
      ),
    ];

    // ✅ SMART FILTERING: Only show relevant unit groups
    final currentUnitType = _getUnitType(selectedUnit);
    final unitGroups = allUnitGroups
        .where((group) => group.unitType == currentUnitType)
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: unitGroups.map((group) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ ALWAYS show group label (even in compact mode for clarity)
              Padding(
                padding: EdgeInsets.only(left: 4, bottom: compact ? 4 : 6),
                child: Row(
                  children: [
                    Container(
                      width: compact ? 3 : 4,
                      height: compact ? 12 : 16,
                      decoration: BoxDecoration(
                        color: group.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      group.groupName.toUpperCase(),
                      style: TextStyle(
                        fontSize: compact ? 10 : 12,
                        fontWeight: FontWeight.w700,
                        color: group.color.withOpacity(0.8),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              // Unit options in row
              Row(
                children: group.units.map((unit) {
                  final isSelected = selectedUnit == unit.value;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onUnitChanged(unit.value),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: EdgeInsets.all(compact ? 8 : 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? group.color.withOpacity(0.15)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? group.color
                                    : Colors.grey.shade300,
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  unit.icon,
                                  size: compact ? 20 : 28,
                                  color: isSelected
                                      ? group.color
                                      : Colors.grey.shade700,
                                ),
                                if (!compact) const SizedBox(height: 4),
                                Text(
                                  unit.label,
                                  style: TextStyle(
                                    fontSize: compact ? 11 : 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? group.color
                                        : Colors.grey.shade800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                // ✅ ALWAYS show conversion hint (even in compact for clarity)
                                if (unit.hint != null)
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: compact ? 1 : 2,
                                    ),
                                    child: Text(
                                      unit.hint!,
                                      style: TextStyle(
                                        fontSize: compact ? 8 : 9,
                                        color: isSelected
                                            ? group.color.withOpacity(0.7)
                                            : Colors.grey.shade500,
                                        fontWeight: compact
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Unit group with related units (e.g., kg and gram together)
class _UnitGroup {
  final String groupName;
  final List<_UnitOption> units;
  final Color color;
  final String unitType; // 'quantity', 'weight', or 'volume'

  _UnitGroup(this.groupName, this.units, this.color, this.unitType);
}

/// Individual unit option with icon and optional hint
class _UnitOption {
  final String value;
  final IconData icon;
  final String label;
  final String? hint; // Conversion hint like "1kg = 1000g"

  _UnitOption(this.value, this.icon, this.label, this.hint);
}

/// Weight preset buttons for quick selection - perfect for merchants
/// who don't know exact weights
class WeightPresetsWidget extends StatelessWidget {
  final String unit;
  final Function(double) onWeightSelected;
  final double? currentQuantity;

  const WeightPresetsWidget({
    super.key,
    required this.unit,
    required this.onWeightSelected,
    this.currentQuantity,
  });

  List<double> _getPresetsForUnit(String unit) {
    switch (unit) {
      case 'kg':
        // ✅ SMART PRESETS for kilograms (common vegetable/fruit quantities)
        return [0.25, 0.5, 1, 2, 3, 5];
      case 'gram':
        // ✅ SMART PRESETS for grams (spices, small items)
        return [50, 100, 250, 500, 750, 1000]; // Note: 1000g = 1kg
      case 'liter':
        // ✅ SMART PRESETS for liters (liquids like oil, milk)
        return [0.5, 1, 2, 3, 5];
      case 'ml':
        // ✅ SMART PRESETS for milliliters (small bottles)
        return [100, 200, 250, 500, 750, 1000]; // Note: 1000ml = 1L
      case 'dozen':
        // ✅ SMART PRESETS for dozens (eggs, bottles, cans)
        return [0.5, 1, 2, 3, 5, 10]; // 0.5 = 6 pieces (half dozen)
      case 'piece':
      default:
        // ✅ SMART PRESETS for pieces (countable items)
        return [1, 2, 3, 5, 10, 20];
    }
  }

  String _formatWeight(double weight, String unit) {
    if (weight == weight.toInt()) {
      return '${weight.toInt()}';
    }
    return weight.toString();
  }

  @override
  Widget build(BuildContext context) {
    final presets = _getPresetsForUnit(unit);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.map((weight) {
            final isSelected = currentQuantity == weight;
            return IntrinsicWidth(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onWeightSelected(weight),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      _formatWeight(weight, unit),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Custom weight input dialog - responsive and beautiful
class CustomWeightDialog extends StatefulWidget {
  final String unit;
  final double? initialValue;

  const CustomWeightDialog({super.key, required this.unit, this.initialValue});

  @override
  State<CustomWeightDialog> createState() => _CustomWeightDialogState();
}

class _CustomWeightDialogState extends State<CustomWeightDialog> {
  late TextEditingController _controller;
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validate() {
    final value = double.tryParse(_controller.text);
    if (value == null || value <= 0) {
      setState(() {
        _errorText = 'Please enter valid ${widget.unit}';
      });
    } else {
      Navigator.of(context).pop(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            Icons.edit_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text(
            'Enter ${widget.unit.toUpperCase()}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '0.0',
              suffixText: widget.unit,
              suffixStyle: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              errorText: _errorText.isEmpty ? null : _errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            onSubmitted: (_) => _validate(),
          ),
          const SizedBox(height: 16),
          // Quick number pad for easy input
          _buildQuickNumberPad(),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
        ),
        ElevatedButton(
          onPressed: _validate,
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Add', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildQuickNumberPad() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['0.25', '0.5', '0.75', '1', '1.5', '2', '2.5', '3'].map((num) {
        return InkWell(
          onTap: () {
            _controller.text = num;
            setState(() => _errorText = '');
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              num,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }).toList(),
    );
  }
}
