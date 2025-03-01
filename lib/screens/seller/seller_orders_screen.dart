import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../models/refund.dart';
import '../../services/seller_service.dart';
import '../../services/realtime_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/custom_text_field.dart';

class SellerOrdersScreen extends ConsumerStatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'all';
  bool _isLoading = true;
  List<Order> _orders = [];
  String? _error;
  StreamSubscription? _ordersSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ordersSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setupRealtimeUpdates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) throw Exception('User not authenticated');

      _ordersSubscription?.cancel();
      _ordersSubscription = ref
          .read(realtimeServiceProvider)
          .listenToOrders(
            user.uid,
            (orders) {
              if (mounted) {
                setState(() {
                  _orders = orders;
                  _isLoading = false;
                });
              }
            },
            status: _selectedStatus == 'all' ? null : _selectedStatus,
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onStatusChanged(bool selected, String status) {
    if (selected) {
      setState(() {
        _selectedStatus = status;
      });
      _setupRealtimeUpdates();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            onPressed: _setupRealtimeUpdates,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CustomTextField(
                  controller: _searchController,
                  label: 'Search Orders',
                  prefixIcon: const Icon(Icons.search),
                  onSubmitted: (_) => _setupRealtimeUpdates(),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      StatusFilterChip(
                        label: 'All',
                        value: 'all',
                        selected: _selectedStatus == 'all',
                        onSelected: (selected) => _onStatusChanged(selected, 'all'),
                      ),
                      const SizedBox(width: 8),
                      StatusFilterChip(
                        label: 'Processing',
                        value: 'processing',
                        selected: _selectedStatus == 'processing',
                        onSelected: (selected) => _onStatusChanged(selected, 'processing'),
                      ),
                      const SizedBox(width: 8),
                      StatusFilterChip(
                        label: 'Shipped',
                        value: 'shipped',
                        selected: _selectedStatus == 'shipped',
                        onSelected: (selected) => _onStatusChanged(selected, 'shipped'),
                      ),
                      const SizedBox(width: 8),
                      StatusFilterChip(
                        label: 'Delivered',
                        value: 'delivered',
                        selected: _selectedStatus == 'delivered',
                        onSelected: (selected) => _onStatusChanged(selected, 'delivered'),
                      ),
                      const SizedBox(width: 8),
                      StatusFilterChip(
                        label: 'Cancelled',
                        value: 'cancelled',
                        selected: _selectedStatus == 'cancelled',
                        onSelected: (selected) => _onStatusChanged(selected, 'cancelled'),
                      ),
                      const SizedBox(width: 8),
                      StatusFilterChip(
                        label: 'Refunded',
                        value: 'refunded',
                        selected: _selectedStatus == 'refunded',
                        onSelected: (selected) => _onStatusChanged(selected, 'refunded'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _setupRealtimeUpdates,
                        child: _orders.isEmpty
                            ? Center(
                                child: Text(
                                  'No orders found',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _orders.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final order = _orders[index];
                                  return _OrderCard(
                                    order: order,
                                    onUpdateStatus: (newStatus) async {
                                      try {
                                        await ref.read(sellerServiceProvider).updateOrderStatus(
                                              order.id,
                                              newStatus,
                                            );
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Failed to update order status: $e'),
                                              backgroundColor: theme.colorScheme.error,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String?> onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (bool isSelected) => onSelected(isSelected ? value : null),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final Order order;
  final void Function(String) onUpdateStatus;

  const _OrderCard({
    required this.order,
    required this.onUpdateStatus,
  });

  Future<void> _showShippingDialog(BuildContext context, WidgetRef ref) async {
    final trackingController = TextEditingController();
    final carrierController = TextEditingController();
    bool hasTracking = false;
    
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Shipping Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Has Tracking Number'),
                value: hasTracking,
                onChanged: (value) {
                  setState(() {
                    hasTracking = value;
                  });
                },
              ),
              if (hasTracking) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: trackingController,
                  decoration: const InputDecoration(
                    labelText: 'Tracking Number',
                    hintText: 'Enter tracking number',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: carrierController,
                  decoration: const InputDecoration(
                    labelText: 'Shipping Carrier',
                    hintText: 'Enter shipping carrier name',
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (hasTracking && (trackingController.text.isEmpty || carrierController.text.isEmpty)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all tracking fields')),
                  );
                  return;
                }
                Navigator.pop(context, {
                  'trackingNumber': hasTracking ? trackingController.text : null,
                  'shippingCarrier': hasTracking ? carrierController.text : null,
                });
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      try {
        if (result['trackingNumber'] != null && result['shippingCarrier'] != null) {
          await ref.read(sellerServiceProvider).updateShippingInfo(
            order.id,
            {
              'trackingNumber': result['trackingNumber'],
              'shippingCarrier': result['shippingCarrier'],
            },
          );
        }
        onUpdateStatus('shipped');
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update shipping info: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showRefundDialog(BuildContext context, WidgetRef ref, Refund refund) async {
    final messageController = TextEditingController();
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Refund Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${refund.shortOrderId}'),
            const SizedBox(height: 8),
            Text('Amount: GHS ${refund.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Reason: ${refund.reason}'),
            const SizedBox(height: 8),
            Text('Phone: ${refund.buyerPhone}'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message (Optional)',
                hintText: 'Add a note about your decision',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'approved': false,
                'message': messageController.text,
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, {
                'approved': true,
                'message': messageController.text,
              });
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await ref.read(sellerServiceProvider).processRefund(
          refundId: refund.id,
          approved: result['approved'],
          message: result['message'],
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Refund ${result['approved'] ? 'approved' : 'rejected'} successfully'),
              backgroundColor: result['approved'] ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order ID and Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order #${order.id.substring(0, 8)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        _StatusChip(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Buyer Info and Date
                    Text(
                      'Buyer: ${order.buyerInfo['name'] ?? 'Unknown'}',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created on ${_formatDate(order.createdAt)}',
                      style: theme.textTheme.bodySmall,
                    ),

                    // Order Total and Delivery Fee
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'GHS ${order.total.toStringAsFixed(2)}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Delivery Fee: GHS ${order.deliveryFee.toStringAsFixed(2)}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Order Items
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Items',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: order.items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = order.items[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.selectedColorImage != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.selectedColorImage!,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.error),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${item.quantity}x ${item.name}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'GHS ${(item.price * item.quantity).toStringAsFixed(2)}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  if (item.selectedColor != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: _getColorFromString(item.selectedColor!),
                                            border: Border.all(color: Colors.grey),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          item.selectedColor!,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.secondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (item.selectedSize != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.secondary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Size: ${item.selectedSize}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Shipping Address
              const Divider(),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shipping Address Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shipping Address',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(order.shippingAddressName),
                            Text(order.shippingAddressAddress),
                            Text('${order.shippingAddressCity}, ${order.shippingAddressState}'),
                            Text('${order.shippingAddressCountry} ${order.shippingAddressZip}'),
                            Text('Phone: ${order.shippingAddressPhone}'),
                          ],
                        ),
                      ),
                      const VerticalDivider(thickness: 1),
                      // Payment Information Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Information',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Method: ${order.paymentMethod == 'mtn_momo' ? 'MTN MoMo' : 'Telecel Cash'}'),
                            Text('Name: ${order.buyerPaymentName ?? 'N/A'}'),
                            Text('Status: ${order.paymentStatus ?? 'pending'}', style: TextStyle(
                              color: (order.paymentStatus ?? 'pending') == 'paid' ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),

              // Action Buttons
              if (order.status == 'processing' || order.status == 'shipped') ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (order.status == 'processing') ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => onUpdateStatus('cancelled'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _showShippingDialog(context, ref),
                            child: const Text('Mark as Shipped'),
                          ),
                        ),
                      ] else if (order.status == 'shipped')
                        Expanded(
                          child: FilledButton(
                            onPressed: () => onUpdateStatus('delivered'),
                            child: const Text('Mark as Delivered'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        _RefundFAB(order: order),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'pink':
        return Colors.pink;
      case 'brown':
        return Colors.brown;
      case 'grey':
        return Colors.grey;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      default:
        return Colors.grey;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color getStatusColor() {
      switch (status.toLowerCase()) {
        case 'processing':
          return Colors.blue;
        case 'shipped':
          return Colors.orange;
        case 'delivered':
          return Colors.green;
        case 'cancelled':
          return Colors.red;
        case 'refunded':
          return Colors.purple;
        default:
          return theme.colorScheme.primary;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: theme.textTheme.bodySmall?.copyWith(
          color: getStatusColor(),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class StatusFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const StatusFilterChip({
    super.key,
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: selected ? Theme.of(context).primaryColor : null,
      ),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }
}

class _RefundFAB extends ConsumerWidget {
  final Order order;

  const _RefundFAB({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (order.status != 'refund_requested') return const SizedBox.shrink();

    return Positioned(
      right: 16,
      bottom: 16,
      child: FloatingActionButton(
        heroTag: 'refund_fab_${order.id}',
        onPressed: () async {
          try {
            final refunds = await ref.read(sellerServiceProvider).getRefunds(
              status: 'pending',
            );
            final refund = refunds.firstWhere(
              (r) => r.orderId == order.id,
              orElse: () => throw Exception('Refund request not found'),
            );
            
            if (context.mounted) {
              await _showRefundDialog(context, ref, refund);
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(e.toString()),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        },
        backgroundColor: Theme.of(context).colorScheme.error,
        child: const Icon(Icons.currency_exchange),
      ),
    );
  }

  Future<void> _showRefundDialog(BuildContext context, WidgetRef ref, Refund refund) async {
    final messageController = TextEditingController();
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Refund Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${refund.shortOrderId}'),
            const SizedBox(height: 8),
            Text('Amount: GHS ${refund.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Reason: ${refund.reason}'),
            const SizedBox(height: 8),
            Text('Phone: ${refund.buyerPhone}'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message (Optional)',
                hintText: 'Add a note about your decision',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'approved': false,
                'message': messageController.text,
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, {
                'approved': true,
                'message': messageController.text,
              });
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        await ref.read(sellerServiceProvider).processRefund(
          refundId: refund.id,
          approved: result['approved'],
          message: result['message'],
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Refund ${result['approved'] ? 'approved' : 'rejected'} successfully'),
              backgroundColor: result['approved'] ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
} 