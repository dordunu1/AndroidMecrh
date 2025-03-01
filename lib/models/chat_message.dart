class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final String? imageUrl;
  final DateTime timestamp;
  final bool? isEdited;
  final DateTime? editedAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    this.imageUrl,
    required this.timestamp,
    this.isEdited,
    this.editedAt,
  });

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? content,
    String? imageUrl,
    DateTime? timestamp,
    bool? isEdited,
    DateTime? editedAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'isEdited': isEdited,
      'editedAt': editedAt?.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      content: map['content'] as String,
      imageUrl: map['imageUrl'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isEdited: map['isEdited'] as bool?,
      editedAt: map['editedAt'] != null ? DateTime.parse(map['editedAt'] as String) : null,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, senderId: $senderId, content: $content, imageUrl: $imageUrl, timestamp: $timestamp, isEdited: $isEdited, editedAt: $editedAt)';
  }
} 