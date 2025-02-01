import 'package:cloud_firestore/cloud_firestore.dart';

class Chat {
  final String id;
  final String buyerId;
  final String sellerId;
  final String buyerName;
  final String sellerName;
  final String? buyerPhoto;
  final String? sellerPhoto;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String lastMessageSenderId;
  final bool isRead;
  final String? productId;
  final String? productName;
  final String? productImage;
  final bool isActive;

  Chat({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.buyerName,
    required this.sellerName,
    this.buyerPhoto,
    this.sellerPhoto,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.lastMessageSenderId,
    this.isRead = false,
    this.productId,
    this.productName,
    this.productImage,
    this.isActive = true,
  });

  factory Chat.fromMap(Map<String, dynamic> map, String id) {
    return Chat(
      id: id,
      buyerId: map['buyerId'] ?? '',
      sellerId: map['sellerId'] ?? '',
      buyerName: map['buyerName'] ?? '',
      sellerName: map['sellerName'] ?? '',
      buyerPhoto: map['buyerPhoto'],
      sellerPhoto: map['sellerPhoto'],
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageSenderId: map['lastMessageSenderId'] ?? '',
      isRead: map['isRead'] ?? false,
      productId: map['productId'],
      productName: map['productName'],
      productImage: map['productImage'],
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'sellerId': sellerId,
      'buyerName': buyerName,
      'sellerName': sellerName,
      'buyerPhoto': buyerPhoto,
      'sellerPhoto': sellerPhoto,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'lastMessageSenderId': lastMessageSenderId,
      'isRead': isRead,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'isActive': isActive,
    };
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String message;
  final DateTime timestamp;
  final List<String>? images;
  final bool isRead;
  final String? replyToId;
  final Map<String, dynamic>? replyToMessage;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    required this.timestamp,
    this.images,
    this.isRead = false,
    this.replyToId,
    this.replyToMessage,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      chatId: map['chatId'] ?? '',
      senderId: map['senderId'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      images: map['images'] != null ? List<String>.from(map['images']) : null,
      isRead: map['isRead'] ?? false,
      replyToId: map['replyToId'],
      replyToMessage: map['replyToMessage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'images': images,
      'isRead': isRead,
      'replyToId': replyToId,
      'replyToMessage': replyToMessage,
    };
  }
} 