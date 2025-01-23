import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product.dart';
import '../../services/buyer_service.dart';
import '../../widgets/common/custom_text_field.dart';
import 'product_details_screen.dart';

final productsProvider = FutureProvider.autoDispose
    .family<List<Product>, Map<String, dynamic>>((ref, params) async {
  final category = params['category'] as String?;
  final search = params['search'] as String?;
  final sortBy = params['sortBy'] as String?;
  return ref.read(buyerServiceProvider).getProducts(
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

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider({
      'category': _selectedCategory,
      'search': _searchController.text,
      'sortBy': _selectedSortBy,
    }));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
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
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Electronics',
                        selected: _selectedCategory == 'electronics',
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory =
                                selected ? 'electronics' : null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Fashion',
                        selected: _selectedCategory == 'fashion',
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? 'fashion' : null;
                          });
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
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Beauty',
                        selected: _selectedCategory == 'beauty',
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? 'beauty' : null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Sports',
                        selected: _selectedCategory == 'sports',
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? 'sports' : null;
                          });
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
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: products.when(
              data: (data) {
                if (data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final product = data[index];
                    return _ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailsScreen(product: product),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: $error',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        ref.invalidate(productsProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
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
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: CachedNetworkImage(
                imageUrl: product.images.first,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'by ${product.sellerName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
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