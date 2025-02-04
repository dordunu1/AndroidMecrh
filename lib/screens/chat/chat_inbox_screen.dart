import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/chat_conversation.dart';
import '../../services/chat_service.dart';
import '../../widgets/common/custom_text_field.dart';
import 'chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatInboxScreen extends ConsumerStatefulWidget {
  const ChatInboxScreen({super.key});

  @override
  ConsumerState<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends ConsumerState<ChatInboxScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversationsStream = ref.watch(chatServiceProvider).watchConversations();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: CustomTextField(
              controller: _searchController,
              label: 'Search conversations',
              prefixIcon: const Icon(Icons.search),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<ChatConversation>>(
              stream: conversationsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final conversations = snapshot.data!;
                final filteredConversations = _searchQuery.isEmpty
                    ? conversations
                    : conversations.where((conv) =>
                        conv.otherParticipantName
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        (conv.lastMessage?.toLowerCase() ?? '')
                            .contains(_searchQuery.toLowerCase())).toList();

                if (filteredConversations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No conversations yet'
                              : 'No conversations found',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // No need to manually refresh as we're using a stream
                    return;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredConversations.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final conversation = filteredConversations[index];
                      return _ConversationCard(
                        conversation: conversation,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                conversationId: conversation.id,
                                otherUserName: conversation.otherParticipantName,
                                productId: conversation.productId ?? '',
                                otherParticipantId: conversation.otherParticipantId,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationCard extends StatelessWidget {
  final ChatConversation conversation;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.conversation,
    required this.onTap,
  });

  Future<String?> _getParticipantPhoto(BuildContext context) async {
    final firestore = FirebaseFirestore.instance;
    final otherParticipantId = conversation.otherParticipantId;
    
    // First try to get from sellers collection
    final sellerDoc = await firestore.collection('sellers').doc(otherParticipantId).get();
    if (sellerDoc.exists) {
      return sellerDoc.data()?['logo'] as String?;
    }
    
    // If not a seller, try users collection
    final userDoc = await firestore.collection('users').doc(otherParticipantId).get();
    if (userDoc.exists) {
      return userDoc.data()?['photoUrl'] as String?;
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = conversation.unreadCount > 0;

    return Card(
      elevation: hasUnread ? 2 : 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  FutureBuilder<String?>(
                    future: _getParticipantPhoto(context),
                    builder: (context, snapshot) {
                      final photoUrl = snapshot.data;
                      
                      return CircleAvatar(
                        radius: 24,
                        backgroundColor: hasUnread 
                            ? theme.colorScheme.primary.withOpacity(0.2)
                            : theme.colorScheme.primary.withOpacity(0.1),
                        child: photoUrl != null && photoUrl.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: photoUrl,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Text(
                                    conversation.otherParticipantName[0].toUpperCase(),
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                conversation.otherParticipantName[0].toUpperCase(),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      );
                    },
                  ),
                  if (hasUnread)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          '${conversation.unreadCount}',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            conversation.otherParticipantName,
                            style: TextStyle(
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (conversation.lastMessageTime != null)
                          Text(
                            timeago.format(conversation.lastMessageTime!),
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnread 
                                  ? theme.colorScheme.primary
                                  : theme.textTheme.bodySmall?.color,
                              fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conversation.lastMessage ?? 'No messages yet',
                      style: TextStyle(
                        color: hasUnread 
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodySmall?.color,
                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 