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

const COLORS = [
  {'name': 'Black', 'value': 0xFF000000},
  {'name': 'White', 'value': 0xFFFFFFFF},
  {'name': 'Gray', 'value': 0xFF808080},
  {'name': 'Red', 'value': 0xFFFF0000},
  {'name': 'Blue', 'value': 0xFF0000FF},
  {'name': 'Green', 'value': 0xFF008000},
  {'name': 'Yellow', 'value': 0xFFFFFF00},
  {'name': 'Purple', 'value': 0xFF800080},
  {'name': 'Pink', 'value': 0xFFFFC0CB},
  {'name': 'Brown', 'value': 0xFFA52A2A}
];

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
    _loadSellerPreferences();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _shippingInfoController.dispose();
    _discountPercentController.dispose();
    super.dispose();
  }

  Future<void> _loadSellerPreferences() async {
    setState(() => _isLoading = true);
    
    try {
      final seller = await ref.read(sellerServiceProvider).getSellerProfile();
      
      setState(() {
        _shippingFee = seller.shippingFee;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImages() async {
    try {
      final images = await ImagePicker().pickMultiImage();
      if (images != null) {
        setState(() {
          _selectedImages.addAll(images.map((image) => File(image.path)));
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
    });
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
                      'Add up to 5 images (2MB each)',
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
                      Column(
                        children: [
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length < 5 ? _selectedImages.length + 1 : _selectedImages.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                if (index == _selectedImages.length && _selectedImages.length < 5) {
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
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _selectedImages[index],
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: InkWell(
                                        onTap: () => _removeImage(index),
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
                            }),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Colors Section
                        Text(
                          'Available Colors & Quantities',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 12,
                          children: COLORS.map((color) {
                            final isSelected = _selectedColors.contains(color['name'] as String);
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () {
                                    final colorName = color['name'] as String;
                                    setState(() {
                                      if (isSelected) {
                                        _selectedColors.remove(colorName);
                                        _colorQuantities.remove(colorName);
                                      } else {
                                        _selectedColors.add(colorName);
                                        _colorQuantities[colorName] = 0;
                                      }
                                    });
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Color(color['value'] as int),
                                      border: Border.all(
                                        color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          color: Color(color['value'] as int).computeLuminance() > 0.5 
                                            ? Colors.black 
                                            : Colors.white,
                                        )
                                      : null,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 60,
                                    child: TextFormField(
                                      initialValue: _colorQuantities[color['name'] as String]?.toString() ?? '0',
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      onChanged: (value) {
                                        setState(() {
                                          _colorQuantities[color['name'] as String] = int.tryParse(value) ?? 0;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            );
                          }).toList(),
                        ),

                        // Total Quantity Display
                        if (_selectedColors.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Quantity:'),
                                Text(
                                  _colorQuantities.values.fold(0, (sum, qty) => sum + qty).toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                              border: OutlineInputBorder(),
                              prefixText: '\$',
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
                                    '\$${double.parse(_priceController.text)}',
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
                                    '\$${(double.parse(_priceController.text) * (1 - _discountPercent / 100)).toStringAsFixed(2)}',
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

                    // Shipping Fee (Read-only)
                    TextFormField(
                      initialValue: _shippingFee.toString(),
                      enabled: false,
                      decoration: const InputDecoration(
                        labelText: 'Shipping Fee (USD)',
                        border: OutlineInputBorder(),
                        prefixText: '\$',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Shipping fee is set in your store settings',
                      style: Theme.of(context).textTheme.bodySmall,
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

    // Additional validations
    if (_selectedImages.isEmpty) {
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
      // Upload images first
      final imageUrls = await Future.wait(
        _selectedImages.map((file) => ref.read(storageServiceProvider).uploadFile(file, 'products')),
      );

      // Calculate discounted price if discount is applied
      final price = double.parse(_priceController.text);
      final discountedPrice = _hasDiscount ? price * (1 - _discountPercent / 100) : null;

      final product = Product(
        id: '',
        sellerId: '',
        sellerName: '',
        name: _nameController.text,
        description: _descriptionController.text,
        price: price,
        stockQuantity: _hasVariants 
          ? _colorQuantities.values.fold(0, (sum, qty) => sum + qty)
          : int.parse(_stockController.text),
        category: _selectedCategory,
        subCategory: _selectedSubCategory,
        images: imageUrls,
        isActive: true,
        createdAt: DateTime.now().toIso8601String(),
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
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
} 