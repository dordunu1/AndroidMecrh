import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/chat_message.dart';
import '../../models/product.dart';
import '../../services/chat_service.dart';
import '../../services/storage_service.dart';
import '../../services/product_service.dart';
import '../../services/seller_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String productId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserName,
    required this.productId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isSending = false;
  List<ChatMessage> _messages = [];
  String? _error;
  Product? _product;
  String? _sellerPhoto;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadProduct();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final messages = await ref.read(chatServiceProvider).watchMessages(
        widget.conversationId,
      ).first;

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadProduct() async {
    try {
      final product = await ref.read(productServiceProvider).getProduct(widget.productId);
      if (product != null) {
        // Load seller profile to get photo
        final seller = await ref.read(sellerServiceProvider).getSellerProfileById(product.sellerId);
        if (mounted) {
          setState(() {
            _product = product;
            _sellerPhoto = seller?.logo;
          });
        }
      }
    } catch (e) {
      print('Error loading product: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await ref.read(chatServiceProvider).sendMessage(
        conversationId: widget.conversationId,
        content: text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _isSending = true);

    try {
      // Upload image
      final urls = await ref.read(storageServiceProvider).uploadFiles(
        [File(image.path)],
        'chats/images',
      );

      // Send message with image
      await ref.read(chatServiceProvider).sendMessage(
        conversationId: widget.conversationId,
        content: '',
        imageUrl: urls.first,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: _sellerPhoto != null ? NetworkImage(_sellerPhoto!) : null,
              child: _sellerPhoto == null ? const Icon(Icons.store) : null,
            ),
            const SizedBox(width: 8),
            Text(widget.otherUserName),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_product != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: _product!.images.first,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _product!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          _product!.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          'GHS ${_product!.price.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      )
                    : StreamBuilder<List<ChatMessage>>(
                        stream: ref.watch(chatServiceProvider).watchMessages(widget.conversationId),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            );
                          }

                          if (!snapshot.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final messages = snapshot.data!;
                          if (messages.isEmpty) {
                            return Center(
                              child: Text(
                                'No messages yet',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isMe = message.senderId == FirebaseAuth.instance.currentUser?.uid;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  mainAxisAlignment: isMe
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!isMe)
                                      CircleAvatar(
                                        radius: 16,
                                        child: Icon(
                                          Icons.store,
                                          size: 16,
                                          color: theme.colorScheme.onPrimary,
                                        ),
                                      ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isMe
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.surface,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: isMe
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            if (message.imageUrl != null)
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(
                                                  message.imageUrl!,
                                                  width: 200,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            if (message.content.isNotEmpty)
                                              Text(
                                                message.content,
                                                style: TextStyle(
                                                  color: isMe
                                                      ? theme.colorScheme.onPrimary
                                                      : theme.colorScheme.onSurface,
                                                ),
                                              ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatTimestamp(message.timestamp),
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: isMe
                                                    ? theme.colorScheme.onPrimary.withOpacity(0.7)
                                                    : theme.colorScheme.onSurface.withOpacity(0.7),
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),

          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    onPressed: _isSending ? null : _sendImage,
                    icon: const Icon(Icons.image),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 