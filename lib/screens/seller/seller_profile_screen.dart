import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  bool _isFollowing = false;

  final Map<String, double> _shippingFees = {
    'Accra': 15.0,
    'Kumasi': 20.0,
    'Tamale': 25.0,
    'Cape Coast': 20.0,
    'Takoradi': 22.0,
    'Ho': 23.0,
    'Koforidua': 18.0,
    'Sunyani': 24.0,
    'Wa': 28.0,
    'Bolgatanga': 30.0,
  };

  void _showShippingFeesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.local_shipping,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('Delivery Fee Info'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery fees are calculated as follows:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 16),
              const ListTile(
                leading: Icon(Icons.public),
                title: Text('International Shipping'),
                subtitle: Text('GHS 250.00 for stores outside Ghana'),
                minLeadingWidth: 0,
              ),
              const ListTile(
                leading: Icon(Icons.location_city),
                title: Text('Local Shipping'),
                subtitle: Text('Same city: GHS 50.00\nDifferent cities (e.g., Accra to Kumasi): GHS 70.00'),
                minLeadingWidth: 0,
              ),
              const ListTile(
                leading: Icon(Icons.shopping_cart),
                title: Text('Quantity Based'),
                subtitle: Text('Orders with more than 5 items:\nAdditional GHS 30.00 fee'),
                minLeadingWidth: 0,
              ),
              const SizedBox(height: 16),
              const Text(
                'Note: Base fee applies for orders with 1-5 items.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

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
      final seller = await ref.read(sellerServiceProvider).getSellerProfile();
      final status = await ref.read(sellerServiceProvider).getSellerStatus();
      final currentUser = await ref.read(authServiceProvider).getCurrentUser();
      
      print('Loaded seller data:');
      print('Average Rating: ${seller.averageRating}');
      print('Review Count: ${seller.reviewCount}');
      
      if (mounted) {
        setState(() {
          _seller = seller;
          _sellerStatus = status;
          _isFollowing = seller.followers.contains(currentUser?.id);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading seller profile: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    try {
      setState(() => _isLoading = true);
      
      if (_isFollowing) {
        await ref.read(sellerServiceProvider).unfollowSeller(_seller!.id);
      } else {
        await ref.read(sellerServiceProvider).followSeller(_seller!.id);
      }

      await _loadSellerProfile();
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

  Future<void> _openMap() async {
    if (_seller?.latitude == null || _seller?.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store location is not available')),
      );
      return;
    }

    final url = 'https://www.google.com/maps/search/?api=1&query=${_seller!.latitude},${_seller!.longitude}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open map')),
        );
      }
    }
  }

  Widget _buildProfileHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Profile Info Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 45,
                  backgroundColor: colorScheme.onPrimary,
                  backgroundImage: _seller?.logo != null
                      ? NetworkImage(_seller!.logo!)
                      : null,
                  child: _seller?.logo == null
                      ? Icon(
                          Icons.store,
                          size: 40,
                          color: colorScheme.primary,
                        )
                      : null,
                ),
                const SizedBox(height: 12),

                // Store Name and Email
                Text(
                  _seller?.storeName ?? '',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _seller?.email ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Social Media Icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_seller?.whatsappNumber != null)
                      IconButton(
                        icon: const Icon(FontAwesomeIcons.whatsapp, size: 22),
                        onPressed: () => _launchWhatsApp(_seller!.whatsappNumber!),
                        color: colorScheme.onPrimary,
                      )
                    else
                      Icon(FontAwesomeIcons.whatsapp, 
                        size: 22, 
                        color: colorScheme.onPrimary.withOpacity(0.5)
                      ),
                    const SizedBox(width: 16),
                    if (_seller?.instagramHandle != null)
                      IconButton(
                        icon: const Icon(FontAwesomeIcons.instagram, size: 22),
                        onPressed: () => _launchInstagram(_seller!.instagramHandle!),
                        color: colorScheme.onPrimary,
                      )
                    else
                      Icon(FontAwesomeIcons.instagram, 
                        size: 22, 
                        color: colorScheme.onPrimary.withOpacity(0.5)
                      ),
                    const SizedBox(width: 16),
                    if (_seller?.tiktokHandle != null)
                      IconButton(
                        icon: const Icon(FontAwesomeIcons.tiktok, size: 22),
                        onPressed: () => _launchTiktok(_seller!.tiktokHandle!),
                        color: colorScheme.onPrimary,
                      )
                    else
                      Icon(FontAwesomeIcons.tiktok, 
                        size: 22, 
                        color: colorScheme.onPrimary.withOpacity(0.5)
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Stats Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.onPrimary.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  Icons.star,
                  _seller?.averageRating != null ? _seller!.averageRating.toStringAsFixed(1) : '0.0',
                  'Rating',
                ),
                _buildStatItem(
                  Icons.reviews,
                  '${_seller?.reviewCount ?? 0}',
                  'Reviews',
                ),
                _buildStatItem(
                  FontAwesomeIcons.users,
                  '${_seller?.followersCount ?? 0}',
                  'Followers',
                ),
                if (_seller?.latitude != null)
                  IconButton(
                    icon: Icon(Icons.location_on, 
                      color: colorScheme.onPrimary,
                    ),
                    onPressed: _openMap,
                    tooltip: 'Open in Maps',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    final theme = Theme.of(context);
    
    if (label == 'Rating') {
      final rating = double.tryParse(value) ?? 0.0;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final starValue = index + 1;
              if (starValue <= rating) {
                return Icon(Icons.star, size: 16, color: theme.colorScheme.onPrimary);
              } else if (starValue - rating < 1 && starValue - rating > 0) {
                return Icon(Icons.star_half, size: 16, color: theme.colorScheme.onPrimary);
              } else {
                return Icon(Icons.star_border, size: 16, color: theme.colorScheme.onPrimary);
              }
            }),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Rating',
            style: TextStyle(
              color: theme.colorScheme.onPrimary.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onPrimary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onPrimary.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodItem(String method) {
    final theme = Theme.of(context);
    final name = _seller?.paymentNames?[method] ?? '';
    final phone = _seller?.paymentPhoneNumbers?[method] ?? '';
    
    String logoPath = '';
    String displayName = '';
    
    switch (method) {
      case 'mtn_momo':
        logoPath = 'public/mtn.png';
        displayName = 'MTN MoMo';
        break;
      case 'telecel_cash':
        logoPath = 'public/telecel.png';
        displayName = 'Telecel Cash';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Image.asset(
            logoPath,
            width: 40,
            height: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (name.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    if (_seller?.acceptedPaymentMethods == null || _seller!.acceptedPaymentMethods.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment Methods',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._seller!.acceptedPaymentMethods.map(_buildPaymentMethodItem),
          ],
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp(String number) async {
    final url = 'https://wa.me/$number';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  Future<void> _launchInstagram(String handle) async {
    final url = 'https://instagram.com/$handle';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Instagram')),
        );
      }
    }
  }

  Future<void> _launchTiktok(String handle) async {
    final url = 'https://tiktok.com/@$handle';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open TikTok')),
        );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(
              context,
              Routes.editSellerProfile,
            ).then((_) => _loadSellerProfile()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSellerProfile,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildProfileHeader(),
              ),

              if (_seller?.description?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _seller?.description ?? '',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Payment Methods Section
              if (_seller?.acceptedPaymentMethods.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildPaymentSection(),
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
                onTap: () async {
                  await Navigator.pushNamed(context, Routes.editSellerProfile);
                  _loadSellerProfile(); // Refresh profile when returning
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
              ),
              CustomListTile(
                leading: const Icon(Icons.local_shipping),
                title: 'Delivery Information',
                trailing: IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  onPressed: _showShippingFeesDialog,
                  tooltip: 'View delivery fee information',
                ),
                subtitle: const Text('Click the info icon to view delivery details'),
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
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
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
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    minimumSize: const Size(double.infinity, 54),
                  ),
                  icon: const Icon(
                    Icons.logout,
                    size: 24,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'LOGOUT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Only show follow button if not the seller's own profile
              if (_seller?.userId != ref.read(authServiceProvider).currentUser?.uid)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(_isFollowing ? 'Unfollow' : 'Follow'),
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