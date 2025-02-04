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
        .orderBy('lastMessageTime', descending: true)
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

      // First check if there's any existing conversation with this seller/buyer pair
      final existingConversations = await _firestore
          .collection('conversations')
          .where('participants', arrayContains: user.uid)
          .get();

      // Find conversation with the same seller/buyer pair
      QueryDocumentSnapshot<Map<String, dynamic>>? existingConversation;
      for (var doc in existingConversations.docs) {
        final participants = List<String>.from(doc.data()['participants'] as List);
        if (participants.contains(sellerId)) {
          existingConversation = doc;
          break;
        }
      }

      if (existingConversation != null) {
        // Update the existing conversation with the new product if different
        if (existingConversation.data()['productId'] != productId) {
          await existingConversation.reference.update({
            'productId': productId,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
        return existingConversation.id;
      }

      // If no existing conversation, create a new one
      // Get seller info
      final sellerDoc = await _firestore.collection('sellers').doc(sellerId).get();
      if (!sellerDoc.exists) throw Exception('Seller not found');
      final sellerName = sellerDoc.data()!['storeName'] as String? ?? 'Unknown Store';
      final sellerPhoto = sellerDoc.data()!['logo'] as String?;

      // Get buyer info
      final buyerDoc = await _firestore.collection('users').doc(user.uid).get();
      final buyerPhoto = buyerDoc.data()?['photoUrl'] as String?;

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
        'participantPhotos': {
          user.uid: buyerPhoto,
          sellerId: sellerPhoto,
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
        'updatedAt': DateTime.now().toIso8601String(),
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

      final conversationRef = _firestore.collection('conversations').doc(conversationId);
      final messageRef = conversationRef.collection('messages').doc(messageId);

      // Get the message first to verify ownership
      final message = await messageRef.get();
      if (!message.exists) throw Exception('Message not found');

      // Verify ownership
      if (message.data()?['senderId'] != user.uid) {
        throw Exception('Not authorized to delete this message');
      }

      // Get the conversation to check if this was the last message
      final conversation = await conversationRef.get();
      if (!conversation.exists) throw Exception('Conversation not found');

      final batch = _firestore.batch();

      // Delete the message
      batch.delete(messageRef);

      // Check if this was the last message
      if (conversation.data()?['lastMessage'] == message.data()?['content']) {
        // Get the previous message
        final previousMessages = await conversationRef
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .where(FieldPath.documentId, isNotEqualTo: messageId)
            .limit(1)
            .get();

        if (previousMessages.docs.isEmpty) {
          // No other messages exist
          batch.update(conversationRef, {
            'lastMessage': null,
            'lastMessageTime': null,
          });
        } else {
          // Update with the previous message
          final previousMessage = previousMessages.docs.first;
          batch.update(conversationRef, {
            'lastMessage': previousMessage.data()['content'],
            'lastMessageTime': previousMessage.data()['timestamp'],
          });
        }
      }

      // Commit all changes
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }
} 