import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_dashboard_screen.dart';
import 'seller_verifications_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_refunds_screen.dart';
import 'admin_store_activations_screen.dart';
import '../profile_screen.dart';

class AdminNavigationScreen extends ConsumerStatefulWidget {
  const AdminNavigationScreen({super.key});

  @override
  ConsumerState<AdminNavigationScreen> createState() => _AdminNavigationScreenState();
}

class _AdminNavigationScreenState extends ConsumerState<AdminNavigationScreen> {
  int _currentIndex = 0;

  final _screens = const [
    AdminDashboardScreen(),
    SellerVerificationsScreen(),
    AdminOrdersScreen(),
    AdminRefundsScreen(),
    AdminStoreActivationsScreen(),
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
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user),
            label: 'Verifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.money_off),
            label: 'Refunds',
          ),
          NavigationDestination(
            icon: Icon(Icons.store),
            label: 'Store Activations',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
} 