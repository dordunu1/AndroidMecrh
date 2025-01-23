import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/buyer/buyer_navigation_screen.dart';
import 'screens/seller/seller_navigation_screen.dart';
import 'screens/admin/admin_navigation_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/buyer/become_seller_screen.dart';

class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String buyerHome = '/buyer-home';
  static const String sellerHome = '/seller-home';
  static const String adminHome = '/admin-home';
  static const String becomeSeller = '/become-seller';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      forgotPassword: (context) => const ForgotPasswordScreen(),
      buyerHome: (context) => const BuyerNavigationScreen(),
      sellerHome: (context) => const SellerNavigationScreen(),
      adminHome: (context) => const AdminNavigationScreen(),
      becomeSeller: (context) => const BecomeSellerScreen(),
    };
  }
} 