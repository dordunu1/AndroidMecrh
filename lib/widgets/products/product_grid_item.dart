import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product.dart';

class ProductGridItem extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductGridItem({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
      onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Product Image
              AspectRatio(
                aspectRatio: 1,
                  child: CachedNetworkImage(
                    imageUrl: product.images.first,
                    fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: theme.colorScheme.surfaceVariant,
                  child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: theme.colorScheme.surfaceVariant,
                  child: const Icon(Icons.error),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Product Name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),

                  // Price
                    Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
        ),
      ),
    );
  }
} 