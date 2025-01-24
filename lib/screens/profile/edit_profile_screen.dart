import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user.dart';
import '../../services/buyer_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/custom_text_field.dart';

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
  
  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _zipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser();
    
    // Add listeners to track changes
    _nameController.addListener(_onFieldChanged);
    _emailController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _cityController.addListener(_onFieldChanged);
    _stateController.addListener(_onFieldChanged);
    _countryController.addListener(_onFieldChanged);
    _zipController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    // Remove listeners
    _nameController.removeListener(_onFieldChanged);
    _emailController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _addressController.removeListener(_onFieldChanged);
    _cityController.removeListener(_onFieldChanged);
    _stateController.removeListener(_onFieldChanged);
    _countryController.removeListener(_onFieldChanged);
    _zipController.removeListener(_onFieldChanged);

    // Dispose controllers
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    final hasTextChanges = 
      _nameController.text != _user?.name ||
      _emailController.text != _user?.email ||
      _phoneController.text != _user?.phone ||
      _addressController.text != _user?.address ||
      _cityController.text != _user?.city ||
      _stateController.text != _user?.state ||
      _countryController.text != _user?.country ||
      _zipController.text != _user?.zip;

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
          _nameController.text = user.name ?? '';
          _emailController.text = user.email;
          _phoneController.text = user.phone ?? '';
          _addressController.text = user.address ?? '';
          _cityController.text = user.city ?? '';
          _stateController.text = user.state ?? '';
          _countryController.text = user.country ?? '';
          _zipController.text = user.zip ?? '';
          _existingPhotoUrl = user.photoUrl;
          _isLoading = false;
        });
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
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
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

      // Create updated user object
      final updatedUser = _user!.copyWith(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        city: _cityController.text,
        state: _stateController.text,
        country: _countryController.text,
        zip: _zipController.text,
        photoUrl: photoUrl,
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Personal Information
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
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
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
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
                  label: 'Street Address',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your street address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _cityController,
                  label: 'City',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your city';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _stateController,
                  label: 'State/Province',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your state/province';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _countryController,
                  label: 'Country',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your country';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _zipController,
                  label: 'ZIP/Postal Code',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your ZIP/postal code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving || !_hasChanges ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    child: _isSaving 
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