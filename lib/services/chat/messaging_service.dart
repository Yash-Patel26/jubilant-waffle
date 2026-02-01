import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:gamer_flick/models/chat/conversation.dart';
import 'package:gamer_flick/models/chat/message.dart';

class MessagingService {
  final SupabaseClient _client = Supabase.instance.client;

  // Fetch all conversations for a user
  Future<List<Conversation>> fetchConversations(String userId) async {
    // Get conversation IDs where the user is a participant
    final participantResponse = await _client
        .from('conversation_participants')
        .select('conversation_id')
        .eq('user_id', userId);

    final conversationIds = (participantResponse as List)
        .map((conv) => conv['conversation_id'] as String)
        .toList();

    if (conversationIds.isEmpty) {
      return [];
    }

    // Fetch the actual conversations
    final response = await _client
        .from('conversations')
        .select()
        .inFilter('id', conversationIds)
        .order('updated_at', ascending: false);

    return (response as List<dynamic>)
        .map((e) => Conversation.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // Fetch messages for a conversation
  Future<List<Message>> fetchMessages(String conversationId) async {
    final response = await _client
        .from('messages')
        .select('*, shared_content_id, shared_content_type')
        .eq('conversation_id', conversationId)
        .order('created_at');
    return (response as List<dynamic>)
        .map((e) => Message.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // Send a text or image message
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    String? text,
    String? imageUrl,
  }) async {
    try {
      final messageData = {
        'conversation_id': conversationId,
        'sender_id': senderId,
        'content': text ?? '',
        'media_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      };

      final insertedMessage =
          await _client.from('messages').insert(messageData).select().single();

      // Update conversation updated_at (last_message_at column doesn't exist)
      await _client
          .from('conversations')
          .update({'updated_at': DateTime.now().toIso8601String()}).eq(
              'id', conversationId);
    } catch (e) {
      rethrow;
    }
  }

  // Listen to real-time updates for conversations
  Stream<List<Conversation>> subscribeConversations(String userId) async* {
    try {
      // Get conversation IDs where the user is a participant
      final participantResponse = await _client
          .from('conversation_participants')
          .select('conversation_id')
          .eq('user_id', userId);

      final conversationIds = (participantResponse as List)
          .map((conv) => conv['conversation_id'] as String)
          .toList();

      if (conversationIds.isEmpty) {
        yield [];
        return;
      }

      // Stream the conversations
      await for (final data in _client
          .from('conversations')
          .stream(primaryKey: ['id'])
          .inFilter('id', conversationIds)
          .order('updated_at', ascending: false)) {
        try {
          final conversations = (data as List<dynamic>)
              .map((e) => Conversation.fromMap(Map<String, dynamic>.from(e)))
              .toList();

          yield conversations;
        } catch (e) {
          if (kDebugMode) {
            print('Error processing conversations stream: $e');
          }
          // Continue streaming even if there's an error with one update
        }
      }
    } catch (e) {
      // Return empty list on error
      yield [];
    }
  }

  // Listen to real-time updates for messages in a conversation
  Stream<List<Message>> subscribeMessages(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((data) {
          try {
            // Ensure the incoming data is treated as a List of dynamic maps
            final messagesRaw = (data as List<dynamic>);

            final messages = messagesRaw
                .map((e) => Message.fromMap(e as Map<String, dynamic>))
                .toList();

            return messages;
          } catch (e) {
            if (kDebugMode) {
              print('Error processing messages stream: $e');
            }
            return <Message>[];
          }
        })
        .handleError((error) {
          if (kDebugMode) {
            print('Error in messages stream: $error');
          }
          return <Message>[];
        });
  }

  // Update message status (delivered/seen)
  Future<void> updateMessageStatus({
    required String messageId,
    bool? isDelivered,
    bool? isSeen,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (isDelivered != null) updateData['is_delivered'] = isDelivered;
      // TODO: is_seen column doesn't exist in current database schema
      // For now, this is a no-op since the column doesn't exist
      if (updateData.isNotEmpty) {
        // Only update columns that exist in the database
        final validUpdateData = <String, dynamic>{};
        if (updateData.containsKey('content')) {
          validUpdateData['content'] = updateData['content'];
        }
        if (updateData.containsKey('media_url')) {
          validUpdateData['media_url'] = updateData['media_url'];
        }
        if (updateData.containsKey('message_type')) {
          validUpdateData['message_type'] = updateData['message_type'];
        }

        if (validUpdateData.isNotEmpty) {
          await _client
              .from('messages')
              .update(validUpdateData)
              .eq('id', messageId);
        }
      }
    } catch (e) {
      // If columns don't exist, log the error but don't crash the app
    }
  }

  // Add or remove a reaction
  /// Note: reactions column doesn't exist in current schema
  /// Reactions are stored in separate message_reactions table
  Future<void> updateReactions({
    required String messageId,
    required List<String> reactions,
  }) async {
    // TODO: Implement when reactions column is added to database
    // For now, this is a no-op since the column doesn't exist
    // Reactions are handled via the message_reactions table
  }

  // Check if two users follow each other (mutual following)
  Future<bool> isMutualFollowing(String userId1, String userId2) async {
    final res1 = await _client
        .from('follows')
        .select()
        .eq('follower_id', userId1)
        .eq('following_id', userId2)
        .maybeSingle();
    final res2 = await _client
        .from('follows')
        .select()
        .eq('follower_id', userId2)
        .eq('following_id', userId1)
        .maybeSingle();
    return res1 != null && res2 != null;
  }

  /// Note: is_pinned column doesn't exist in current schema
  Future<void> pinMessage(String messageId, bool isPinned) async {
    // TODO: Implement when is_pinned column is added to database
    // For now, this is a no-op since the column doesn't exist
  }

  /// Finds a conversation between two users, or creates one if it doesn't exist.
  Future<Map<String, dynamic>?> findOrCreateConversation(
      String otherUserId) async {
    final currentUserId = _client.auth.currentUser!.id;

    // First, check if a conversation already exists between these two users
    final currentUserConversations = await _client
        .from('conversation_participants')
        .select('conversation_id')
        .eq('user_id', currentUserId);

    final otherUserConversations = await _client
        .from('conversation_participants')
        .select('conversation_id')
        .eq('user_id', otherUserId);

    final currentUserConvIds = (currentUserConversations as List)
        .map((conv) => conv['conversation_id'] as String)
        .toList();

    final otherUserConvIds = (otherUserConversations as List)
        .map((conv) => conv['conversation_id'] as String)
        .toList();

    // Find common conversation IDs
    final commonConvIds = currentUserConvIds
        .where((id) => otherUserConvIds.contains(id))
        .toList();

    if (commonConvIds.isNotEmpty) {
      final existingConversation = await _client
          .from('conversations')
          .select('id')
          .eq('type', 'direct')
          .inFilter('id', commonConvIds)
          .limit(1)
          .maybeSingle();

      if (existingConversation != null) {
        return existingConversation;
      }
    }

    // If no conversation exists, create a new one
    final newConversation = await _client.from('conversations').insert({
      'type': 'direct',
      'created_by': currentUserId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).select();

    final conversationId = newConversation.first['id'];

    // Add both users as participants
    await _client.from('conversation_participants').insert([
      {
        'conversation_id': conversationId,
        'user_id': currentUserId,
      },
      {
        'conversation_id': conversationId,
        'user_id': otherUserId,
      },
    ]);

    return newConversation.first;
  }

  /// Note: status column doesn't exist in current schema
  Future<void> acceptConversationRequest(String conversationId) async {
    // TODO: Implement when status column is added to database
    // For now, this is a no-op since the column doesn't exist
  }

  Future<void> declineConversationRequest(String conversationId) async {
    await _client.from('conversations').delete().eq('id', conversationId);
  }

  // Test real-time connection
  Future<bool> testRealtimeConnection() async {
    try {
      final channel = _client.channel('test');
      channel.subscribe();
      await channel.unsubscribe();
      return true;
    } catch (e) {
      return false;
    }
  }
}
