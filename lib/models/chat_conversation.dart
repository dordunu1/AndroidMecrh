import 'package:firebase_auth/firebase_auth.dart';

class ChatConversation {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final Map<String, String?> participantPhotos;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCounts;
  final DateTime createdAt;
  final String? productId;
  final String? productName;

  ChatConversation({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.participantPhotos,
    this.lastMessage,
    this.lastMessageTime,
    required this.unreadCounts,
    required this.createdAt,
    this.productId,
    this.productName,
  });

  String get currentUserId => FirebaseAuth.instance.currentUser!.uid;

  String get otherParticipantId => participants.firstWhere((id) => id != currentUserId);

  String get otherParticipantName => participantNames[otherParticipantId] ?? 'Unknown';

  String? get otherParticipantPhoto => participantPhotos[otherParticipantId];

  int get unreadCount => unreadCounts[currentUserId] ?? 0;

  ChatConversation copyWith({
    String? id,
    List<String>? participants,
    Map<String, String>? participantNames,
    Map<String, String?>? participantPhotos,
    String? lastMessage,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCounts,
    DateTime? createdAt,
    String? productId,
    String? productName,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantNames: participantNames ?? this.participantNames,
      participantPhotos: participantPhotos ?? this.participantPhotos,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      createdAt: createdAt ?? this.createdAt,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'participantNames': participantNames,
      'participantPhotos': participantPhotos,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCounts': unreadCounts,
      'createdAt': createdAt.toIso8601String(),
      'productId': productId,
      'productName': productName,
    };
  }

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      id: map['id'] as String,
      participants: List<String>.from(map['participants'] as List),
      participantNames: Map<String, String>.from(map['participantNames'] as Map),
      participantPhotos: map['participantPhotos'] != null 
          ? Map<String, String?>.from(map['participantPhotos'] as Map)
          : {},
      lastMessage: map['lastMessage'] as String?,
      lastMessageTime: map['lastMessageTime'] != null
          ? DateTime.parse(map['lastMessageTime'] as String)
          : null,
      unreadCounts: Map<String, int>.from(map['unreadCounts'] as Map),
      createdAt: DateTime.parse(map['createdAt'] as String),
      productId: map['productId'] as String?,
      productName: map['productName'] as String?,
    );
  }

  @override
  String toString() {
    return 'ChatConversation(id: $id, participants: $participants, participantNames: $participantNames, participantPhotos: $participantPhotos, lastMessage: $lastMessage, lastMessageTime: $lastMessageTime, unreadCounts: $unreadCounts, createdAt: $createdAt, productId: $productId, productName: $productName)';
  }
} 