import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/withdrawal.dart';
import '../../services/admin_service.dart';
import '../../widgets/common/custom_text_field.dart';

class AdminWithdrawalsScreen extends ConsumerStatefulWidget {
  const AdminWithdrawalsScreen({super.key});

  @override
  ConsumerState<AdminWithdrawalsScreen> createState() => _AdminWithdrawalsScreenState();
}

class _AdminWithdrawalsScreenState extends ConsumerState<AdminWithdrawalsScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'all';
  bool _isLoading = true;
  List<Withdrawal> _withdrawals = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWithdrawals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWithdrawals() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final withdrawals = await ref.read(adminServiceProvider).getWithdrawals(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );

      if (mounted) {
        setState(() {
          _withdrawals = withdrawals;
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

  Future<void> _processWithdrawal(Withdrawal withdrawal, bool approved, [String? message]) async {
    try {
      await ref.read(adminServiceProvider).processWithdrawal(
        withdrawalId: withdrawal.id,
        approved: approved,
        message: message,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Withdrawal ${approved ? 'approved' : 'rejected'} successfully'),
            backgroundColor: approved ? Colors.green : Colors.red,
          ),
        );
        _loadWithdrawals();
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

  Future<void> _showWithdrawalDialog(Withdrawal withdrawal, bool approved) async {
    final messageController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Process Withdrawal #${withdrawal.id.substring(0, 8)}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount: \$${withdrawal.amount.toStringAsFixed(2)}'),
              const SizedBox(height: 8),
              Text('Payment Method: ${withdrawal.paymentMethod}'),
              const SizedBox(height: 8),
              Text('Payment Details: ${withdrawal.paymentDetails}'),
              const SizedBox(height: 16),
              CustomTextField(
                controller: messageController,
                label: 'Message (optional)',
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
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _processWithdrawal(withdrawal, false, messageController.text);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _processWithdrawal(withdrawal, true, messageController.text);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  final withdrawalsProvider = FutureProvider.family<List<Withdrawal>, String>((ref, status) async {
    final adminService = ref.read(adminServiceProvider);
    return adminService.getWithdrawals(status: status);
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Withdrawals'),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final withdrawalsAsyncValue = ref.watch(withdrawalsProvider(_selectedStatus));
          
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('All'),
                    ),
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
                      setState(() {
                        _selectedStatus = value;
                      });
                    }
                  },
                ),
              ),
              Expanded(
                child: withdrawalsAsyncValue.when(
                  data: (withdrawals) {
                    if (withdrawals.isEmpty) {
                      return Center(
                        child: Text(
                          'No withdrawals found',
                          style: theme.textTheme.bodyLarge,
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: withdrawals.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final withdrawal = withdrawals[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Seller: ${withdrawal.sellerName}',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Created on: ${_formatDate(withdrawal.createdAt)}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Amount: \$${withdrawal.amount.toStringAsFixed(2)}',
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Payment Method: ${withdrawal.paymentMethod}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Status: ${withdrawal.status}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: _getStatusColor(theme, withdrawal.status),
                                  ),
                                ),
                                if (withdrawal.status == 'pending')
                                  Padding(
                                    padding: const EdgeInsets.only(top: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => _showWithdrawalDialog(withdrawal, false),
                                          child: const Text('Reject'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () => _showWithdrawalDialog(withdrawal, true),
                                          child: const Text('Approve'),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  error: (e, _) => Center(
                    child: Text(
                      e.toString(),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(ThemeData theme, String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return theme.colorScheme.onSurface;
    }
  }
} 