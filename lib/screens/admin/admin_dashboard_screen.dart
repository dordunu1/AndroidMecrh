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
  bool _isGridView = false;
  String _searchQuery = '';
  String _selectedStore = 'All Stores';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAdminAndSetupUpdates();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = MediaQuery.of(context).size.width;
          final isTablet = width > 800 && width <= 1200;
          final isWide = constraints.maxWidth > 200;
          
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isTablet ? 6 : 8),
                    decoration: BoxDecoration(
                      color: (iconColor ?? Colors.pink).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: isTablet ? 16 : (isWide ? 20 : 18),
                      color: iconColor ?? Colors.pink,
                    ),
                  ),
                  SizedBox(width: isTablet ? 8 : 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: isTablet ? 11 : (isWide ? 13 : 12),
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: isTablet ? 6 : 8),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: isTablet ? 20 : (isWide ? 24 : 20),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 6 : 8,
                  vertical: isTablet ? 3 : 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isTablet ? 9 : (isWide ? 11 : 10),
                    color: Colors.grey[600],
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildRecentOrdersList(List<Map<String, dynamic>> orders) {
    // Get unique store names for dropdown
    final stores = ['All Stores', ...orders.map((o) => o['seller'] as String).toSet().toList()..sort()];
    
    // Filter orders based on search and selected store
    var filteredOrders = orders.where((order) {
      final matchesSearch = _searchQuery.isEmpty ||
          order['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order['seller'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order['customer'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesStore = _selectedStore == 'All Stores' || order['seller'] == _selectedStore;
      
      return matchesSearch && matchesStore;
    }).toList();

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
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      DropdownButton<String>(
                        value: _selectedStore,
                        items: stores.map((store) => DropdownMenuItem(
                          value: store,
                          child: Text(
                            store,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedStore = value);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: SizedBox(
                          width: 200,
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search orders...',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              prefixIcon: Icon(Icons.search, size: 20),
                            ),
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                        onPressed: () {
                          setState(() => _isGridView = !_isGridView);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isGridView)
            Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width > 1200 ? 4 : width > 800 ? 3 : 2;
                  
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: width > 800 ? 1.4 : 1.2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return Card(
                        child: Padding(
                          padding: EdgeInsets.all(width > 800 ? 8 : 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order['id'].toString().substring(0, 8),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Seller: ${order['seller']}',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Customer: ${order['customer']}',
                                style: const TextStyle(fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Amount: ₵${(order['amount'] as num).toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(order['status'] as String),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        order['status'] as String,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _getStatusTextColor(order['status'] as String),
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(order['date'] as String),
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          else
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
                rows: filteredOrders.map((order) {
                  return DataRow(
                    cells: [
                      DataCell(Text(order['id'].toString().substring(0, 8))),
                      DataCell(Text(order['seller'] as String)),
                      DataCell(Text(order['customer'] as String)),
                      DataCell(Text('₵${(order['amount'] as num).toStringAsFixed(2)}')),
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
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusTextColor(order['status'] as String),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(_formatDate(order['date'] as String))),
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
        return Colors.green[50]!;
      case 'processing':
        return Colors.blue[50]!;
      case 'cancelled':
        return Colors.red[50]!;
      case 'refunded':
        return Colors.orange[50]!;
      case 'pending':
        return Colors.yellow[50]!;
      case 'shipped':
        return Colors.indigo[50]!;
      default:
        return Colors.grey[50]!;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green[900]!;
      case 'processing':
        return Colors.blue[900]!;
      case 'cancelled':
        return Colors.red[900]!;
      case 'refunded':
        return Colors.orange[900]!;
      case 'pending':
        return Colors.yellow[900]!;
      case 'shipped':
        return Colors.indigo[900]!;
      default:
        return Colors.grey[900]!;
    }
  }

  Widget _buildTopSellersList(List<Map<String, dynamic>> sellers) {
    if (sellers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text('No top sellers data available'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sellers.length,
      itemBuilder: (context, index) {
        final seller = sellers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.pink[50],
              child: const Icon(Icons.store, color: Colors.pink),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    seller['storeName'] ?? 'Unknown Store',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.pink[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Rank #${index + 1}',
                    style: TextStyle(
                      color: Colors.pink[900],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'Orders: ${seller['totalOrders']} | Customers: ${seller['totalCustomers']}',
              style: const TextStyle(fontSize: 13),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₵${(seller['totalSales'] as double).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.pink,
                  ),
                ),
                Text(
                  'Total Sales',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width > 1200 ? 4 : width > 800 ? 4 : 2;
                  final horizontalSpacing = width > 1200 ? 16.0 : width > 800 ? 12.0 : 16.0;
                  final verticalSpacing = width > 1200 ? 16.0 : width > 800 ? 12.0 : 16.0;
                  
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: horizontalSpacing,
                    mainAxisSpacing: verticalSpacing,
                    childAspectRatio: width > 1200 ? 1.8 : width > 800 ? 1.9 : 1.4,
                    padding: EdgeInsets.symmetric(
                      horizontal: width > 800 ? 8.0 : 16.0,
                      vertical: width > 800 ? 8.0 : 16.0,
                    ),
                    children: [
                      _buildMetricCard(
                        title: 'All-time Sales',
                        value: '₵${stats['totalSales'].toStringAsFixed(2)}',
                        subtitle: 'Total volume (excl. refunds)',
                        icon: Icons.trending_up,
                      ),
                      _buildMetricCard(
                        title: 'Current Sales',
                        value: '₵${(stats['totalSales'] - stats['totalRefunds']).toStringAsFixed(2)}',
                        subtitle: 'Net sales after refunds',
                        icon: Icons.attach_money,
                      ),
                      _buildMetricCard(
                        title: 'Total Refunds',
                        value: '₵${stats['totalRefunds'].toStringAsFixed(2)}',
                        subtitle: 'Refunded amount',
                        icon: Icons.credit_card,
                      ),
                      _buildMetricCard(
                        title: 'All-time Platform Fees',
                        value: '₵${stats['totalPlatformFees'].toStringAsFixed(2)}',
                        subtitle: 'Total platform fees',
                        icon: Icons.account_balance_wallet,
                      ),
                      _buildMetricCard(
                        title: 'Current Platform Fees',
                        value: '₵${(stats['totalPlatformFees'] - (stats['totalRefunds'] * 0.1)).toStringAsFixed(2)}',
                        subtitle: 'Platform fees after refunds',
                        icon: Icons.payments,
                      ),
                      _buildMetricCard(
                        title: 'Active Sellers',
                        value: '${stats['activeSellers']}',
                        subtitle: '${stats['totalProducts']} products listed',
                        icon: Icons.store,
                      ),
                      _buildMetricCard(
                        title: 'Total Orders',
                        value: '${stats['totalOrders']}',
                        subtitle: 'All-time orders',
                        icon: Icons.shopping_bag,
                      ),
                      _buildMetricCard(
                        title: 'Total Products',
                        value: '${stats['totalProducts']}',
                        subtitle: 'Listed products',
                        icon: Icons.inventory_2,
                      ),
                      _buildMetricCard(
                        title: 'Total Customers',
                        value: '${stats['totalCustomers']}',
                        subtitle: 'Unique buyers',
                        icon: Icons.people,
                      ),
                    ],
                  );
                },
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
                      _buildTopSellersList(
                        List<Map<String, dynamic>>.from(
                          _dashboardData!['topSellers'] as List<dynamic>? ?? [],
                        ),
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