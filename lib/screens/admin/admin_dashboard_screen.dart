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
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.error,
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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Revenue Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenue',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: StatsCard(
                            title: 'Total Sales',
                            value: 'GHS ${stats['totalSales'].toStringAsFixed(2)}',
                            subtitle: 'All-time sales',
                            icon: Icons.trending_up,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatsCard(
                            title: 'Platform Fees',
                            value: 'GHS ${stats['platformFees'].toStringAsFixed(2)}',
                            subtitle: '10% of sales',
                            icon: Icons.account_balance_wallet,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Orders Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orders',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: StatsCard(
                            title: 'Total Orders',
                            value: stats['totalOrders'].toString(),
                            subtitle: 'All-time orders',
                            icon: Icons.shopping_bag,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatsCard(
                            title: 'Processing',
                            value: stats['processingOrders'].toString(),
                            subtitle: 'Needs attention',
                            icon: Icons.pending_actions,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Sellers Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sellers',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: StatsCard(
                            title: 'Active Sellers',
                            value: stats['activeSellers'].toString(),
                            subtitle: '${stats['totalProducts']} products',
                            icon: Icons.store,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatsCard(
                            title: 'Pending Verifications',
                            value: stats['pendingVerifications'].toString(),
                            subtitle: 'Awaiting review',
                            icon: Icons.verified_user,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pending Actions Stats
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
                    Row(
                      children: [
                        Expanded(
                          child: StatsCard(
                            title: 'Withdrawals',
                            value: stats['pendingWithdrawals'].toString(),
                            subtitle: 'Pending requests',
                            icon: Icons.money,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatsCard(
                            title: 'Refunds',
                            value: stats['pendingRefunds'].toString(),
                            subtitle: 'Pending requests',
                            icon: Icons.assignment_return,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

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

            // Recent Orders
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
                          'Recent Orders',
                          style: theme.textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to orders screen
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    RecentOrdersList(
                      orders: List<app_order.Order>.from(
                        _dashboardData!['recentOrders'] as List<dynamic>? ?? [],
                      ),
                      onOrderTap: (order) {
                        // Navigate to order details
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

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
    );
  }
} 