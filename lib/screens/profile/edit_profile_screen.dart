import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user.dart';
import '../../services/buyer_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../models/shipping_address.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  MerchUser? _user;
  File? _photoFile;
  bool _hasChanges = false;
  String? _existingPhotoUrl;
  double _completionPercentage = 0;
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Shipping Information Controllers
  final _shippingNameController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _zipController = TextEditingController();
  final _shippingPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    // Dispose basic info controllers
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    
    // Dispose shipping info controllers
    _shippingNameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _zipController.dispose();
    _shippingPhoneController.dispose();
    super.dispose();
  }

  void _calculateCompletionPercentage() {
    int totalFields = 10; // Total number of important fields
    int filledFields = 0;
    
    if (_nameController.text.isNotEmpty) filledFields++;
    if (_emailController.text.isNotEmpty) filledFields++;
    if (_phoneController.text.isNotEmpty) filledFields++;
    if (_shippingNameController.text.isNotEmpty) filledFields++;
    if (_streetController.text.isNotEmpty) filledFields++;
    if (_cityController.text.isNotEmpty) filledFields++;
    if (_stateController.text.isNotEmpty) filledFields++;
    if (_countryController.text.isNotEmpty) filledFields++;
    if (_zipController.text.isNotEmpty) filledFields++;
    if (_shippingPhoneController.text.isNotEmpty) filledFields++;
    
    setState(() {
      _completionPercentage = (filledFields / totalFields) * 100;
    });
  }

  void _onFieldChanged() {
    _calculateCompletionPercentage();
    
    final hasTextChanges = 
      _nameController.text != _user?.name ||
      _emailController.text != _user?.email ||
      _phoneController.text != _user?.phone ||
      _shippingNameController.text != _user?.defaultShippingAddress?.name ||
      _streetController.text != _user?.defaultShippingAddress?.street ||
      _cityController.text != _user?.defaultShippingAddress?.city ||
      _stateController.text != _user?.defaultShippingAddress?.state ||
      _countryController.text != _user?.defaultShippingAddress?.country ||
      _zipController.text != _user?.defaultShippingAddress?.zipCode ||
      _shippingPhoneController.text != _user?.defaultShippingAddress?.phone;

    final hasFileChanges = _photoFile != null;

    setState(() {
      _hasChanges = hasTextChanges || hasFileChanges;
    });
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final user = await ref.read(buyerServiceProvider).getCurrentUser();
      if (mounted) {
        setState(() {
          _user = user;
          // Set basic info
          _nameController.text = user.name ?? '';
          _emailController.text = user.email;
          _phoneController.text = user.phone ?? '';
          
          // Set shipping info from default address if available
          if (user.defaultShippingAddress != null) {
            _shippingNameController.text = user.defaultShippingAddress!.name;
            _streetController.text = user.defaultShippingAddress!.street;
            _cityController.text = user.defaultShippingAddress!.city;
            _stateController.text = user.defaultShippingAddress!.state;
            _countryController.text = user.defaultShippingAddress!.country;
            _zipController.text = user.defaultShippingAddress!.zipCode;
            _shippingPhoneController.text = user.defaultShippingAddress!.phone ?? '';
          }
          
          _existingPhotoUrl = user.photoUrl;
          _isLoading = false;
        });
        _calculateCompletionPercentage();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profile. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _photoFile = File(pickedFile.path);
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

    setState(() => _isSaving = true);

    try {
      String? photoUrl = _user?.photoUrl;
      
      // Upload new photo if selected
      if (_photoFile != null) {
        final urls = await ref.read(storageServiceProvider).uploadFiles(
          [_photoFile!],
          'users/photos',
        );
        photoUrl = urls.first;
      }

      // Create shipping address
      final shippingAddress = ShippingAddress(
        id: _user?.defaultShippingAddress?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _shippingNameController.text,
        street: _streetController.text,
        city: _cityController.text,
        state: _stateController.text,
        country: _countryController.text,
        zipCode: _zipController.text,
        phone: _shippingPhoneController.text.isNotEmpty ? _shippingPhoneController.text : null,
      );

      // Create updated user object
      final updatedUser = _user!.copyWith(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        address: _streetController.text,
        city: _cityController.text,
        state: _stateController.text,
        country: _countryController.text,
        zip: _zipController.text,
        photoUrl: photoUrl,
        defaultShippingAddress: shippingAddress,
        shippingAddresses: [shippingAddress],
      );

      await ref.read(buyerServiceProvider).updateProfile(updatedUser);

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
        setState(() => _isSaving = false);
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
                  onPressed: _loadUser,
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
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          onChanged: _onFieldChanged,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Completion Indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Profile Completion',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            '${_completionPercentage.toStringAsFixed(0)}%',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _completionPercentage / 100,
                        backgroundColor: colorScheme.onPrimaryContainer.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _completionPercentage == 100 
                              ? Colors.green 
                              : colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Profile Photo
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: colorScheme.primary,
                        backgroundImage: _photoFile != null
                            ? FileImage(_photoFile!) as ImageProvider
                            : _user?.photoUrl != null
                                ? NetworkImage(_user!.photoUrl!) as ImageProvider
                                : null,
                        child: _user?.photoUrl == null && _photoFile == null
                            ? Icon(
                                Icons.person,
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
                            onPressed: _pickPhoto,
                            tooltip: 'Change profile photo',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Personal Information Section
                Text(
                  'Personal Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                  onChanged: (_) => _onFieldChanged(),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  enabled: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                  onChanged: (_) => _onFieldChanged(),
                ),
                const SizedBox(height: 32),

                // Shipping Information Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_shipping_outlined,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Shipping Information',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _shippingNameController,
                        label: 'Full Name',
                        helperText: 'Name of the person receiving packages',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the recipient\'s name';
                          }
                          return null;
                        },
                        onChanged: (_) => _onFieldChanged(),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _streetController,
                        label: 'Street Address',
                        helperText: 'Enter your complete street address',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your street address';
                          }
                          return null;
                        },
                        onChanged: (_) => _onFieldChanged(),
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
                                  return 'Required';
                                }
                                return null;
                              },
                              onChanged: (_) => _onFieldChanged(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _stateController,
                              label: 'State/Region',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                              onChanged: (_) => _onFieldChanged(),
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
                                  return 'Required';
                                }
                                return null;
                              },
                              onChanged: (_) => _onFieldChanged(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _zipController,
                              label: 'ZIP/Postal Code',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                return null;
                              },
                              onChanged: (_) => _onFieldChanged(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _shippingPhoneController,
                        label: 'Contact Phone',
                        helperText: 'Phone number for delivery contact',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a contact phone number';
                          }
                          return null;
                        },
                        onChanged: (_) => _onFieldChanged(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _hasChanges ? _saveProfile : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    child: _isSaving 
                      ? const CircularProgressIndicator()
                      : const Text('Save Changes', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 