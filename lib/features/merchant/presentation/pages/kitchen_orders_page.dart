import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:ui';
import '../../data/models/session_model.dart';
import '../../../../core/services/device_mode_service.dart';

/// Kitchen Orders Page - displays active restaurant orders with real-time updates
/// Merchant uses this screen on second device to track cooking status
class KitchenOrdersPage extends StatefulWidget {
  final String merchantId;

  const KitchenOrdersPage({super.key, required this.merchantId});

  @override
  State<KitchenOrdersPage> createState() => _KitchenOrdersPageState();
}

class _KitchenOrdersPageState extends State<KitchenOrdersPage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh screen every 10 seconds (in addition to real-time stream)
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent back navigation if in kitchen mode
        final isKitchen = await DeviceModeService.isKitchenMode();
        return !isKitchen; // Return false to block, true to allow
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.restaurant),
              SizedBox(width: 8),
              Text('Kitchen Orders'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() {}),
              tooltip: 'Refresh orders',
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('billingSessions')
              .where('merchantId', isEqualTo: widget.merchantId)
              // Show both ACTIVE and COMPLETED sessions (completed = paid orders)
              .where('status', whereIn: ['ACTIVE', 'COMPLETED'])
              .where('kitchenStatus', whereIn: ['NEW', 'COOKING', 'READY'])
              .orderBy('createdAt', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: Colors.green.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No Active Orders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All orders completed! ✅',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }

            final orders = snapshot.data!.docs
                .map((doc) => SessionModel.fromFirestore(doc))
                .toList();

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {});
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _KitchenOrderCard(
                    order: order,
                    onStatusUpdate: (newStatus) =>
                        _updateOrderStatus(order, newStatus),
                  );
                },
              ),
            );
          },
        ), // End of body StreamBuilder
      ), // End of Scaffold (child of WillPopScope)
    ); // End of WillPopScope
  }

  Future<void> _updateOrderStatus(SessionModel order, String newStatus) async {
    try {
      final updates = <String, dynamic>{
        'kitchenStatus': newStatus,
        'updatedBy': FirebaseAuth.instance.currentUser?.uid,
      };

      // Add timestamps based on status
      if (newStatus == 'COOKING') {
        updates['cookingStartedAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == 'READY') {
        updates['readyAt'] = FieldValue.serverTimestamp();
      } else if (newStatus == 'SERVED') {
        // When marked as served, complete the session
        updates['status'] = 'COMPLETED';
        updates['completedAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection('billingSessions')
          .doc(order.sessionId)
          .update(updates);

      // No snackbar - silent update
    } catch (e) {
      // Silent error handling - could log to console if needed
      debugPrint('Failed to update kitchen status: $e');
    }
  }
}

/// Kitchen Order Card Widget - displays single order with status and actions
class _KitchenOrderCard extends StatefulWidget {
  final SessionModel order;
  final Function(String) onStatusUpdate;

  const _KitchenOrderCard({
    super.key,
    required this.order,
    required this.onStatusUpdate,
  });

  @override
  State<_KitchenOrderCard> createState() => _KitchenOrderCardState();
}

class _KitchenOrderCardState extends State<_KitchenOrderCard> {
  bool _isReady = false; // Toggle state for Ready/Serve

  @override
  Widget build(BuildContext context) {
    final status = widget.order.kitchenStatus ?? 'NEW';
    final isNew = status == 'NEW';
    final isCooking = status == 'COOKING';

    // Status colors
    final Color statusColor = isNew
        ? Colors.red
        : isCooking
        ? Colors.orange
        : Colors.green;

    final Color cardColor = isNew
        ? Colors.red.shade50
        : isCooking
        ? Colors.orange.shade50
        : Colors.green.shade50;

    // Time elapsed
    final timeElapsed = _getTimeElapsed(widget.order.createdAt.toDate());

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isNew
                            ? Icons.fiber_new
                            : isCooking
                            ? Icons.restaurant
                            : Icons.check_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  timeElapsed,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Order Info
            _buildOrderInfo(),

            const Divider(height: 24),

            // Items List
            ...widget.order.items.map((item) => _buildItemRow(item)),

            const SizedBox(height: 16),

            // Action Buttons or Toggle
            if (isNew)
              _buildActionButtons(context, status)
            else if (isCooking)
              _buildReadyServeToggle(),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyServeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (_isReady) {
                setState(() => _isReady = false);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: !_isReady ? Colors.orange : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Ready',
                style: TextStyle(
                  color: !_isReady ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (!_isReady) {
                setState(() => _isReady = true);
                // Auto-mark as served after toggle
                Future.delayed(const Duration(milliseconds: 300), () {
                  widget.onStatusUpdate('SERVED');
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _isReady ? Colors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Serve',
                style: TextStyle(
                  color: _isReady ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
    final isParcel = widget.order.orderType == 'PARCEL';
    final icon = isParcel ? Icons.shopping_bag : Icons.table_restaurant;
    final orderTypeText = isParcel ? 'PARCEL' : 'Dine-in';

    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(
          orderTypeText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (widget.order.tableNumber != null) ...[
          const SizedBox(width: 8),
          Text(
            '• Table ${widget.order.tableNumber}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
        if (widget.order.customerName != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Text(
              widget.order.customerName!,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildItemRow(SessionItemLine item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.qty}x ',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          // Modifiers
          if (item.selectedModifiers != null &&
              item.selectedModifiers!.isNotEmpty)
            ...item.selectedModifiers!.map(
              (mod) => Padding(
                padding: const EdgeInsets.only(left: 24, top: 2),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_right, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      mod.modifierName,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (mod.price > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '+₹${mod.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          // Special Instructions
          if (item.specialInstructions != null &&
              item.specialInstructions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 4),
              child: Row(
                children: [
                  const Icon(Icons.note, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.specialInstructions!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String status) {
    if (status == 'NEW') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => widget.onStatusUpdate('COOKING'),
          icon: const Icon(Icons.restaurant),
          label: const Text('START COOKING', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    } else if (status == 'COOKING') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => widget.onStatusUpdate('READY'),
          icon: const Icon(Icons.check_circle),
          label: const Text('MARK AS READY', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    } else {
      // READY - allow marking as SERVED
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => widget.onStatusUpdate('SERVED'),
          icon: const Icon(Icons.done_all),
          label: const Text('MARK AS SERVED', style: TextStyle(fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }
  }

  String _getTimeElapsed(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      return '${hours}h ${minutes}m ago';
    }
  }
}
