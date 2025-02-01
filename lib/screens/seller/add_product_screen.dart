import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/product.dart';
import '../../services/seller_service.dart';
import '../../services/storage_service.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/feature_tour.dart';
import '../../constants/size_standards.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../routes.dart';

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
  final _quantityController = TextEditingController();
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
  final Map<String, TextEditingController> _colorQuantityControllers = {};
  int _currentImageIndex = 0;

  double _uploadProgress = 0;
  String _uploadStatus = '';

  bool get isFootwearProduct => 
    _selectedCategory == 'clothing' && 
    _selectedSubCategory.split(' - ')[0] == 'Footwear';

  bool _showFeatureTour = false;
  final Map<String, GlobalKey> _tourKeys = {
    'images': GlobalKey(),
    'name': GlobalKey(),
    'description': GlobalKey(),
    'price': GlobalKey(),
    'category': GlobalKey(),
    'variants': GlobalKey(),
    'sizes': GlobalKey(),
  };

  String _selectedJewelryType = '';

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    _checkProfileCompleteness();
    // Show guide when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAddProductGuide();
    });
    _selectedJewelryType = '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _shippingInfoController.dispose();
    _discountPercentController.dispose();
    _colorController.dispose();
    _colorQuantityControllers.values.forEach((controller) => controller.dispose());
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

  void _showAddProductGuide() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('How to Add a Product'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Follow these steps to add your product:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('1. Upload Product Images (up to 10):'),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Click the + button to add images'),
                    Text('• Each image should show a different color variant'),
                    Text('• Click the pencil icon (✏️) on each image to set its color'),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text('2. Fill in Basic Details:'),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Product name and description'),
                    Text('• Select category and subcategory'),
                    Text('• Set base price'),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text('3. Set Up Color Variants:'),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Enable color variants toggle'),
                    Text('• Enter quantity available for each color'),
                    Text('• Make sure each color matches an uploaded image'),
                  ],
                ),
              ),
              SizedBox(height: 12),
              Text('4. Optional Settings:'),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Add discount if applicable'),
                    Text('• Set shipping information'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it, let\'s start!'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('seller_add_product_tour_shown') ?? true;
    
    if (isFirstTime) {
      if (mounted) {
        setState(() => _showFeatureTour = true);
      }
      await prefs.setBool('seller_add_product_tour_shown', false);
    }
  }

  Future<void> _checkProfileCompleteness() async {
    try {
      final seller = await ref.read(sellerServiceProvider).getSellerProfile();
      
      // Check for required fields
      if (seller.storeName.isEmpty ||
          seller.description.isEmpty ||
          seller.address.isEmpty ||
          seller.city.isEmpty ||
          seller.state.isEmpty ||
          seller.country.isEmpty ||
          seller.phone.isEmpty ||
          seller.acceptedPaymentMethods.isEmpty ||
          seller.paymentPhoneNumbers.isEmpty) {
            
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange[900]),
                  const SizedBox(width: 8),
                  const Text('Complete Your Profile'),
                ],
              ),
              content: const Text(
                'Please complete your seller profile before adding products.\n\n'
                'Required information includes:\n'
                '• Store name and description\n'
                '• Complete address\n'
                '• Contact phone number\n'
                '• Payment methods and details\n\n'
                'You will be redirected to edit your profile.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, Routes.editSellerProfile);
                  },
                  child: const Text('Complete Profile'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking profile: $e')),
        );
      }
    }
  }

  List<FeatureTourStep> _getFeatureTourSteps() {
    return [
      FeatureTourStep(
        title: 'Product Images',
        description: 'Add multiple images of your product. The first image will be the main display image.',
        targetKey: _tourKeys['images']!,
      ),
      FeatureTourStep(
        title: 'Product Details',
        description: 'Enter your product name, description, and pricing information.',
        targetKey: _tourKeys['name']!,
      ),
      FeatureTourStep(
        title: 'Category Selection',
        description: 'Choose the appropriate category and subcategory for your product.',
        targetKey: _tourKeys['category']!,
      ),
      FeatureTourStep(
        title: 'Color Variants',
        description: 'If your product comes in different colors, you can add them here with separate images.',
        targetKey: _tourKeys['variants']!,
      ),
      FeatureTourStep(
        title: 'Size Options',
        description: 'Add available sizes based on international standards for your product category.',
        targetKey: _tourKeys['sizes']!,
      ),
    ];
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                  key: _tourKeys['images'],
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

                // Product Details Section
                Card(
                  key: _tourKeys['name'],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Details',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _nameController,
                          label: 'Product Name',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a product name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          maxLines: 5,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a product description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Price and Quantity Row
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _priceController,
                                label: 'Price (GHS)',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Invalid price';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: _quantityController,
                                label: 'Quantity',
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter quantity';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Invalid quantity';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Shipping Info
                        CustomTextField(
                          controller: _shippingInfoController,
                          label: 'Shipping Information',
                          hint: 'Enter shipping details, handling time, etc.',
                          maxLines: 3,
                        ),
                        
                        // Discount Section
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Apply Discount',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Switch(
                              value: _hasDiscount,
                              onChanged: (value) {
                                setState(() {
                                  _hasDiscount = value;
                                  if (!value) {
                                    _discountPercentController.clear();
                                    _discountEndsAt = null;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        if (_hasDiscount) ...[
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _discountPercentController,
                            label: 'Discount Percentage',
                            hint: 'Enter discount percentage (e.g. 10)',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                final percent = double.tryParse(value);
                                if (percent != null) {
                                  setState(() {
                                    _discountPercent = percent;
                                  });
                                }
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter discount percentage';
                              }
                              final percent = double.tryParse(value);
                              if (percent == null) {
                                return 'Please enter a valid number';
                              }
                              if (percent <= 0 || percent >= 100) {
                                return 'Percentage must be between 0 and 100';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Discount End Date',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            subtitle: Text(
                              _discountEndsAt != null
                                  ? 'Ends on ${_formatDate(_discountEndsAt!)}'
                                  : 'Not set',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () async {
                                final date = await showDateTimePicker(
                                  context: context,
                                  initialDate: _discountEndsAt ?? DateTime.now().add(const Duration(days: 7)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() {
                                    _discountEndsAt = date;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category Section
                Card(
                  key: _tourKeys['category'],
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

                        // Subcategories Section
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

                // Variants Section
                _buildVariantsSection(),
              ],
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading) ...[
                  Text(_uploadStatus),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _uploadProgress / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      await _submitForm();
                    }
                  },
                  child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Add Product'),
                ),
              ],
            ),
          ),
        ),
        
        if (_showFeatureTour)
          FeatureTour(
            steps: _getFeatureTourSteps(),
            onComplete: () {
              setState(() => _showFeatureTour = false);
            },
          ),
      ],
    );
  }

  Widget _buildVariantsSection() {
    return Card(
      key: _tourKeys['variants'],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Variants',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // Color Variants
            SwitchListTile(
              title: const Text('Add Color Variants'),
              value: _hasVariants,
              onChanged: (value) {
                setState(() {
                  _hasVariants = value;
                  if (!value) {
                    _selectedColors = [];
                    _colorQuantities = {};
                  }
                });
              },
            ),
            if (_hasVariants) ... [
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
              // Add stock management for color variants
              if (_imageColors.isNotEmpty) ...[
                Text(
                  'Stock Management',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...(_imageColors.values.map((color) {
                  _colorQuantityControllers.putIfAbsent(
                    color, 
                    () => TextEditingController(text: _colorQuantities[color]?.toString() ?? '0')
                  );
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(color),
                        ),
                        Expanded(
                          flex: 3,
                          child: CustomTextField(
                            controller: _colorQuantityControllers[color],
                            label: 'Quantity',
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                _colorQuantities[color] = int.tryParse(value) ?? 0;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              if (int.tryParse(value) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                })).toList(),
                if (_colorQuantities.isNotEmpty) ...[
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Stock:',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          _colorQuantities.values.fold(0, (sum, qty) => sum + qty).toString(),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ],
            
            // Size Variants
            _buildSizeSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSizeSection() {
    return Column(
      key: _tourKeys['sizes'],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Available Sizes',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (_selectedSubCategory.endsWith('Jewelry')) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 16),
                label: Text(_selectedJewelryType.isEmpty ? 'Select Type' : _selectedJewelryType),
                onPressed: () async {
                  final result = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Select Jewelry Type'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            title: const Text('Necklaces'),
                            onTap: () => Navigator.pop(context, 'Necklaces'),
                          ),
                          ListTile(
                            title: const Text('Bracelets'),
                            onTap: () => Navigator.pop(context, 'Bracelets'),
                          ),
                          ListTile(
                            title: const Text('Rings'),
                            onTap: () => Navigator.pop(context, 'Rings'),
                          ),
                        ],
                      ),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _selectedJewelryType = result;
                      _selectedSizes = [];
                    });
                  }
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _getAvailableSizes()
            .map((size) => FilterChip(
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
            ))
            .toList(),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one product image')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0;
      _uploadStatus = 'Preparing to upload images...';
    });

    try {
      // Upload images
      final storageService = ref.read(storageServiceProvider);
      final imageUrls = <String>[];
      final newImageColors = <String, String>{};
      
      for (var i = 0; i < _selectedImages.length; i++) {
        setState(() {
          _uploadStatus = 'Uploading image ${i + 1} of ${_selectedImages.length}';
          _uploadProgress = (i / _selectedImages.length) * 40; // First 40% for images
        });
        
        final file = _selectedImages[i];
        final url = await storageService.uploadProductImage(file);
        imageUrls.add(url);
        
        // Transfer the color from local path to uploaded URL
        final color = _imageColors[file.path];
        if (color != null) {
          newImageColors[url] = color;
        }
      }

      setState(() {
        _uploadStatus = 'Creating product...';
        _uploadProgress = 50; // Next 50% for product creation
      });

      // Get seller profile to get the store name
      final seller = await ref.read(sellerServiceProvider).getSellerProfile();

      // Create product with updated image colors
      final product = Product(
        id: '',  // Will be set by Firestore
        sellerId: ref.read(authServiceProvider).currentUser?.uid ?? '',
        sellerName: seller.storeName,
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        stockQuantity: _hasVariants 
          ? _colorQuantities.values.fold(0, (sum, qty) => sum + qty)
          : int.parse(_quantityController.text),
        images: imageUrls,
        category: _selectedCategory,
        subCategory: _selectedSubCategory,
        isActive: true,
        createdAt: DateTime.now().toIso8601String(),
        hasVariants: _hasVariants,
        sizes: _selectedSizes,
        colors: newImageColors.values.toList(),
        colorQuantities: _colorQuantities,
        imageColors: newImageColors,
        hasDiscount: _hasDiscount,
        discountPercent: _discountPercent,
        discountEndsAt: _discountEndsAt,
        discountedPrice: _hasDiscount ? 
          double.parse(_priceController.text) * (1 - _discountPercent / 100) : 
          null,
        soldCount: 0,
        rating: 0,
        reviewCount: 0,
        shippingInfo: _shippingInfoController.text,
      );

      setState(() {
        _uploadStatus = 'Saving product details...';
        _uploadProgress = 75;
      });

      await ref.read(productServiceProvider).createProduct(product.toMap());

      setState(() {
        _uploadStatus = 'Product added successfully!';
        _uploadProgress = 100;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product added successfully! Click refresh to see your products.'),
            duration: const Duration(seconds: 3),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        
        // Wait for the progress to be visible before closing
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadStatus = 'Error: ${e.toString()}';
        });
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

  List<String> _getAvailableSizes() {
    if (_selectedCategory == 'clothing') {
      if (_selectedSubCategory.startsWith("Men's Wear")) {
        if (_selectedSubCategory.contains('Pants')) {
          return MENS_CLOTHING_SIZES['Pants & Trousers']!;
        } else if (_selectedSubCategory.contains('Suits')) {
          return MENS_CLOTHING_SIZES['Suits']!;
        }
        return MENS_CLOTHING_SIZES['Shirts & T-Shirts']!;
      } else if (_selectedSubCategory.startsWith("Women's Wear")) {
        if (_selectedSubCategory.contains('Pants') || _selectedSubCategory.contains('Skirts')) {
          return WOMENS_CLOTHING_SIZES['Pants & Skirts']!;
        } else if (_selectedSubCategory.contains('Blouses')) {
          return WOMENS_CLOTHING_SIZES['Blouses']!;
        }
        return WOMENS_CLOTHING_SIZES['Dresses & Tops']!;
      } else if (_selectedSubCategory.startsWith('Footwear')) {
        final footwearTypes = ['Sneakers', 'Formal Shoes', 'Boots', 'Slippers', 'Sandals'];
        final type = _selectedSubCategory.split(' - ').last;
        if (footwearTypes.contains(type)) {
          return SHOE_SIZES;
        }
      }
    } else if (_selectedCategory == 'accessories') {
      if (_selectedSubCategory.endsWith('Jewelry')) {
        if (_selectedJewelryType == 'Necklaces') {
          return JEWELRY_SIZES['Necklaces']!;
        } else if (_selectedJewelryType == 'Bracelets') {
          return JEWELRY_SIZES['Bracelets']!;
        } else if (_selectedJewelryType == 'Rings') {
          return JEWELRY_SIZES['Rings']!;
        }
        return [];
      } else if (_selectedSubCategory.endsWith('Hats')) {
        return HAT_SIZES['US-UK']!;
      } else if (_selectedSubCategory.endsWith('Belts')) {
        return BELT_SIZES;
      }
    }
    return [];
  }
} 