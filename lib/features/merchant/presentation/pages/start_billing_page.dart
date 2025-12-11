import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../providers/item_provider.dart';
import '../providers/session_provider.dart';
import 'live_session_page.dart';

/// Start Billing Page - Select items and create billing session
class StartBillingPage extends StatefulWidget {
  final String merchantId;

  const StartBillingPage({super.key, required this.merchantId});

  @override
  State<StartBillingPage> createState() => _StartBillingPageState();
}

class _StartBillingPageState extends State<StartBillingPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItemProvider>().loadItems(widget.merchantId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Start Billing'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        ),
      ),
      body: Row(
        children: [
          Expanded(flex: 2, child: _buildItemSelection()),
          Container(width: 1, color: AppColors.lightBorder),
          Expanded(child: _buildCart()),
        ],
      ),
    );
  }

  Widget _buildItemSelection() {
    return Consumer<ItemProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!provider.hasItems) {
          return const Center(child: Text('No items available'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          itemCount: provider.items.length,
          itemBuilder: (context, index) {
            final item = provider.items[index];
            return Card(
              child: ListTile(
                title: Text(item.name),
                subtitle: Text('₹${item.price} • Tax: ${item.taxRate}%'),
                trailing: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  onPressed: () {
                    context.read<SessionProvider>().addToCart(item);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${item.name} added to cart')),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCart() {
    return Consumer<SessionProvider>(
      builder: (context, provider, child) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMD),
              color: AppColors.lightSurface,
              child: Text(
                'Cart (${provider.cartItemCount})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: provider.cartItems.isEmpty
                  ? const Center(child: Text('Cart is empty'))
                  : ListView.builder(
                      itemCount: provider.cartItems.length,
                      itemBuilder: (context, index) {
                        final item = provider.cartItems[index];
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text('₹${item.price} × ${item.qty}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () {
                                  provider.updateCartItemQuantity(
                                    item.name,
                                    item.qty - 1,
                                  );
                                },
                              ),
                              Text('${item.qty}'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  provider.updateCartItemQuantity(
                                    item.name,
                                    item.qty + 1,
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  provider.removeFromCart(item.name);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingLG),
              decoration: BoxDecoration(
                color: AppColors.lightSurface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text('₹${provider.cartSubtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tax:'),
                      Text('₹${provider.cartTax.toStringAsFixed(2)}'),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '₹${provider.cartTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingMD),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(AppDimensions.paddingMD),
                        backgroundColor: Colors.green,
                      ),
                      onPressed: provider.cartItems.isEmpty
                          ? null
                          : () async {
                              final sessionId = await provider.createSession(
                                widget.merchantId,
                              );
                              if (sessionId != null && mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        LiveSessionPage(sessionId: sessionId),
                                  ),
                                );
                              }
                            },
                      child: const Text(
                        'Create Session',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
