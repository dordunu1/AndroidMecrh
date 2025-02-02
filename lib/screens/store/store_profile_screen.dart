import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/seller.dart';
import '../../models/product.dart';
import '../../services/seller_service.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/common/cached_image.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/product/product_card.dart';

class StoreProfileScreen extends ConsumerStatefulWidget {
  final String sellerId;

  const StoreProfileScreen({
    super.key,
    required this.sellerId,
  });

  @override
  ConsumerState<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends ConsumerState<StoreProfileScreen> {
  bool _isLoading = true;
  String? _error;
  Seller? _seller;
  List<Product> _products = [];
  bool _isFollowing = false;
  bool _isLoadingAction = false;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final seller = await ref.read(sellerServiceProvider).getSellerProfileById(widget.sellerId);
      if (seller == null) throw Exception('Store not found');

      final products = await ref.read(productServiceProvider).getSellerProducts(widget.sellerId);
      final currentUser = await ref.read(authServiceProvider).getCurrentUser();

      // Calculate total sold products from all products
      final totalSold = products.fold(0, (sum, product) => sum + (product.soldCount ?? 0));

      if (mounted) {
        setState(() {
          _seller = seller.copyWith(totalSoldProducts: totalSold);
          _products = products;
          _isFollowing = seller.followers.contains(currentUser?.id);
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

  Future<void> _toggleFollow() async {
    if (_seller == null) return;

    setState(() => _isLoadingAction = true);

    try {
      if (_isFollowing) {
        await ref.read(sellerServiceProvider).unfollowSeller(_seller!.id);
      } else {
        await ref.read(sellerServiceProvider).followSeller(_seller!.id);
      }

      setState(() {
        _isFollowing = !_isFollowing;
        _isLoadingAction = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
      setState(() => _isLoadingAction = false);
    }
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Widget _buildSocialLinks() {
    if (_seller == null) return const SizedBox.shrink();

    return Wrap(
      spacing: 16,
      children: [
        if (_seller!.whatsappNumber != null)
          IconButton(
            onPressed: () => _launchUrl('https://wa.me/${_seller!.whatsappNumber}'),
            icon: const FaIcon(FontAwesomeIcons.whatsapp),
            color: Colors.green,
          ),
        if (_seller!.instagramHandle != null)
          IconButton(
            onPressed: () => _launchUrl('https://instagram.com/${_seller!.instagramHandle}'),
            icon: const FaIcon(FontAwesomeIcons.instagram),
            color: Colors.purple,
          ),
        if (_seller!.tiktokHandle != null)
          IconButton(
            onPressed: () => _launchUrl('https://tiktok.com/@${_seller!.tiktokHandle}'),
            icon: const FaIcon(FontAwesomeIcons.tiktok),
            color: Colors.black,
          ),
      ],
    );
  }

  Widget _buildStoreHeader() {
    final theme = Theme.of(context);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE91E63),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: _seller?.logo != null
                      ? ClipOval(
                          child: CachedImage(
                            imageUrl: _seller!.logo!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.store,
                          size: 40,
                          color: Color(0xFFE91E63),
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  _seller?.storeName ?? '',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_seller?.email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _seller!.email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                // Follow Button
                SizedBox(
                  width: 150,
                  height: 40,
                  child: ElevatedButton(
                    onPressed: _isLoadingAction ? null : _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFollowing ? Colors.transparent : Colors.white,
                      foregroundColor: _isFollowing ? Colors.white : const Color(0xFFE91E63),
                      elevation: 0,
                      side: _isFollowing ? const BorderSide(color: Colors.white, width: 1.5) : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: _isLoadingAction
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isFollowing ? Icons.check_circle : Icons.add_circle_outline,
                                size: 20,
                                color: _isFollowing ? Colors.white : const Color(0xFFE91E63),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isFollowing ? 'Following' : 'Follow',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_seller?.whatsappNumber != null)
                      IconButton(
                        onPressed: () => _launchUrl('https://wa.me/${_seller!.whatsappNumber}'),
                        icon: const Icon(FontAwesomeIcons.whatsapp),
                        color: Colors.white,
                      ),
                    if (_seller?.instagramHandle != null)
                      IconButton(
                        onPressed: () => _launchUrl('https://instagram.com/${_seller!.instagramHandle}'),
                        icon: const Icon(FontAwesomeIcons.instagram),
                        color: Colors.white,
                      ),
                    if (_seller?.tiktokHandle != null)
                      IconButton(
                        onPressed: () => _launchUrl('https://tiktok.com/@${_seller!.tiktokHandle}'),
                        icon: const Icon(FontAwesomeIcons.tiktok),
                        color: Colors.white,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat(
                  _seller?.averageRating.toStringAsFixed(1) ?? '0.0',
                  'Rating',
                  icon: Icons.star,
                ),
                _buildStat(
                  '${_seller?.reviewCount ?? 0}',
                  'Reviews',
                  icon: Icons.rate_review_outlined,
                ),
                _buildStat(
                  '${_seller?.followersCount ?? 0}',
                  'Followers',
                  icon: Icons.people_outline,
                ),
                if (_seller?.city != null)
                  InkWell(
                    onTap: () async {
                      final address = Uri.encodeComponent(
                        [_seller?.address, _seller?.city, _seller?.state, _seller?.country]
                            .where((e) => e != null)
                            .join(', '),
                      );
                      final url = 'https://www.google.com/maps/search/?api=1&query=$address';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                    child: _buildStat(
                      _seller!.city,
                      'Location',
                      icon: Icons.location_on_outlined,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, {IconData? icon}) {
    return Column(
      children: [
        if (icon != null)
          Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_seller?.description?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(_seller!.description!),
            ],
            const SizedBox(height: 24),
            Text(
              'Payment Methods',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment Methods Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_seller?.acceptedPaymentMethods.isNotEmpty ?? false)
                        ..._seller!.acceptedPaymentMethods.map((method) {
                          String logoPath = '';
                          String label = '';
                          String? number;
                          String? name;
                          
                          switch (method) {
                            case 'mtn_momo':
                              logoPath = 'public/mtn.png';
                              label = 'MTN Mobile Money';
                              number = _seller?.paymentPhoneNumbers['mtn_momo'];
                              name = _seller?.paymentNames['mtn_momo'];
                              break;
                            case 'telecel_cash':
                              logoPath = 'public/telecel.png';
                              label = 'Telecel Cash';
                              number = _seller?.paymentPhoneNumbers['telecel_cash'];
                              name = _seller?.paymentNames['telecel_cash'];
                              break;
                            default:
                              return const SizedBox.shrink();
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Image.asset(
                                  logoPath,
                                  height: 40,
                                  width: 40,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        label,
                                        style: theme.textTheme.titleSmall,
                                      ),
                                      if (name != null)
                                        Text(
                                          name,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      if (number != null)
                                        Text(
                                          number,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
                // Contact Information Column
                if (_seller?.phone != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contact Information',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 24,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Phone Number',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  Text(
                                    _seller!.phone,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  '${_products.length}',
                  'Total Products',
                  icon: Icons.shopping_bag_outlined,
                ),
                _buildDivider(),
                _buildStatItem(
                  '${_seller?.totalSoldProducts ?? 0}',
                  'Products Sold',
                  icon: Icons.sell_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Text(_error!),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_seller?.storeName ?? 'Store Profile'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadStoreData,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildStoreHeader(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildAboutSection(),
              ),
              const SizedBox(height: 16),
              _buildProductsGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductsGrid() {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Products',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all products screen
                },
                child: const Text('See All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_products.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No products available',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = (constraints.maxWidth / 180).floor();
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return ProductCard(product: product);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildStoreStats() {
    final theme = Theme.of(context);
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem(
          '${_seller?.followersCount ?? 0}',
          'Followers',
        ),
        _buildDivider(),
        _buildStatItem(
          _seller?.averageRating.toStringAsFixed(1) ?? '0.0',
          'Rating',
          icon: Icons.star,
          iconColor: Colors.amber,
        ),
        _buildDivider(),
        _buildStatItem(
          '${_products.length}',
          'Products',
          icon: Icons.shopping_bag_outlined,
        ),
        _buildDivider(),
        _buildStatItem(
          '${_seller?.totalSoldProducts ?? 0}',
          'Sold',
          icon: Icons.sell_outlined,
        ),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, {IconData? icon, Color? iconColor}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        if (icon != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: iconColor ?? theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          )
        else
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
    );
  }

  Widget _buildPaymentMethods() {
    if (_seller?.acceptedPaymentMethods.isEmpty ?? true) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _seller!.acceptedPaymentMethods.map((method) {
        String logoPath = '';
        String label = '';
        switch (method) {
          case 'mtn_momo':
            logoPath = 'public/mtn.png';
            label = 'MTN Mobile Money';
            break;
          case 'telecel_cash':
            logoPath = 'public/telecel.png';
            label = 'Telecel Cash';
            break;
          default:
            return const SizedBox.shrink();
        }
        return Column(
          children: [
            Image.asset(
              logoPath,
              height: 40,
              width: 40,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }
} 