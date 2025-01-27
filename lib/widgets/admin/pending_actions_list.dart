import 'package:flutter/material.dart';

class PendingActionsList extends StatelessWidget {
  final List<Map<String, dynamic>> actions;
  final Function(Map<String, dynamic>)? onActionTap;

  const PendingActionsList({
    super.key,
    required this.actions,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (actions.isEmpty) {
      return Center(
        child: Text(
          'No pending actions',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final action = actions[index];
        return ListTile(
          onTap: onActionTap != null ? () => onActionTap!(action) : null,
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: _getActionColor(action['type']).withOpacity(0.1),
            child: Icon(
              _getActionIcon(action['type']),
              color: _getActionColor(action['type']),
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Text(
                _getActionTitle(action['type']),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getActionColor(action['type']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  action['type'].toString().toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _getActionColor(action['type']),
                  ),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                _getActionSubtitle(action),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
        );
      },
    );
  }

  String _getActionTitle(String type) {
    switch (type.toLowerCase()) {
      case 'verification':
        return 'Seller Verification';
      case 'refund':
        return 'Refund Request';
      case 'withdrawal':
        return 'Withdrawal Request';
      default:
        return 'Unknown Action';
    }
  }

  String _getActionSubtitle(Map<String, dynamic> action) {
    switch (action['type'].toString().toLowerCase()) {
      case 'verification':
        return 'Store: ${action['storeName']}';
      case 'refund':
        return 'Order #${action['orderId']} • GHS ${action['amount'].toStringAsFixed(2)}';
      case 'withdrawal':
        return 'Seller: ${action['sellerName']} • GHS ${action['amount'].toStringAsFixed(2)}';
      default:
        return '';
    }
  }

  IconData _getActionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'verification':
        return Icons.verified_user;
      case 'refund':
        return Icons.money;
      case 'withdrawal':
        return Icons.account_balance_wallet;
      default:
        return Icons.error;
    }
  }

  Color _getActionColor(String type) {
    switch (type.toLowerCase()) {
      case 'verification':
        return Colors.blue;
      case 'refund':
        return Colors.purple;
      case 'withdrawal':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
} 