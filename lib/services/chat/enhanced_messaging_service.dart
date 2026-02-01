import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:gamer_flick/models/chat/conversation.dart';
import 'package:gamer_flick/models/chat/message.dart';
import 'package:gamer_flick/models/post/reaction.dart';
import 'package:gamer_flick/utils/error_handler.dart';

class EnhancedMessagingService {
  static final EnhancedMessagingService _instance =
      EnhancedMessagingService._internal();
  factory EnhancedMessagingService() => _instance;
  EnhancedMessagingService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// Send message with media and reactions support
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    String? text,
    String? mediaUrl,
    String? mediaType,
    Map<String, dynamic>? sharedContent,
    String? replyToMessageId,
  }) async {
    try {
      // 1. Insert the new message
      final messageData = {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': text ?? '',
        'media_url': mediaUrl,
        'message_type': mediaType ?? 'text',
        'reply_to_id': replyToMessageId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      // Add shared content fields if provided
      if (sharedContent != null) {
        messageData['shared_content_id'] = sharedContent['content_id'];
        messageData['shared_content_type'] = sharedContent['content_type'];
      }

      final response =
          await _client.from('messages').insert(messageData).select().single();

      // 2. Update the conversation's timestamp
      await _client.from('conversations').update({
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'last_message': text ??
            (mediaType != null ? 'Sent a $mediaType' : 'Sent a message'),
      }).eq('id', conversationId);

      // Note: Message reactions are handled separately via message_reactions table

      if (kDebugMode) {
        print('Message sent successfully to conversation: $conversationId');
      }
    } catch (e) {
      ErrorHandler.logError('Failed to send message', e);
      rethrow;
    }
  }

  /// Add reaction to message
  Future<void> addReaction({
    required String messageId,
    required String userId,
    required String reactionType,
  }) async {
    try {
      await _client.from('message_reactions').insert({
        'message_id': messageId,
        'user_id': userId,
        'reaction_type': reactionType,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Update message reactions count
      await _client.rpc('increment_message_reaction_count', params: {
        'message_id': messageId,
        'reaction_type': reactionType,
      });
    } catch (e) {
      ErrorHandler.logError('Failed to add reaction', e);
      rethrow;
    }
  }

  /// Remove reaction from message
  Future<void> removeReaction({
    required String messageId,
    required String userId,
    required String reactionType,
  }) async {
    try {
      await _client
          .from('message_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .eq('reaction_type', reactionType);

      // Update message reactions count
      await _client.rpc('decrement_message_reaction_count', params: {
        'message_id': messageId,
        'reaction_type': reactionType,
      });
    } catch (e) {
      ErrorHandler.logError('Failed to remove reaction', e);
      rethrow;
    }
  }

  /// Get message reactions
  Future<List<Reaction>> getMessageReactions(String messageId) async {
    try {
      final response = await _client.from('message_reactions').select('''
            reaction_type,
            user_id,
            created_at,
            profiles!message_reactions_user_id_fkey(username, display_name, avatar_url)
          ''').eq('message_id', messageId).order('created_at');

      return (response as List)
          .map((reaction) => Reaction.fromMap(reaction))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get message reactions', e);
      return [];
    }
  }

  /// Share content in message
  Future<void> shareContent({
    required String conversationId,
    required String senderId,
    required String contentId,
    required String contentType,
    String? message,
  }) async {
    try {
      final sharedContent = {
        'content_id': contentId,
        'content_type': contentType,
      };

      await sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        text: message ?? 'Shared a $contentType',
        sharedContent: sharedContent,
      );
    } catch (e) {
      ErrorHandler.logError('Failed to share content', e);
      rethrow;
    }
  }

  /// Reply to a message
  Future<void> replyToMessage({
    required String conversationId,
    required String senderId,
    required String replyToMessageId,
    required String text,
    String? mediaUrl,
    String? mediaType,
  }) async {
    try {
      await sendMessage(
        conversationId: conversationId,
        senderId: senderId,
        text: text,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
        replyToMessageId: replyToMessageId,
      );
    } catch (e) {
      ErrorHandler.logError('Failed to reply to message', e);
      rethrow;
    }
  }

  /// Get conversation with enhanced details
  Future<Conversation?> getConversation(String conversationId) async {
    try {
      final response = await _client.from('conversations').select('''
            *,
            participants:conversation_participants(
              user_id,
              profiles!conversation_participants_user_id_fkey(
                id,
                username,
                display_name,
                avatar_url,
                is_online,
                last_seen
              )
            )
          ''').eq('id', conversationId).single();

      return Conversation.fromMap(response);
    } catch (e) {
      ErrorHandler.logError('Failed to get conversation', e);
      return null;
    }
  }

  /// Get messages with reactions and replies
  Future<List<Message>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('messages')
          .select('''
            *,
            sender:profiles!messages_sender_id_fkey(
              id,
              username,
              display_name,
              avatar_url
            ),
            reactions:message_reactions(
              reaction_type,
              user_id,
              created_at
            ),
            reply_to:messages!messages_reply_to_message_id_fkey(
              id,
              content,
              sender:profiles!messages_sender_id_fkey(username, display_name)
            )
          ''')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((message) => Message.fromMap(message))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get messages', e);
      return [];
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _client
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', userId)
          .eq('is_read', false);
    } catch (e) {
      ErrorHandler.logError('Failed to mark messages as read', e);
    }
  }

  /// Get unread message count
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _client
          .from('messages')
          .select('id')
          .neq('sender_id', userId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      ErrorHandler.logError('Failed to get unread count', e);
      return 0;
    }
  }

  /// Delete message
  Future<void> deleteMessage({
    required String messageId,
    required String userId,
  }) async {
    try {
      // Check if user is the sender
      final message = await _client
          .from('messages')
          .select('sender_id')
          .eq('id', messageId)
          .single();

      if (message['sender_id'] != userId) {
        throw Exception('Only message sender can delete the message');
      }

      await _client.from('messages').delete().eq('id', messageId);
    } catch (e) {
      ErrorHandler.logError('Failed to delete message', e);
      rethrow;
    }
  }

  /// Edit message
  Future<void> editMessage({
    required String messageId,
    required String userId,
    required String newContent,
  }) async {
    try {
      // Check if user is the sender
      final message = await _client
          .from('messages')
          .select('sender_id, created_at')
          .eq('id', messageId)
          .single();

      if (message['sender_id'] != userId) {
        throw Exception('Only message sender can edit the message');
      }

      // Check if message is within edit time limit (e.g., 15 minutes)
      final messageTime = DateTime.parse(message['created_at']);
      final timeLimit = DateTime.now().subtract(const Duration(minutes: 15));

      if (messageTime.isBefore(timeLimit)) {
        throw Exception('Message can only be edited within 15 minutes');
      }

      await _client.from('messages').update({
        'content': newContent,
        'edited_at': DateTime.now().toUtc().toIso8601String(),
        'is_edited': true,
      }).eq('id', messageId);
    } catch (e) {
      ErrorHandler.logError('Failed to edit message', e);
      rethrow;
    }
  }

  /// Pin message
  Future<void> pinMessage({
    required String messageId,
    required String conversationId,
    required String userId,
  }) async {
    try {
      // Check if user has permission to pin messages
      final participant = await _client
          .from('conversation_participants')
          .select('role')
          .eq('conversation_id', conversationId)
          .eq('user_id', userId)
          .single();

      if (participant['role'] != 'admin' && participant['role'] != 'owner') {
        throw Exception('Only admins can pin messages');
      }

      await _client
          .from('messages')
          .update({'is_pinned': true}).eq('id', messageId);
    } catch (e) {
      ErrorHandler.logError('Failed to pin message', e);
      rethrow;
    }
  }

  /// Unpin message
  Future<void> unpinMessage({
    required String messageId,
    required String conversationId,
    required String userId,
  }) async {
    try {
      // Check if user has permission to unpin messages
      final participant = await _client
          .from('conversation_participants')
          .select('role')
          .eq('conversation_id', conversationId)
          .eq('user_id', userId)
          .single();

      if (participant['role'] != 'admin' && participant['role'] != 'owner') {
        throw Exception('Only admins can unpin messages');
      }

      await _client
          .from('messages')
          .update({'is_pinned': false}).eq('id', messageId);
    } catch (e) {
      ErrorHandler.logError('Failed to unpin message', e);
      rethrow;
    }
  }

  /// Get pinned messages
  Future<List<Message>> getPinnedMessages(String conversationId) async {
    try {
      final response = await _client
          .from('messages')
          .select('''
            *,
            sender:profiles!messages_sender_id_fkey(
              id,
              username,
              display_name,
              avatar_url
            )
          ''')
          .eq('conversation_id', conversationId)
          .eq('is_pinned', true)
          .order('created_at');

      return (response as List)
          .map((message) => Message.fromMap(message))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get pinned messages', e);
      return [];
    }
  }

  /// Search messages
  Future<List<Message>> searchMessages({
    required String conversationId,
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('messages')
          .select('''
            *,
            sender:profiles!messages_sender_id_fkey(
              id,
              username,
              display_name,
              avatar_url
            )
          ''')
          .eq('conversation_id', conversationId)
          .ilike('content', '%$query%')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((message) => Message.fromMap(message))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search messages', e);
      return [];
    }
  }

  /// Get message statistics
  Future<Map<String, dynamic>> getMessageStats(String conversationId) async {
    try {
      final response = await _client.from('messages').select('''
            sender_id,
            media_type,
            reactions,
            created_at
          ''').eq('conversation_id', conversationId);

      final messages = response as List;
      final stats = <String, dynamic>{
        'total_messages': messages.length,
        'media_messages': messages.where((m) => m['media_type'] != null).length,
        'text_messages': messages.where((m) => m['media_type'] == null).length,
        'reactions_count': messages.fold<int>(
            0, (sum, m) => sum + ((m['reactions'] as List?)?.length ?? 0)),
        'participants': messages.map((m) => m['sender_id']).toSet().length,
      };

      return stats;
    } catch (e) {
      ErrorHandler.logError('Failed to get message stats', e);
      return {};
    }
  }
}
