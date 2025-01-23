import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;
  final String? image;
  final String? action;
  final Map<String, dynamic>? actionData;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    this.isRead = false,
    required this.createdAt,
    this.image,
    this.action,
    this.actionData,
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? '',
      data: map['data'],
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      image: map['image'],
      action: map['action'],
      actionData: map['actionData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'image': image,
      'action': action,
      'actionData': actionData,
    };
  }

  AppNotification copyWith({
    bool? isRead,
  }) {
    return AppNotification(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      data: data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      image: image,
      action: action,
      actionData: actionData,
    );
  }

  static String getNotificationTitle(String type) {
    switch (type) {
      case 'order_placed':
        return 'New Order';
      case 'order_shipped':
        return 'Order Shipped';
      case 'order_delivered':
        return 'Order Delivered';
      case 'order_cancelled':
        return 'Order Cancelled';
      case 'refund_requested':
        return 'Refund Requested';
      case 'refund_approved':
        return 'Refund Approved';
      case 'refund_rejected':
        return 'Refund Rejected';
      case 'new_message':
        return 'New Message';
      case 'store_verified':
        return 'Store Verified';
      case 'store_rejected':
        return 'Store Verification Failed';
      default:
        return 'Notification';
    }
  }
} 