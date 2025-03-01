import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product.dart';
import '../../services/buyer_service.dart';
import '../../services/product_service.dart';
import '../../services/review_service.dart';
import '../../models/review.dart';
import '../../widgets/common/custom_button.dart';
import '../../models/user.dart';
import '../../models/seller.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item.dart';
import 'cart_screen.dart';
import '../../services/seller_service.dart';
import '../chat/chat_screen.dart';
import '../checkout/checkout_screen.dart';
import '../../services/realtime_service.dart';
import 'dart:async';
import 'package:intl/intl.dart';

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
  bool _isDescriptionExpanded = false;
  List<Product>? _sellerProducts;
  List<Review>? _reviews;
  MerchUser? _currentUser;
  bool _isLoadingMore = false;
  String? _sellerCity;
  String? _sellerCountry;
  String? _selectedColor;
  Seller? _seller;
  StreamSubscription? _productSubscription;
  late Product _product;
  String? _selectedColorImage;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    // Auto-select color if there's only one
    if (widget.product.colors.length == 1) {
      _selectedColor = widget.product.colors.first;
      _selectedColorImage = widget.product.imageColors.entries
          .firstWhere(
            (entry) => entry.value == _selectedColor,
            orElse: () => MapEntry(widget.product.images.first, _selectedColor ?? '')
          ).key;
    }
    _loadInitialData();
    _setupRealtimeUpdates();
  }

  Future<void> _loadInitialData() async {
    try {
      // Load current user
      final user = await ref.read(authServiceProvider).getCurrentUser();
      setState(() => _currentUser = user);
      
      // Load seller info from sellers collection
      final seller = await ref.read(sellerServiceProvider).getSellerProfileById(widget.product.sellerId);
      if (seller != null) {
        setState(() {
          _seller = seller;
          _sellerCity = seller.city;
          _sellerCountry = seller.country;
        });
      }
      
      // Load seller's other products
      final products = await ref.read(productServiceProvider).getProducts(
        sellerId: widget.product.sellerId,
        limit: 10,
      );
      setState(() => _sellerProducts = products.where((p) => p.id != widget.product.id).toList());

      // Load reviews
      final reviews = await ref.read(reviewServiceProvider).getProductReviews(widget.product.id);
      setState(() => _reviews = reviews);
    } catch (e) {
      print('Error loading initial data: $e');
    }
  }

  void _setupRealtimeUpdates() {
    _productSubscription?.cancel();
    _productSubscription = ref
        .read(realtimeServiceProvider)
        .listenToProductStock(
          _product.id,
          (updatedProduct) {
            if (mounted) {
              setState(() {
                // Update product data using copyWith
                _product = _product.copyWith(
                  stockQuantity: updatedProduct.stockQuantity,
                  colorQuantities: updatedProduct.colorQuantities,
                  variantQuantities: updatedProduct.variantQuantities,
                );
                
                // Validate current selections
                if (_selectedColor != null) {
                  final availableQuantity = _product.colorQuantities[_selectedColor] ?? 0;
                  if (_quantity > availableQuantity) {
                    _quantity = availableQuantity > 0 ? availableQuantity : 1;
                  }
                } else {
                  if (_quantity > _product.stockQuantity) {
                    _quantity = _product.stockQuantity > 0 ? _product.stockQuantity : 1;
                  }
                }
              });
            }
          },
        );
  }

  double _calculateDeliveryFee() {
    if (_currentUser == null) return 0.5; // Default to same city fee if user not loaded
    
    final buyerCity = _currentUser!.city?.trim().toLowerCase() ?? '';
    final buyerCountry = _currentUser!.country?.trim().toLowerCase() ?? '';
    final sellerCity = _sellerCity?.trim().toLowerCase() ?? '';
    final sellerCountry = _sellerCountry?.trim().toLowerCase() ?? '';
    
    print('Calculating delivery fee:');
    print('Buyer city: $buyerCity');
    print('Buyer country: $buyerCountry');
    print('Seller city: $sellerCity');
    print('Seller country: $sellerCountry');
    
    // First check if both are in Ghana
    if (buyerCountry == 'ghana' && sellerCountry == 'ghana') {
      // If same city, return 0.5
      if (buyerCity == sellerCity) {
        return 0.5;
      }
      // Different cities in Ghana
      return 0.7;
    }
    
    // International shipping
    return 1.0;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _productSubscription?.cancel();
    super.dispose();
  }

  void _onImageTapped(int index) {
    final imageUrl = widget.product.images[index];
    final color = widget.product.imageColors[imageUrl];
    final quantity = color != null ? widget.product.colorQuantities[color] : null;
    
    // Check if the variant is sold out
    if (quantity != null && quantity == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$color is sold out'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _currentImageIndex = index;
      _pageController.jumpToPage(index);
      // Update selected color based on the image
      if (color != null) {
        _selectedColor = color;
        _selectedColorImage = imageUrl;
      }
    });
  }

  Future<void> _addToCart() async {
    if (!mounted) return;

    try {
      // Validate size selection if product has sizes
      if (widget.product.sizes.isNotEmpty && (_selectedSize == null || _selectedSize!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a size')),
        );
        return;
      }

      // Check if selected color is sold out
      if (_selectedColor != null) {
        final quantity = widget.product.colorQuantities[_selectedColor] ?? 0;
        if (quantity == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$_selectedColor is sold out'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      } else if (widget.product.stockQuantity == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This product is sold out'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Get the color-specific image URL by finding the image URL (key) that maps to the selected color (value)
      String? colorImage;
      String? finalColor = _selectedColor;

      // If no color is selected but we're on an image, try to find its color
      if ((finalColor == null || finalColor.isEmpty) && widget.product.images.isNotEmpty) {
        final currentImage = widget.product.images[_currentImageIndex];
        finalColor = widget.product.imageColors[currentImage];
        if (finalColor != null && finalColor.isNotEmpty) {
          colorImage = currentImage;
        }
      }

      // If we have a color but no image, find the matching image
      if (finalColor != null && finalColor.isNotEmpty) {
        if (colorImage == null) {
          final currentImage = widget.product.images[_currentImageIndex];
          if ((widget.product.imageColors[currentImage] ?? '').toLowerCase() == finalColor.toLowerCase()) {
            colorImage = currentImage;
          } else {
            final colorEntry = widget.product.imageColors.entries.firstWhere(
              (entry) => (entry.value ?? '').toLowerCase() == (finalColor ?? '').toLowerCase(),
              orElse: () => MapEntry(widget.product.images.first, ''),
            );
            colorImage = colorEntry.key;
            // If we found a valid color entry, make sure color matches exactly
            if (colorEntry.value.isNotEmpty) {
              finalColor = colorEntry.value; // Use exact case from the product data
            }
          }
        }
      } else {
        // If still no color, use the first available color and its image
        final firstColorEntry = widget.product.imageColors.entries.firstWhere(
          (entry) => entry.value.isNotEmpty,
          orElse: () => MapEntry(widget.product.images.first, ''),
        );
        colorImage = firstColorEntry.key;
        finalColor = firstColorEntry.value;
      }

      // Check if the final selected color is sold out
      if (finalColor != null && finalColor.isNotEmpty) {
        final quantity = widget.product.colorQuantities[finalColor] ?? 0;
        if (quantity == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$finalColor is sold out'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      ref.read(cartProvider.notifier).addToCart(
        CartItem(
          product: widget.product,
          quantity: _quantity,
          selectedSize: _selectedSize,
          selectedColor: finalColor,
          selectedColorImage: colorImage,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Added to cart'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _buyNow() async {
    if (!mounted) return;

    try {
      // Validate size selection if product has sizes
      if (widget.product.sizes.isNotEmpty && (_selectedSize == null || _selectedSize!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a size')),
        );
        return;
      }

      // Get the color-specific image URL by finding the image URL (key) that maps to the selected color (value)
      String? colorImage;
      String? finalColor = _selectedColor;

      // If no color is selected but we're on an image, try to find its color
      if ((finalColor == null || finalColor.isEmpty) && widget.product.images.isNotEmpty) {
        final currentImage = widget.product.images[_currentImageIndex];
        finalColor = widget.product.imageColors[currentImage];
        if (finalColor != null && finalColor.isNotEmpty) {
          colorImage = currentImage;
        }
      }

      // If we have a color but no image, find the matching image
      if (finalColor != null && finalColor.isNotEmpty) {
        if (colorImage == null) {
          final currentImage = widget.product.images[_currentImageIndex];
          if ((widget.product.imageColors[currentImage] ?? '').toLowerCase() == finalColor.toLowerCase()) {
            colorImage = currentImage;
          } else {
            final colorEntry = widget.product.imageColors.entries.firstWhere(
              (entry) => (entry.value ?? '').toLowerCase() == (finalColor ?? '').toLowerCase(),
              orElse: () => MapEntry(widget.product.images.first, ''),
            );
            colorImage = colorEntry.key;
            // If we found a valid color entry, make sure color matches exactly
            if (colorEntry.value.isNotEmpty) {
              finalColor = colorEntry.value; // Use exact case from the product data
            }
          }
        }
      } else {
        // If still no color, use the first available color and its image
        final firstColorEntry = widget.product.imageColors.entries.firstWhere(
          (entry) => entry.value.isNotEmpty,
          orElse: () => MapEntry(widget.product.images.first, ''),
        );
        colorImage = firstColorEntry.key;
        finalColor = firstColorEntry.value;
      }

      // Clear the cart first
      ref.read(cartProvider.notifier).clearCart();

      // Add the current item to cart
      ref.read(cartProvider.notifier).addToCart(
        CartItem(
          product: widget.product,
          quantity: _quantity,
          selectedSize: _selectedSize,
          selectedColor: finalColor,
          selectedColorImage: colorImage,
        ),
      );

      if (!mounted) return;
      
      // Navigate directly to checkout
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CheckoutScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _contactStore() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to contact the store')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final conversationId = await ref.read(chatServiceProvider).createOrGetConversation(
        _product.sellerId,
        _product.id,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationId,
              otherUserName: _seller?.storeName ?? 'Store',
              productId: _product.id,
              otherParticipantId: _product.sellerId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
    final theme = Theme.of(context);
    final discountedPrice = widget.product.hasDiscount && widget.product.discountPercent > 0
        ? widget.product.price * (1 - widget.product.discountPercent / 100)
        : null;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
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
                        onPageChanged: _onImageTapped,
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
                            final imageUrl = widget.product.images[index];
                            final color = widget.product.imageColors[imageUrl];
                            if (color != null) {
                              final quantity = widget.product.colorQuantities[color];
                              final isSoldOut = quantity == null || quantity == 0;
                              return Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (isSoldOut) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('$color is sold out'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }
                                      _onImageTapped(index);
                                    },
                                    child: Container(
                                      width: 64,
                                      height: 64,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _currentImageIndex == index
                                              ? theme.colorScheme.primary
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(6),
                                            child: ColorFiltered(
                                              colorFilter: ColorFilter.matrix(
                                                isSoldOut ? [
                                                  0.2126, 0.7152, 0.0722, 0, 0,
                                                  0.2126, 0.7152, 0.0722, 0, 0,
                                                  0.2126, 0.7152, 0.0722, 0, 0,
                                                  0, 0, 0, 1, 0,
                                                ] : [
                                                  1, 0, 0, 0, 0,
                                                  0, 1, 0, 0, 0,
                                                  0, 0, 1, 0, 0,
                                                  0, 0, 0, 1, 0,
                                                ],
                                              ),
                                              child: CachedNetworkImage(
                                                imageUrl: imageUrl,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          if (isSoldOut)
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.5),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  'SOLD OUT',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (color != null)
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: const BorderRadius.only(
                                            bottomLeft: Radius.circular(8),
                                            bottomRight: Radius.circular(8),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              color,
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: Colors.white,
                                                fontSize: 10,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (!isSoldOut && quantity != null)
                                              Text(
                                                '$quantity left',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: Colors.white70,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            if (isSoldOut)
                                              Text(
                                                'Sold Out',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: Colors.red[300],
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            }
                            return Container();
                          },
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.product.name,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            Icons.store,
                                            size: 24,
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () => Navigator.pushNamed(
                                              context,
                                              '/store',
                                              arguments: {'sellerId': widget.product.sellerId},
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _seller?.storeName ?? 'Loading...',
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    color: theme.colorScheme.primary,
                                                    fontWeight: FontWeight.w600,
                                                    decoration: TextDecoration.underline,
                                                  ),
                                                ),
                                                if (_seller?.city != null || _seller?.country != null)
                                                  Text(
                                                    [
                                                      if (_seller?.city != null) _seller!.city,
                                                      if (_seller?.country != null) _seller!.country,
                                                    ].where((e) => e != null).join(', '),
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        TextButton.icon(
                                          onPressed: _contactStore,
                                          icon: const Icon(Icons.chat_bubble_outline, size: 20),
                                          label: const Text('Chat'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: theme.colorScheme.primary,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.star,
                                              size: 16,
                                              color: theme.colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${widget.product.rating?.toStringAsFixed(1) ?? '0.0'}',
                                              style: theme.textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              ' (${widget.product.reviewCount ?? 0})',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 16),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.shopping_bag_outlined,
                                              size: 16,
                                              color: theme.colorScheme.primary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${widget.product.soldCount ?? 0} sold',
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!widget.product.hasDiscount)
                                Text(
                                  'GHS ${widget.product.price.toStringAsFixed(2)}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Price Section with Discount Card
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
                                        child: Text(
                                          'Ends: ${DateFormat('MMM d, HH:mm').format(widget.product.discountEndsAt ?? DateTime.now())}',
                                          style: TextStyle(
                                            color: theme.colorScheme.primary,
                                            fontSize: 11,
                                          ),
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

                          // Description Section
                          InkWell(
                            onTap: () {
                              setState(() {
                                _isDescriptionExpanded = !_isDescriptionExpanded;
                              });
                            },
                            child: Row(
                              children: [
                                Text(
                                  'Description',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  _isDescriptionExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                          AnimatedCrossFade(
                            firstChild: Text(
                              widget.product.description,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            secondChild: Text(
                              widget.product.description,
                              style: theme.textTheme.bodyMedium,
                            ),
                            crossFadeState: _isDescriptionExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 300),
                          ),
                          const SizedBox(height: 24),

                          // Delivery Fee Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.local_shipping_outlined,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Delivery Fee',
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'GHS ${_calculateDeliveryFee().toStringAsFixed(2)}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_currentUser?.city != null || _sellerCity != null)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (_currentUser?.city != null)
                                              Text(
                                                'Delivering to: ${_currentUser!.city}',
                                                style: theme.textTheme.bodySmall,
                                              ),
                                            if (_sellerCity != null)
                                              Text(
                                                'Shipping from: $_sellerCity',
                                                style: theme.textTheme.bodySmall,
                                              ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Shipping Information Section
                          if (_seller?.shippingInfo != null && _seller!.shippingInfo!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.local_shipping,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Shipping Information',
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _seller!.shippingInfo!,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Note: Delivery times and fees may vary based on your location.',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            fontStyle: FontStyle.italic,
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),

                          // Payment Methods Section
                          if (_seller?.acceptedPaymentMethods != null && _seller!.acceptedPaymentMethods.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.payment,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Accepted Payment Methods',
                                          style: theme.textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: _seller!.acceptedPaymentMethods.map((method) {
                                            String logoPath = '';
                                            switch (method) {
                                              case 'mtn_momo':
                                                logoPath = 'public/mtn.png';
                                                break;
                                              case 'telecel_cash':
                                                logoPath = 'public/telecel.png';
                                                break;
                                              default:
                                                return const SizedBox.shrink();
                                            }
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 12),
                                              child: Image.asset(
                                                logoPath,
                                                width: 40,
                                                height: 40,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 24),

                          // Reviews Section
                          Text(
                            'Reviews',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_reviews == null)
                            const Center(child: CircularProgressIndicator())
                          else if (_reviews!.isEmpty)
                            Center(
                              child: Text(
                                'No reviews yet',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _reviews!.length,
                              itemBuilder: (context, index) {
                                final review = _reviews![index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            if (review.userPhoto != null)
                                              CircleAvatar(
                                                backgroundImage: NetworkImage(review.userPhoto!),
                                                radius: 16,
                                              )
                                            else
                                              CircleAvatar(
                                                child: Text(review.userName[0].toUpperCase()),
                                                radius: 16,
                                              ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    review.userName,
                                                    style: theme.textTheme.titleSmall,
                                                  ),
                                                  Row(
                                                    children: List.generate(
                                                      5,
                                                      (index) => Icon(
                                                        index < review.rating.round()
                                                            ? Icons.star
                                                            : Icons.star_border,
                                                        size: 16,
                                                        color: theme.colorScheme.primary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              _formatDate(review.createdAt),
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(review.comment),
                                        if (review.images != null && review.images!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            height: 80,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: review.images!.length,
                                              itemBuilder: (context, imageIndex) {
                                                return Padding(
                                                  padding: const EdgeInsets.only(right: 8),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(4),
                                                    child: CachedNetworkImage(
                                                      imageUrl: review.images![imageIndex],
                                                      width: 80,
                                                      height: 80,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                        if (review.sellerResponse != null) ...[
                                          const SizedBox(height: 16),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Seller Response',
                                                  style: theme.textTheme.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(review.sellerResponse!['comment'] as String),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 24),

                          // More from this seller products
                          if (_sellerProducts != null && _sellerProducts!.isNotEmpty) ...[
                            Text(
                              'More from ${widget.product.sellerName}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.7,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: _sellerProducts!.length,
                              itemBuilder: (context, index) {
                                final product = _sellerProducts![index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetailsScreen(
                                          product: product,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(6),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  product.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme.textTheme.bodyMedium,
                                                ),
                                                const SizedBox(height: 2),
                                                if (product.hasDiscount) ...[
                                                  Card(
                                                    margin: EdgeInsets.zero,
                                                    color: theme.colorScheme.error.withOpacity(0.1),
                                                    child: Padding(
                                                      padding: const EdgeInsets.all(6),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets.symmetric(
                                                              horizontal: 4,
                                                              vertical: 2,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: theme.colorScheme.error,
                                                              borderRadius: BorderRadius.circular(4),
                                                            ),
                                                            child: Text(
                                                              '-${product.discountPercent.toStringAsFixed(0)}%',
                                                              style: theme.textTheme.labelSmall?.copyWith(
                                                                color: Colors.white,
                                                                fontWeight: FontWeight.bold,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 6),
                                                          Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Text(
                                                                'GHS ${product.discountedPrice?.toStringAsFixed(2)}',
                                                                style: theme.textTheme.labelSmall?.copyWith(
                                                                  color: theme.colorScheme.primary,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                              Text(
                                                                'GHS ${product.price.toStringAsFixed(2)}',
                                                                style: theme.textTheme.labelSmall?.copyWith(
                                                                  color: theme.colorScheme.outline,
                                                                  decoration: TextDecoration.lineThrough,
                                                                  fontSize: 10,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ] else
                                                  Text(
                                                    'GHS ${product.price.toStringAsFixed(2)}',
                                                    style: theme.textTheme.labelSmall?.copyWith(
                                                      color: theme.colorScheme.primary,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],

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
                          const SizedBox(height: 100), // Add padding at bottom for the fixed navigation
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.shopping_cart_outlined, size: 28),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CartScreen()),
                              );
                            },
                          ),
                          Consumer(
                            builder: (context, ref, child) {
                              final cartItemCount = ref.watch(cartItemCountProvider);
                              if (cartItemCount == 0) return const SizedBox();
                              return Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.error,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Text(
                                    '$cartItemCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              onPressed: _addToCart,
                              text: 'Add to Cart',
                              backgroundColor: Colors.white,
                              textColor: Theme.of(context).primaryColor,
                              outlined: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomButton(
                              onPressed: _buyNow,
                              text: 'Buy Now',
                              backgroundColor: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 