import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/seller.dart';
import '../../services/seller_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/auth_service.dart';
import '../../routes.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/payment_provider.dart';
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
      'title': 'Secure Payments',
      'description': 'Platform holds payments until shipping confirmation. Immediate withdrawal available after shipping.'
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
  final _paymentInfoController = TextEditingController();
  final _addressController = TextEditingController();
  File? _logoFile;
  File? _bannerFile;
  bool _isLoading = false;
  bool _termsAccepted = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled. Please enable them.')),
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
            const SnackBar(content: Text('Location permissions are denied')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied, we cannot request permissions.'),
          ),
        );
      }
      return;
    }

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      setState(() {
        _currentPosition = position;
        _addressController.text = 'Lat: ${position.latitude.toStringAsFixed(6)}, Long: ${position.longitude.toStringAsFixed(6)}';
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeDescriptionController.dispose();
    _shippingInfoController.dispose();
    _paymentInfoController.dispose();
    _addressController.dispose();
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

    setState(() => _isLoading = true);
    try {
      final user = await ref.read(buyerServiceProvider).getCurrentUser();

      // Generate reference
      final reference = DateTime.now().millisecondsSinceEpoch.toString();

      // Initialize payment
      final metadata = {
        'storeName': _storeNameController.text,
        'storeDescription': _storeDescriptionController.text,
        'country': 'Unknown',
        'shippingInfo': _shippingInfoController.text,
        'paymentInfo': _paymentInfoController.text,
        'address': _addressController.text,
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
      };

      final paymentUrl = await ref.read(paymentServiceProvider).initializeTransaction(
        email: user.email,
        amount: 1.0, // GHS 100 seller registration fee
        currency: 'GHS',
        reference: reference,
        metadata: metadata,
      );

      final paymentSuccess = await ref.read(paymentServiceProvider).handlePayment(context, paymentUrl);
      
      if (!mounted) return;

      if (paymentSuccess) {
        final isVerified = await ref.read(paymentServiceProvider).verifyTransaction(reference);
        
        if (isVerified) {
          await ref.read(sellerServiceProvider).verifyPayment(
            reference,
            metadata,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Congratulations! Your seller account is now active.'),
                duration: Duration(seconds: 5),
              ),
            );
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/seller-home',
              (route) => false,
            );
          }
        }
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
                      const SizedBox(height: 16),
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
                    ],
                  ),
                ),
              ),
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
                text: _isLoading ? 'Processing...' : 'Pay Registration Fee (GHS 1)',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
} 