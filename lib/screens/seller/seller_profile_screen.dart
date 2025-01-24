import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/seller.dart';
import '../../services/seller_service.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_list_tile.dart';
import '../../routes.dart';
import '../../providers/theme_provider.dart';

class SellerProfileScreen extends ConsumerStatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  ConsumerState<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends ConsumerState<SellerProfileScreen> {
  bool _isLoading = true;
  String? _error;
  Seller? _seller;
  String? _sellerStatus;

  @override
  void initState() {
    super.initState();
    _loadSellerProfile();
  }

  Future<void> _loadSellerProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First check seller status
      _sellerStatus = await ref.read(sellerServiceProvider).getSellerStatus();
      
      if (_sellerStatus == null) {
        // Create initial seller profile
        await ref.read(sellerServiceProvider).verifyPayment('', {
          'storeName': 'My Store',
          'storeDescription': '',
          'country': '',
          'shippingInfo': '',
          'paymentInfo': '',
        });
      }

      // Now load the seller profile
      final seller = await ref.read(sellerServiceProvider).getSellerProfile();
      if (mounted) {
        setState(() {
          _seller = seller;
          _isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error message if there's an error
    if (_error != null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Error Loading Profile',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loadSellerProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Retry',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show profile screen if seller profile exists
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: colorScheme.primary,
                    backgroundImage: _seller?.logo != null
                        ? NetworkImage(_seller!.logo!)
                        : null,
                    child: _seller?.logo == null
                        ? Icon(
                            Icons.store,
                            size: 40,
                            color: colorScheme.onPrimary,
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _seller?.storeName ?? 'My Store',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _seller?.email ?? '',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  if (_sellerStatus != null && _sellerStatus != 'approved') ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _sellerStatus == 'pending'
                            ? Colors.orange.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _sellerStatus == 'pending'
                            ? 'Pending Verification'
                            : 'Not Verified',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _sellerStatus == 'pending'
                              ? Colors.orange
                              : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Store Settings Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Store Settings',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            CustomListTile(
              leading: const Icon(Icons.store),
              title: 'Edit Store Profile',
              onTap: () {
                Navigator.pushNamed(context, Routes.editProfile);
              },
            ),
            CustomListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: 'Shipping Information',
              subtitle: Text(
                _seller?.shippingInfo ?? 'Not set',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              onTap: () {
                Navigator.pushNamed(context, Routes.shippingAddresses);
              },
            ),
            CustomListTile(
              leading: const Icon(Icons.payment_outlined),
              title: 'Payment Information',
              subtitle: Text(
                _seller?.paymentInfo ?? 'Not set',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              onTap: () {
                Navigator.pushNamed(context, Routes.paymentMethods);
              },
            ),

            // App Settings Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'App Settings',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            CustomListTile(
              leading: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
              ),
              title: 'Dark Mode',
              trailing: Switch(
                value: isDark,
                onChanged: (value) {
                  ref
                      .read(themeProvider.notifier)
                      .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ),
            CustomListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: 'Notifications',
              onTap: () {
                Navigator.pushNamed(context, Routes.notificationsSettings);
              },
            ),

            // Legal Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Legal',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            CustomListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: 'Privacy Policy',
              onTap: () {
                Navigator.pushNamed(context, Routes.privacyPolicy);
              },
            ),
            CustomListTile(
              leading: const Icon(Icons.description_outlined),
              title: 'Terms & Conditions',
              onTap: () {
                Navigator.pushNamed(context, Routes.termsConditions);
              },
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await ref.read(authServiceProvider).signOut();
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        Routes.login,
                        (route) => false,
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 