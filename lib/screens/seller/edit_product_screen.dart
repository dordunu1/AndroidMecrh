import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/custom_text_field.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    "Chargers",
    "Headphones",
    "Speakers",
    "MP3 Players",
    "Sound Systems",
    "Audio Cables"
  ]
};

const ELECTRONICS_SUBCATEGORIES = {
  "Computers & Laptops": [
    "Laptops",
    "Desktop PCs",
    "Monitors",
    "Keyboards",
    "Mouse",
    "PC Components",
    "Storage Devices"
  ],
  "Mobile Devices": [
    "Smartphones",
    "Tablets",
    "Smartwatches",
    "E-readers",
    "Power Banks"
  ],
  "Gaming": [
    "Gaming Consoles",
    "Video Games",
    "Gaming Accessories",
    "VR Headsets",
    "Gaming Chairs"
  ],
  "Home Electronics": [
    "TVs",
    "Home Theater Systems",
    "Smart Home Devices",
    "Security Cameras",
    "Air Conditioners"
  ]
};

const ART_SUBCATEGORIES = {
  "Visual Art": [
    "Paintings",
    "Drawings",
    "Prints",
    "Photography",
    "Digital Art",
    "Sculptures"
  ],
  "Handmade Crafts": [
    "Pottery",
    "Jewelry",
    "Textile Art",
    "Wood Crafts",
    "Glass Art"
  ],
  "Art Supplies": [
    "Paint & Brushes",
    "Drawing Materials",
    "Canvas",
    "Craft Tools",
    "Art Paper"
  ],
  "Collectible Art": [
    "Limited Editions",
    "Art Prints",
    "Vintage Posters",
    "Art Books",
    "Exhibition Pieces"
  ]
};

const HOME_SUBCATEGORIES = {
  "Furniture": [
    "Sofas & Couches",
    "Dining Tables",
    "Beds",
    "Chairs",
    "Coffee Tables",
    "Wardrobes",
    "TV Stands",
    "Bookshelves"
  ],
  "Home Decor": [
    "Carpets & Rugs",
    "Curtains",
    "Wall Art",
    "Mirrors",
    "Throw Pillows",
    "Vases",
    "Lighting"
  ],
  "Kitchen & Dining": [
    "Cookware",
    "Dinnerware",
    "Kitchen Appliances",
    "Storage Containers",
    "Cutlery",
    "Kitchen Textiles"
  ],
  "Bathroom": [
    "Towels",
    "Bath Mats",
    "Shower Curtains",
    "Bathroom Storage",
    "Bathroom Accessories"
  ]
};

const SHOE_SIZES = [
  "US 6 / EU 39",
  "US 6.5 / EU 39.5",
  "US 7 / EU 40",
  "US 7.5 / EU 40.5",
  "US 8 / EU 41",
  "US 8.5 / EU 41.5",
  "US 9 / EU 42",
  "US 9.5 / EU 42.5",
  "US 10 / EU 43",
  "US 10.5 / EU 43.5",
  "US 11 / EU 44",
  "US 11.5 / EU 44.5",
  "US 12 / EU 45",
  "US 13 / EU 46"
];

const CLOTHING_SIZES = ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL'];

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
  
  bool _isLoading = true;
  bool _submitting = false;
  String? _error;
  Product? _originalProduct;
  bool _hasChanges = false;
  Map<String, bool> _changedFields = {};
  
  // Product Data
  String _selectedCategory = '';
  String _selectedSubCategory = '';
  List<String> _existingImages = [];
  List<File> _newImages = [];
  bool _hasVariants = false;
  List<String> _selectedSizes = [];
  Map<String, int> _colorQuantities = {};
  Map<String, String> _imageColors = {};
  bool _hasDiscount = false;
  double _discountPercent = 0.0;
  DateTime? _discountEndsAt;

  bool get isFootwearProduct => 
    _selectedCategory == 'clothing' && 
    _selectedSubCategory.split(' - ')[0] == 'Footwear';

  void _markFieldAsChanged(String field) {
    setState(() {
      _changedFields[field] = true;
      _hasChanges = true;
      _checkForChanges();
    });
  }

  bool _isFieldChanged(String field) {
    return _changedFields[field] ?? false;
  }

  @override
  void initState() {
    super.initState();
    _loadProduct();
    // Show color variants by default if product has variants
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_originalProduct?.hasVariants ?? false) {
        setState(() {
          _hasVariants = true;
          // Restore color quantities and image colors
          _colorQuantities = Map<String, int>.from(_originalProduct?.colorQuantities ?? {});
          _imageColors = Map<String, String>.from(_originalProduct?.imageColors ?? {});
        });
      }
    });
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
    super.dispose();
  }

  Future<void> _loadProduct() async {
    try {
      final product = await ref.read(productServiceProvider).getProduct(widget.productId);
      setState(() {
        _originalProduct = product;
        _nameController.text = product.name ?? '';
        _descriptionController.text = product.description ?? '';
        _priceController.text = product.price.toString();
        _stockController.text = product.stockQuantity.toString();
        _shippingInfoController.text = product.shippingInfo ?? '';
        _selectedCategory = product.category;
        _selectedSubCategory = product.subCategory ?? '';
        _existingImages = List<String>.from(product.images);
        _hasVariants = product.hasVariants;
        _selectedSizes = List<String>.from(product.sizes);
        _colorQuantities = Map<String, int>.from(product.colorQuantities);
        _imageColors = Map<String, String>.from(product.imageColors);
        _hasDiscount = product.hasDiscount;
        _discountPercent = product.discountPercent;
        _discountEndsAt = product.discountEndsAt;
        if (_hasDiscount) {
          _discountPercentController.text = _discountPercent.toString();
          if (_discountEndsAt != null) {
            _discountEndsAtController.text = DateFormat('yyyy-MM-dd').format(_discountEndsAt!);
          }
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
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
      price: double.parse(_priceController.text),
      stockQuantity: _hasVariants 
        ? _colorQuantities.values.fold(0, (sum, qty) => sum + qty)
        : int.parse(_stockController.text),
      category: _selectedCategory,
      subCategory: _selectedSubCategory,
      images: _existingImages,
      isActive: _originalProduct!.isActive,
      createdAt: _originalProduct!.createdAt,
      updatedAt: DateTime.now().toIso8601String(),
      shippingInfo: _shippingInfoController.text,
      hasVariants: _hasVariants,
      sizes: _selectedSizes,
      colors: _imageColors.values.toList(),
      colorQuantities: _colorQuantities,
      imageColors: _imageColors,
      hasDiscount: _hasDiscount,
      discountPercent: _discountPercent,
      discountEndsAt: _discountEndsAt,
      discountedPrice: _hasDiscount ? 
        double.parse(_priceController.text) * (1 - _discountPercent / 100) : 
        null,
      soldCount: _originalProduct!.soldCount,
      rating: _originalProduct!.rating,
      reviewCount: _originalProduct!.reviewCount,
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
        if (_existingImages.length + _newImages.length + images.length > 10) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Maximum 10 images allowed')),
            );
          }
          return;
        }
        setState(() {
          _newImages.addAll(images.map((image) => File(image.path)));
          _markFieldAsChanged('images');  // Mark as changed when new images are added
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
      final imageUrl = _existingImages[index];
      final color = _imageColors[imageUrl];
      if (color != null) {
        _colorQuantities.remove(color);
        _imageColors.remove(imageUrl);
      }
      _existingImages.removeAt(index);
      _markFieldAsChanged('images');  // Mark as changed when image is removed
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      final imagePath = _newImages[index].path;
      final color = _imageColors[imagePath];
      if (color != null) {
        _colorQuantities.remove(color);
        _imageColors.remove(imagePath);
      }
      _newImages.removeAt(index);
      _markFieldAsChanged('images');  // Mark as changed when image is removed
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (_selectedSubCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subcategory')),
      );
      return;
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

      final productData = {
        'sellerId': _originalProduct!.sellerId,
        'sellerName': _originalProduct!.sellerName,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': price,
        'stockQuantity': int.parse(_stockController.text),
        'category': _selectedCategory,
        'subCategory': _selectedSubCategory,
        'images': allImages,
        'isActive': _originalProduct!.isActive,
        'createdAt': _originalProduct!.createdAt,
        'updatedAt': DateTime.now().toIso8601String(),
        'shippingInfo': _shippingInfoController.text.trim(),
        'hasVariants': _hasVariants,
        'sizes': _selectedSizes,
        'colors': _imageColors.values.toList(),
        'colorQuantities': _colorQuantities,
        'imageColors': _imageColors,
        'hasDiscount': _hasDiscount,
        'discountPercent': _discountPercent,
        'discountEndsAt': _discountEndsAt?.toIso8601String(),
        'discountedPrice': discountedPrice,
        'soldCount': _originalProduct!.soldCount,
        'rating': _originalProduct!.rating,
        'reviewCount': _originalProduct!.reviewCount,
      };

      await ref.read(productServiceProvider).updateProduct(widget.productId, productData);
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _showColorEditDialog(String imagePath, bool isNewImage) {
    final currentColor = _imageColors[imagePath];
    final colorController = TextEditingController(text: currentColor);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Color'),
        content: TextField(
          controller: colorController,
          decoration: const InputDecoration(labelText: 'Color Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final newColor = colorController.text.trim();
              if (newColor.isNotEmpty) {
                setState(() {
                  if (currentColor != null) {
                    // Transfer quantity from old color to new color
                    final qty = _colorQuantities[currentColor];
                    if (qty != null) {
                      _colorQuantities[newColor] = qty;
                      _colorQuantities.remove(currentColor);
                    }
                  } else {
                    // If no previous color, initialize quantity to 0
                    _colorQuantities[newColor] = 0;
                  }
                  _imageColors[imagePath] = newColor;
                  _markFieldAsChanged('colors');
                  _hasVariants = true;  // Ensure variants stay visible
                });
              }
              Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _editColorQuantity(String color) {
    final currentQty = _colorQuantities[color] ?? 0;
    final qtyController = TextEditingController(text: currentQty.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Quantity for $color'),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Quantity'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final qty = int.tryParse(qtyController.text);
              if (qty != null && qty >= 0) {
                setState(() {
                  _colorQuantities[color] = qty;
                  _markFieldAsChanged('quantities');  // Mark as changed when quantity is edited
                });
              }
              Navigator.pop(context);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _removeColor(String color) {
    setState(() {
      _colorQuantities.remove(color);
      // Remove color from all images that had this color
      _imageColors.removeWhere((key, value) => value == color);
      _markFieldAsChanged('colors');  // Mark as changed when color is removed
    });
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _existingImages.length + _newImages.length + 1,
      itemBuilder: (context, index) {
        if (index < _existingImages.length) {
          // Existing image
          final imageUrl = _existingImages[index];
          final color = _imageColors[imageUrl];
          return Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _removeExistingImage(index),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(4),
                  ),
                ),
              ),
              if (_hasVariants)
                Positioned(
                  bottom: 4,
                  left: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            color ?? 'Set Color',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                          onPressed: () => _showColorEditDialog(imageUrl, false),
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        } else if (index < _existingImages.length + _newImages.length) {
          // New image
          final newIndex = index - _existingImages.length;
          final imagePath = _newImages[newIndex].path;
          final color = _imageColors[imagePath];
          return Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _newImages[newIndex],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => _removeNewImage(newIndex),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(4),
                  ),
                ),
              ),
              if (_hasVariants)
                Positioned(
                  bottom: 4,
                  left: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            color ?? 'Set Color',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                          onPressed: () => _showColorEditDialog(imagePath, true),
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        } else {
          // Add image button
          return InkWell(
            onTap: _pickImages,
            child: Container(
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
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
        actions: [
          TextButton(
            onPressed: _hasChanges ? () => _submit() : null,
            style: TextButton.styleFrom(
              foregroundColor: _hasChanges ? theme.colorScheme.primary : Colors.grey,
            ),
            child: Text(
              'SAVE CHANGES',
              style: TextStyle(
                fontWeight: _hasChanges ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
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
                      'Add up to 10 images (2MB each)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    _buildImageGrid(),
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
              onChanged: (value) => _markFieldAsChanged('name'),
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
              onChanged: (value) => _markFieldAsChanged('description'),
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
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                if (double.parse(value) <= 0) {
                  return 'Price must be greater than 0';
                }
                return null;
              },
              onChanged: (value) => _markFieldAsChanged('price'),
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
              onChanged: (value) => _markFieldAsChanged('stock'),
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
              onChanged: (value) => _markFieldAsChanged('shippingInfo'),
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
                    // Only reset variants if switching between categories that don't support variants
                    if (!_hasVariants) {
                      _selectedSizes = [];
                      _colorQuantities = {};
                      _imageColors = {};
                    }
                    _markFieldAsChanged('category');
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

            // Subcategories
            if (_selectedCategory == 'clothing' || _selectedCategory == 'accessories' || 
                _selectedCategory == 'electronics' || _selectedCategory == 'art' ||
                _selectedCategory == 'home')
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
                      ...(_selectedCategory == 'clothing' ? CLOTHING_SUBCATEGORIES :
                         _selectedCategory == 'accessories' ? ACCESSORIES_SUBCATEGORIES :
                         _selectedCategory == 'electronics' ? ELECTRONICS_SUBCATEGORIES :
                         _selectedCategory == 'art' ? ART_SUBCATEGORIES :
                         _selectedCategory == 'home' ? HOME_SUBCATEGORIES : {})
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
                                  // Only reset variants if switching between subcategories that don't support variants
                                  if (selected && !_hasVariants) {
                                    _selectedSizes = [];
                                    _colorQuantities = {};
                                  }
                                  _markFieldAsChanged('subCategory');
                                });
                              },
                            );
                          }).toList();
                        }).toList(),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Variants Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Color Variants',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(width: 16),
                        Switch(
                          value: _hasVariants,
                          onChanged: (value) {
                            setState(() {
                              _hasVariants = value;
                              if (!value) {
                                _selectedSizes = [];
                                _colorQuantities = {};
                                _imageColors = {};
                              }
                              _markFieldAsChanged('hasVariants');
                            });
                          },
                        ),
                      ],
                    ),
                    if (_hasVariants) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Guide: How to add color variants',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('1. Upload product images above'),
                              Text('2. Click the pencil icon (✏️) on each image'),
                              Text('3. Enter the color name for that variant'),
                              Text('4. Set the quantity available for each color below'),
                              Text('Note: Each image should represent a different color variant'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_colorQuantities.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Color Quantities',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _colorQuantities.length,
                              separatorBuilder: (context, index) => const Divider(),
                              itemBuilder: (context, index) {
                                final color = _colorQuantities.keys.elementAt(index);
                                final quantity = _colorQuantities[color] ?? 0;
                                return ListTile(
                                  title: Text(color),
                                  subtitle: Text('$quantity in stock'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () => _editColorQuantity(color),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => _removeColor(color),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Total Stock: ${_colorQuantities.values.fold(0, (sum, quantity) => sum + quantity)}',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Price and Discount Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Price & Discount',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Price Field
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              hintText: '0.00',
                              prefixText: 'GHS ',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a price';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter a valid number';
                              }
                              if (double.parse(value) <= 0) {
                                return 'Price must be greater than 0';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Discount Switch
                    Row(
                      children: [
                        Text(
                          'Apply Discount',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(width: 16),
                        Switch(
                          value: _hasDiscount,
                          onChanged: (value) {
                            setState(() {
                              _hasDiscount = value;
                              _markFieldAsChanged('hasDiscount');
                            });
                          },
                        ),
                      ],
                    ),

                    if (_hasDiscount) ...[
                      const SizedBox(height: 16),
                      
                      // Discount Percentage
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _discountPercentController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Discount Percentage',
                                border: OutlineInputBorder(),
                                suffixText: '%',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _discountPercent = double.tryParse(value) ?? 0;
                                  _markFieldAsChanged('discountPercent');
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter discount percentage';
                                }
                                final discount = double.tryParse(value);
                                if (discount == null) {
                                  return 'Please enter a valid number';
                                }
                                if (discount <= 0 || discount >= 100) {
                                  return 'Discount must be between 0 and 100';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Discount End Date
                      InkWell(
                        onTap: () async {
                          final now = DateTime.now();
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _discountEndsAt ?? now.add(const Duration(days: 1)),
                            firstDate: now,
                            lastDate: now.add(const Duration(days: 365)),
                          );
                          
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(_discountEndsAt ?? now.add(const Duration(days: 1))),
                            );
                            
                            if (time != null) {
                              setState(() {
                                _discountEndsAt = DateTime(
                                  date.year,
                                  date.month,
                                  date.day,
                                  time.hour,
                                  time.minute,
                                );
                                _discountEndsAtController.text = _discountEndsAt!.toIso8601String();
                              });
                            }
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Discount Ends At',
                            border: const OutlineInputBorder(),
                            suffixIcon: Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          child: Text(
                            _discountEndsAt != null
                                ? DateFormat('yyyy-MM-dd HH:mm').format(_discountEndsAt!)
                                : 'Select date and time',
                          ),
                        ),
                      ),

                      // Discounted Price Preview
                      if (_discountPercent > 0 && double.tryParse(_priceController.text) != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Original Price:'),
                                  Text(
                                    'GHS ${double.parse(_priceController.text)}',
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Discounted Price:',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'GHS ${(double.parse(_priceController.text) * (1 - _discountPercent / 100)).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 