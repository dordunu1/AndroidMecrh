import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/seller.dart';
import '../../services/seller_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../services/auth_service.dart';
import '../../routes.dart';
import '../../services/buyer_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SellerTerms {
  static const List<Map<String, dynamic>> terms = [
    {
      'icon': FontAwesomeIcons.truck,
      'title': 'Fast Shipping Required',
      'description': 'Maximum 3 days to confirm and ship orders after sale confirmation.'
    },
    {
      'icon': FontAwesomeIcons.moneyBillTransfer,
      'title': 'P2P Marketplace',
      'description': 'This is a peer-to-peer marketplace. The platform does not hold payments. Sellers must confirm shipping within 3 days or refund and cancel orders.'
    },
    {
      'icon': FontAwesomeIcons.shieldHalved,
      'title': 'Account Security',
      'description': 'Multiple reports or suspicious activity may lead to account termination.'
    },
    {
      'icon': FontAwesomeIcons.boxOpen,
      'title': 'Product Handling',
      'description': 'Sellers are responsible for proper product handling and packaging.'
    },
    {
      'icon': FontAwesomeIcons.star,
      'title': 'Store Verification',
      'description': 'Based on positive reviews and sales performance over time.'
    },
  ];
}

class BecomeSellerScreen extends ConsumerStatefulWidget {
  const BecomeSellerScreen({super.key});

  @override
  ConsumerState<BecomeSellerScreen> createState() => _BecomeSellerScreenState();
}

class _BecomeSellerScreenState extends ConsumerState<BecomeSellerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _storeDescriptionController = TextEditingController();
  final _shippingInfoController = TextEditingController();
  final _addressController = TextEditingController();
  final _mtnMomoPhoneController = TextEditingController();
  final _mtnMomoNameController = TextEditingController();
  final _telecelCashPhoneController = TextEditingController();
  final _telecelCashNameController = TextEditingController();
  final _paymentReferenceController = TextEditingController();
  final _emailController = TextEditingController();
  final _amountController = TextEditingController();
  File? _logoFile;
  File? _bannerFile;
  bool _isLoading = false;
  bool _termsAccepted = false;
  bool _acceptsMtnMomo = false;
  bool _acceptsTelecelCash = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _loadUserEmail();
    _amountController.text = '800.00'; // Set default registration fee
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        // Show dialog but keep track of its context
        BuildContext? dialogContext;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            dialogContext = context;
            return AlertDialog(
              title: const Text('Location Required'),
              content: const Text(
                'Your store location is required for registration. '
                'Please enable GPS location services to continue.'
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    // Open location settings
                    await Geolocator.openLocationSettings();
                    
                    // Start checking for GPS to be enabled
                    if (mounted) {
                      _checkGPSStatus(dialogContext);
                    }
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is required to register your store'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        BuildContext? dialogContext;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            dialogContext = context;
            return AlertDialog(
              title: const Text('Location Permission Required'),
              content: const Text(
                'Location permission is required to register your store. '
                'Please enable it in your device settings.'
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await Geolocator.openAppSettings();
                    // Start checking for permission to be granted
                    if (mounted) {
                      _checkPermissionStatus(dialogContext);
                    }
                  },
                  child: const Text('Open Settings'),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _checkGPSStatus(BuildContext? dialogContext) async {
    // Check GPS status every second
    bool isChecking = true;
    while (isChecking && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      
      if (isEnabled) {
        isChecking = false;
        // Close the dialog if it's still showing
        if (dialogContext != null && mounted) {
          Navigator.of(dialogContext).pop();
        }
        // Proceed with location permission check
        if (mounted) {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }
          if (permission == LocationPermission.whileInUse || 
              permission == LocationPermission.always) {
            _getCurrentLocation();
          }
        }
      }
    }
  }

  Future<void> _checkPermissionStatus(BuildContext? dialogContext) async {
    // Check permission status every second
    bool isChecking = true;
    while (isChecking && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      final permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        isChecking = false;
        // Close the dialog if it's still showing
        if (dialogContext != null && mounted) {
          Navigator.of(dialogContext).pop();
        }
        // Proceed with getting location
        if (mounted) {
          _getCurrentLocation();
        }
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _addressController.text = 'Lat: ${position.latitude.toStringAsFixed(6)}, Long: ${position.longitude.toStringAsFixed(6)}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to get location. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _loadUserEmail() async {
    try {
      final user = await ref.read(buyerServiceProvider).getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          _emailController.text = user.email;
        });
      }
    } catch (e) {
      debugPrint('Error loading user email: $e');
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeDescriptionController.dispose();
    _shippingInfoController.dispose();
    _addressController.dispose();
    _mtnMomoPhoneController.dispose();
    _mtnMomoNameController.dispose();
    _telecelCashPhoneController.dispose();
    _telecelCashNameController.dispose();
    _paymentReferenceController.dispose();
    _emailController.dispose();
    _amountController.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms and conditions')),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please get your store location before proceeding'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!_acceptsMtnMomo && !_acceptsTelecelCash) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one payment method')),
      );
      return;
    }

    if (_paymentReferenceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your payment reference')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 800.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid payment amount (minimum GHS 800.00)')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await ref.read(buyerServiceProvider).getCurrentUser();

      // Prepare payment methods
      final acceptedPaymentMethods = <String>[];
      final paymentPhoneNumbers = <String, String>{};
      final paymentNames = <String, String>{};

      if (_acceptsMtnMomo) {
        acceptedPaymentMethods.add('mtn_momo');
        paymentPhoneNumbers['mtn_momo'] = _mtnMomoPhoneController.text;
        paymentNames['mtn_momo'] = _mtnMomoNameController.text;
      }

      if (_acceptsTelecelCash) {
        acceptedPaymentMethods.add('telecel_cash');
        paymentPhoneNumbers['telecel_cash'] = _telecelCashPhoneController.text;
        paymentNames['telecel_cash'] = _telecelCashNameController.text;
      }

      final metadata = {
        'storeName': _storeNameController.text,
        'storeDescription': _storeDescriptionController.text,
        'country': 'Unknown',
        'shippingInfo': _shippingInfoController.text,
        'address': _addressController.text,
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'acceptedPaymentMethods': acceptedPaymentMethods,
        'paymentPhoneNumbers': paymentPhoneNumbers,
        'paymentNames': paymentNames,
        'paymentReference': _paymentReferenceController.text,
        'registrationFee': amount,
      };

      await ref.read(sellerServiceProvider).submitSellerRegistration(
        metadata,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Registration Submitted'),
            content: const Text(
              'Your seller registration has been submitted successfully!\n\n'
              'Please note that it may take up to 6 hours for your store to be activated. '
              'This time is needed to verify your payment and review your store details.\n\n'
              'You can check back later by logging in again to see if your store has been activated.'
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Return to profile screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTermsCard(Map<String, dynamic> term) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: FaIcon(term['icon'] as IconData, color: Theme.of(context).primaryColor),
        title: Text(
          term['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(term['description']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Seller'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Registration Fee Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Registration Fee',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.pink[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.pink[900]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.pink[900],
                                    fontSize: 14,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: 'One-time Registration Fee: ',
                                      style: TextStyle(fontWeight: FontWeight.normal),
                                    ),
                                    TextSpan(
                                      text: 'GHS 800.00',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'To register your store, please follow these steps:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      const Text('1. Send GHS 800.00 to MTN MoMo number:'),
                      Row(
                        children: [
                          Image.asset(
                            'public/mtn.png',
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SelectableText(
                              '0550325188',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(const ClipboardData(text: '0550325188'));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Phone number copied to clipboard')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('2. Copy the transaction ID'),
                      const SizedBox(height: 8),
                      const Text('3. Enter the payment amount and reference below:'),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _amountController,
                        label: 'Payment Amount (GHS)',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the payment amount';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount < 800.0) {
                            return 'Amount must be at least GHS 800.00';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _paymentReferenceController,
                        label: 'Payment Reference',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the payment reference';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Note: Store activation may take up to 6 hours after submission. '
                        'You will need to log in again to access your store once activated.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Seller Terms & Conditions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...SellerTerms.terms.map(_buildTermsCard).toList(),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Store Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),
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
                      CustomTextField(
                        controller: _storeDescriptionController,
                        label: 'Store Description',
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your store description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _addressController,
                        label: 'Store Location',
                        maxLines: 2,
                        readOnly: true,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.gps_fixed),
                          tooltip: 'Get Location',
                          onPressed: _checkLocationPermission,
                        ),
                      ),
                      if (_addressController.text.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Store location is required. Please click the GPS icon to get your location.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shipping & Payment',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 24),
                      const Text(
                        'Payment Methods',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // MTN MoMo
                      CheckboxListTile(
                        value: _acceptsMtnMomo,
                        onChanged: (value) => setState(() => _acceptsMtnMomo = value ?? false),
                        title: Row(
                          children: [
                            Image.asset(
                              'public/mtn.png',
                              width: 40,
                              height: 40,
                            ),
                            const SizedBox(width: 8),
                            const Text('MTN MoMo'),
                          ],
                        ),
                      ),
                      if (_acceptsMtnMomo) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              CustomTextField(
                                controller: _mtnMomoPhoneController,
                                label: 'MTN MoMo Phone Number',
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (_acceptsMtnMomo && (value == null || value.isEmpty)) {
                                    return 'Please enter your MTN MoMo phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: _mtnMomoNameController,
                                label: 'Registered MTN MoMo Name',
                                validator: (value) {
                                  if (_acceptsMtnMomo && (value == null || value.isEmpty)) {
                                    return 'Please enter your registered MTN MoMo name';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Telecel Cash
                      CheckboxListTile(
                        value: _acceptsTelecelCash,
                        onChanged: (value) => setState(() => _acceptsTelecelCash = value ?? false),
                        title: Row(
                          children: [
                            Image.asset(
                              'public/telecel.png',
                              width: 40,
                              height: 40,
                            ),
                            const SizedBox(width: 8),
                            const Text('Telecel Cash'),
                          ],
                        ),
                      ),
                      if (_acceptsTelecelCash) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              CustomTextField(
                                controller: _telecelCashPhoneController,
                                label: 'Telecel Cash Phone Number',
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (_acceptsTelecelCash && (value == null || value.isEmpty)) {
                                    return 'Please enter your Telecel Cash phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: _telecelCashNameController,
                                label: 'Registered Telecel Cash Name',
                                validator: (value) {
                                  if (_acceptsTelecelCash && (value == null || value.isEmpty)) {
                                    return 'Please enter your registered Telecel Cash name';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        value: _termsAccepted,
                        onChanged: (value) => setState(() => _termsAccepted = value ?? false),
                        title: const Text('I accept the terms and conditions'),
                        subtitle: const Text('I understand and agree to follow the platform guidelines'),
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        onPressed: _isLoading ? null : _submit,
                        text: _isLoading ? 'Processing...' : 'Activate Store',
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 