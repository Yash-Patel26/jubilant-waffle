import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/models/chat/conversation.dart';
import 'package:gamer_flick/models/chat/message.dart';
import 'package:gamer_flick/services/chat/messaging_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// MessagingService provider
final messagingServiceProvider =
    Provider<MessagingService>((ref) => MessagingService());

// StreamProvider for all conversations for a user
final conversationListProvider =
    StreamProvider.family<List<Conversation>, String>((ref, userId) {
  final service = ref.watch(messagingServiceProvider);
  return service.subscribeConversations(userId);
});

// StreamProvider for messages in a conversation
final messageListProvider =
    StreamProvider.family<List<Message>, String>((ref, conversationId) {
  final service = ref.watch(messagingServiceProvider);
  return service.subscribeMessages(conversationId);
});

// Provider to get a user's profile
final userProfileProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final response = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', userId)
      .single();
  return response;
});
