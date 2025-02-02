import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/seller.dart';
import '../../services/seller_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../widgets/common/cached_image.dart';

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
  dynamic _logoFile; // Changed to dynamic to support both File and XFile
  dynamic _bannerFile; // Changed to dynamic to support both File and XFile
  bool _hasChanges = false;
  Uint8List? _webLogoBytes;
  Uint8List? _webBannerBytes;
  
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
  final _paymentReferenceController = TextEditingController();
  
  // Payment method controllers
  final _mtnMomoNameController = TextEditingController();
  final _mtnMomoPhoneController = TextEditingController();
  final _telecelCashNameController = TextEditingController();
  final _telecelCashPhoneController = TextEditingController();
  
  List<String> _selectedPaymentMethods = [];

  // Add new controllers for social media
  final _whatsappNumberController = TextEditingController();
  final _instagramHandleController = TextEditingController();
  final _tiktokHandleController = TextEditingController();

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
    _paymentReferenceController.addListener(_onFieldChanged);
    _mtnMomoNameController.addListener(_onFieldChanged);
    _mtnMomoPhoneController.addListener(_onFieldChanged);
    _telecelCashNameController.addListener(_onFieldChanged);
    _telecelCashPhoneController.addListener(_onFieldChanged);
    _whatsappNumberController.addListener(_onFieldChanged);
    _instagramHandleController.addListener(_onFieldChanged);
    _tiktokHandleController.addListener(_onFieldChanged);
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
    _paymentReferenceController.removeListener(_onFieldChanged);
    _mtnMomoNameController.removeListener(_onFieldChanged);
    _mtnMomoPhoneController.removeListener(_onFieldChanged);
    _telecelCashNameController.removeListener(_onFieldChanged);
    _telecelCashPhoneController.removeListener(_onFieldChanged);
    _whatsappNumberController.removeListener(_onFieldChanged);
    _instagramHandleController.removeListener(_onFieldChanged);
    _tiktokHandleController.removeListener(_onFieldChanged);

    // Dispose controllers
    _storeNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    _shippingInfoController.dispose();
    _paymentReferenceController.dispose();
    _mtnMomoNameController.dispose();
    _mtnMomoPhoneController.dispose();
    _telecelCashNameController.dispose();
    _telecelCashPhoneController.dispose();
    _whatsappNumberController.dispose();
    _instagramHandleController.dispose();
    _tiktokHandleController.dispose();
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
      _paymentReferenceController.text != _seller?.paymentReference ||
      _mtnMomoNameController.text != _seller?.paymentNames?['mtn_momo'] ||
      _mtnMomoPhoneController.text != _seller?.paymentPhoneNumbers?['mtn_momo'] ||
      _telecelCashNameController.text != _seller?.paymentNames?['telecel_cash'] ||
      _telecelCashPhoneController.text != _seller?.paymentPhoneNumbers?['telecel_cash'] ||
      _whatsappNumberController.text != _seller?.whatsappNumber ||
      _instagramHandleController.text != _seller?.instagramHandle ||
      _tiktokHandleController.text != _seller?.tiktokHandle;

    final hasFileChanges = _logoFile != null || _bannerFile != null;

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
        _cityController.text = seller.city ?? '';
        _stateController.text = seller.state ?? '';
        _countryController.text = seller.country;
        _zipController.text = seller.zip ?? '';
        _phoneController.text = seller.phone;
        _shippingInfoController.text = seller.shippingInfo ?? '';
        _paymentReferenceController.text = seller.paymentReference ?? '';
        _selectedPaymentMethods = List<String>.from(seller.acceptedPaymentMethods ?? []);
        
        // Initialize payment method controllers
        _mtnMomoNameController.text = seller.paymentNames?['mtn_momo'] ?? '';
        _mtnMomoPhoneController.text = seller.paymentPhoneNumbers?['mtn_momo'] ?? '';
        _telecelCashNameController.text = seller.paymentNames?['telecel_cash'] ?? '';
        _telecelCashPhoneController.text = seller.paymentPhoneNumbers?['telecel_cash'] ?? '';
        
        // Initialize social media controllers
        _whatsappNumberController.text = seller.whatsappNumber ?? '';
        _instagramHandleController.text = seller.instagramHandle ?? '';
        _tiktokHandleController.text = seller.tiktokHandle ?? '';
        
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
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          if (kIsWeb) {
            _logoFile = pickedFile;
            pickedFile.readAsBytes().then((bytes) {
              setState(() {
                _webLogoBytes = bytes;
                _hasChanges = true;
              });
            });
          } else {
            _logoFile = File(pickedFile.path);
            _hasChanges = true;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _pickBanner() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 400,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          if (kIsWeb) {
            _bannerFile = pickedFile;
            pickedFile.readAsBytes().then((bytes) {
              setState(() {
                _webBannerBytes = bytes;
                _hasChanges = true;
              });
            });
          } else {
            _bannerFile = File(pickedFile.path);
            _hasChanges = true;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking banner image: $e')),
      );
    }
  }

  Widget _buildStoreLogo() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[200],
          child: _logoFile != null
              ? ClipOval(
                  child: kIsWeb
                      ? _webLogoBytes != null
                          ? Image.memory(
                              _webLogoBytes!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            )
                          : const CircularProgressIndicator()
                      : Image.file(
                          _logoFile as File,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                )
              : _seller?.logo != null
                  ? ClipOval(
                      child: CachedImage(
                        imageUrl: _seller!.logo!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const Icon(Icons.store, size: 50),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: IconButton(
              icon: const Icon(Icons.camera_alt, size: 18),
              color: Colors.white,
              onPressed: _pickLogo,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStoreBanner() {
    return Stack(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: _bannerFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                          _bannerFile as File,
                          fit: BoxFit.cover,
                        ),
                )
              : _seller?.banner != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedImage(
                        imageUrl: _seller!.banner!,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        placeholder: Container(
                          width: double.infinity,
                          height: 150,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.image, size: 50),
                    ),
        ),
        Positioned(
          bottom: 8,
          right: 8,
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: IconButton(
              icon: const Icon(Icons.camera_alt, size: 18),
              color: Colors.white,
              onPressed: _pickBanner,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment Information',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _paymentReferenceController,
          label: 'Payment Reference',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter payment reference';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        const Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('MTN MoMo'),
              selected: _selectedPaymentMethods.contains('mtn_momo'),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedPaymentMethods.add('mtn_momo');
                  } else {
                    _selectedPaymentMethods.remove('mtn_momo');
                  }
                  _hasChanges = true;
                });
              },
            ),
            FilterChip(
              label: const Text('Telecel Cash'),
              selected: _selectedPaymentMethods.contains('telecel_cash'),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    _selectedPaymentMethods.add('telecel_cash');
                  } else {
                    _selectedPaymentMethods.remove('telecel_cash');
                  }
                  _hasChanges = true;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_selectedPaymentMethods.contains('mtn_momo')) ...[
          CustomTextField(
            controller: _mtnMomoNameController,
            label: 'Payment Name (MTN MoMo)',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter MTN MoMo payment name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _mtnMomoPhoneController,
            label: 'Payment Phone Number (MTN MoMo)',
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter MTN MoMo phone number';
              }
              return null;
            },
          ),
        ],
        if (_selectedPaymentMethods.contains('telecel_cash')) ...[
          const SizedBox(height: 16),
          CustomTextField(
            controller: _telecelCashNameController,
            label: 'Payment Name (Telecel Cash)',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter Telecel Cash payment name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _telecelCashPhoneController,
            label: 'Payment Phone Number (Telecel Cash)',
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter Telecel Cash phone number';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSocialMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Social Media',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _whatsappNumberController,
          label: 'WhatsApp Number',
          prefixIcon: const Icon(FontAwesomeIcons.whatsapp, color: Color(0xFF25D366)),
          helperText: 'Enter your WhatsApp number with country code (e.g., 263773123456)',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _instagramHandleController,
          label: 'Instagram Handle',
          prefixIcon: const Icon(FontAwesomeIcons.instagram, color: Color(0xFFE1306C)),
          helperText: 'Enter your Instagram handle without @ (e.g., yourstorename)',
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _tiktokHandleController,
          label: 'TikTok Handle',
          prefixIcon: const Icon(FontAwesomeIcons.tiktok),
          helperText: 'Enter your TikTok handle without @ (e.g., yourstorename)',
        ),
      ],
    );
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
                        child: ClipOval(
                          child: _logoFile != null
                              ? kIsWeb
                                  ? _webLogoBytes != null
                                      ? Image.memory(
                                          _webLogoBytes!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        )
                                      : const CircularProgressIndicator()
                                  : Image.file(
                                      _logoFile as File,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    )
                              : _seller?.logo != null
                                  ? CachedImage(
                                      imageUrl: _seller!.logo!,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      placeholder: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    )
                                  : Icon(
                                      Icons.store,
                                      size: 50,
                                      color: colorScheme.onPrimary,
                                    ),
                        ),
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
                _buildPaymentSection(),
                const SizedBox(height: 24),
                _buildSocialMediaSection(),
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? logoUrl = _seller?.logo;
      String? bannerUrl = _seller?.banner;
      
      // Upload new logo if selected
      if (_logoFile != null) {
        if (kIsWeb) {
          // For web, pass the XFile directly
          logoUrl = await ref.read(storageServiceProvider).uploadSellerFile(
            _logoFile,  // Pass XFile directly
            'logo',
          );
        } else {
          // For mobile, use File
          logoUrl = await ref.read(storageServiceProvider).uploadSellerFile(
            _logoFile as File,
            'logo',
          );
        }
      }

      // Upload new banner if selected
      if (_bannerFile != null) {
        if (kIsWeb) {
          // For web, pass the XFile directly
          bannerUrl = await ref.read(storageServiceProvider).uploadSellerFile(
            _bannerFile,  // Pass XFile directly
            'banner',
          );
        } else {
          // For mobile, use File
          bannerUrl = await ref.read(storageServiceProvider).uploadSellerFile(
            _bannerFile as File,
            'banner',
          );
        }
      }

      // Create maps for payment information
      Map<String, String> paymentPhoneNumbers = {};
      Map<String, String> paymentNames = {};
      
      // Update MTN MoMo information
      if (_selectedPaymentMethods.contains('mtn_momo')) {
        paymentPhoneNumbers['mtn_momo'] = _mtnMomoPhoneController.text.trim();
        paymentNames['mtn_momo'] = _mtnMomoNameController.text.trim();
      }
      
      // Update Telecel Cash information
      if (_selectedPaymentMethods.contains('telecel_cash')) {
        paymentPhoneNumbers['telecel_cash'] = _telecelCashPhoneController.text.trim();
        paymentNames['telecel_cash'] = _telecelCashNameController.text.trim();
      }

      // Create updated seller object using the Seller model
      final updatedSeller = _seller!.copyWith(
        storeName: _storeNameController.text,
        description: _descriptionController.text,
        logo: logoUrl,
        banner: bannerUrl,
        address: _addressController.text,
        city: _cityController.text,
        state: _stateController.text,
        country: _countryController.text,
        zip: _zipController.text,
        phone: _phoneController.text,
        shippingInfo: _shippingInfoController.text,
        paymentReference: _paymentReferenceController.text,
        acceptedPaymentMethods: _selectedPaymentMethods,
        paymentPhoneNumbers: paymentPhoneNumbers,
        paymentNames: paymentNames,
        whatsappNumber: _whatsappNumberController.text.trim(),
        instagramHandle: _instagramHandleController.text.trim(),
        tiktokHandle: _tiktokHandleController.text.trim(),
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
} 