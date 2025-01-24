import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product.dart';
import '../../services/buyer_service.dart';
import '../../widgets/common/custom_text_field.dart';
import 'product_details_screen.dart';

final productsProvider = StreamProvider.autoDispose
    .family<List<Product>, Map<String, dynamic>>((ref, params) {
  final category = params['category'] as String?;
  final search = params['search'] as String?;
  final sortBy = params['sortBy'] as String?;
  
  ref.keepAlive();
  
  return ref.read(buyerServiceProvider).getProductsStream(
        category: category,
        search: search,
        sortBy: sortBy,
      );
});

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedSortBy;
  Timer? _searchDebounce;
  bool _isLoading = true;
  List<Product> _products = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _loadProducts();
    });
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final products = await ref.read(buyerServiceProvider).getProducts(
        category: _selectedCategory,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        sortBy: _selectedSortBy,
      );

      if (mounted) {
        setState(() {
          _products = products;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          IconButton(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              // TODO: Navigate to cart screen
            },
            icon: const Icon(Icons.shopping_cart_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CustomTextField(
                  controller: _searchController,
                  label: 'Search products',
                  prefixIcon: const Icon(Icons.search),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _selectedCategory == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = null;
                          });
                          _loadProducts();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Clothing',
                        selected: _selectedCategory == 'clothing',
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? 'clothing' : null;
                          });
                          _loadProducts();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Accessories',
                        selected: _selectedCategory == 'accessories',
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? 'accessories' : null;
                          });
                          _loadProducts();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Electronics',
                        selected: _selectedCategory == 'electronics',
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? 'electronics' : null;
                          });
                          _loadProducts();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Home',
                        selected: _selectedCategory == 'home',
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? 'home' : null;
                          });
                          _loadProducts();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Art',
                        selected: _selectedCategory == 'art',
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? 'art' : null;
                          });
                          _loadProducts();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Collectibles',
                        selected: _selectedCategory == 'collectibles',
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? 'collectibles' : null;
                          });
                          _loadProducts();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Latest',
                        selected: _selectedSortBy == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedSortBy = null;
                          });
                          _loadProducts();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Price: Low to High',
                        selected: _selectedSortBy == 'price_asc',
                        onSelected: (selected) {
                          setState(() {
                            _selectedSortBy = selected ? 'price_asc' : null;
                          });
                          _loadProducts();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Price: High to Low',
                        selected: _selectedSortBy == 'price_desc',
                        onSelected: (selected) {
                          setState(() {
                            _selectedSortBy = selected ? 'price_desc' : null;
                          });
                          _loadProducts();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Most Popular',
                        selected: _selectedSortBy == 'popularity',
                        onSelected: (selected) {
                          setState(() {
                            _selectedSortBy = selected ? 'popularity' : null;
                          });
                          _loadProducts();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading products',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _error!,
                              style: Theme.of(context).textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed: _loadProducts,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _products.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 64,
                                  color: Theme.of(context).disabledColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No products found',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                if (_selectedCategory != null || _searchController.text.isNotEmpty)
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedCategory = null;
                                        _searchController.clear();
                                      });
                                      _loadProducts();
                                    },
                                    child: const Text('Clear filters'),
                                  ),
                              ],
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              return _ProductCard(product: product);
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
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: selected ? Theme.of(context).primaryColor : null,
      ),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;

  const _ProductCard({
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: CachedNetworkImage(
                    imageUrl: product.images.first,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
                if (product.hasDiscount)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '-${product.discountPercent.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'by ${product.sellerName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (product.discountedPrice != null) ...[
                    Text(
                      '₵${product.discountedPrice?.toStringAsFixed(2)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₵${product.price.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ] else
                    Text(
                      '₵${product.price.toStringAsFixed(2)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 