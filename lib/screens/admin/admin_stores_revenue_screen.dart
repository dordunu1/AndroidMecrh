import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/seller.dart';
import '../../services/admin_service.dart';
import '../../services/realtime_service.dart';

class AdminStoresRevenueScreen extends ConsumerStatefulWidget {
  const AdminStoresRevenueScreen({super.key});

  @override
  ConsumerState<AdminStoresRevenueScreen> createState() => _AdminStoresRevenueScreenState();
}

class _AdminStoresRevenueScreenState extends ConsumerState<AdminStoresRevenueScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _storesData = [];
  StreamSubscription? _storesSubscription;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _setupStoresRevenueStream();
  }

  @override
  void dispose() {
    _storesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setupStoresRevenueStream() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      _storesSubscription?.cancel();
      _storesSubscription = await ref
          .read(realtimeServiceProvider)
          .listenToStoresRevenue((data) {
        if (mounted) {
          setState(() {
            _storesData = List<Map<String, dynamic>>.from(data);
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

  Widget _buildStoreCard(Map<String, dynamic> store) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store['name'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Store ID: ${store['id']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: store['verified'] == true
                        ? Colors.green[100]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    store['verified'] == true ? 'Verified' : 'Unverified',
                    style: TextStyle(
                      color: store['verified'] == true
                          ? Colors.green[900]
                          : Colors.grey[800],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'All Time Revenue',
                    '\$${(store['allTimeRevenue'] as num).toStringAsFixed(2)}',
                    'Withdrawn: \$${(store['withdrawn'] as num).toStringAsFixed(2)}',
                    Icons.attach_money,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Net Revenue',
                    '\$${(store['netRevenue'] as num).toStringAsFixed(2)}',
                    '${store['revenueGrowth']}% from last month',
                    Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Orders',
                    store['totalOrders'].toString(),
                    '${store['ordersGrowth']}% from last month',
                    Icons.shopping_bag,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Total Customers',
                    store['totalCustomers'].toString(),
                    '${store['customersGrowth']}% from last month',
                    Icons.people,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Withdrawal History'),
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: (store['withdrawalHistory'] as List?)?.length ?? 0,
                  itemBuilder: (context, index) {
                    final withdrawal = (store['withdrawalHistory'] as List)[index];
                    return ListTile(
                      title: Text('\$${withdrawal['amount']}'),
                      subtitle: Text(withdrawal['date']),
                      trailing: Text(withdrawal['status']),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.pink),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stores Revenue')),
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
                onPressed: _setupStoresRevenueStream,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stores Revenue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement store search
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _setupStoresRevenueStream,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _setupStoresRevenueStream,
        child: ListView.builder(
          itemCount: _storesData.length,
          itemBuilder: (context, index) => _buildStoreCard(_storesData[index]),
        ),
      ),
    );
  }
} 