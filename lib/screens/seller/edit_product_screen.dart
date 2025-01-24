import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product.dart';
import '../../services/seller_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/custom_text_field.dart';

const CLOTHING_SUBCATEGORIES = {
  "Men's Wear": [
    "T-Shirts",
    "Shirts",
    "Pants",
    "Hoodies",
    "Jackets",
    "Suits"
  ],
  "Women's Wear": [
    "Dresses",
    "Tops",
    "Skirts",
    "Pants",
    "Blouses",
    "Jackets"
  ],
  "Footwear": [
    "Sneakers",
    "Formal Shoes",
    "Boots",
    "Sandals",
    "Slippers"
  ]
};

const ACCESSORIES_SUBCATEGORIES = {
  "Fashion Accessories": [
    "Bags",
    "Belts",
    "Hats",
    "Scarves",
    "Jewelry"
  ],
  "Tech Accessories": [
    "Phone Cases",
    "Laptop Bags",
    "Headphone Cases",
    "Tablet Covers",
    "Chargers"
  ]
};

class EditProductScreen extends ConsumerStatefulWidget {
  final String productId;

  const EditProductScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _shippingInfoController = TextEditingController();
  final _discountPercentController = TextEditingController();
  final _discountEndsAtController = TextEditingController();
  final _selectedSizesController = TextEditingController();
  final _selectedColorsController = TextEditingController();
  final _colorQuantitiesController = TextEditingController();
  
  bool _isLoading = true;
  bool _submitting = false;
  String? _error;
  Product? _originalProduct;
  bool _hasChanges = false;
  
  // Product Data
  String _selectedCategory = '';
  String _selectedSubCategory = '';
  List<String> _existingImages = [];
  List<File> _newImages = [];
  double _shippingFee = 0.0;
  bool _hasVariants = false;
  List<String> _selectedSizes = [];
  List<String> _selectedColors = [];
  Map<String, int> _colorQuantities = {};
  bool _hasDiscount = false;
  double _discountPercent = 0.0;
  DateTime? _discountEndsAt;

  bool get isFootwearProduct => 
    _selectedCategory == 'clothing' && 
    _selectedSubCategory.split(' - ')[0] == 'Footwear';

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _shippingInfoController.dispose();
    _discountPercentController.dispose();
    _discountEndsAtController.dispose();
    _selectedSizesController.dispose();
    _selectedColorsController.dispose();
    _colorQuantitiesController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    
    try {
      // Load product details
      final product = await ref.read(sellerServiceProvider).getProduct(widget.productId);
      
      // Try to load seller's shipping fee, but don't fail if not found
      double? sellerShippingFee;
      try {
        final seller = await ref.read(sellerServiceProvider).getSellerProfile();
        sellerShippingFee = seller.shippingFee;
      } catch (e) {
        // Ignore seller profile errors
      }
      
      setState(() {
        _originalProduct = product;
        _nameController.text = product.name;
        _descriptionController.text = product.description;
        _priceController.text = product.price.toString();
        _stockController.text = product.stockQuantity.toString();
        _shippingInfoController.text = product.shippingInfo ?? '';
        _selectedCategory = product.category;
        _selectedSubCategory = product.subCategory ?? '';
        _existingImages = List<String>.from(product.images);
        _shippingFee = sellerShippingFee ?? product.shippingFee ?? 0.0;
        _hasVariants = product.hasVariants;
        _selectedSizes = List<String>.from(product.sizes);
        _selectedColors = List<String>.from(product.colors);
        _colorQuantities = Map<String, int>.from(product.colorQuantities);
        _hasDiscount = product.hasDiscount;
        _discountPercent = product.discountPercent;
        if (product.discountEndsAt != null) {
          _discountEndsAt = DateTime.parse(product.discountEndsAt!);
          _discountEndsAtController.text = product.discountEndsAt!;
        }
        if (product.hasDiscount) {
          _discountPercentController.text = product.discountPercent.toString();
        }
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _checkForChanges() {
    if (_originalProduct == null) return;

    final currentProduct = Product(
      id: widget.productId,
      sellerId: _originalProduct!.sellerId,
      sellerName: _originalProduct!.sellerName,
      name: _nameController.text,
      description: _descriptionController.text,
      price: double.tryParse(_priceController.text) ?? _originalProduct!.price,
      stockQuantity: int.tryParse(_stockController.text) ?? _originalProduct!.stockQuantity,
      category: _selectedCategory,
      subCategory: _selectedSubCategory,
      images: _existingImages,
      isActive: _originalProduct!.isActive,
      createdAt: _originalProduct!.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      shippingFee: _shippingFee,
      shippingInfo: _shippingInfoController.text,
      hasVariants: _hasVariants,
      sizes: _selectedSizes,
      colors: _selectedColors,
      colorQuantities: _colorQuantities,
      hasDiscount: _hasDiscount,
      discountPercent: _discountPercent,
      discountEndsAt: _discountEndsAt?.toIso8601String(),
      discountedPrice: _hasDiscount ? 
        (double.tryParse(_priceController.text) ?? _originalProduct!.price) * (1 - _discountPercent / 100) : 
        null,
    );

    setState(() {
      _hasChanges = _originalProduct!.name != currentProduct.name ||
        _originalProduct!.description != currentProduct.description ||
        _originalProduct!.price != currentProduct.price ||
        _originalProduct!.stockQuantity != currentProduct.stockQuantity ||
        _originalProduct!.category != currentProduct.category ||
        _originalProduct!.subCategory != currentProduct.subCategory ||
        _originalProduct!.images.length != currentProduct.images.length ||
        _originalProduct!.shippingInfo != currentProduct.shippingInfo ||
        _originalProduct!.hasVariants != currentProduct.hasVariants ||
        _originalProduct!.sizes.length != currentProduct.sizes.length ||
        _originalProduct!.colors.length != currentProduct.colors.length ||
        _originalProduct!.hasDiscount != currentProduct.hasDiscount ||
        _originalProduct!.discountPercent != currentProduct.discountPercent ||
        _originalProduct!.discountEndsAt != currentProduct.discountEndsAt ||
        _newImages.isNotEmpty;
    });
  }

  Future<void> _pickImages() async {
    try {
      final images = await ImagePicker().pickMultiImage();
      if (images != null) {
        if (_existingImages.length + _newImages.length + images.length > 5) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Maximum 5 images allowed')),
            );
          }
          return;
        }
        setState(() {
          _newImages.addAll(images.map((image) => File(image.path)));
          _checkForChanges();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
      _checkForChanges();
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
      _checkForChanges();
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional validations
    if (_existingImages.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product image')),
      );
      return;
    }

    if (_selectedCategory == 'clothing' || _selectedCategory == 'accessories') {
      if (_selectedSubCategory.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a product type')),
        );
        return;
      }

      if (_hasVariants) {
        if (_selectedSizes.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select at least one size')),
          );
          return;
        }

        if (_selectedColors.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select at least one color')),
          );
          return;
        }

        final totalQuantity = _colorQuantities.values.fold(0, (sum, qty) => sum + qty);
        if (totalQuantity == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please specify quantities for selected colors')),
          );
          return;
        }
      }
    }

    if (_hasDiscount) {
      if (_discountPercent <= 0 || _discountPercent >= 100) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discount percentage must be between 0 and 99')),
        );
        return;
      }

      if (_discountEndsAt == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select when the discount ends')),
        );
        return;
      }
    }

    setState(() => _submitting = true);

    try {
      // Upload new images first
      final newImageUrls = await Future.wait(
        _newImages.map((file) => ref.read(storageServiceProvider).uploadFile(file, 'products')),
      );

      // Combine existing and new image URLs
      final allImages = [..._existingImages, ...newImageUrls];

      // Calculate discounted price if discount is applied
      final price = double.parse(_priceController.text);
      final discountedPrice = _hasDiscount ? price * (1 - _discountPercent / 100) : null;

      final updatedProduct = Product(
        id: widget.productId,
        sellerId: _originalProduct!.sellerId,
        sellerName: _originalProduct!.sellerName,
        name: _nameController.text,
        description: _descriptionController.text,
        price: price,
        stockQuantity: _hasVariants 
          ? _colorQuantities.values.fold(0, (sum, qty) => sum + qty)
          : int.parse(_stockController.text),
        category: _selectedCategory,
        subCategory: _selectedSubCategory,
        images: allImages,
        isActive: _originalProduct!.isActive,
        createdAt: _originalProduct!.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
        shippingFee: _shippingFee,
        shippingInfo: _shippingInfoController.text,
        hasVariants: _hasVariants,
        sizes: _selectedSizes,
        colors: _selectedColors,
        colorQuantities: _colorQuantities,
        hasDiscount: _hasDiscount,
        discountPercent: _discountPercent,
        discountEndsAt: _discountEndsAt?.toIso8601String(),
        discountedPrice: discountedPrice,
      );

      await ref.read(sellerServiceProvider).updateProduct(widget.productId, updatedProduct);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text('Error: $_error'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
      ),
      body: Form(
        key: _formKey,
        onChanged: _checkForChanges,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Image Upload Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Images',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add up to 5 images (2MB each)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    if (_existingImages.isEmpty && _newImages.isEmpty)
                      InkWell(
                        onTap: _pickImages,
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_photo_alternate_outlined, size: 48),
                                SizedBox(height: 8),
                                Text('Add Images'),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _existingImages.length + _newImages.length < 5 
                                ? _existingImages.length + _newImages.length + 1 
                                : _existingImages.length + _newImages.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                if (index == _existingImages.length + _newImages.length && 
                                    _existingImages.length + _newImages.length < 5) {
                                  return InkWell(
                                    onTap: _pickImages,
                                    child: Container(
                                      width: 120,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.add_photo_alternate_outlined, size: 32),
                                      ),
                                    ),
                                  );
                                }

                                final isExistingImage = index < _existingImages.length;
                                final imageWidget = isExistingImage
                                  ? Image.network(
                                      _existingImages[index],
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      _newImages[index - _existingImages.length],
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    );

                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageWidget,
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: InkWell(
                                        onTap: () {
                                          if (isExistingImage) {
                                            _removeExistingImage(index);
                                          } else {
                                            _removeNewImage(index - _existingImages.length);
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Name
            CustomTextField(
              controller: _nameController,
              label: 'Name',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            CustomTextField(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Price
            CustomTextField(
              controller: _priceController,
              label: 'Price',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                final price = double.tryParse(value);
                if (price == null) {
                  return 'Please enter a valid price';
                }
                if (price <= 0) {
                  return 'Price must be greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Stock
            CustomTextField(
              controller: _stockController,
              label: 'Stock',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter stock quantity';
                }
                final stock = int.tryParse(value);
                if (stock == null) {
                  return 'Please enter a valid number';
                }
                if (stock < 0) {
                  return 'Stock cannot be negative';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Shipping Info
            CustomTextField(
              controller: _shippingInfoController,
              label: 'Shipping Info',
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter shipping information';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory.isEmpty ? null : _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                {'value': 'clothing', 'label': 'Clothing'},
                {'value': 'accessories', 'label': 'Accessories'},
                {'value': 'electronics', 'label': 'Electronics'},
                {'value': 'home', 'label': 'Home'},
                {'value': 'art', 'label': 'Art'},
                {'value': 'collectibles', 'label': 'Collectibles'},
              ].map((category) {
                return DropdownMenuItem(
                  value: category['value'],
                  child: Text(category['label']!),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                    _selectedSubCategory = '';
                    _hasVariants = false;
                    _selectedSizes = [];
                    _selectedColors = [];
                    _colorQuantities = {};
                  });
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Subcategories for Clothing and Accessories
            if (_selectedCategory == 'clothing' || _selectedCategory == 'accessories')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product Type',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...((_selectedCategory == 'clothing' ? CLOTHING_SUBCATEGORIES : ACCESSORIES_SUBCATEGORIES)
                        .entries
                        .expand((mainCategory) {
                          return mainCategory.value.map((subItem) {
                            final fullSubCategory = '${mainCategory.key} - $subItem';
                            return FilterChip(
                              selected: _selectedSubCategory == fullSubCategory,
                              label: Text(subItem),
                              onSelected: (selected) {
                                setState(() {
                                  _selectedSubCategory = selected ? fullSubCategory : '';
                                  if (selected) {
                                    _hasVariants = false;
                                    _selectedSizes = [];
                                    _selectedColors = [];
                                    _colorQuantities = {};
                                  }
                                });
                              },
                            );
                          });
                        })),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Sizes
            if (_selectedCategory == 'clothing' || _selectedCategory == 'accessories')
              CustomTextField(
                controller: _selectedSizesController,
                label: 'Sizes',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter sizes';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 16),

            // Colors
            if (_selectedCategory == 'clothing' || _selectedCategory == 'accessories')
              CustomTextField(
                controller: _selectedColorsController,
                label: 'Colors',
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter colors';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 16),

            // Quantity
            if (_selectedCategory == 'clothing' || _selectedCategory == 'accessories')
              CustomTextField(
                controller: _colorQuantitiesController,
                label: 'Quantity',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null) {
                    return 'Please enter a valid number';
                  }
                  if (quantity < 0) {
                    return 'Quantity cannot be negative';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 16),

            // Discount
            if (_selectedCategory == 'clothing' || _selectedCategory == 'accessories')
              CustomTextField(
                controller: _discountPercentController,
                label: 'Discount Percent',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter discount percentage';
                  }
                  final discount = double.tryParse(value);
                  if (discount == null) {
                    return 'Please enter a valid discount percentage';
                  }
                  if (discount < 0 || discount > 100) {
                    return 'Discount percentage must be between 0 and 100';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 16),

            // Discount Ends At
            if (_selectedCategory == 'clothing' || _selectedCategory == 'accessories')
              CustomTextField(
                controller: _discountEndsAtController,
                label: 'Discount Ends At',
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select when the discount ends';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 16),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _hasChanges && !_submitting ? _submitForm : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _submitting
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Updating Product...'),
                        ],
                      )
                    : const Text('Save Changes'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
} 