import 'package:flutter/material.dart';
import '../../domain/entities/item_entity.dart';
import '../../../../widgets/unit_selector_widget.dart';

/// Beautiful, responsive dialog for adding items to cart with unit/weight support
/// Designed for both educated and uneducated merchants
class AddItemToCartDialog extends StatefulWidget {
  final ItemEntity item;
  final Function(double quantity, String unit) onAdd;

  const AddItemToCartDialog({
    super.key,
    required this.item,
    required this.onAdd,
  });

  @override
  State<AddItemToCartDialog> createState() => _AddItemToCartDialogState();
}

class _AddItemToCartDialogState extends State<AddItemToCartDialog> {
  late String _selectedUnit;
  double _selectedQuantity = 1.0;
  final bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.item.unit;
    _selectedQuantity = widget.item.defaultQuantity ?? 1.0;
  }

  String _formatQuantity(double qty) {
    if (qty == qty.toInt()) {
      return qty.toInt().toString();
    }
    return qty.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  String _formatPrice() {
    if (widget.item.isWeightBased && widget.item.pricePerUnit != null) {
      // ✅ Convert price per unit based on current selected unit
      double displayPricePerUnit = widget.item.pricePerUnit!;

      // If item was stored in kg but we're displaying in gram, convert price
      if (widget.item.unit == 'kg' && _selectedUnit == 'gram') {
        displayPricePerUnit =
            widget.item.pricePerUnit! / 1000; // ₹50/kg → ₹0.05/gram
      }
      // If item was stored in gram but we're displaying in kg, convert price
      else if (widget.item.unit == 'gram' && _selectedUnit == 'kg') {
        displayPricePerUnit =
            widget.item.pricePerUnit! * 1000; // ₹0.05/gram → ₹50/kg
      }
      // If item was stored in liter but we're displaying in ml, convert price
      else if (widget.item.unit == 'liter' && _selectedUnit == 'ml') {
        displayPricePerUnit =
            widget.item.pricePerUnit! / 1000; // ₹100/L → ₹0.1/ml
      }
      // If item was stored in ml but we're displaying in liter, convert price
      else if (widget.item.unit == 'ml' && _selectedUnit == 'liter') {
        displayPricePerUnit =
            widget.item.pricePerUnit! * 1000; // ₹0.1/ml → ₹100/L
      }
      // If item was stored in dozen but we're displaying in piece, convert price
      else if (widget.item.unit == 'dozen' && _selectedUnit == 'piece') {
        displayPricePerUnit =
            widget.item.pricePerUnit! / 12; // ₹120/dozen → ₹10/piece
      }
      // If item was stored in piece but we're displaying in dozen, convert price
      else if (widget.item.unit == 'piece' && _selectedUnit == 'dozen') {
        displayPricePerUnit =
            widget.item.pricePerUnit! * 12; // ₹10/piece → ₹120/dozen
      }

      return '₹${displayPricePerUnit.toStringAsFixed(2)}/$_selectedUnit';
    }
    return '₹${widget.item.price.toStringAsFixed(2)}/piece';
  }

  double _calculateTotal() {
    if (widget.item.isWeightBased && widget.item.pricePerUnit != null) {
      // ✅ Calculate based on ORIGINAL unit's price
      // Then convert the selected quantity to match the original unit
      double quantityInOriginalUnit = _selectedQuantity;

      // Convert selected quantity to original unit
      if (widget.item.unit == 'kg' && _selectedUnit == 'gram') {
        quantityInOriginalUnit = _selectedQuantity / 1000; // 1000g → 1kg
      } else if (widget.item.unit == 'gram' && _selectedUnit == 'kg') {
        quantityInOriginalUnit = _selectedQuantity * 1000; // 1kg → 1000g
      } else if (widget.item.unit == 'liter' && _selectedUnit == 'ml') {
        quantityInOriginalUnit = _selectedQuantity / 1000; // 1000ml → 1L
      } else if (widget.item.unit == 'ml' && _selectedUnit == 'liter') {
        quantityInOriginalUnit = _selectedQuantity * 1000; // 1L → 1000ml
      } else if (widget.item.unit == 'dozen' && _selectedUnit == 'piece') {
        quantityInOriginalUnit = _selectedQuantity / 12; // 12 pieces → 1 dozen
      } else if (widget.item.unit == 'piece' && _selectedUnit == 'dozen') {
        quantityInOriginalUnit = _selectedQuantity * 12; // 1 dozen → 12 pieces
      }

      return widget.item.pricePerUnit! * quantityInOriginalUnit;
    }
    return widget.item.price * _selectedQuantity;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.item.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatPrice(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Unit selector (if weight-based)
                    if (widget.item.isWeightBased) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.scale_outlined,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Select Unit',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      UnitSelectorWidget(
                        selectedUnit: _selectedUnit,
                        onUnitChanged: (newUnit) {
                          setState(() {
                            // ✅ SMART AUTO-CONVERSION between related units
                            final oldUnit = _selectedUnit;
                            final oldQuantity = _selectedQuantity;

                            // Convert kg ↔ gram
                            if (oldUnit == 'kg' && newUnit == 'gram') {
                              _selectedQuantity =
                                  oldQuantity * 1000; // 1kg = 1000g
                            } else if (oldUnit == 'gram' && newUnit == 'kg') {
                              _selectedQuantity =
                                  oldQuantity / 1000; // 1000g = 1kg
                            }
                            // Convert liter ↔ ml
                            else if (oldUnit == 'liter' && newUnit == 'ml') {
                              _selectedQuantity =
                                  oldQuantity * 1000; // 1L = 1000ml
                            } else if (oldUnit == 'ml' && newUnit == 'liter') {
                              _selectedQuantity =
                                  oldQuantity / 1000; // 1000ml = 1L
                            }
                            // Convert dozen ↔ piece
                            else if (oldUnit == 'dozen' && newUnit == 'piece') {
                              _selectedQuantity =
                                  oldQuantity * 12; // 1 dozen = 12 pieces
                            } else if (oldUnit == 'piece' &&
                                newUnit == 'dozen') {
                              _selectedQuantity =
                                  oldQuantity / 12; // 12 pieces = 1 dozen
                            }
                            // Different unit category - reset to 1
                            else {
                              _selectedQuantity = 1.0;
                            }

                            _selectedUnit = newUnit;
                          });
                        },
                        compact: true,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Quantity selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Select Quantity',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final result = await showDialog<double>(
                              context: context,
                              builder: (context) => CustomWeightDialog(
                                unit: _selectedUnit,
                                initialValue: _selectedQuantity,
                              ),
                            );
                            if (result != null) {
                              setState(() {
                                _selectedQuantity = result;
                              });
                            }
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Custom'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Weight presets
                    WeightPresetsWidget(
                      unit: _selectedUnit,
                      currentQuantity: _selectedQuantity,
                      onWeightSelected: (weight) {
                        setState(() {
                          _selectedQuantity = weight;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Total calculation display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Quantity:',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                '${_formatQuantity(_selectedQuantity)} $_selectedUnit',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                '₹${_calculateTotal().toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Add to cart button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onAdd(_selectedQuantity, _selectedUnit);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_shopping_cart, size: 22),
                            const SizedBox(width: 12),
                            Text(
                              'Add to Cart • ₹${_calculateTotal().toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
