import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/admin_service.dart';
import '../../models/seller.dart';

class AdminStoreActivationsScreen extends ConsumerStatefulWidget {
  const AdminStoreActivationsScreen({super.key});

  @override
  ConsumerState<AdminStoreActivationsScreen> createState() => _AdminStoreActivationsScreenState();
}

class _AdminStoreActivationsScreenState extends ConsumerState<AdminStoreActivationsScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'pending';
  bool _isLoading = true;
  List<Seller> _sellers = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSellers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSellers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sellers = await ref.read(adminServiceProvider).getPendingSellerRegistrations(
        status: _selectedStatus,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );

      if (mounted) {
        setState(() {
          _sellers = sellers;
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

  Future<void> _processRegistration(Seller seller, bool approved, [String? message]) async {
    try {
      await ref.read(adminServiceProvider).processSellerRegistration(
        sellerId: seller.id,
        approved: approved,
        message: message,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Store registration ${approved ? 'approved' : 'rejected'} successfully'),
            backgroundColor: approved ? Colors.green : Colors.red,
          ),
        );
        _loadSellers();
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

  Future<void> _showRegistrationDialog(Seller seller, bool approved) async {
    final messageController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${approved ? 'Approve' : 'Reject'} Store Registration'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID: ${seller.id.substring(0, 8)}'),
              const SizedBox(height: 8),
              Text('Store Name: ${seller.storeName}'),
              const SizedBox(height: 8),
              Text('Location: ${seller.address}'),
              const SizedBox(height: 8),
              Text('Payment Reference: ${seller.paymentReference}'),
              const SizedBox(height: 8),
              Text('Description: ${seller.description}'),
              const SizedBox(height: 8),
              Text('Email: ${seller.email}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (!approved)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _processRegistration(seller, false, messageController.text);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          if (approved)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _processRegistration(seller, true, messageController.text);
              },
              child: const Text('Approve'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Activations'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search stores...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _loadSellers(),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('Pending'),
                    ),
                    DropdownMenuItem(
                      value: 'approved',
                      child: Text('Approved'),
                    ),
                    DropdownMenuItem(
                      value: 'rejected',
                      child: Text('Rejected'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedStatus = value);
                      _loadSellers();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      )
                    : _sellers.isEmpty
                        ? const Center(
                            child: Text('No store registrations found'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _sellers.length,
                            itemBuilder: (context, index) {
                              final seller = _sellers[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              seller.storeName,
                                              style: theme.textTheme.titleLarge,
                                            ),
                                          ),
                                          Text(
                                            '#${seller.id.substring(0, 8)}',
                                            style: theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Location: ${seller.address}'),
                                      const SizedBox(height: 4),
                                      Text('Payment Reference: ${seller.paymentReference}'),
                                      const SizedBox(height: 4),
                                      Text('Email: ${seller.email}'),
                                      if (_selectedStatus == 'pending') ...[
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () => _showRegistrationDialog(seller, false),
                                              style: TextButton.styleFrom(
                                                foregroundColor: theme.colorScheme.error,
                                              ),
                                              child: const Text('Reject'),
                                            ),
                                            const SizedBox(width: 8),
                                            FilledButton(
                                              onPressed: () => _showRegistrationDialog(seller, true),
                                              child: const Text('Approve'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
} 