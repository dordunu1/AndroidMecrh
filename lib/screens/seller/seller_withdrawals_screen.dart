import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/withdrawal.dart';
import '../../services/seller_service.dart';
import '../../widgets/common/custom_text_field.dart';

class SellerWithdrawalsScreen extends ConsumerStatefulWidget {
  const SellerWithdrawalsScreen({super.key});

  @override
  ConsumerState<SellerWithdrawalsScreen> createState() => _SellerWithdrawalsScreenState();
}

class _SellerWithdrawalsScreenState extends ConsumerState<SellerWithdrawalsScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'all';
  bool _isLoading = true;
  List<Withdrawal> _withdrawals = [];
  String? _error;
  double _balance = 0;

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
      final sellerService = ref.read(sellerServiceProvider);
      final balance = await sellerService.getBalance();
      final withdrawals = await sellerService.getWithdrawals(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );

      if (mounted) {
        setState(() {
          _balance = balance;
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

  Future<void> _showWithdrawalDialog() async {
    final amountController = TextEditingController();
    final paymentMethodController = TextEditingController();
    final paymentDetailsController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Withdrawal'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Available Balance: \$${_balance.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              CustomTextField(
                controller: amountController,
                label: 'Amount',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null) {
                    return 'Please enter a valid amount';
                  }
                  if (amount <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  if (amount > _balance) {
                    return 'Amount cannot exceed your balance';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: paymentMethodController,
                label: 'Payment Method',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a payment method';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: paymentDetailsController,
                label: 'Payment Details',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter payment details';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await ref.read(sellerServiceProvider).requestWithdrawal(
                    amount: double.parse(amountController.text),
                    paymentMethod: paymentMethodController.text,
                    paymentDetails: {
                      'details': paymentDetailsController.text,
                    },
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Withdrawal request submitted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadData();
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Submit'),
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
        title: const Text('Withdrawals'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Balance Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Balance',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${_balance.toStringAsFixed(2)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _balance > 0 ? _showWithdrawalDialog : null,
                      child: const Text('Request Withdrawal'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search and Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                CustomTextField(
                  controller: _searchController,
                  label: 'Search Withdrawals',
                  prefixIcon: const Icon(Icons.search),
                  onSubmitted: (_) => _loadData(),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _selectedStatus == 'all',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedStatus = 'all');
                            _loadData();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Pending',
                        selected: _selectedStatus == 'pending',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedStatus = 'pending');
                            _loadData();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Approved',
                        selected: _selectedStatus == 'approved',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedStatus = 'approved');
                            _loadData();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Rejected',
                        selected: _selectedStatus == 'rejected',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedStatus = 'rejected');
                            _loadData();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Withdrawals List
          Expanded(
            child: _isLoading
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
                    : _withdrawals.isEmpty
                        ? Center(
                            child: Text(
                              'No withdrawals found',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _withdrawals.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final withdrawal = _withdrawals[index];
                              return _WithdrawalCard(withdrawal: withdrawal);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

class _WithdrawalCard extends StatelessWidget {
  final Withdrawal withdrawal;

  const _WithdrawalCard({required this.withdrawal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Withdrawal ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Withdrawal #${withdrawal.id.substring(0, 8)}',
                  style: theme.textTheme.titleMedium,
                ),
                _StatusChip(status: withdrawal.status),
              ],
            ),
            const SizedBox(height: 8),

            // Amount and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount: \$${withdrawal.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Created on ${_formatDate(withdrawal.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Payment Method
            Text(
              'Payment Method:',
              style: theme.textTheme.titleSmall,
            ),
            Text(
              withdrawal.paymentMethod,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),

            // Payment Details
            Text(
              'Payment Details:',
              style: theme.textTheme.titleSmall,
            ),
            Text(
              withdrawal.paymentDetails,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),

            // Admin Message
            if (withdrawal.adminNote != null) ...[
              Text(
                'Admin Message:',
                style: theme.textTheme.titleSmall,
              ),
              Text(
                withdrawal.adminNote!,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
            ],

            // Processed Date
            if (withdrawal.processedAt != null)
              Text(
                'Processed on ${_formatDate(withdrawal.processedAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
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
        case 'pending':
          return Colors.orange;
        case 'approved':
          return Colors.green;
        case 'rejected':
          return Colors.red;
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