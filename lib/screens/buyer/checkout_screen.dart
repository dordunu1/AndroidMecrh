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
      final user = await ref.read(authServiceProvider).getCurrentUser();
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
    if (_currentUser?.address == null) {
      setState(() {
        _error = 'Please set your shipping address before placing an order';
      });
      return;
    }

    try {
      // Show loading overlay
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Generate reference
      final reference = DateTime.now().millisecondsSinceEpoch.toString();

      // Initialize payment
      final paymentUrl = await ref.read(paymentServiceProvider).initializeTransaction(
        email: _currentUser!.email,
        amount: widget.total,
        currency: 'GHS',
        reference: reference,
        metadata: {
          'items': widget.cartItems.map((item) => {
            'productId': item.product.id,
            'name': item.product.name,
            'quantity': item.quantity,
            'color': item.selectedColor,
            'size': item.selectedSize,
          }).toList(),
          'shippingAddress': {
            'address': _currentUser!.address,
            'city': _currentUser!.city,
            'country': _currentUser!.country,
          },
        },
      );

      // Close loading overlay
      if (mounted) {
        Navigator.pop(context);
      }

      // Launch payment page
      await ref.read(paymentServiceProvider).launchPaymentPage(paymentUrl);

      // Show loading overlay again
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Verify transaction
      final isVerified = await ref.read(paymentServiceProvider).verifyTransaction(reference);
      if (!isVerified) {
        throw Exception('Payment verification failed');
      }

      // Place order
      await ref.read(buyerServiceProvider).placeOrder(
        items: widget.cartItems,
        shippingAddressId: _currentUser!.defaultShippingAddress?.id ?? '',
      );

      // Close loading overlay
      if (mounted) {
        Navigator.pop(context);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const OrderConfirmationScreen(),
          ),
        );
      }
    } catch (e) {
      // Close loading overlay if open
      if (mounted) {
        Navigator.pop(context);
      }
      
      // Show error in snackbar instead of screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
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
                        if (_currentUser?.address == null)
                          const Text('No shipping address set')
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_currentUser!.name ?? 'No name provided'),
                              const SizedBox(height: 4),
                              Text(_currentUser!.address!),
                              if (_currentUser!.city != null) ...[
                                const SizedBox(height: 4),
                                Text(_currentUser!.city!),
                              ],
                              if (_currentUser!.country != null) ...[
                                const SizedBox(height: 4),
                                Text(_currentUser!.country!),
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
                      onPressed: _currentUser?.address == null ? null : _placeOrder,
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