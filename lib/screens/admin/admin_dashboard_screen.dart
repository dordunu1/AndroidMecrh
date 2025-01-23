import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart' as app_order;
import '../../models/seller.dart';
import '../../services/admin_service.dart';
import '../../widgets/admin/stats_card.dart';
import '../../widgets/admin/recent_orders_list.dart';
import '../../widgets/admin/top_sellers_list.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic> _stats = {
    'totalSales': 0.0,
    'currentSales': 0.0,
    'totalRefunds': 0.0,
    'activeSellers': 0,
    'pendingWithdrawals': 0,
    'platformBalance': 0.0,
    'totalOrders': 0,
    'totalProducts': 0,
    'totalCustomers': 0,
    'platformFee': 0.0,
    'totalPlatformFees': 0.0,
    'withdrawnFees': 0.0,
    'totalEarnings': 0.0,
    'salesByNetwork': {
      'unichain': 0.0,
      'polygon': 0.0,
    },
  };
  List<app_order.Order> _filteredOrders = [];
  String _searchTerm = '';
  String _selectedStore = 'all';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() => _isLoading = true);

      final adminService = ref.read(adminServiceProvider);
      final data = await adminService.getDashboardData();

      setState(() {
        _dashboardData = data;
        _stats = data['stats'];
        _filteredOrders = List<app_order.Order>.from(data['recentOrders']);
        _filterOrders();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard data: $e')),
        );
      }
    }
  }

  void _filterOrders() {
    if (_searchTerm.isEmpty) {
      _filteredOrders = List<app_order.Order>.from(_dashboardData!['recentOrders']);
    } else {
      final searchLower = _searchTerm.toLowerCase();
      _filteredOrders = List<app_order.Order>.from(_dashboardData!['recentOrders'])
          .where((order) =>
              order.id.toLowerCase().contains(searchLower) ||
              order.buyerName.toLowerCase().contains(searchLower) ||
              order.sellerName.toLowerCase().contains(searchLower))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16.0,
              crossAxisSpacing: 16.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                StatsCard(
                  title: 'Total Sales',
                  value: '\$${_stats['totalSales'].toStringAsFixed(2)}',
                  subtitle: 'All-time sales',
                  icon: Icons.trending_up,
                ),
                StatsCard(
                  title: 'Active Sellers',
                  value: _stats['activeSellers'].toString(),
                  subtitle: '${_stats['totalProducts']} products',
                  icon: Icons.store,
                ),
                StatsCard(
                  title: 'Total Orders',
                  value: _stats['totalOrders'].toString(),
                  subtitle: 'All-time orders',
                  icon: Icons.shopping_bag,
                ),
                StatsCard(
                  title: 'Platform Fees',
                  value: '\$${_stats['platformFee'].toStringAsFixed(2)}',
                  subtitle: 'Available balance',
                  icon: Icons.account_balance_wallet,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Top Sellers
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Sellers',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TopSellersList(sellers: _dashboardData!['topSellers']),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recent Orders
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Orders',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(
                          width: 150,
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search orders...',
                              isDense: true,
                              prefixIcon: Icon(Icons.search),
                            ),
                            onChanged: (value) {
                              setState(() => _searchTerm = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    RecentOrdersList(orders: _filteredOrders),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 