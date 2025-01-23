import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/products/product_grid_item.dart';
import '../../widgets/common/custom_text_field.dart';

final productsProvider = FutureProvider.autoDispose.family<List<Product>, Map<String, dynamic>>(
  (ref, filters) async {
    return ref.read(productServiceProvider).getProducts(
      category: filters['category'],
      searchQuery: filters['searchQuery'],
      sortBy: filters['sortBy'],
      isActive: true,
    );
  },
);

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = '';
  String _selectedSort = 'newest';
  bool _isLoading = false;
  List<Product> _products = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (_isLoading) return;
    if (!refresh && !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final products = await ref.read(productServiceProvider).getProducts(
        category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
        searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
        sortBy: _selectedSort,
        isActive: true,
        limit: _limit,
        startAfter: refresh ? null : _lastDocument,
      );

      setState(() {
        if (refresh) {
          _products = products;
        } else {
          _products.addAll(products);
        }
        _hasMore = products.length == _limit;
        _lastDocument = products.isEmpty ? null : products.last as DocumentSnapshot?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: $e')),
      );
    }
  }

  Future<void> _refresh() {
    _lastDocument = null;
    _hasMore = true;
    return _loadProducts(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomTextField(
              controller: _searchController,
              hint: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              onChanged: (value) {
                _refresh();
              },
            ),
          ),

          // Category Chips
          if (_selectedCategory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(_selectedCategory),
                    onDeleted: () {
                      setState(() {
                        _selectedCategory = '';
                      });
                      _refresh();
                    },
                  ),
                ],
              ),
            ),

          // Products Grid
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _products.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _products.length) {
                    if (!_isLoading) {
                      _loadProducts();
                    }
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final product = _products[index];
                  return ProductGridItem(
                    product: product,
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        '/product-details',
                        arguments: product,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Newest'),
                        selected: _selectedSort == 'newest',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedSort = 'newest');
                            _refresh();
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Price: Low to High'),
                        selected: _selectedSort == 'price_asc',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedSort = 'price_asc');
                            _refresh();
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Price: High to Low'),
                        selected: _selectedSort == 'price_desc',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedSort = 'price_desc');
                            _refresh();
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Rating'),
                        selected: _selectedSort == 'rating',
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedSort = 'rating');
                            _refresh();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<String>>(
                    future: ref.read(productServiceProvider).getCategories(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Error loading categories');
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      return Wrap(
                        spacing: 8,
                        children: snapshot.data!.map((category) {
                          return ChoiceChip(
                            label: Text(category),
                            selected: _selectedCategory == category,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = selected ? category : '';
                              });
                              _refresh();
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
} 