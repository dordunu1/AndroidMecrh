import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'seller_dashboard_screen.dart';
import 'seller_orders_screen.dart';
import 'seller_products_screen.dart';
import 'seller_profile_screen.dart';
import '../chat/chat_inbox_screen.dart';
import '../../providers/chat_providers.dart';

class SellerNavigationScreen extends ConsumerStatefulWidget {
  const SellerNavigationScreen({super.key});

  @override
  ConsumerState<SellerNavigationScreen> createState() => _SellerNavigationScreenState();
}

class _SellerNavigationScreenState extends ConsumerState<SellerNavigationScreen> {
  int _currentIndex = 0;

  final _screens = const [
    SellerDashboardScreen(),
    SellerOrdersScreen(),
    SellerProductsScreen(),
    ChatInboxScreen(),
    SellerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadMessagesCountProvider);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory),
            label: 'Products',
          ),
          NavigationDestination(
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
          const NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
} 