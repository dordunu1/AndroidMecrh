class ChatConversation {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String? lastMessage;
  final String? lastMessageTime;
  final Map<String, int> unreadCounts;
  final String createdAt;

  ChatConversation({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.lastMessage,
    this.lastMessageTime,
    required this.unreadCounts,
    required this.createdAt,
  });

  String get otherParticipantId => participants[0];
  String get otherParticipantName => participantNames[otherParticipantId] ?? 'Unknown';

  ChatConversation copyWith({
    String? id,
    List<String>? participants,
    Map<String, String>? participantNames,
    String? lastMessage,
    String? lastMessageTime,
    Map<String, int>? unreadCounts,
    String? createdAt,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      participantNames: participantNames ?? this.participantNames,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime,
      'unreadCounts': unreadCounts,
      'createdAt': createdAt,
    };
  }

  factory ChatConversation.fromMap(Map<String, dynamic> map) {
    return ChatConversation(
      id: map['id'] as String,
      participants: List<String>.from(map['participants'] as List),
      participantNames: Map<String, String>.from(map['participantNames'] as Map),
      lastMessage: map['lastMessage'] as String?,
      lastMessageTime: map['lastMessageTime'] as String?,
      unreadCounts: Map<String, int>.from(map['unreadCounts'] as Map),
      createdAt: map['createdAt'] as String,
    );
  }

  @override
  String toString() {
    return 'ChatConversation(id: $id, participants: $participants, participantNames: $participantNames, lastMessage: $lastMessage, lastMessageTime: $lastMessageTime, unreadCounts: $unreadCounts, createdAt: $createdAt)';
  }
} 