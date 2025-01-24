import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/buyer/buyer_navigation_screen.dart';
import 'screens/seller/seller_navigation_screen.dart';
import 'screens/admin/admin_navigation_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/buyer/become_seller_screen.dart';
import 'screens/seller/edit_profile_screen.dart';
import 'screens/profile/shipping_addresses_screen.dart';
import 'screens/profile/payment_methods_screen.dart';
import 'screens/profile/notifications_settings_screen.dart';
import 'screens/profile/privacy_policy_screen.dart';
import 'screens/profile/terms_conditions_screen.dart';

class Routes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String buyerHome = '/buyer-home';
  static const String sellerHome = '/seller-home';
  static const String adminHome = '/admin-home';
  static const String becomeSeller = '/become-seller';
  static const String editProfile = '/edit-profile';
  static const String shippingAddresses = '/shipping-addresses';
  static const String paymentMethods = '/payment-methods';
  static const String notificationsSettings = '/notifications-settings';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsConditions = '/terms-conditions';

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
      editProfile: (context) => const EditProfileScreen(),
      shippingAddresses: (context) => const ShippingAddressesScreen(),
      paymentMethods: (context) => const PaymentMethodsScreen(),
      notificationsSettings: (context) => const NotificationsSettingsScreen(),
      privacyPolicy: (context) => const PrivacyPolicyScreen(),
      termsConditions: (context) => const TermsConditionsScreen(),
    };
  }
} 