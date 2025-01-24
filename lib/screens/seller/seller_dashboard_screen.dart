import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../services/seller_service.dart';
import '../../widgets/common/stats_card.dart';

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
                        children: [
                          StatsCard(
                            title: 'Total Sales',
                            value: '\$${_dashboardData!['statistics']['totalSales'].toStringAsFixed(2)}',
                            subtitle: 'All time',
                            icon: Icons.attach_money,
                          ),
                          StatsCard(
                            title: 'Available Balance',
                            value: '\$${_dashboardData!['statistics']['balance'].toStringAsFixed(2)}',
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
                            title: 'Total Products',
                            value: _dashboardData!['statistics']['totalProducts'].toString(),
                            subtitle: 'Active listings',
                            icon: Icons.inventory,
                          ),
                          StatsCard(
                            title: 'Processing Orders',
                            value: _dashboardData!['statistics']['processingOrders'].toString(),
                            subtitle: 'Needs attention',
                            icon: Icons.pending_actions,
                          ),
                          StatsCard(
                            title: 'Average Rating',
                            value: _dashboardData!['statistics']['averageRating'].toStringAsFixed(1),
                            subtitle: 'From ${_dashboardData!['statistics']['reviewCount']} reviews',
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
                            final order = Order.fromMap(
                              _dashboardData!['recentOrders'][index] as Map<String, dynamic>,
                              _dashboardData!['recentOrders'][index]['id'] as String
                            );
                            return ListTile(
                              title: Text(
                                'Order #${order.id}',
                                style: theme.textTheme.titleMedium,
                              ),
                              subtitle: Text(
                                'Buyer: ${order.buyerName}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            );
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
            Text(
              'Buyer: ${order.buyerName}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
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
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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