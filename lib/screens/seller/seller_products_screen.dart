import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/product.dart';
import '../../services/seller_service.dart';
import '../../services/auth_service.dart';
import '../../services/realtime_service.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/product_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class SellerProductsScreen extends ConsumerStatefulWidget {
  const SellerProductsScreen({super.key});

  @override
  ConsumerState<SellerProductsScreen> createState() => _SellerProductsScreenState();
}

class _SellerProductsScreenState extends ConsumerState<SellerProductsScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'all';
  bool _isLoading = true;
  List<Product> _products = [];
  String? _error;
  StreamSubscription? _productsSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _productsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _setupRealtimeUpdates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) throw Exception('User not authenticated');

      _productsSubscription?.cancel();
      _productsSubscription = ref
          .read(realtimeServiceProvider)
          .listenToProducts(
            user.uid,
            (products) {
              if (mounted) {
                setState(() {
                  // Filter products based on search and category
                  _products = products.where((product) {
                    bool matchesSearch = true;
                    if (_searchController.text.isNotEmpty) {
                      matchesSearch = product.name.toLowerCase().contains(_searchController.text.toLowerCase());
                    }
                    
                    bool matchesCategory = true;
                    if (_selectedCategory != 'all') {
                      matchesCategory = product.category == _selectedCategory;
                    }
                    
                    return matchesSearch && matchesCategory;
                  }).toList();
                  
                  _isLoading = false;
                });
              }
            },
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleProductStatus(Product product) async {
    try {
      await ref.read(sellerServiceProvider).toggleProductStatus(product.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product ${product.isActive ? 'deactivated' : 'activated'} successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _setupRealtimeUpdates();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(sellerServiceProvider).deleteProduct(product.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _setupRealtimeUpdates();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _addProduct() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    );

    if (result == true && mounted) {
      _setupRealtimeUpdates();
    }
  }

  Future<void> _editProduct(Product product) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(productId: product.id),
      ),
    );

    if (result == true && mounted) {
      _setupRealtimeUpdates();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            onPressed: _setupRealtimeUpdates,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CustomTextField(
                  controller: _searchController,
                  label: 'Search Products',
                  prefixIcon: const Icon(Icons.search),
                  onSubmitted: (_) => _setupRealtimeUpdates(),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _selectedCategory == 'all',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = 'all');
                            _setupRealtimeUpdates();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Electronics',
                        selected: _selectedCategory == 'electronics',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = 'electronics');
                            _setupRealtimeUpdates();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Fashion',
                        selected: _selectedCategory == 'fashion',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = 'fashion');
                            _setupRealtimeUpdates();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Home',
                        selected: _selectedCategory == 'home',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = 'home');
                            _setupRealtimeUpdates();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Beauty',
                        selected: _selectedCategory == 'beauty',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = 'beauty');
                            _setupRealtimeUpdates();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Sports',
                        selected: _selectedCategory == 'sports',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = 'sports');
                            _setupRealtimeUpdates();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Products List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      )
                    : _products.isEmpty
                        ? Center(
                            child: Text(
                              'No products found',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.65,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              return Stack(
                                children: [
                                  ProductCard(
                                    product: product,
                                    onTap: () => _editProduct(product),
                                    nameMaxLines: 1,
                                    nameStyle: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surface.withOpacity(0.8),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              product.isActive ? Icons.visibility : Icons.visibility_off,
                                              color: product.isActive ? Colors.green : Colors.red,
                                            ),
                                            onPressed: () => _toggleProductStatus(product),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surface.withOpacity(0.8),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _deleteProduct(product),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isActive ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: theme.textTheme.bodySmall?.copyWith(
          color: isActive ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 