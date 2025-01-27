import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/buyer/buyer_navigation_screen.dart';
import 'screens/seller/seller_navigation_screen.dart';
import 'screens/admin/admin_navigation_screen.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: ".env");
  
  runApp(
    const ProviderScope(
      child: MerchApp(),
    ),
  );
}

class MerchApp extends ConsumerWidget {
  const MerchApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authStateProvider);

    return ProviderScope(
      child: MaterialApp(
        title: 'Merch Store',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        darkTheme: AppTheme.darkTheme(),
        themeMode: ThemeMode.light,
        initialRoute: Routes.splash,
        routes: Routes.getRoutes(),
      ),
    );
  }
} 