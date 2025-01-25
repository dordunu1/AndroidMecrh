import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product.dart';
import '../../services/seller_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/custom_text_field.dart';

Future<DateTime?> showDateTimePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  final DateTime? date = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );

  if (date == null) return null;

  if (!context.mounted) return null;

  final TimeOfDay? time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initialDate),
  );

  return time == null
      ? null
      : DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
}

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

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _shippingInfoController = TextEditingController();
  final _discountPercentController = TextEditingController();
  
  bool _isLoading = false;
  bool _submitting = false;
  String? _error;
  
  // Product Data
  String _selectedCategory = '';
  String _selectedSubCategory = '';
  List<File> _selectedImages = [];
  bool _hasVariants = false;
  List<String> _selectedSizes = [];
  List<String> _selectedColors = [];
  Map<String, int> _colorQuantities = {};
  bool _hasDiscount = false;
  double _discountPercent = 0.0;
  DateTime? _discountEndsAt;

  final Map<String, String> _imageColors = {};
  final TextEditingController _colorController = TextEditingController();
  int _currentImageIndex = 0;

  bool get isFootwearProduct => 
    _selectedCategory == 'clothing' && 
    _selectedSubCategory.split(' - ')[0] == 'Footwear';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _shippingInfoController.dispose();
    _discountPercentController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final images = await ImagePicker().pickMultiImage();
      if (images != null) {
        setState(() {
          // Limit to 10 images
          final remainingSlots = 10 - _selectedImages.length;
          if (remainingSlots > 0) {
            _selectedImages.addAll(
              images.take(remainingSlots).map((image) => File(image.path))
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maximum 10 images allowed'),
                backgroundColor: Colors.orange,
              ),
            );
          }
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

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      // Remove color mapping if exists
      final imageKeys = _imageColors.keys.toList();
      if (index < imageKeys.length) {
        _imageColors.remove(imageKeys[index]);
      }
    });
  }

  void _showColorEditDialog(int imageIndex) {
    final imageKey = _selectedImages[imageIndex].path;
    String? currentColor = _imageColors[imageKey];
    _colorController.text = currentColor ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Color'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _colorController,
              decoration: const InputDecoration(
                labelText: 'Color Name',
                hintText: 'e.g., Red, Blue, White',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This color will be used for variant tracking',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final color = _colorController.text.trim();
              if (color.isNotEmpty) {
                setState(() {
                  _imageColors[imageKey] = color;
                  if (!_selectedColors.contains(color)) {
                    _selectedColors.add(color);
                    _colorQuantities[color] = 0; // Initialize quantity
                  }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
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
                    if (_selectedImages.isEmpty)
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
                      SizedBox(
                        height: 200,
                        child: Stack(
                          children: [
                            PageView.builder(
                              itemCount: _selectedImages.length + (_selectedImages.length < 10 ? 1 : 0),
                              onPageChanged: (index) {
                                setState(() {
                                  _currentImageIndex = index;
                                });
                              },
                              itemBuilder: (context, index) {
                                if (index == _selectedImages.length) {
                                  return Center(
                                    child: TextButton.icon(
                                      onPressed: _pickImages,
                                      icon: const Icon(Icons.add_photo_alternate),
                                      label: const Text('Add More'),
                                    ),
                                  );
                                }

                                final imageKey = _selectedImages[index].path;
                                final color = _imageColors[imageKey];

                                return Stack(
                                  children: [
                                    Center(
                                      child: Image.file(
                                        _selectedImages[index],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () => _showColorEditDialog(index),
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              padding: const EdgeInsets.all(8),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () => _removeImage(index),
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              padding: const EdgeInsets.all(8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (color != null)
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            color,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            // Page indicator dots
                            if (_selectedImages.length > 1)
                              Positioned(
                                bottom: 16,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    _selectedImages.length + (_selectedImages.length < 10 ? 1 : 0),
                                    (index) => Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: index == _currentImageIndex
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.grey.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Category and Subcategory Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Category',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    // Main Category Dropdown
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
                        setState(() {
                          _selectedCategory = value ?? '';
                          _selectedSubCategory = '';
                          _hasVariants = false;
                          _selectedSizes = [];
                          _selectedColors = [];
                          _colorQuantities = {};
                        });
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
                    if (_selectedCategory == 'clothing' || _selectedCategory == 'accessories' || 
                        _selectedCategory == 'electronics' || _selectedCategory == 'art')
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
                                 _selectedCategory == 'art' ? ART_SUBCATEGORIES : {})
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
                                }).toList(),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Variants Section for Clothing and Accessories
            if (_selectedCategory == 'clothing' || _selectedCategory == 'accessories')
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Product Variants',
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
                                  _selectedColors = [];
                                  _colorQuantities = {};
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      if (_hasVariants) ...[
                        const SizedBox(height: 16),
                        
                        // Sizes Section
                        Text(
                          'Available Sizes',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ...(isFootwearProduct ? SHOE_SIZES : CLOTHING_SIZES).map((size) {
                              return FilterChip(
                                selected: _selectedSizes.contains(size),
                                label: Text(size),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedSizes.add(size);
                                    } else {
                                      _selectedSizes.remove(size);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Color Summary Section
                        if (_imageColors.isNotEmpty) ...[
                          Text(
                            'Color Variants',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ..._imageColors.entries.map((entry) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(entry.value),
                                        SizedBox(
                                          width: 80,
                                          child: TextFormField(
                                            initialValue: '${_colorQuantities[entry.value] ?? 0}',
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.end,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              suffixText: ' pcs',
                                            ),
                                            onChanged: (value) {
                                              final quantity = int.tryParse(value) ?? 0;
                                              setState(() {
                                                _colorQuantities[entry.value] = quantity;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(width: 16),
                        Switch(
                          value: _hasDiscount,
                          onChanged: (value) {
                            setState(() {
                              _hasDiscount = value;
                              if (!value) {
                                _discountPercent = 0;
                                _discountEndsAt = null;
                                _discountPercentController.text = '';
                              }
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
                                final percent = double.tryParse(value) ?? 0;
                                setState(() {
                                  _discountPercent = percent.clamp(0, 99);
                                  if (percent != _discountPercent) {
                                    _discountPercentController.text = _discountPercent.toString();
                                  }
                                });
                              },
                              validator: (value) {
                                if (_hasDiscount) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a discount percentage';
                                  }
                                  final percent = double.tryParse(value);
                                  if (percent == null) {
                                    return 'Please enter a valid number';
                                  }
                                  if (percent <= 0 || percent >= 100) {
                                    return 'Percentage must be between 0 and 99';
                                  }
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
                          final picked = await showDateTimePicker(
                            context: context,
                            initialDate: _discountEndsAt ?? now.add(const Duration(days: 1)),
                            firstDate: now,
                            lastDate: now.add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _discountEndsAt = picked);
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
                                ? _discountEndsAt!.toLocal().toString().split('.')[0]
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
            const SizedBox(height: 16),

            // Shipping Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shipping Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Shipping Information
                    TextFormField(
                      controller: _shippingInfoController,
                      decoration: const InputDecoration(
                        labelText: 'Shipping Information',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Worldwide shipping available',
                      ),
                      maxLines: 2,
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

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitForm,
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
                          Text('Adding Product...'),
                        ],
                      )
                    : const Text('Add Product'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload images
      final imageUrls = await Future.wait(
        _selectedImages.map((file) => ref.read(storageServiceProvider).uploadFile(file, 'products')),
      );

      // Create image colors map with uploaded URLs
      final imageColors = <String, String>{};
      for (var i = 0; i < _selectedImages.length; i++) {
        final color = _imageColors[_selectedImages[i].path];
        if (color != null) {
          imageColors[imageUrls[i]] = color;
        }
      }

      // Get seller profile
      final seller = await ref.read(sellerServiceProvider).getSellerProfile();
      
      final product = Product(
        id: '',
        sellerId: '',
        sellerName: '',
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        stockQuantity: _hasVariants 
          ? _colorQuantities.values.fold(0, (sum, qty) => sum + qty)
          : int.parse(_stockController.text),
        category: _selectedCategory,
        subCategory: _selectedSubCategory,
        images: imageUrls,
        isActive: true,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
        shippingInfo: _shippingInfoController.text,
        hasVariants: _hasVariants,
        sizes: _selectedSizes,
        colors: _selectedColors,
        colorQuantities: _colorQuantities,
        hasDiscount: _hasDiscount,
        discountPercent: _discountPercent,
        discountEndsAt: _discountEndsAt,
        discountedPrice: _hasDiscount ? 
          double.parse(_priceController.text) * (1 - _discountPercent / 100) : 
          null,
        imageColors: imageColors,
        soldCount: 0,
        rating: 0,
        reviewCount: 0,
      );

      await ref.read(sellerServiceProvider).createProduct(product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully')),
        );
        Navigator.pop(context);
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
} 