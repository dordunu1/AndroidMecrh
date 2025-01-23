class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final String? imageUrl;
  final String timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    this.imageUrl,
    required this.timestamp,
  });

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? content,
    String? imageUrl,
    String? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      senderId: map['senderId'] as String,
      content: map['content'] as String,
      imageUrl: map['imageUrl'] as String?,
      timestamp: map['timestamp'] as String,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, senderId: $senderId, content: $content, imageUrl: $imageUrl, timestamp: $timestamp)';
  }
} 