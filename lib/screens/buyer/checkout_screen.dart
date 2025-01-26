import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user.dart';
import '../../models/cart_item.dart';
import '../../models/seller.dart';
import '../../services/buyer_service.dart';
import '../../services/auth_service.dart';
import '../../services/seller_service.dart';
import '../../services/payment_service.dart';
import '../../widgets/common/custom_button.dart';
import 'order_confirmation_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final List<CartItem> cartItems;
  final double total;

  const CheckoutScreen({
    super.key,
    required this.cartItems,
    required this.total,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isLoading = false;
  String? _error;
  MerchUser? _currentUser;
  Map<String, Seller?> _sellers = {};

  @override
  void initState() {
    super.initState();
    _loadUserAndSellers();
  }

  Future<void> _loadUserAndSellers() async {
    try {
      // Load current user
      final user = await ref.read(buyerServiceProvider).getCurrentUser();
      print('Loaded user data: ${user?.toMap()}');
      print('Default shipping address: ${user?.defaultShippingAddress?.toMap()}');
      setState(() => _currentUser = user);

      // Load sellers
      final sellerIds = widget.cartItems.map((item) => item.product.sellerId).toSet();
      for (final sellerId in sellerIds) {
        final seller = await ref.read(sellerServiceProvider).getSellerProfileById(sellerId);
        setState(() {
          _sellers[sellerId] = seller;
        });
      }
    } catch (e) {
      print('Error loading user and sellers: $e');
    }
  }

  Future<void> _placeOrder() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to place an order')),
      );
      return;
    }

    try {
      // Initialize payment
      final paymentService = ref.read(paymentServiceProvider);
      final reference = DateTime.now().millisecondsSinceEpoch.toString();
      
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final authorizationUrl = await paymentService.initializeTransaction(
        email: _currentUser!.email,
        amount: widget.total,
        currency: 'GHS',
        reference: reference,
        metadata: {
          'items': widget.cartItems.map((item) => {
            'productId': item.product.id,
            'name': item.product.name,
            'quantity': item.quantity.toString(),
            'color': item.selectedColor,
            'size': item.selectedSize ?? '',
          }).toList(),
          'shippingAddress': {
            'street': _currentUser!.defaultShippingAddress?.street ?? '',
            'city': _currentUser!.defaultShippingAddress?.city ?? '',
            'state': _currentUser!.defaultShippingAddress?.state ?? '',
          },
        },
      );

      setState(() => _isLoading = false);

      // Show payment WebView and wait for result
      final paymentSuccess = await paymentService.handlePayment(context, authorizationUrl);

      if (!mounted) return;

      if (paymentSuccess) {
        setState(() => _isLoading = true);

        // Verify the transaction
        final isVerified = await paymentService.verifyTransaction(reference);

        if (!mounted) return;

        if (isVerified) {
          // Place order
          await ref.read(buyerServiceProvider).placeOrder(
            items: widget.cartItems,
            shippingAddressId: _currentUser!.defaultShippingAddress?.id ?? '',
          );

          if (!mounted) return;

          // Navigate to confirmation
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrderConfirmationScreen(
                orderReference: reference,
              ),
            ),
          );
        } else {
          setState(() {
            _error = 'Payment verification failed. Please contact support if payment was deducted.';
            _isLoading = false;
          });
        }
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
    final theme = Theme.of(context);

    // Group items by seller
    final itemsBySeller = <String, List<CartItem>>{};
    for (var item in widget.cartItems) {
      if (!itemsBySeller.containsKey(item.product.sellerId)) {
        itemsBySeller[item.product.sellerId] = [];
      }
      itemsBySeller[item.product.sellerId]!.add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Shipping Address Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined),
                            const SizedBox(width: 8),
                            Text(
                              'Shipping Address',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_currentUser?.defaultShippingAddress == null)
                          const Text('No shipping address set')
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_currentUser!.defaultShippingAddress!.name),
                              const SizedBox(height: 4),
                              Text(_currentUser!.defaultShippingAddress!.street),
                              Text('${_currentUser!.defaultShippingAddress!.city}, ${_currentUser!.defaultShippingAddress!.state}'),
                              Text('${_currentUser!.defaultShippingAddress!.zipCode}'),
                              if (_currentUser!.defaultShippingAddress!.phone != null) ...[
                                const SizedBox(height: 4),
                                Text(_currentUser!.defaultShippingAddress!.phone!),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Order Items Section
                ...itemsBySeller.entries.map((entry) {
                  final sellerId = entry.key;
                  final items = entry.value;
                  final seller = _sellers[sellerId];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (seller != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.store,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                seller.storeName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Card(
                        child: Column(
                          children: items.map((item) {
                            return ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: CachedNetworkImage(
                                  imageUrl: item.selectedColorImage ?? item.product.images.first,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(
                                item.product.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item.selectedSize != null || item.selectedColor != null)
                                    Wrap(
                                      spacing: 4,
                                      children: [
                                        if (item.selectedSize != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surfaceVariant,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Size: ${item.selectedSize}',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        if (item.selectedColor != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.surfaceVariant,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Color: ${item.selectedColor}',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  Text(
                                    'Quantity: ${item.quantity}',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              trailing: Text(
                                'GHS ${((item.product.hasDiscount
                                        ? item.product.price * (1 - item.product.discountPercent / 100)
                                        : item.product.price) * item.quantity)
                                    .toStringAsFixed(2)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                }).toList(),

                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
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
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        'GHS ${widget.total.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _currentUser?.defaultShippingAddress == null ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('PLACE ORDER'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 