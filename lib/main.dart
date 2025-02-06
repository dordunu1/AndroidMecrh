import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'services/messaging_service.dart';
import 'services/notification_service.dart';
import 'routes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // Web-specific Firebase initialization
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDPxnrmBdz3z9QsiNEhbQ1zitXVBVLApYQ",
        authDomain: "androind-merch.firebaseapp.com",
        projectId: "androind-merch",
        storageBucket: "androind-merch.firebasestorage.app",
        messagingSenderId: "984904295859",
        appId: "1:984904295859:web:dc1736ac3a7b520ed157c6",
        measurementId: "G-F6M0GV6HQL",
      ),
    );

    // Web-specific notification handling
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Request permission and get token
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        String? token = await messaging.getToken(
          vapidKey: 'BAMS2lCtry6mKr9mQB28zCsE9lYcmAuVHL7Tcilf7KlV6m1jzUg27j1Xqnz7q_nwd1JONU_UZ6CMphr2ZOjp_ME', // You need to add your VAPID key here
        );
        print('FCM Token: $token');

        // Listen for token refresh
        messaging.onTokenRefresh.listen((token) {
          print('FCM Token refreshed: $token');
          // Update token in your backend if needed
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          print("Received foreground message: ${message.notification?.title}");
        });

        // Handle message clicks when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          print("Message clicked: ${message.notification?.title}");
        });
      }
    } catch (e) {
      print('Error setting up web notifications: $e');
    }
  } else {
    // Mobile Firebase initialization - uses google-services.json automatically
    await Firebase.initializeApp();
    
    // Mobile-specific notification setup
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Configure FCM for background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Received foreground message: ${message.notification?.title}");
    });
  }

  await dotenv.load(fileName: ".env");
  
  runApp(
    const ProviderScope(
      child: MerchApp(),
    ),
  );
}

// Define the background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

class MerchApp extends ConsumerStatefulWidget {
  const MerchApp({super.key});

  @override
  ConsumerState<MerchApp> createState() => _MerchAppState();
}

class _MerchAppState extends ConsumerState<MerchApp> {
  @override
  void initState() {
    super.initState();
    _initializeMessaging();
  }

  Future<void> _initializeMessaging() async {
    final messagingService = ref.read(messagingServiceProvider);
    await messagingService.initialize();

    // Get FCM token and update in Firestore
    final token = await messagingService.getToken();
    if (token != null) {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.updateFCMToken(token);
    }

    // Subscribe to topics based on user role
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _updateUserTopics(user);
      }
    });
  }

  Future<void> _updateUserTopics(User user) async {
    final messagingService = ref.read(messagingServiceProvider);
    
    // Subscribe to user-specific topic
    await messagingService.subscribeToTopic('user_${user.uid}');
    
    // Check user roles and subscribe to appropriate topics
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    
    if (userDoc.exists) {
      final userData = userDoc.data();
      if (userData != null) {
        // Subscribe to seller topic if user is a seller
        if (await _isSeller(user.uid)) {
          await messagingService.subscribeToTopic('sellers');
        }
        
        // Subscribe to admin topic if user is an admin
        if (userData['isAdmin'] == true) {
          await messagingService.subscribeToTopic('admins');
        }
      }
    }
  }

  Future<bool> _isSeller(String uid) async {
    final sellerDoc = await FirebaseFirestore.instance
        .collection('sellers')
        .doc(uid)
        .get();
    return sellerDoc.exists;
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Merch Store',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.light,
      initialRoute: Routes.splash,
      routes: Routes.getRoutes(),
      onGenerateRoute: Routes.generateRoute,
    );
  }
} 