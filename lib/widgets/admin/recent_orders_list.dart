import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';

class RecentOrdersList extends StatelessWidget {
  final List<Order> orders;

  const RecentOrdersList({
    super.key,
    required this.orders,
  });

  Color _getStatusColor(BuildContext context, String status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'processing':
        return colorScheme.primary;
      case 'shipped':
        return const Color(0xFF3B82F6); // Blue
      case 'delivered':
        return const Color(0xFF10B981); // Green
      case 'cancelled':
        return colorScheme.error;
      case 'refunded':
        return const Color(0xFFF59E0B); // Amber
      default:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (orders.isEmpty) {
      return Center(
        child: Text(
          'No orders found',
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
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
        return InkWell(
          onTap: () {
            // TODO: Navigate to order details
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order #${order.id.substring(order.id.length - 6)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(context, order.status)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        order.status.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _getStatusColor(context, order.status),
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Customer: ',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(0.6),
                                    ),
                              ),
                              Text(
                                order.buyerInfo['name'] ?? 'Anonymous',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (order.flag != null) ...[
                                const SizedBox(width: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: CachedNetworkImage(
                                    imageUrl: order.flag!,
                                    width: 16,
                                    height: 12,
                                    fit: BoxFit.cover,
                                    errorWidget: (context, url, error) =>
                                        const SizedBox(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Seller: ',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withOpacity(0.6),
                                    ),
                              ),
                              Text(
                                order.sellerName,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${order.total.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          DateFormat('MMM dd, yyyy').format(order.createdAt),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 