import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart' as app_order;
import '../../models/seller.dart';
import '../../services/admin_service.dart';
import '../../services/realtime_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/admin/stats_card.dart';
import '../../widgets/admin/recent_orders_list.dart';
import '../../widgets/admin/top_sellers_list.dart';
import '../../widgets/admin/pending_actions_list.dart';
import 'admin_stores_revenue_screen.dart';
import '../../routes.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  StreamSubscription? _dashboardSubscription;
  String _selectedTimeRange = 'today';
  String _error = '';

  @override
  void initState() {
    super.initState();
    _checkAdminAndSetupUpdates();
  }

  @override
  void dispose() {
    _dashboardSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkAdminAndSetupUpdates() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final isAdmin = await ref.read(adminServiceProvider).isAdmin(user.uid);
      if (!isAdmin) {
        throw Exception('User is not an admin');
      }

      _dashboardSubscription?.cancel();
      _dashboardSubscription = await ref
          .read(realtimeServiceProvider)
          .listenToAdminDashboard((data) {
            if (mounted) {
              setState(() {
                _dashboardData = data;
                _isLoading = false;
              });
            }
          });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, size: 24, color: iconColor ?? Colors.pink),
              const SizedBox(width: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersList(List<Map<String, dynamic>> orders) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Orders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: 'All Stores',
                      items: const [
                        DropdownMenuItem(
                          value: 'All Stores',
                          child: Text('All Stores'),
                        ),
                      ],
                      onChanged: (value) {},
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.grid_view),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('ORDER ID')),
                DataColumn(label: Text('SELLER')),
                DataColumn(label: Text('CUSTOMER')),
                DataColumn(label: Text('AMOUNT')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('DATE')),
              ],
              rows: orders.map((order) {
                return DataRow(
                  cells: [
                    DataCell(Text(order['id'] as String)),
                    DataCell(Text(order['seller'] as String)),
                    DataCell(Text(order['customer'] as String)),
                    DataCell(Text('\$${(order['amount'] as num).toStringAsFixed(2)}')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order['status'] as String),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          order['status'] as String,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    DataCell(Text(order['date'] as String)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green[100]!;
      case 'cancelled':
        return Colors.red[100]!;
      case 'refunded':
        return Colors.orange[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(_error),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkAdminAndSetupUpdates,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _dashboardData!['stats'];
    final pendingActions = List<Map<String, dynamic>>.from(
      _dashboardData!['pendingActions'] as List<dynamic>? ?? [],
    );
    final recentOrders = List<Map<String, dynamic>>.from(
      _dashboardData!['recentOrders'] as List<dynamic>? ?? [],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() => _selectedTimeRange = value);
              _checkAdminAndSetupUpdates();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'today',
                child: Text('Today'),
              ),
              const PopupMenuItem(
                value: 'week',
                child: Text('This Week'),
              ),
              const PopupMenuItem(
                value: 'month',
                child: Text('This Month'),
              ),
              const PopupMenuItem(
                value: 'year',
                child: Text('This Year'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkAdminAndSetupUpdates,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _checkAdminAndSetupUpdates,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildMetricCard(
                    title: 'All-time Sales',
                    value: '\$${stats['totalSales'].toStringAsFixed(2)}',
                    subtitle: 'Total volume (excl. refunds)',
                    icon: Icons.trending_up,
                  ),
                  _buildMetricCard(
                    title: 'Current Sales',
                    value: '\$${(stats['totalSales'] - stats['totalRefunds']).toStringAsFixed(2)}',
                    subtitle: 'Net sales after refunds',
                    icon: Icons.attach_money,
                  ),
                  _buildMetricCard(
                    title: 'Total Refunds',
                    value: '\$${stats['totalRefunds'].toStringAsFixed(2)}',
                    subtitle: 'Refunded amount',
                    icon: Icons.credit_card,
                  ),
                  _buildMetricCard(
                    title: 'All-time Platform Fees',
                    value: '\$${stats['totalPlatformFees'].toStringAsFixed(2)}',
                    subtitle: 'Total platform fees',
                    icon: Icons.account_balance_wallet,
                  ),
                  _buildMetricCard(
                    title: 'Current Platform Fees',
                    value: '\$${(stats['totalPlatformFees'] - (stats['totalRefunds'] * 0.1)).toStringAsFixed(2)}',
                    subtitle: 'Platform fees after refunds',
                    icon: Icons.payments,
                  ),
                  _buildMetricCard(
                    title: 'Active Sellers',
                    value: stats['activeSellers'].toString(),
                    subtitle: '${stats['totalProducts']} products listed',
                    icon: Icons.store,
                  ),
                  _buildMetricCard(
                    title: 'Total Orders',
                    value: stats['totalOrders'].toString(),
                    subtitle: 'All-time orders',
                    icon: Icons.shopping_bag,
                  ),
                  _buildMetricCard(
                    title: 'Total Products',
                    value: stats['totalProducts'].toString(),
                    subtitle: 'Listed products',
                    icon: Icons.inventory_2,
                  ),
                  _buildMetricCard(
                    title: 'Total Customers',
                    value: stats['totalCustomers'].toString(),
                    subtitle: 'Unique buyers',
                    icon: Icons.people,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildRecentOrdersList(recentOrders),

              // Pending Actions
              if (pendingActions.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pending Actions',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        PendingActionsList(
                          actions: pendingActions,
                          onActionTap: (action) {
                            // Handle action tap
                            switch (action['type']) {
                              case 'verification':
                                // Navigate to verification screen
                                break;
                              case 'refund':
                                // Navigate to refund screen
                                break;
                              case 'withdrawal':
                                // Navigate to withdrawal screen
                                break;
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Top Sellers
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Top Sellers',
                            style: theme.textTheme.titleLarge,
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to sellers screen
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TopSellersList(
                        sellers: List<Seller>.from(
                          _dashboardData!['topSellers'] as List<dynamic>? ?? [],
                        ),
                        onSellerTap: (seller) {
                          // Navigate to seller details
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, Routes.adminStoresRevenue);
        },
        icon: const Icon(Icons.store),
        label: const Text('Stores Revenue'),
      ),
    );
  }
} 