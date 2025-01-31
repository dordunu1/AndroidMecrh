import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(
    FirebaseFirestore.instance,
    FirebaseAuth.instance,
  );
});

class ChatService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ChatService(this._firestore, this._auth);

  Future<List<ChatConversation>> getConversations({String? search}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      Query query = _firestore.collection('conversations').where(
        'participants',
        arrayContains: user.uid,
      );

      final snapshot = await query.get();

      final conversations = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ChatConversation.fromMap(data);
      }).toList();

      if (search != null && search.isNotEmpty) {
        final searchLower = search.toLowerCase();
        return conversations.where((conversation) {
          return conversation.otherParticipantName.toLowerCase().contains(searchLower);
        }).toList();
      }

      return conversations;
    } catch (e) {
      throw Exception('Failed to get conversations: $e');
    }
  }

  Stream<List<ChatConversation>> watchConversations() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return ChatConversation.fromMap(data);
      }).toList();
    });
  }

  Future<String> createOrGetConversation(String sellerId, String productId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if conversation already exists for this product
      final existingConversation = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: user.uid)
          .where('productId', isEqualTo: productId)
          .get();

      if (existingConversation.docs.isNotEmpty) {
        return existingConversation.docs.first.id;
      }

      // Get seller info
      final sellerDoc = await _firestore.collection('sellers').doc(sellerId).get();
      if (!sellerDoc.exists) throw Exception('Seller not found');
      final sellerName = sellerDoc.data()!['storeName'] as String? ?? 'Unknown Store';

      // Get product info
      final productDoc = await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) throw Exception('Product not found');
      final productName = productDoc.data()!['name'] as String;

      // Create new conversation
      final conversationRef = _firestore.collection('conversations').doc();
      final conversation = {
        'participants': [user.uid, sellerId],
        'participantNames': {
          user.uid: user.displayName ?? 'Unknown',
          sellerId: sellerName,
        },
        'productId': productId,
        'productName': productName,
        'lastMessage': null,
        'lastMessageTime': null,
        'unreadCounts': {
          user.uid: 0,
          sellerId: 0,
        },
        'createdAt': DateTime.now().toIso8601String(),
      };

      await conversationRef.set(conversation);
      return conversationRef.id;
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  Stream<List<ChatMessage>> watchMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ChatMessage.fromMap(data);
      }).toList();
    });
  }

  Future<void> sendMessage({
    required String conversationId,
    required String content,
    String? imageUrl,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final conversationRef = _firestore.collection('conversations').doc(conversationId);
      final conversation = await conversationRef.get();
      if (!conversation.exists) throw Exception('Conversation not found');

      final participants = List<String>.from(conversation.data()!['participants'] as List);
      final otherUserId = participants.firstWhere((id) => id != user.uid);

      final batch = _firestore.batch();

      // Add message
      final messageRef = conversationRef.collection('messages').doc();
      batch.set(messageRef, {
        'senderId': user.uid,
        'content': content,
        'imageUrl': imageUrl,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Update conversation
      final unreadCounts = Map<String, int>.from(conversation.data()!['unreadCounts'] as Map);
      unreadCounts[otherUserId] = (unreadCounts[otherUserId] ?? 0) + 1;

      batch.update(conversationRef, {
        'lastMessage': content,
        'lastMessageTime': DateTime.now().toIso8601String(),
        'unreadCounts': unreadCounts,
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> markAsRead(String conversationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final conversationRef = _firestore.collection('conversations').doc(conversationId);
      final conversation = await conversationRef.get();
      if (!conversation.exists) throw Exception('Conversation not found');

      final unreadCounts = Map<String, int>.from(conversation.data()!['unreadCounts'] as Map);
      unreadCounts[user.uid] = 0;

      await conversationRef.update({
        'unreadCounts': unreadCounts,
      });
    } catch (e) {
      throw Exception('Failed to mark conversation as read: $e');
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final conversationRef = _firestore.collection('conversations').doc(conversationId);
      final conversation = await conversationRef.get();
      if (!conversation.exists) throw Exception('Conversation not found');

      final participants = List<String>.from(conversation.data()!['participants'] as List);
      if (!participants.contains(user.uid)) {
        throw Exception('Not authorized to delete this conversation');
      }

      // Delete all messages
      final messages = await conversationRef.collection('messages').get();
      final batch = _firestore.batch();
      for (final message in messages.docs) {
        batch.delete(message.reference);
      }

      // Delete conversation
      batch.delete(conversationRef);

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  Stream<int> watchTotalUnreadCount() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;
      for (var doc in snapshot.docs) {
        final unreadCounts = Map<String, int>.from(doc.data()['unreadCounts'] as Map);
        totalUnread += unreadCounts[user.uid] ?? 0;
      }
      return totalUnread;
    });
  }

  Future<void> editMessage({
    required String conversationId,
    required String messageId,
    required String newContent,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final messageRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId);

      final message = await messageRef.get();
      if (!message.exists) throw Exception('Message not found');

      // Verify the message belongs to the current user
      if (message.data()?['senderId'] != user.uid) {
        throw Exception('Not authorized to edit this message');
      }

      await messageRef.update({
        'content': newContent,
        'isEdited': true,
        'editedAt': DateTime.now().toIso8601String(),
      });

      // Update conversation's last message if this was the last message
      final conversationRef = _firestore.collection('conversations').doc(conversationId);
      final conversation = await conversationRef.get();
      
      if (conversation.data()?['lastMessage'] == message.data()?['content']) {
        await conversationRef.update({
          'lastMessage': newContent,
        });
      }
    } catch (e) {
      throw Exception('Failed to edit message: $e');
    }
  }

  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final messageRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId);

      final message = await messageRef.get();
      if (!message.exists) throw Exception('Message not found');

      // Verify the message belongs to the current user
      if (message.data()?['senderId'] != user.uid) {
        throw Exception('Not authorized to delete this message');
      }

      // Start a batch write
      final batch = _firestore.batch();
      batch.delete(messageRef);

      // If this was the last message, update the conversation
      final conversationRef = _firestore.collection('conversations').doc(conversationId);
      final conversation = await conversationRef.get();
      
      if (conversation.data()?['lastMessage'] == message.data()?['content']) {
        // Get the previous message
        final previousMessages = await conversationRef
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(2)
            .get();

        String? newLastMessage;
        DateTime? newLastMessageTime;

        if (previousMessages.docs.length > 1) {
          // If there was more than one message, get the second-to-last one
          final previousMessage = previousMessages.docs[1].data();
          newLastMessage = previousMessage['content'];
          newLastMessageTime = DateTime.parse(previousMessage['timestamp']);
        }

        batch.update(conversationRef, {
          'lastMessage': newLastMessage,
          'lastMessageTime': newLastMessageTime?.toIso8601String(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }
} 