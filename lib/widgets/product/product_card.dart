import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../widgets/common/cached_image.dart';
import '../../routes.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final bool showSellerInfo;

  const ProductCard({
    super.key,
    required this.product,
    this.showSellerInfo = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDiscount = product.discountPrice != null && product.discountPrice! < product.price;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.productDetails,
        arguments: {'productId': product.id},
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                AspectRatio(
                  aspectRatio: 1,
                  child: CachedImage(
                    imageUrl: product.images.first,
                    fit: BoxFit.cover,
                  ),
                ),

                // Product Info
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      if (showSellerInfo) ...[
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context,
                            Routes.storeProfile,
                            arguments: {'sellerId': product.sellerId},
                          ),
                          child: Text(
                            product.sellerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Row(
                        children: [
                          if (hasDiscount) ...[
                            Text(
                              'GHS ${product.discountPrice!.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'GHS ${product.price.toStringAsFixed(2)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                decoration: TextDecoration.lineThrough,
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ] else
                            Text(
                              'GHS ${product.price.toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (hasDiscount)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '-${((product.price - product.discountPrice!) / product.price * 100).round()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onError,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 