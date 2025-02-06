import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/notification.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Get user's notification settings
  Future<Map<String, bool>> getNotificationSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('notifications')
          .get();

      if (!doc.exists) {
        // Return default settings
        return {
          'pushNotifications': true,
          'emailNotifications': true,
          'orderUpdates': true,
          'messages': true,
          'statusUpdates': true,
          'promotions': true,
        };
      }

      return {
        'pushNotifications': doc.data()?['pushNotifications'] ?? true,
        'emailNotifications': doc.data()?['emailNotifications'] ?? true,
        'orderUpdates': doc.data()?['orderUpdates'] ?? true,
        'messages': doc.data()?['messages'] ?? true,
        'statusUpdates': doc.data()?['statusUpdates'] ?? true,
        'promotions': doc.data()?['promotions'] ?? true,
      };
    } catch (e) {
      throw Exception('Failed to get notification settings: $e');
    }
  }

  // Update user's notification settings and manage FCM topics
  Future<void> updateNotificationSettings(Map<String, bool> settings) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Update settings in Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('notifications')
          .set(settings, SetOptions(merge: true));

      // Update FCM token if push notifications are enabled/disabled
      if (settings['pushNotifications'] == true) {
        await updateFCMToken();
      } else {
        await deleteFCMToken();
      }
    } catch (e) {
      throw Exception('Failed to update notification settings: $e');
    }
  }

  // Update FCM token
  Future<void> updateFCMToken([String? token]) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tokens')
          .doc('fcm')
          .set({
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update FCM token: $e');
    }
  }

  // Delete FCM token
  Future<void> deleteFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tokens')
          .doc('fcm')
          .delete();
    } catch (e) {
      throw Exception('Failed to delete FCM token: $e');
    }
  }

  // Get user's notifications
  Stream<List<Notification>> watchNotifications() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Notification.fromMap(doc.data(), doc.id))
              .toList();
        });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .get();

      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  // Get unread notifications count
  Stream<int> watchUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
} 