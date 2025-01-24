import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product.dart';
import '../../services/buyer_service.dart';
import '../../widgets/common/custom_button.dart';
import 'cart_screen.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  int _currentImageIndex = 0;
  int _quantity = 1;
  bool _isLoading = false;
  String? _error;
  String? _selectedSize;
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    if (widget.product.hasVariants && widget.product.sizes.isNotEmpty && _selectedSize == null) {
      setState(() => _error = 'Please select a size');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(buyerServiceProvider).addToCart(
        widget.product.id,
        _quantity,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to cart')),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final discountedPrice = widget.product.hasDiscount && widget.product.discountPercent > 0
        ? widget.product.price * (1 - widget.product.discountPercent / 100)
        : null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: widget.product.images.isEmpty ? 1 : widget.product.images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          if (widget.product.images.isEmpty)
                            Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported, size: 64),
                            )
                          else
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Scaffold(
                                      backgroundColor: Colors.black,
                                      appBar: AppBar(
                                        backgroundColor: Colors.black,
                                        iconTheme: const IconThemeData(color: Colors.white),
                                      ),
                                      body: Center(
                                        child: InteractiveViewer(
                                          minScale: 0.5,
                                          maxScale: 4.0,
                                          child: CachedNetworkImage(
                                            imageUrl: widget.product.images[index],
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: CachedNetworkImage(
                                imageUrl: widget.product.images[index],
                                fit: BoxFit.cover,
                                width: double.infinity,
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
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (widget.product.images.isNotEmpty)
                  Container(
                    height: 80,
                    color: Colors.grey[100],
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: widget.product.images.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: 64,
                            height: 64,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _currentImageIndex == index
                                    ? const Color(0xFFFF4646)
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: CachedNetworkImage(
                                imageUrl: widget.product.images[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'by ${widget.product.sellerName}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Price Section
                      if (widget.product.hasDiscount)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            'GHS ${discountedPrice?.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'GHS ${widget.product.price.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              decoration: TextDecoration.lineThrough,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Save GHS ${(widget.product.price - (discountedPrice ?? 0)).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.timer_outlined,
                                          color: Color(0xFFE91E63),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Ends: Feb 1, 07:59 GMT',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.product.stockQuantity} in stock',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Variants Section
                      if (widget.product.hasVariants && widget.product.sizes.isNotEmpty) ...[
                        Text(
                          'Select Size',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.product.sizes.map((size) {
                            return ChoiceChip(
                              label: Text(size),
                              selected: _selectedSize == size,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedSize = selected ? size : null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Description
                      Text(
                        'Description',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.product.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 24),

                      // Error Message
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Quantity and Add to Cart
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: theme.colorScheme.outline,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: _quantity > 1
                                      ? () {
                                          setState(() {
                                            _quantity--;
                                          });
                                        }
                                      : null,
                                  icon: const Icon(Icons.remove),
                                ),
                                Text(
                                  '$_quantity',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _quantity < widget.product.stockQuantity
                                      ? () {
                                          setState(() {
                                            _quantity++;
                                          });
                                        }
                                      : null,
                                  icon: const Icon(Icons.add),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _addToCart,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                              child: Text(_isLoading ? 'Adding to Cart...' : 'Add to Cart'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 