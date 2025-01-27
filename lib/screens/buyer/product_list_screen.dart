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
import '../../services/realtime_service.dart';

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
  StreamSubscription? _productsSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _productsSubscription?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _setupRealtimeUpdates();
    });
  }

  Future<void> _setupRealtimeUpdates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      _productsSubscription?.cancel();
      _productsSubscription = ref
          .read(realtimeServiceProvider)
          .listenToProducts(
            '', // Empty string for no seller filter
            (products) {
              if (mounted) {
                setState(() {
                  // Filter products based on search and category
                  _products = products.where((product) {
                    if (!product.isActive) return false;
                    
                    bool matchesSearch = true;
                    if (_searchController.text.isNotEmpty) {
                      matchesSearch = product.name.toLowerCase().contains(_searchController.text.toLowerCase());
                    }
                    
                    bool matchesCategory = true;
                    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
                      matchesCategory = product.category == _selectedCategory;
                    }
                    
                    return matchesSearch && matchesCategory;
                  }).toList();
                  
                  // Sort products if needed
                  if (_selectedSortBy != null) {
                    switch (_selectedSortBy) {
                      case 'price_low_high':
                        _products.sort((a, b) => a.price.compareTo(b.price));
                        break;
                      case 'price_high_low':
                        _products.sort((a, b) => b.price.compareTo(a.price));
                        break;
                      case 'newest':
                        _products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                        break;
                      case 'rating':
                        _products.sort((a, b) => b.rating.compareTo(a.rating));
                        break;
                    }
                  }
                  
                  _isLoading = false;
                });
              }
            },
          );
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
                    onPressed: _setupRealtimeUpdates,
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
                      _setupRealtimeUpdates();
                    },
                  ),
                  _CategoryChip(
                    label: 'Clothing',
                    selected: _selectedCategory == 'clothing',
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? 'clothing' : null;
                      });
                      _setupRealtimeUpdates();
                    },
                  ),
                  _CategoryChip(
                    label: 'Accessories',
                    selected: _selectedCategory == 'accessories',
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? 'accessories' : null;
                      });
                      _setupRealtimeUpdates();
                    },
                  ),
                  _CategoryChip(
                    label: 'Electronics',
                    selected: _selectedCategory == 'electronics',
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? 'electronics' : null;
                      });
                      _setupRealtimeUpdates();
                    },
                  ),
                  _CategoryChip(
                    label: 'Home',
                    selected: _selectedCategory == 'home',
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? 'home' : null;
                      });
                      _setupRealtimeUpdates();
                    },
                  ),
                  _CategoryChip(
                    label: 'Art',
                    selected: _selectedCategory == 'art',
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? 'art' : null;
                      });
                      _setupRealtimeUpdates();
                    },
                  ),
                  _CategoryChip(
                    label: 'Collectibles',
                    selected: _selectedCategory == 'collectibles',
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? 'collectibles' : null;
                      });
                      _setupRealtimeUpdates();
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
                                onPressed: _setupRealtimeUpdates,
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
                                        _setupRealtimeUpdates();
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
                                childAspectRatio: 0.645,
                                mainAxisSpacing: 8,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: product.images.first,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[100],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[100],
                      child: const Icon(Icons.error),
                    ),
                  ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${product.discountPercent.toStringAsFixed(0)}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onError,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'by ${product.sellerName}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (product.hasDiscount) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'GHS ${discountedPrice?.toStringAsFixed(2)}',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'GHS ${product.price.toStringAsFixed(2)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                        ] else
                          Text(
                            'GHS ${product.price.toStringAsFixed(2)}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        Text(
                          '${product.soldCount} sold',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 