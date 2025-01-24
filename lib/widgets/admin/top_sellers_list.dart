import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TopSellersList extends StatelessWidget {
  final List<Map<String, dynamic>> sellers;

  const TopSellersList({
    super.key,
    required this.sellers,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (sellers.isEmpty) {
      return Center(
        child: Text(
          'No sellers found',
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sellers.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final seller = sellers[index];
        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        seller['name'] ?? 'Unknown Store',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  Text(
                    '${seller['orders']} orders',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                ],
              ),
            ),
            Text(
              '\$${(seller['total'] as double).toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        );
      },
    );
  }
} 