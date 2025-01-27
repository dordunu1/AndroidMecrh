import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../../services/product_service.dart';
import '../../services/review_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/reviews/review_list_item.dart';
import '../../services/realtime_service.dart';
import '../../services/cart_service.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _currentImageIndex = 0;
  Map<String, dynamic>? _selectedVariant;
  final _pageController = PageController();
  int _quantity = 1;
  String? _selectedSize;
  String? _selectedColor;
  String? _selectedColorImage;
  bool _isLoading = false;
  StreamSubscription? _productSubscription;
  Product? _product;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _productSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeUpdates() {
    _productSubscription?.cancel();
    _productSubscription = ref
        .read(realtimeServiceProvider)
        .listenToProductStock(
          widget.product.id,
          (updatedProduct) {
            if (mounted) {
              setState(() {
                _product = updatedProduct;
                // Validate current selections
                if (_selectedColor != null) {
                  final availableQuantity = updatedProduct.colorQuantities[_selectedColor] ?? 0;
                  if (availableQuantity < _quantity) {
                    _quantity = availableQuantity > 0 ? availableQuantity : 1;
                  }
                } else {
                  if (updatedProduct.stockQuantity < _quantity) {
                    _quantity = updatedProduct.stockQuantity > 0 ? updatedProduct.stockQuantity : 1;
                  }
                }
              });
            }
          },
        );
  }

  void _selectColor(String color, String? imageUrl) {
    setState(() {
      _selectedColor = color;
      _selectedColorImage = imageUrl;
      // Reset quantity if it exceeds available stock
      final availableQuantity = _product?.colorQuantities[color] ?? 0;
      if (_quantity > availableQuantity) {
        _quantity = availableQuantity > 0 ? availableQuantity : 1;
      }
    });
  }

  void _selectSize(String size) {
    setState(() {
      _selectedSize = size;
    });
  }

  void _updateQuantity(int newQuantity) {
    if (newQuantity < 1) return;
    
    final availableQuantity = _selectedColor != null
        ? _product?.colorQuantities[_selectedColor] ?? 0
        : _product?.stockQuantity ?? 0;

    if (newQuantity > availableQuantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum available quantity reached'),
        ),
      );
      return;
    }

    setState(() {
      _quantity = newQuantity;
    });
  }

  Future<void> _addToCart() async {
    if (_product == null) return;

    if (_product!.hasVariants && _selectedColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a color'),
        ),
      );
      return;
    }

    if (_product!.sizes.isNotEmpty && _selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a size'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(cartServiceProvider).addToCart(
        _product!,
        _quantity,
        selectedSize: _selectedSize,
        selectedColor: _selectedColor,
        selectedColorImage: _selectedColorImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to cart'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_product == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image Carousel
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Image Carousel
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _product!.images.length,
                    onPageChanged: (index) {
                      setState(() => _currentImageIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: _product!.images[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
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
                      );
                    },
                  ),

                  // Image Indicators
                  if (_product!.images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _product!.images.asMap().entries.map((entry) {
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary.withOpacity(
                                _currentImageIndex == entry.key ? 1 : 0.4,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Product Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _product!.name,
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '₵${_product!.price.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Rating and Reviews
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 20,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _product!.rating.toStringAsFixed(1),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${_product!.reviewCount} reviews)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Store Info
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        child: Text(
                          _product!.sellerName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _product!.sellerName,
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            '/chat',
                            arguments: {
                              'sellerId': _product!.sellerId,
                              'productId': _product!.id,
                            },
                          );
                        },
                        child: const Text('Contact Store'),
                      ),
                    ],
                  ),
                  const Divider(height: 32),

                  // Description
                  Text(
                    'Description',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _product!.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // Variants
                  if (_product!.variants != null) ...[
                    Text(
                      'Variants',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _product!.variants!.entries.map((variant) {
                        return ChoiceChip(
                          label: Text(variant.value['name']),
                          selected: _selectedVariant?['name'] == variant.value['name'],
                          onSelected: (selected) {
                            setState(() {
                              _selectedVariant = selected ? variant.value : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Reviews
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Reviews',
                        style: theme.textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            '/reviews',
                            arguments: _product,
                          );
                        },
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<Review>>(
                    stream: ref
                        .read(reviewServiceProvider)
                        .watchProductReviews(_product!.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final reviews = snapshot.data!;
                      if (reviews.isEmpty) {
                        return const Text('No reviews yet');
                      }

                      return Column(
                        children: reviews
                            .take(3)
                            .map((review) => ReviewListItem(review: review))
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: CustomButton(
                  onPressed: _product!.quantity > 0
                      ? _addToCart
                      : null,
                  child: Text(
                    _product!.quantity > 0 ? 'Add to Cart' : 'Out of Stock',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              CustomButton(
                onPressed: () {
                  // Buy now
                },
                backgroundColor: theme.colorScheme.secondary,
                child: const Text('Buy Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 