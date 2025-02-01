import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';

final unreadMessagesCountProvider = StreamProvider<int>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.watchTotalUnreadCount();
}); 