import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/seller.dart';
import '../../services/seller_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class SellerProfileScreen extends ConsumerStatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  ConsumerState<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends ConsumerState<SellerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _countryController = TextEditingController();
  final _shippingInfoController = TextEditingController();
  final _paymentInfoController = TextEditingController();
  File? _logoFile;
  File? _bannerFile;
  String? _existingLogo;
  String? _existingBanner;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSellerProfile();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _descriptionController.dispose();
    _countryController.dispose();
    _shippingInfoController.dispose();
    _paymentInfoController.dispose();
    super.dispose();
  }

  Future<void> _loadSellerProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final seller = await ref.read(sellerServiceProvider).getSellerProfile();
      if (mounted) {
        _storeNameController.text = seller.storeName;
        _descriptionController.text = seller.description ?? '';
        _countryController.text = seller.country ?? '';
        _shippingInfoController.text = seller.shippingInfo ?? '';
        _paymentInfoController.text = seller.paymentInfo ?? '';
        _existingLogo = seller.logo;
        _existingBanner = seller.banner;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _logoFile = File(image.path));
    }
  }

  Future<void> _pickBanner() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _bannerFile = File(image.path));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      String? logoUrl = _existingLogo;
      String? bannerUrl = _existingBanner;

      // Upload new logo if selected
      if (_logoFile != null) {
        final urls = await ref.read(storageServiceProvider).uploadFiles(
          [_logoFile!],
          'sellers/logos',
        );
        logoUrl = urls.first;
      }

      // Upload new banner if selected
      if (_bannerFile != null) {
        final urls = await ref.read(storageServiceProvider).uploadFiles(
          [_bannerFile!],
          'sellers/banners',
        );
        bannerUrl = urls.first;
      }

      // Update seller profile
      await ref.read(sellerServiceProvider).updateSellerProfile({
        'storeName': _storeNameController.text,
        'description': _descriptionController.text,
        'country': _countryController.text,
        'shippingInfo': _shippingInfoController.text,
        'paymentInfo': _paymentInfoController.text,
        if (logoUrl != null) 'logo': logoUrl,
        if (bannerUrl != null) 'banner': bannerUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Profile'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Logo
            AspectRatio(
              aspectRatio: 1,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _pickLogo,
                  child: _logoFile != null
                      ? Image.file(
                          _logoFile!,
                          fit: BoxFit.cover,
                        )
                      : _existingLogo != null
                          ? Image.network(
                              _existingLogo!,
                              fit: BoxFit.cover,
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 48,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add Store Logo',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Banner
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _pickBanner,
                  child: _bannerFile != null
                      ? Image.file(
                          _bannerFile!,
                          fit: BoxFit.cover,
                        )
                      : _existingBanner != null
                          ? Image.network(
                              _existingBanner!,
                              fit: BoxFit.cover,
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 48,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add Store Banner',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Store Name
            CustomTextField(
              controller: _storeNameController,
              label: 'Store Name',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your store name';
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
                  return 'Please enter your store description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Country
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

            // Shipping Info
            CustomTextField(
              controller: _shippingInfoController,
              label: 'Shipping Information',
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your shipping information';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Payment Info
            CustomTextField(
              controller: _paymentInfoController,
              label: 'Payment Information',
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your payment information';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Save Button
            CustomButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
} 