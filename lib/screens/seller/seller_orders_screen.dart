import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../services/seller_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await ref.read(sellerServiceProvider).getOrders(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );

      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateOrderStatus(Order order, String status) async {
    try {
      await ref.read(sellerServiceProvider).updateOrderStatus(order.id, status);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
            onPressed: _loadOrders,
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
                  onSubmitted: (_) => _loadOrders(),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _selectedStatus == 'all',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedStatus = 'all');
                            _loadOrders();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Processing',
                        selected: _selectedStatus == 'processing',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedStatus = 'processing');
                            _loadOrders();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Shipped',
                        selected: _selectedStatus == 'shipped',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedStatus = 'shipped');
                            _loadOrders();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Delivered',
                        selected: _selectedStatus == 'delivered',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedStatus = 'delivered');
                            _loadOrders();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Cancelled',
                        selected: _selectedStatus == 'cancelled',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedStatus = 'cancelled');
                            _loadOrders();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Refunded',
                        selected: _selectedStatus == 'refunded',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedStatus = 'refunded');
                            _loadOrders();
                          }
                        },
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
                    : _orders.isEmpty
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
                                onUpdateStatus: _updateOrderStatus,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final void Function(Order order, String status) onUpdateStatus;

  const _OrderCard({
    required this.order,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
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
                  style: theme.textTheme.titleMedium,
                ),
                _StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 8),

            // Buyer Info
            ListTile(
              title: Text(
                'Buyer: ${order.buyerName}',
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Created on ${_formatDate(order.createdAt)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Shipping Address:',
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(order.shippingAddress['address']),
                  Text(
                    '${order.shippingAddress['city']}, ${order.shippingAddress['state']} ${order.shippingAddress['zip']}',
                  ),
                  Text(order.shippingAddress['country']),
                  Text('Phone: ${order.shippingAddress['phone']}'),
                ],
              ),
            ),

            // Order Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: GHS ${order.total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Items
            Text(
              'Items:',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            ...order.items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      '${item.quantity}x',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.productName,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'GHS ${(item.price * item.quantity).toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),

            // Shipping Address
            Text(
              'Shipping Address:',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              order.shippingAddress['address'],
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              '${order.shippingAddress['city']}, ${order.shippingAddress['state']} ${order.shippingAddress['zip']}',
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              order.shippingAddress['country'],
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              'Phone: ${order.shippingAddress['phone']}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Action Buttons
            if (order.status == 'processing')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onUpdateStatus(order, 'cancelled'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => onUpdateStatus(order, 'shipped'),
                      child: const Text('Mark as Shipped'),
                    ),
                  ),
                ],
              )
            else if (order.status == 'shipped')
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => onUpdateStatus(order, 'delivered'),
                  child: const Text('Mark as Delivered'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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