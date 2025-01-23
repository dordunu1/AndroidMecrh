import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
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

class BecomeSellerScreen extends ConsumerStatefulWidget {
  const BecomeSellerScreen({super.key});

  @override
  ConsumerState<BecomeSellerScreen> createState() => _BecomeSellerScreenState();
}

class _BecomeSellerScreenState extends ConsumerState<BecomeSellerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _storeDescriptionController = TextEditingController();
  final _countryController = TextEditingController();
  final _shippingInfoController = TextEditingController();
  final _paymentInfoController = TextEditingController();
  File? _logoFile;
  File? _bannerFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeDescriptionController.dispose();
    _countryController.dispose();
    _shippingInfoController.dispose();
    _paymentInfoController.dispose();
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

    setState(() => _isLoading = true);
    try {
      final user = await ref.read(buyerServiceProvider).getCurrentUser();

      // Generate reference
      final reference = DateTime.now().millisecondsSinceEpoch.toString();

      // Initialize payment
      final paymentUrl = await ref.read(paymentServiceProvider).initializeTransaction(
        email: user.email,
        amount: 1.0, // 1 GHS
        currency: 'GHS',
        reference: reference,
        metadata: {
          'storeName': _storeNameController.text,
          'storeDescription': _storeDescriptionController.text,
          'country': _countryController.text,
          'shippingInfo': _shippingInfoController.text,
          'paymentInfo': _paymentInfoController.text,
        },
      );

      // Launch payment page
      await ref.read(paymentServiceProvider).launchPaymentPage(paymentUrl);

      // Verify payment and create seller profile
      await ref.read(sellerServiceProvider).verifyPayment(reference);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Congratulations! Your seller account is now active.'),
            duration: Duration(seconds: 5),
          ),
        );
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                        controller: _countryController,
                        label: 'Country',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your country';
                          }
                          return null;
                        },
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
              CustomButton(
                onPressed: _isLoading ? null : _submit,
                text: _isLoading ? 'Processing...' : 'Pay Registration Fee (GHS 1)',
              ),
            ],
          ),
        ),
      ),
    );
  }
} 