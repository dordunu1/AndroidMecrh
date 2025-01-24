import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product.dart';
import '../../services/buyer_service.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/product_skeleton.dart';
import 'product_details_screen.dart';
import 'package:shimmer/shimmer.dart';

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
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search products',
                          prefixIcon: const Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.camera_alt_outlined),
                            onPressed: () {
                              // TODO: Implement image search
                            },
                          ),
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _loadProducts,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),

            // Categories
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'All',
                    selected: _selectedCategory == null,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = null;
                      });
                      _loadProducts();
                    },
                  ),
                  _CategoryChip(
                    label: 'Clothing',
                    selected: _selectedCategory == 'clothing',
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? 'clothing' : null;
                      });
                      _loadProducts();
                    },
                  ),
                  _CategoryChip(
                    label: 'Accessories',
                    selected: _selectedCategory == 'accessories',
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? 'accessories' : null;
                      });
                      _loadProducts();
                    },
                  ),
                  _CategoryChip(
                    label: 'Electronics',
                    selected: _selectedCategory == 'electronics',
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? 'electronics' : null;
                      });
                      _loadProducts();
                    },
                  ),
                  _CategoryChip(
                    label: 'Home',
                    selected: _selectedCategory == 'home',
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? 'home' : null;
                      });
                      _loadProducts();
                    },
                  ),
                  _CategoryChip(
                    label: 'Art',
                    selected: _selectedCategory == 'art',
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? 'art' : null;
                      });
                      _loadProducts();
                    },
                  ),
                  _CategoryChip(
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

            // Products Grid
            Expanded(
              child: _isLoading
                  ? GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.9,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) => const ProductSkeleton(),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
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
                                    size: 48,
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
                              padding: const EdgeInsets.all(8),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.9,
                                mainAxisSpacing: 4,
                                crossAxisSpacing: 8,
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
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: () => onSelected(!selected),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: selected ? Theme.of(context).primaryColor : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
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
    final discountedPrice = product.hasDiscount && product.discountPercent > 0
        ? product.price * (1 - product.discountPercent / 100)
        : null;
    
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide.none,
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
        child: SizedBox(
          height: 215,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: product.images.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              color: Colors.white,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[100],
                            child: const Icon(Icons.error, color: Colors.grey),
                          ),
                        ),
                        if (product.hasDiscount)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                '-${product.discountPercent.toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                      if (discountedPrice != null)
                        Row(
                          children: [
                            Text(
                              'GH₵${discountedPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'GH₵${product.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'GH₵${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 