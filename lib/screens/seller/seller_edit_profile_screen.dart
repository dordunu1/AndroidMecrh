import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/seller.dart';
import '../../services/seller_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class SellerEditProfileScreen extends ConsumerStatefulWidget {
  const SellerEditProfileScreen({super.key});

  @override
  ConsumerState<SellerEditProfileScreen> createState() => _SellerEditProfileScreenState();
}

class _SellerEditProfileScreenState extends ConsumerState<SellerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String? _error;
  Seller? _seller;
  File? _logoFile;
  bool _hasChanges = false;
  
  // Controllers
  final _storeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _zipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _shippingInfoController = TextEditingController();
  final _paymentInfoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSellerProfile();
    
    // Add listeners to track changes
    _storeNameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _cityController.addListener(_onFieldChanged);
    _stateController.addListener(_onFieldChanged);
    _countryController.addListener(_onFieldChanged);
    _zipController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _shippingInfoController.addListener(_onFieldChanged);
    _paymentInfoController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    // Remove listeners
    _storeNameController.removeListener(_onFieldChanged);
    _descriptionController.removeListener(_onFieldChanged);
    _addressController.removeListener(_onFieldChanged);
    _cityController.removeListener(_onFieldChanged);
    _stateController.removeListener(_onFieldChanged);
    _countryController.removeListener(_onFieldChanged);
    _zipController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _shippingInfoController.removeListener(_onFieldChanged);
    _paymentInfoController.removeListener(_onFieldChanged);

    _storeNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    _shippingInfoController.dispose();
    _paymentInfoController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    final hasTextChanges = 
      _storeNameController.text != _seller?.storeName ||
      _descriptionController.text != _seller?.description ||
      _addressController.text != _seller?.address ||
      _cityController.text != _seller?.city ||
      _stateController.text != _seller?.state ||
      _countryController.text != _seller?.country ||
      _zipController.text != _seller?.zip ||
      _phoneController.text != _seller?.phone ||
      _shippingInfoController.text != _seller?.shippingInfo ||
      _paymentInfoController.text != _seller?.paymentInfo;

    final hasFileChanges = _logoFile != null;

    setState(() {
      _hasChanges = hasTextChanges || hasFileChanges;
    });
  }

  Future<void> _loadSellerProfile() async {
    try {
      final seller = await ref.read(sellerServiceProvider).getSellerProfile();
      setState(() {
        _seller = seller;
        _storeNameController.text = seller.storeName;
        _descriptionController.text = seller.description;
        _addressController.text = seller.address;
        _cityController.text = seller.city;
        _stateController.text = seller.state;
        _countryController.text = seller.country;
        _zipController.text = seller.zip;
        _phoneController.text = seller.phone;
        _shippingInfoController.text = seller.shippingInfo ?? '';
        _paymentInfoController.text = seller.paymentInfo ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() {
          _logoFile = File(pickedFile.path);
          _hasChanges = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? logoUrl = _seller?.logo;
      
      // Upload new logo if selected
      if (_logoFile != null) {
        logoUrl = await ref.read(storageServiceProvider).uploadSellerFile(
          _logoFile!,
          'logo',
        );
      }

      // Create updated seller object
      final updatedSeller = _seller!.copyWith(
        storeName: _storeNameController.text,
        description: _descriptionController.text,
        logo: logoUrl,
        address: _addressController.text,
        city: _cityController.text,
        state: _stateController.text,
        country: _countryController.text,
        zip: _zipController.text,
        phone: _phoneController.text,
        shippingInfo: _shippingInfoController.text,
        paymentInfo: _paymentInfoController.text,
        updatedAt: DateTime.now().toIso8601String(),
      );

      await ref.read(sellerServiceProvider).updateSellerProfile(updatedSeller);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'Error loading profile',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadSellerProfile,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Store Profile'),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Store Logo
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: colorScheme.primary,
                        backgroundImage: _logoFile != null
                            ? FileImage(_logoFile!) as ImageProvider
                            : _seller?.logo != null
                                ? NetworkImage(_seller!.logo!) as ImageProvider
                                : null,
                        child: _seller?.logo == null && _logoFile == null
                            ? Icon(
                                Icons.store,
                                size: 50,
                                color: colorScheme.onPrimary,
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: colorScheme.primary,
                          child: IconButton(
                            icon: Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: colorScheme.onPrimary,
                            ),
                            onPressed: _pickLogo,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Store Information
                Text(
                  'Store Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _storeNameController,
                  label: 'Store Name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter store name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Store Description',
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter store description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Contact Information
                Text(
                  'Contact Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Address Information
                Text(
                  'Address Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _addressController,
                  label: 'Address',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _cityController,
                        label: 'City',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter city';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _stateController,
                        label: 'State',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter state';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _countryController,
                        label: 'Country',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter country';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _zipController,
                        label: 'ZIP Code',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter ZIP code';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Shipping & Payment Information
                Text(
                  'Business Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _shippingInfoController,
                  label: 'Shipping Information',
                  helperText: 'Enter your shipping policy and delivery timeframes',
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter shipping information';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _paymentInfoController,
                  label: 'Payment Information',
                  helperText: 'Enter your accepted payment methods and terms',
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter payment information';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading || !_hasChanges ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator()
                      : const Text('Save Changes', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 