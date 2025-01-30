import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../models/cart_item.dart';
import '../../models/shipping_address.dart';
import '../../models/seller.dart';
import '../../providers/cart_provider.dart';
import '../../services/buyer_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../services/seller_service.dart';
import 'package:flutter/services.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  final _buyerPaymentNameController = TextEditingController();
  bool _isLoading = true;
  bool _isProcessing = false;
  List<CartItem> _items = [];
  String? _error;
  String? _selectedPaymentMethod;
  Map<String, double> _deliveryFees = {};
  ShippingAddress? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _loadCheckout();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    _buyerPaymentNameController.dispose();
    super.dispose();
  }

  Future<void> _loadCheckout() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = ref.read(cartProvider);
      final user = await ref.read(buyerServiceProvider).getCurrentUser();

      if (mounted) {
        setState(() {
          _items = items;
          if (user?.defaultShippingAddress != null) {
            _selectedAddress = user!.defaultShippingAddress;
            _addressController.text = user.defaultShippingAddress!.street;
            _cityController.text = user.defaultShippingAddress!.city;
            _stateController.text = user.defaultShippingAddress!.state;
            _zipController.text = user.defaultShippingAddress!.zipCode;
            _countryController.text = user.defaultShippingAddress!.country;
            _phoneController.text = user.defaultShippingAddress!.phone ?? '';
          }
          _selectedPaymentMethod = null;
        });
      }

      await _loadDeliveryFees();

      if (mounted) {
        setState(() {
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

  Future<void> _loadDeliveryFees() async {
    final itemsBySeller = <String, List<CartItem>>{};
    for (var item in _items) {
      if (!itemsBySeller.containsKey(item.product.sellerId)) {
        itemsBySeller[item.product.sellerId] = [];
      }
      itemsBySeller[item.product.sellerId]!.add(item);
    }

    // Calculate delivery fees for each seller
    for (var entry in itemsBySeller.entries) {
      final sellerId = entry.key;
      final sellerItems = entry.value;
      final deliveryFee = await _calculateDeliveryFee(sellerId, sellerItems);
      setState(() {
        _deliveryFees[sellerId] = deliveryFee;
      });
    }
  }

  Future<double> _calculateDeliveryFee(String sellerId, List<CartItem> items) async {
    // For now, return a fixed fee
    return 0.5;
  }

  Future<void> _placeOrder() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    if (_buyerPaymentNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the name used for payment')),
      );
      return;
    }

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a shipping address in your profile')),
      );
      return;
    }

    // Show warning dialog
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            const Text('Warning'),
          ],
        ),
        content: const Text(
          'IMPORTANT: Please ensure you make the payment before placing the order.\n\n'
          'If you are reported for not making payments or submitting empty/unpaid orders, '
          'and two or more stores report such behavior, your account will be permanently terminated '
          'without any consideration.\n\n'
          'Do you want to proceed with placing the order?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    setState(() => _isLoading = true);

    try {
      final cartItems = ref.read(cartProvider);

      // Group items by seller
      final itemsBySeller = <String, List<CartItem>>{};
      for (var item in cartItems) {
        if (!itemsBySeller.containsKey(item.product.sellerId)) {
          itemsBySeller[item.product.sellerId] = [];
        }
        itemsBySeller[item.product.sellerId]!.add(item);
      }

      // Create an order for each seller
      for (var entry in itemsBySeller.entries) {
        final sellerId = entry.key;
        final sellerItems = entry.value;
        
        // Get seller's payment details
        final seller = await ref.read(sellerServiceProvider).getSellerProfileById(sellerId);
        if (seller == null) throw Exception('Seller not found');
        
        if (!seller.acceptedPaymentMethods.contains(_selectedPaymentMethod)) {
          throw Exception('Selected payment method not accepted by seller');
        }

        final paymentPhoneNumber = seller.paymentPhoneNumbers[_selectedPaymentMethod];
        if (paymentPhoneNumber == null) throw Exception('Seller payment details not found');

        // Calculate total for this seller's items
        final itemsTotal = sellerItems.fold(
          0.0,
          (sum, item) => sum + (item.product.price * item.quantity),
        );
        final deliveryFee = _deliveryFees[sellerId] ?? 0.5;
        final total = itemsTotal + deliveryFee;

        await ref.read(buyerServiceProvider).placeOrder(
          items: sellerItems,
          shippingAddress: {
            'street': _addressController.text,
            'city': _cityController.text,
            'state': _stateController.text,
            'country': _countryController.text,
            'zipCode': _zipController.text,
            'phone': _phoneController.text,
          },
          paymentMethod: _selectedPaymentMethod!,
          buyerPaymentName: _buyerPaymentNameController.text.trim(),
          total: total,
        );
      }

      // Clear cart after successful order placement
      await ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Order Placed Successfully'),
            content: const Text(
              'Your order has been placed successfully!\n\n'
              'The seller will be notified and will process your order once they confirm your payment.'
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/home',
                    (route) => false,
                  );
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
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
    final cartItems = ref.watch(cartProvider);

    if (cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: Text('Your cart is empty')),
      );
    }

    // Group items by seller
    final itemsBySeller = <String, List<CartItem>>{};
    for (var item in cartItems) {
      if (!itemsBySeller.containsKey(item.product.sellerId)) {
        itemsBySeller[item.product.sellerId] = [];
      }
      itemsBySeller[item.product.sellerId]!.add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Shipping Address',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_addressController.text),
                        Text('${_cityController.text}, ${_stateController.text}'),
                        Text('${_countryController.text} ${_zipController.text}'),
                        Text('Phone: ${_phoneController.text}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Orders by Seller
                ...itemsBySeller.entries.map((entry) {
                  final sellerId = entry.key;
                  final sellerItems = entry.value;
                  return FutureBuilder<Seller?>(
                    future: ref.read(sellerServiceProvider).getSellerProfileById(sellerId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final seller = snapshot.data!;
                      final itemsTotal = sellerItems.fold(
                        0.0,
                        (sum, item) => sum + (item.product.price * item.quantity),
                      );
                      final deliveryFee = _deliveryFees[sellerId] ?? 0.5;
                      final total = itemsTotal + deliveryFee;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                seller.storeName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...sellerItems.map((item) => ListTile(
                                    leading: item.product.imageUrl != null
                                        ? Image.network(
                                            item.product.imageUrl!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(Icons.image),
                                    title: Text(item.product.name),
                                    subtitle: Text(
                                      'Quantity: ${item.quantity}',
                                    ),
                                    trailing: Text(
                                      'GHS ${(item.product.price * item.quantity).toStringAsFixed(2)}',
                                    ),
                                  )),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Items Total:'),
                                  Text('GHS ${itemsTotal.toStringAsFixed(2)}'),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Delivery Fee:'),
                                  Text('GHS ${deliveryFee.toStringAsFixed(2)}'),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'GHS ${total.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Accepted Payment Methods:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: seller.acceptedPaymentMethods.map((method) {
                                  final isSelected = _selectedPaymentMethod == method;
                                  return ChoiceChip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          'public/${method == 'mtn_momo' ? 'mtn.png' : 'telecel.png'}',
                                          width: 24,
                                          height: 24,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(method == 'mtn_momo' ? 'MTN MoMo' : 'Telecel Cash'),
                                      ],
                                    ),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() => _selectedPaymentMethod = selected ? method : null);
                                    },
                                  );
                                }).toList(),
                              ),
                              if (_selectedPaymentMethod != null) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Send payment to:'),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: SelectableText(
                                                  seller.paymentPhoneNumbers[_selectedPaymentMethod]!,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  Clipboard.setData(ClipboardData(
                                                    text: seller.paymentPhoneNumbers[_selectedPaymentMethod]!,
                                                  ));
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Phone number copied to clipboard'),
                                                      duration: Duration(seconds: 2),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.copy),
                                                tooltip: 'Copy phone number',
                                              ),
                                            ],
                                          ),
                                          Text(
                                            'Name: ${seller.paymentNames[_selectedPaymentMethod]}',
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
                const SizedBox(height: 16),

                // Buyer Payment Name
                if (_selectedPaymentMethod != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Payment Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _buyerPaymentNameController,
                            label: 'Your Payment Name',
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your payment name';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
                CustomButton(
                  onPressed: _isLoading ? null : _placeOrder,
                  text: _isLoading ? 'Processing...' : 'Place Order',
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
} 