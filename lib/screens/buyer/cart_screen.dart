import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../services/auth_service.dart';
import '../../services/seller_service.dart';
import '../../widgets/common/custom_button.dart';
import 'checkout_screen.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _isLoading = false;
  Set<String> _selectedItems = {};
  Map<String, double> _sellerShippingFees = {};

  @override
  void initState() {
    super.initState();
    _calculateShippingFees();
  }

  Future<void> _calculateShippingFees() async {
    final cartItems = ref.read(cartProvider);
    final currentUser = await ref.read(authServiceProvider).getCurrentUser();
    final buyerCity = currentUser?.city?.trim().toLowerCase() ?? '';
    
    // Group items by seller
    final sellerItems = <String, List<CartItem>>{};
    for (var item in cartItems) {
      if (!sellerItems.containsKey(item.product.sellerId)) {
        sellerItems[item.product.sellerId] = [];
      }
      sellerItems[item.product.sellerId]!.add(item);
    }

    // Calculate shipping fee for each seller
    for (var sellerId in sellerItems.keys) {
      final seller = await ref.read(sellerServiceProvider).getSellerProfileById(sellerId);
      final sellerCity = seller?.city?.trim().toLowerCase() ?? '';
      
      double baseFee = (buyerCity == sellerCity) ? 50.0 : 70.0;
      // If multiple items from same seller, divide shipping fee by 2
      if (sellerItems[sellerId]!.length > 1) {
        baseFee = baseFee / 2;
      }
      
      setState(() {
        _sellerShippingFees[sellerId] = baseFee;
      });
    }
  }

  double _calculateTotalShippingFee() {
    double total = 0;
    final selectedItems = ref.read(cartProvider)
        .where((item) => _selectedItems.contains(item.product.id));
    
    // Group selected items by seller
    final selectedSellerItems = <String, List<CartItem>>{};
    for (var item in selectedItems) {
      if (!selectedSellerItems.containsKey(item.product.sellerId)) {
        selectedSellerItems[item.product.sellerId] = [];
      }
      selectedSellerItems[item.product.sellerId]!.add(item);
    }

    // Add shipping fee for each seller
    for (var sellerId in selectedSellerItems.keys) {
      if (_sellerShippingFees.containsKey(sellerId)) {
        total += _sellerShippingFees[sellerId]!;
      }
    }

    return total;
  }

  double _calculateSubtotal() {
    return ref.read(cartProvider)
        .where((item) => _selectedItems.contains(item.product.id))
        .fold(0, (sum, item) => sum + (item.product.hasDiscount
            ? item.product.price * (1 - item.product.discountPercent / 100) * item.quantity
            : item.product.price * item.quantity));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cartItems = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text('Are you sure you want to clear your cart?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(cartProvider.notifier).clearCart();
                          Navigator.pop(context);
                        },
                        child: const Text('CLEAR'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Clear'),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final isSelected = _selectedItems.contains(item.product.id);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              shape: const CircleBorder(),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedItems.add(item.product.id);
                                  } else {
                                    _selectedItems.remove(item.product.id);
                                  }
                                });
                              },
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: item.product.images.first,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.product.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'GHS ${(item.product.hasDiscount
                                            ? item.product.price * (1 - item.product.discountPercent / 100)
                                            : item.product.price).toStringAsFixed(2)}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_sellerShippingFees.containsKey(item.product.sellerId))
                                    Text(
                                      'Shipping: GHS ${_sellerShippingFees[item.product.sellerId]!.toStringAsFixed(2)}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () {
                                    ref.read(cartProvider.notifier).removeFromCart(item.product.id);
                                    _selectedItems.remove(item.product.id);
                                  },
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: item.quantity > 1
                                          ? () {
                                              ref.read(cartProvider.notifier).updateQuantity(
                                                    item.product.id,
                                                    item.quantity - 1,
                                                  );
                                            }
                                          : null,
                                    ),
                                    Text('${item.quantity}'),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        ref.read(cartProvider.notifier).updateQuantity(
                                              item.product.id,
                                              item.quantity + 1,
                                            );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (cartItems.isNotEmpty)
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
                              const Text('Subtotal'),
                              Text(
                                'GHS ${_calculateSubtotal().toStringAsFixed(2)}',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Shipping Fee'),
                              Text(
                                'GHS ${_calculateTotalShippingFee().toStringAsFixed(2)}',
                                style: theme.textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: theme.textTheme.titleMedium,
                              ),
                              Text(
                                'GHS ${(_calculateSubtotal() + _calculateTotalShippingFee()).toStringAsFixed(2)}',
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
                              onPressed: _selectedItems.isEmpty
                                  ? null
                                  : () {
                                      final selectedCartItems = cartItems
                                          .where((item) => _selectedItems.contains(item.product.id))
                                          .toList();
                                      
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CheckoutScreen(
                                            cartItems: selectedCartItems,
                                            total: _calculateSubtotal() + _calculateTotalShippingFee(),
                                          ),
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('CHECKOUT'),
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