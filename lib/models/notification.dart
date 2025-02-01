import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  orderUpdate,
  message,
  statusUpdate,
  promotion,
}

class Notification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final String? orderId;
  final String? chatId;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.orderId,
    this.chatId,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  factory Notification.fromMap(Map<String, dynamic> map, String id) {
    return Notification(
      id: id,
      userId: map['userId'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${map['type']}',
      ),
      orderId: map['orderId'] as String?,
      chatId: map['chatId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      data: map['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'orderId': orderId,
      'chatId': chatId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'data': data,
    };
  }

  Notification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    String? orderId,
    String? chatId,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? data,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      orderId: orderId ?? this.orderId,
      chatId: chatId ?? this.chatId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
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