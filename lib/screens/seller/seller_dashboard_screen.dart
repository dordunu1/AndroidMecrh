import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../services/seller_service.dart';
import '../../widgets/common/stats_card.dart';
import 'package:intl/intl.dart';

class SellerDashboardScreen extends ConsumerStatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  ConsumerState<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends ConsumerState<SellerDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dashboardData = await ref.read(sellerServiceProvider).getDashboardData();

      if (mounted) {
        setState(() {
          _dashboardData = dashboardData;
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
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
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
                  onRefresh: _loadDashboardData,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Statistics Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        padding: const EdgeInsets.all(16),
                        children: [
                          StatsCard(
                            title: 'Total Sales',
                            value: 'GHS ${_dashboardData!['statistics']['totalSales'].toStringAsFixed(2)}',
                            subtitle: 'All time',
                            icon: Icons.attach_money,
                          ),
                          StatsCard(
                            title: 'Available Balance',
                            value: 'GHS ${_dashboardData!['statistics']['balance'].toStringAsFixed(2)}',
                            subtitle: 'Ready to withdraw',
                            icon: Icons.account_balance_wallet,
                          ),
                          StatsCard(
                            title: 'Total Orders',
                            value: _dashboardData!['statistics']['totalOrders'].toString(),
                            subtitle: 'All time',
                            icon: Icons.shopping_cart,
                          ),
                          StatsCard(
                            title: 'Processing Orders',
                            value: _dashboardData!['statistics']['processingOrders'].toString(),
                            subtitle: 'Needs attention',
                            icon: Icons.pending_actions,
                          ),
                          StatsCard(
                            title: 'Total Products',
                            value: _dashboardData!['statistics']['totalProducts'].toString(),
                            subtitle: 'Active listings',
                            icon: Icons.inventory_2,
                          ),
                          StatsCard(
                            title: 'Average Rating',
                            value: _dashboardData!['statistics']['averageRating'].toStringAsFixed(1),
                            subtitle: '${_dashboardData!['statistics']['reviewCount']} reviews',
                            icon: Icons.star,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Recent Orders
                      Text(
                        'Recent Orders',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      if (_dashboardData!['recentOrders'].isEmpty)
                        Center(
                          child: Text(
                            'No orders yet',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _dashboardData!['recentOrders'].length,
                          separatorBuilder: (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final order = _dashboardData!['recentOrders'][index] as Order;
                            return _OrderCard(order: order);
                          },
                        ),
                    ],
                  ),
                ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Buyer: ${order.buyerInfo['name'] ?? 'Unknown'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Date: ${DateFormat('yyyy-MM-dd').format(order.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(),
            Text(
              'Total: GHS ${order.total.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              'Delivery Fee: GHS ${order.deliveryFee.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Items:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = order.items[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.quantity}x ${item.name} - GHS ${(item.price * item.quantity).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (item.options != null) ...[
                      if (item.options!['color'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Color: ${item.options!['color']}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                      if (item.options!['size'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Size: ${item.options!['size']}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                      if (item.options!['variant'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Variant: ${item.options!['variant']}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toLowerCase()) {
      case 'processing':
        color = Colors.orange;
        break;
      case 'shipped':
        color = Colors.blue;
        break;
      case 'delivered':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      case 'refunded':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
} 