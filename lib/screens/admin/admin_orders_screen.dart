import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../services/admin_service.dart';
import '../../widgets/common/custom_text_field.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
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
      final orders = await ref.read(adminServiceProvider).getOrders(
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Orders'),
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
                              return _OrderCard(order: order);
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

  const _OrderCard({required this.order});

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

            // Buyer and Seller Info
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buyer:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        order.buyerName,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seller:',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        order.sellerName,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Order Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: \$${order.total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Created on ${_formatDate(order.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
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