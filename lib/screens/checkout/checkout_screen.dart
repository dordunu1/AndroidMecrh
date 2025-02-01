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
import '../../services/auth_service.dart';
import '../../routes.dart';
import '../buyer/order_confirmation_screen.dart';

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
  Map<String, TextEditingController> _buyerPaymentNameControllers = {};
  bool _isLoading = true;
  bool _isProcessing = false;
  List<CartItem> _items = [];
  String? _error;
  Map<String, String> _selectedPaymentMethods = {};
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
    // Dispose all payment name controllers
    for (var controller in _buyerPaymentNameControllers.values) {
      controller.dispose();
    }
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

      // Initialize payment name controllers for each seller
      final itemsBySeller = <String, List<CartItem>>{};
      for (var item in items) {
        if (!itemsBySeller.containsKey(item.product.sellerId)) {
          itemsBySeller[item.product.sellerId] = [];
          _buyerPaymentNameControllers[item.product.sellerId] = TextEditingController();
        }
        itemsBySeller[item.product.sellerId]!.add(item);
      }

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
          _selectedPaymentMethods = {};
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
    try {
      final currentUser = await ref.read(authServiceProvider).getCurrentUser();
      final seller = await ref.read(sellerServiceProvider).getSellerProfileById(sellerId);
      
      if (currentUser == null || seller == null) return 0.5;
      
      final buyerCity = currentUser.city?.trim().toLowerCase() ?? '';
      final buyerCountry = currentUser.country?.trim().toLowerCase() ?? '';
      final sellerCity = seller.city?.trim().toLowerCase() ?? '';
      final sellerCountry = seller.country?.trim().toLowerCase() ?? '';
      
      // Calculate base fee based on location
      double baseFee;
      
      // International shipping
      if (buyerCountry != 'ghana' || sellerCountry != 'ghana') {
        baseFee = 1.0;
      } else {
        // Local shipping
        baseFee = (buyerCity == sellerCity) ? 0.5 : 0.7;
      }
      
      // Calculate total quantity from this seller
      int totalQuantity = items.fold(0, (sum, item) => sum + item.quantity);
      
      // Add extra fee if more than 5 items
      if (totalQuantity > 5) {
        baseFee += 0.3;
      }
      
      return baseFee;
    } catch (e) {
      print('Error calculating delivery fee: $e');
      return 0.5; // Default fee on error
    }
  }

  Future<void> _placeOrder() async {
    // Check if all sellers have payment methods selected
    final itemsBySeller = <String, List<CartItem>>{};
    for (var item in _items) {
      if (!itemsBySeller.containsKey(item.product.sellerId)) {
        itemsBySeller[item.product.sellerId] = [];
      }
      itemsBySeller[item.product.sellerId]!.add(item);
    }

    // Verify all sellers have payment methods and names selected
    for (var sellerId in itemsBySeller.keys) {
      if (!_selectedPaymentMethods.containsKey(sellerId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select payment methods for all sellers')),
        );
        return;
      }
      
      final paymentName = _buyerPaymentNameControllers[sellerId]?.text.trim();
      if (paymentName == null || paymentName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter payment names for all sellers')),
        );
        return;
      }
    }

    // Check for complete shipping details
    if (_addressController.text.isEmpty ||
        _cityController.text.isEmpty ||
        _stateController.text.isEmpty ||
        _countryController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[900]),
              const SizedBox(width: 8),
              const Text('Incomplete Profile'),
            ],
          ),
          content: const Text(
            'Please complete your profile with shipping details before placing an order.\n\n'
            'You will be redirected to your profile settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, Routes.editProfile);
              },
              child: const Text('Complete Profile'),
            ),
          ],
        ),
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
        
        if (!seller.acceptedPaymentMethods.contains(_selectedPaymentMethods[sellerId])) {
          throw Exception('Selected payment method not accepted by seller');
        }

        final paymentPhoneNumber = seller.paymentPhoneNumbers[_selectedPaymentMethods[sellerId]];
        if (paymentPhoneNumber == null) throw Exception('Seller payment details not found');

        // Calculate total for this seller's items
        final itemsTotal = sellerItems.fold(
          0.0,
          (sum, item) => sum + (item.product.hasDiscount 
            ? item.product.price * (1 - item.product.discountPercent / 100) * item.quantity
            : item.product.price * item.quantity),
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
          paymentMethod: _selectedPaymentMethods[sellerId]!,
          buyerPaymentName: _buyerPaymentNameControllers[sellerId]!.text.trim(),
          total: total,
          deliveryFee: deliveryFee,
        );
      }

      // Clear cart after successful order placement
      await ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const OrderConfirmationScreen(),
          ),
          (route) => false,
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
                        if (_addressController.text.isEmpty ||
                            _cityController.text.isEmpty ||
                            _stateController.text.isEmpty ||
                            _countryController.text.isEmpty ||
                            _phoneController.text.isEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, 
                                      color: Colors.orange[900],
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Please complete your profile with shipping details before proceeding with checkout.',
                                        style: TextStyle(
                                          color: Colors.orange[900],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(context, Routes.editProfile);
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Complete Profile'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_addressController.text),
                              Text('${_cityController.text}, ${_stateController.text}'),
                              Text('${_countryController.text} ${_zipController.text}'),
                              Text('Phone: ${_phoneController.text}'),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, Routes.editProfile);
                                },
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit'),
                              ),
                            ],
                          ),
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
                        (sum, item) => sum + (item.product.hasDiscount 
                          ? item.product.price * (1 - item.product.discountPercent / 100) * item.quantity
                          : item.product.price * item.quantity),
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
                                  final isSelected = _selectedPaymentMethods[sellerId] == method;
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
                                      setState(() {
                                        if (selected) {
                                          _selectedPaymentMethods[sellerId] = method;
                                        } else {
                                          _selectedPaymentMethods.remove(sellerId);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                              if (_selectedPaymentMethods[sellerId] != null) ...[
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
                                                  seller.paymentPhoneNumbers[_selectedPaymentMethods[sellerId]]!,
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                onPressed: () {
                                                  Clipboard.setData(ClipboardData(
                                                    text: seller.paymentPhoneNumbers[_selectedPaymentMethods[sellerId]]!,
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
                                            'Name: ${seller.paymentNames[_selectedPaymentMethods[sellerId]]}',
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(height: 16),
                                          CustomTextField(
                                            controller: _buyerPaymentNameControllers[sellerId]!,
                                            label: 'Your Payment Name for ${_selectedPaymentMethods[sellerId] == 'mtn_momo' ? 'MTN MoMo' : 'Telecel Cash'}',
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