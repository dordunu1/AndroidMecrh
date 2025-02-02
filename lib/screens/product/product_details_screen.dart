import 'package:flutter/material.dart';
import 'package:your_app/models/product.dart';
import 'package:your_app/routes.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product? product;

  const ProductDetailsScreen({Key? key, this.product}) : super(key: key);

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Product? _product;
  Seller? _seller;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _seller = _product?.seller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_product?.name ?? 'Product Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProductImage(),
            _buildSellerInfo(),
            // Add other widgets as needed
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    // Implementation of _buildProductImage
    return Container();
  }

  Widget _buildSellerInfo() {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        Routes.storeProfile,
        arguments: {'sellerId': _product!.sellerId},
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(
                  Icons.store,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _product!.sellerName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_seller?.isVerified == true) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            color: theme.colorScheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Verified Store',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 