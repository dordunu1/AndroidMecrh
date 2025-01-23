import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_list_screen.dart';
import 'buyer_orders_screen.dart';
import 'buyer_refunds_screen.dart';
import '../profile/profile_screen.dart';

class BuyerNavigationScreen extends ConsumerStatefulWidget {
  const BuyerNavigationScreen({super.key});

  @override
  ConsumerState<BuyerNavigationScreen> createState() =>
      _BuyerNavigationScreenState();
}

class _BuyerNavigationScreenState extends ConsumerState<BuyerNavigationScreen> {
  int _currentIndex = 0;

  final _screens = const [
    ProductListScreen(),
    BuyerOrdersScreen(),
    BuyerRefundsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            selectedIcon: Icon(Icons.shopping_bag),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_return_outlined),
            selectedIcon: Icon(Icons.assignment_return),
            label: 'Refunds',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
} 