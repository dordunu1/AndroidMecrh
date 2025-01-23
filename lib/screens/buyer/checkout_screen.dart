import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user.dart';
import '../../models/cart_item.dart';
import '../../services/buyer_service.dart';
import '../../widgets/common/custom_button.dart';
import 'order_confirmation_screen.dart';

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
  String? _selectedAddressId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MerchUser>(
      future: ref.read(buyerServiceProvider).getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final user = snapshot.data!;
        if (user.defaultShippingAddress != null) {
          // Set default shipping address if available
          _selectedAddressId = user.defaultShippingAddress!.id;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Checkout'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...widget.cartItems.map((item) => ListTile(
                              title: Text(item.product.name),
                              subtitle: Text('Quantity: ${item.quantity}'),
                              trailing: Text(
                                '\$${(item.product.price * item.quantity).toStringAsFixed(2)}',
                              ),
                            )),
                        const Divider(),
                        ListTile(
                          title: const Text(
                            'Total',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Text(
                            '\$${widget.total.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Shipping Address',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (user.shippingAddresses.isEmpty)
                          const Text('No shipping addresses found')
                        else
                          ...user.shippingAddresses.map(
                            (address) => RadioListTile(
                              title: Text(address.name),
                              subtitle: Text(
                                '${address.street}, ${address.city}, ${address.state} ${address.zipCode}',
                              ),
                              value: address.id,
                              groupValue: _selectedAddressId,
                              onChanged: (value) {
                                setState(() {
                                  _selectedAddressId = value as String;
                                });
                              },
                            ),
                          ),
                        const SizedBox(height: 16),
                        CustomButton(
                          onPressed: () {
                            // TODO: Navigate to add shipping address screen
                          },
                          text: 'Add New Address',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_selectedAddressId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a shipping address'),
                              ),
                            );
                            return;
                          }

                          setState(() => _isLoading = true);
                          try {
                            await ref.read(buyerServiceProvider).placeOrder(
                              items: widget.cartItems,
                              shippingAddressId: _selectedAddressId!,
                            );

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Order placed successfully'),
                                ),
                              );
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const OrderConfirmationScreen(),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error placing order: $e'),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isLoading = false);
                            }
                          }
                        },
                  text: _isLoading ? 'Placing Order...' : 'Place Order',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 