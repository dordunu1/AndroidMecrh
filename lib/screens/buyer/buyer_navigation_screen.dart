import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'product_list_screen.dart';
import 'buyer_orders_screen.dart';
import 'buyer_refunds_screen.dart';
import '../profile/profile_screen.dart';
import 'cart_screen.dart';
import '../chat/chat_inbox_screen.dart';
import '../../widgets/seller_promotion_bubble.dart';
import '../../widgets/feature_tour.dart';
import '../../providers/chat_providers.dart';

class BuyerNavigationScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  
  const BuyerNavigationScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<BuyerNavigationScreen> createState() => _BuyerNavigationScreenState();
}

class _BuyerNavigationScreenState extends ConsumerState<BuyerNavigationScreen> {
  late int _selectedIndex;
  bool _showFeatureTour = false;
  final List<GlobalKey> _navigationKeys = List.generate(6, (_) => GlobalKey());

  final _screens = const [
    ProductListScreen(),
    CartScreen(),
    BuyerOrdersScreen(),
    BuyerRefundsScreen(),
    ChatInboxScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstTime = prefs.getBool('is_first_time') ?? true;
    
    if (isFirstTime) {
      if (mounted) {
        setState(() => _showFeatureTour = true);
      }
      await prefs.setBool('is_first_time', false);
    }
  }

  List<FeatureTourStep> _getFeatureTourSteps() {
    return [
      FeatureTourStep(
        title: 'Browse Products',
        description: 'Explore our wide range of merchandise and find what you love.',
        targetKey: _navigationKeys[0],
      ),
      FeatureTourStep(
        title: 'Shopping Cart',
        description: 'View and manage items you want to purchase.',
        targetKey: _navigationKeys[1],
      ),
      FeatureTourStep(
        title: 'Your Orders',
        description: 'Track and manage all your orders in one place.',
        targetKey: _navigationKeys[2],
      ),
      FeatureTourStep(
        title: 'Refunds',
        description: 'Request and track refunds for your orders.',
        targetKey: _navigationKeys[3],
      ),
      FeatureTourStep(
        title: 'Messages',
        description: 'Chat with sellers about products and orders.',
        targetKey: _navigationKeys[4],
      ),
      FeatureTourStep(
        title: 'Profile',
        description: 'Manage your account settings and preferences.',
        targetKey: _navigationKeys[5],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadMessagesCountProvider);
    
    return Stack(
      children: [
        Scaffold(
          body: IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: [
              NavigationDestination(
                key: _navigationKeys[0],
                icon: const Icon(Icons.shopping_bag_outlined),
                selectedIcon: const Icon(Icons.shopping_bag),
                label: 'Shop',
              ),
              NavigationDestination(
                key: _navigationKeys[1],
                icon: const Icon(Icons.shopping_cart_outlined),
                selectedIcon: const Icon(Icons.shopping_cart),
                label: 'Cart',
              ),
              NavigationDestination(
                key: _navigationKeys[2],
                icon: const Icon(Icons.local_shipping_outlined),
                selectedIcon: const Icon(Icons.local_shipping),
                label: 'Orders',
              ),
              NavigationDestination(
                key: _navigationKeys[3],
                icon: const Icon(Icons.assignment_return_outlined),
                selectedIcon: const Icon(Icons.assignment_return),
                label: 'Refunds',
              ),
              NavigationDestination(
                key: _navigationKeys[4],
                icon: Badge(
                  isLabelVisible: unreadCount.when(
                    data: (count) => count > 0,
                    loading: () => false,
                    error: (_, __) => false,
                  ),
                  label: unreadCount.when(
                    data: (count) => Text('$count'),
                    loading: () => null,
                    error: (_, __) => null,
                  ),
                  child: const Icon(Icons.chat_bubble_outline),
                ),
                selectedIcon: Badge(
                  isLabelVisible: unreadCount.when(
                    data: (count) => count > 0,
                    loading: () => false,
                    error: (_, __) => false,
                  ),
                  label: unreadCount.when(
                    data: (count) => Text('$count'),
                    loading: () => null,
                    error: (_, __) => null,
                  ),
                  child: const Icon(Icons.chat_bubble),
                ),
                label: 'Messages',
              ),
              NavigationDestination(
                key: _navigationKeys[5],
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
        
        // Seller Promotion Bubble
        const SellerPromotionBubble(),

        // Feature Tour
        if (_showFeatureTour)
          FeatureTour(
            steps: _getFeatureTourSteps(),
            onComplete: () {
              setState(() => _showFeatureTour = false);
            },
          ),
      ],
    );
  }
} 