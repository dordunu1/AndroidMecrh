import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/seller.dart';
import '../../services/admin_service.dart';
import '../../widgets/common/custom_text_field.dart';

class SellerVerificationsScreen extends ConsumerStatefulWidget {
  const SellerVerificationsScreen({super.key});

  @override
  ConsumerState<SellerVerificationsScreen> createState() => _SellerVerificationsScreenState();
}

class _SellerVerificationsScreenState extends ConsumerState<SellerVerificationsScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  List<Seller> _pendingSellers = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingSellers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingSellers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sellers = await ref.read(adminServiceProvider).getPendingVerifications(
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );

      if (mounted) {
        setState(() {
          _pendingSellers = sellers;
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

  Future<void> _verifyStore(Seller seller, bool approve) async {
    final messageController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve Store' : 'Reject Store'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              approve
                  ? 'Are you sure you want to approve ${seller.storeName}?'
                  : 'Are you sure you want to reject ${seller.storeName}?',
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: messageController,
              label: approve ? 'Approval Message' : 'Rejection Reason',
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: approve ? Colors.green : Colors.red,
            ),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(adminServiceProvider).verifyStore(
        seller.id,
        approve,
        message: messageController.text.isEmpty ? null : messageController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              approve
                  ? '${seller.storeName} has been approved'
                  : '${seller.storeName} has been rejected',
            ),
          ),
        );
        _loadPendingSellers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Verifications'),
        actions: [
          IconButton(
            onPressed: _loadPendingSellers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomTextField(
              controller: _searchController,
              label: 'Search Sellers',
              prefixIcon: const Icon(Icons.search),
              onSubmitted: (_) => _loadPendingSellers(),
            ),
          ),

          // Sellers List
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
                    : _pendingSellers.isEmpty
                        ? Center(
                            child: Text(
                              'No pending verifications',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _pendingSellers.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final seller = _pendingSellers[index];
                              return _SellerCard(
                                seller: seller,
                                onApprove: () => _verifyStore(seller, true),
                                onReject: () => _verifyStore(seller, false),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  final Seller seller;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _SellerCard({
    required this.seller,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Info
            Row(
              children: [
                if (seller.logo != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      seller.logo!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        seller.storeName[0].toUpperCase(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seller.storeName,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        seller.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Store Description
            Text(
              'Description:',
              style: theme.textTheme.titleSmall,
            ),
            Text(
              seller.description ?? 'No description provided',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Store Details
            Row(
              children: [
                if (seller.country != null) ...[
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    seller.country!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  'Requested on ${_formatDate(DateTime.parse(seller.createdAt))}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: onApprove,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Approve'),
                ),
              ],
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