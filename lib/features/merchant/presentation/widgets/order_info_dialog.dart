import 'package:flutter/material.dart';

/// Order Information captured before starting billing
class OrderInfo {
  final String orderType; // 'DINE_IN' or 'PARCEL'
  final String customerName;
  final String? tableNumber; // Required for dine-in
  final String? phoneNumber; // Optional for parcels

  OrderInfo({
    required this.orderType,
    required this.customerName,
    this.tableNumber,
    this.phoneNumber,
  });
}

/// Dialog to capture order information before billing
/// Shows for restaurant merchants to capture customer name, table, order type
class OrderInfoDialog extends StatefulWidget {
  const OrderInfoDialog({Key? key}) : super(key: key);

  @override
  State<OrderInfoDialog> createState() => _OrderInfoDialogState();
}

class _OrderInfoDialogState extends State<OrderInfoDialog> {
  String _orderType = 'DINE_IN';
  final _nameController = TextEditingController();
  final _tableController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _tableController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDineIn = _orderType == 'DINE_IN';

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.restaurant_menu),
          SizedBox(width: 8),
          Text('Order Information'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Type Toggle
            const Text(
              'Order Type',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _OrderTypeButton(
                    icon: Icons.table_restaurant,
                    label: 'Dine-in',
                    isSelected: isDineIn,
                    onTap: () => setState(() => _orderType = 'DINE_IN'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OrderTypeButton(
                    icon: Icons.shopping_bag,
                    label: 'Parcel',
                    isSelected: !isDineIn,
                    onTap: () => setState(() => _orderType = 'PARCEL'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Customer Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 16),

            // Table Number (only for dine-in)
            if (isDineIn)
              TextField(
                controller: _tableController,
                decoration: const InputDecoration(
                  labelText: 'Table Number *',
                  prefixIcon: Icon(Icons.table_bar),
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 5, A3',
                ),
                textCapitalization: TextCapitalization.characters,
              ),

            if (isDineIn) const SizedBox(height: 16),

            // Phone Number (optional, more relevant for parcels)
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: isDineIn
                    ? 'Phone (optional)'
                    : 'Phone (optional, for callback)',
                prefixIcon: const Icon(Icons.phone),
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),

            // Error Message
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _validateAndSubmit,
          icon: const Icon(Icons.shopping_cart),
          label: const Text('Start Billing'),
        ),
      ],
    );
  }

  void _validateAndSubmit() {
    setState(() => _errorMessage = null);

    final name = _nameController.text.trim();
    final table = _tableController.text.trim();
    final phone = _phoneController.text.trim();
    final isDineIn = _orderType == 'DINE_IN';

    // Validation
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter customer name');
      return;
    }

    if (isDineIn && table.isEmpty) {
      setState(() => _errorMessage = 'Please enter table number for dine-in');
      return;
    }

    // Return order info
    Navigator.pop(
      context,
      OrderInfo(
        orderType: _orderType,
        customerName: name,
        tableNumber: isDineIn ? table : null,
        phoneNumber: phone.isNotEmpty ? phone : null,
      ),
    );
  }
}

/// Order Type Button for selection
class _OrderTypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OrderTypeButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper function to show order info dialog
Future<OrderInfo?> showOrderInfoDialog(BuildContext context) {
  return showDialog<OrderInfo>(
    context: context,
    barrierDismissible: false, // Must fill form or cancel
    builder: (context) => const OrderInfoDialog(),
  );
}
