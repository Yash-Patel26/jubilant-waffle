import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/chat/random_chat.dart';

class RandomChatService {
  final SupabaseClient _client = Supabase.instance.client;

  // Create or find a session to match the user
  Future<RandomSession> joinQueue(String userId,
      {List<String> interests = const [],
      String mode = 'text',
      String? question}) async {
    // Try to find an available session with status 'matching' and empty slot
    final available = await _client
        .from('random_sessions')
        .select()
        .eq('status', 'matching')
        .isFilter('b_user_id', null)
        .neq('a_user_id', userId)
        .overlaps('interests', interests)
        .eq('mode', mode)
        .limit(1);

    if ((available as List).isNotEmpty) {
      final sessionId =
          (available.first)['id'] as String;
      final updated = await _client
          .from('random_sessions')
          .update({'b_user_id': userId, 'status': 'connected'})
          .eq('id', sessionId)
          .select()
          .single();
      return RandomSession.fromMap(updated);
    }

    // Otherwise create a session with user as A
    final created = await _client
        .from('random_sessions')
        .insert({
          'a_user_id': userId,
          'status': 'matching',
          'interests': interests,
          'mode': mode,
          'question': question,
        })
        .select()
        .single();
    return RandomSession.fromMap(created);
  }

  Future<void> leaveSession(String sessionId, String reason) async {
    await _client.from('random_sessions').update({
      'status': 'ended',
      'end_reason': reason,
      'ended_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', sessionId);
  }

  Future<RandomMessage> sendMessage({
    required String sessionId,
    required String senderId,
    required String content,
  }) async {
    final inserted = await _client
        .from('random_messages')
        .insert({
          'session_id': sessionId,
          'sender_id': senderId,
          'content': content,
        })
        .select()
        .single();
    return RandomMessage.fromMap(inserted);
  }

  RealtimeChannel subscribeMessages(
      String sessionId, void Function(RandomMessage) onMessage) {
    final channel = _client
        .channel('public:random_messages:session_id=eq.$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'random_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (payload) {
            onMessage(RandomMessage.fromMap(payload.newRecord));
          },
        )
        .subscribe();
    return channel;
  }

  RealtimeChannel subscribeSession(
      String sessionId, void Function(RandomSession) onChange) {
    final channel = _client
        .channel('public:random_sessions:id=eq.$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'random_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: sessionId,
          ),
          callback: (payload) {
            onChange(RandomSession.fromMap(payload.newRecord));
          },
        )
        .subscribe();
    return channel;
  }

  // Presence: upsert typing for current user
  Future<void> setTyping(String sessionId, String userId, bool typing) async {
    await _client.from('random_presence').upsert({
      'session_id': sessionId,
      'user_id': userId,
      'typing': typing,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // Presence stream for other user typing
  Stream<bool> subscribeOtherTyping(String sessionId, String currentUserId) {
    return _client
        .from('random_presence')
        .stream(primaryKey: ['session_id', 'user_id'])
        .eq('session_id', sessionId)
        .map((rows) {
          for (final r in rows) {
            if (r['user_id'] != currentUserId &&
                (r['typing'] as bool?) == true) {
              return true;
            }
          }
          return false;
        });
  }
}
