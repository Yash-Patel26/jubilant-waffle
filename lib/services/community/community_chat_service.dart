import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/community/community_chat_message.dart';

class CommunityChatService {
  final SupabaseClient _client = Supabase.instance.client;
  final String table = 'community_chat_messages';

  Future<List<CommunityChatMessage>> fetchMessages(String communityId) async {
    final response = await _client
        .from(table)
        .select()
        .eq('community_id', communityId)
        .order('created_at', ascending: true);
    return (response as List)
        .map((data) =>
            CommunityChatMessage.fromMap(data as Map<String, dynamic>))
        .toList();
  }

  Future<CommunityChatMessage> sendMessage({
    required String communityId,
    required String userId,
    required String message,
    String messageType = 'text',
  }) async {
    final response = await _client
        .from(table)
        .insert({
          'community_id': communityId,
          'user_id': userId,
          'message': message,
          'message_type': messageType,
        })
        .select()
        .single();
    return CommunityChatMessage.fromMap(response);
  }

  RealtimeChannel subscribeToMessages(
      String communityId, void Function(CommunityChatMessage) onMessage) {
    final channel = _client
        .channel('public:$table:community_id=eq.$communityId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'community_id',
            value: communityId,
          ),
          callback: (payload) {
            final newMsg = CommunityChatMessage.fromMap(payload.newRecord);
            onMessage(newMsg);
          },
        )
        .subscribe();
    return channel;
  }
}
