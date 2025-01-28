import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/order.dart';
import '../../models/seller.dart';
import '../../services/admin_service.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../constants/colors.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'all';
  String? _selectedSeller;
  bool _isLoading = true;
  List<Order> _orders = [];
  List<Seller> _sellers = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sellers = await ref.read(adminServiceProvider).getSellers();
      final orders = await ref.read(adminServiceProvider).getOrders(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        sellerId: _selectedSeller,
      );

      if (mounted) {
        setState(() {
          _sellers = sellers;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search bar
                CustomTextField(
                  controller: _searchController,
                  hint: 'Search by order ID or buyer name...',
                  prefixIcon: const Icon(Icons.search),
                  onChanged: (value) => _loadData(),
                ),
                const SizedBox(height: 16),
                // Filters row
                Row(
                  children: [
                    // Status filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'all',
                          'processing',
                          'shipped',
                          'delivered',
                          'cancelled',
                          'refunded',
                        ].map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.toUpperCase()),
                        )).toList(),
                        onChanged: (value) {
                          setState(() => _selectedStatus = value!);
                          _loadData();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Seller filter
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _selectedSeller,
                        decoration: const InputDecoration(
                          labelText: 'Seller',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Sellers'),
                          ),
                          ..._sellers.map((seller) => DropdownMenuItem(
                            value: seller.id,
                            child: Text(seller.storeName),
                          )),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedSeller = value);
                          _loadData();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _orders.isEmpty
                        ? const Center(child: Text('No orders found'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _orders.length,
                            itemBuilder: (context, index) => _OrderCard(
                              order: _orders[index],
                              onStatusUpdate: _loadData,
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onStatusUpdate;

  const _OrderCard({
    required this.order,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    order.items.first.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                // Order details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Buyer: ${order.buyerInfo['name']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Seller: ${order.sellerInfo['name']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      _StatusChip(status: order.status),
                    ],
                  ),
                ),
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'GHS ${order.total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            if (order.status == 'processing') ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      // Show confirmation dialog for shipping
                    },
                    child: const Text('Mark as Shipped'),
                  ),
                ],
              ),
            ],
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
        color = AppColors.warning;
        break;
      case 'shipped':
        color = AppColors.info;
        break;
      case 'delivered':
        color = AppColors.success;
        break;
      case 'cancelled':
      case 'refunded':
        color = AppColors.error;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 