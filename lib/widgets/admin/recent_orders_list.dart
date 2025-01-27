import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart' as app_order;
import '../../utils/date_formatter.dart';

class RecentOrdersList extends StatelessWidget {
  final List<app_order.Order> orders;
  final Function(app_order.Order)? onOrderTap;

  const RecentOrdersList({
    super.key,
    required this.orders,
    this.onOrderTap,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return Colors.blue;
      case 'shipped':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'refund_requested':
        return Colors.purple;
      case 'refunded':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (orders.isEmpty) {
      return Center(
        child: Text(
          'No recent orders',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final order = orders[index];
        return ListTile(
          onTap: onOrderTap != null ? () => onOrderTap!(order) : null,
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Text(
                '#${order.id.substring(0, 8)}',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.status.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _getStatusColor(order.status),
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
                'By ${order.buyerName}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'GHS ${order.total.toStringAsFixed(2)} • ${formatDate(order.createdAt)}',
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
} 