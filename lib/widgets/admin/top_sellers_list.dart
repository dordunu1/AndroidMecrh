import 'package:flutter/material.dart';
import '../../models/seller.dart';

class TopSellersList extends StatelessWidget {
  final List<Seller> sellers;
  final Function(Seller)? onSellerTap;

  const TopSellersList({
    super.key,
    required this.sellers,
    this.onSellerTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (sellers.isEmpty) {
      return Center(
        child: Text(
          'No sellers found',
          style: theme.textTheme.bodyLarge,
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
        return ListTile(
          onTap: onSellerTap != null ? () => onSellerTap!(seller) : null,
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundImage: seller.logo != null
                ? NetworkImage(seller.logo!)
                : null,
            child: seller.logo == null
                ? Text(
                    seller.storeName[0].toUpperCase(),
                    style: theme.textTheme.titleMedium,
                  )
                : null,
          ),
          title: Row(
            children: [
              Text(
                seller.storeName,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(width: 8),
              if (seller.isVerified)
                Icon(
                  Icons.verified,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${seller.reviewCount} reviews • GHS ${seller.balance.toStringAsFixed(2)}',
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