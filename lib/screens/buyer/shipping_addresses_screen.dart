import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/merch_user.dart';
import '../../models/shipping_address.dart';
import '../../services/buyer_service.dart';
import '../../widgets/common/custom_button.dart';
import 'shipping_address_screen.dart';

class ShippingAddressesScreen extends ConsumerStatefulWidget {
  const ShippingAddressesScreen({super.key});

  @override
  ConsumerState<ShippingAddressesScreen> createState() =>
      _ShippingAddressesScreenState();
}

class _ShippingAddressesScreenState
    extends ConsumerState<ShippingAddressesScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _addAddress() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const ShippingAddressScreen(),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _editAddress(ShippingAddress address) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ShippingAddressScreen(address: address),
      ),
    );

    if (result == true) {
      setState(() {});
    }
  }

  Future<void> _deleteAddress(ShippingAddress address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(buyerServiceProvider).deleteShippingAddress(address.id);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _setDefaultAddress(ShippingAddress address) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await ref.read(buyerServiceProvider).setDefaultShippingAddress(address.id);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shipping Addresses'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : FutureBuilder<MerchUser>(
              future: ref.read(buyerServiceProvider).getCurrentUser(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          onPressed: () => setState(() {}),
                          text: 'Retry',
                        ),
                      ],
                    ),
                  );
                }

                final user = snapshot.data!;
                final addresses = user.shippingAddresses;

                if (addresses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No shipping addresses found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          onPressed: _addAddress,
                          text: 'Add Address',
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: addresses.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final address = addresses[index];
                          final isDefault = user.defaultShippingAddress?.id ==
                              address.id;
                          return _AddressCard(
                            address: address,
                            isDefault: isDefault,
                            onEdit: () => _editAddress(address),
                            onDelete: () => _deleteAddress(address),
                            onSetDefault: isDefault
                                ? null
                                : () => _setDefaultAddress(address),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: CustomButton(
                        onPressed: _addAddress,
                        text: 'Add Address',
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final ShippingAddress address;
  final bool isDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  const _AddressCard({
    required this.address,
    required this.isDefault,
    required this.onEdit,
    required this.onDelete,
    this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Row(
              children: [
                Text(
                  address.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Default',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${address.street}, ${address.city}'),
                Text('${address.state}, ${address.country} ${address.zipCode}'),
                if (address.phone != null) ...[
                  const SizedBox(height: 4),
                  Text(address.phone!),
                ],
              ],
            ),
          ),
          ButtonBar(
            children: [
              if (onSetDefault != null)
                TextButton(
                  onPressed: onSetDefault,
                  child: const Text('Set as Default'),
                ),
              TextButton(
                onPressed: onEdit,
                child: const Text('Edit'),
              ),
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
} 