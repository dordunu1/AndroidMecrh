import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService();
});

class MessagingService {
  final _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Request notification permissions
    if (Platform.isIOS) {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } else {
      // For Android
      final status = await Permission.notification.request();
      if (status.isDenied) {
        // Handle denied permissions
        return;
      }
    }

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app was terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    _initialized = true;
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.notification?.title}');
    // The notification will be handled automatically by Firebase Messaging
    // with the settings from AndroidManifest.xml
  }

  void _handleMessage(RemoteMessage message) {
    print('Handling message tap: ${message.notification?.title}');
    // Handle navigation based on message data
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  // Test function to verify FCM is working
  Future<bool> testNotification() async {
    try {
      // Request permission first
      if (Platform.isIOS) {
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        if (settings.authorizationStatus != AuthorizationStatus.authorized) {
          return false;
        }
      } else {
        final status = await Permission.notification.request();
        if (status.isDenied) {
          return false;
        }
      }

      // Get the token
      final token = await getToken();
      if (token == null) {
        print('Failed to get FCM token');
        return false;
      }
      print('FCM Token: $token');

      return true;
    } catch (e) {
      print('Error testing notification: $e');
      return false;
    }
  }
}

// This needs to be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  print('Received background message: ${message.notification?.title}');
} 