import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/ui/stick_cam_session.dart';

class StickCamService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<StickCamSession> joinQueue(
    String userId, {
    List<String> interests = const [],
    String mode = 'video',
  }) async {
    try {
      final response = await _supabase
          .from('stick_cam_sessions')
          .insert({
            'a_user_id': userId,
            'status': 'matching',
            'interests': interests,
            'mode': mode,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return StickCamSession.fromMap(response);
    } catch (e) {
      throw Exception('Failed to join queue: $e');
    }
  }

  Future<StickCamMessage> sendMessage({
    required String sessionId,
    required String senderId,
    required String content,
  }) async {
    try {
      final response = await _supabase
          .from('stick_cam_messages')
          .insert({
            'session_id': sessionId,
            'sender_id': senderId,
            'content': content,
            'message_type': 'text',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return StickCamMessage.fromMap(response);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> leaveSession(String sessionId, String reason) async {
    try {
      await _supabase.from('stick_cam_sessions').update({
        'status': 'ended',
        'end_reason': reason,
        'ended_at': DateTime.now().toIso8601String(),
      }).eq('id', sessionId);
    } catch (e) {
      throw Exception('Failed to leave session: $e');
    }
  }

  RealtimeChannel subscribeMessages(
    String sessionId,
    Function(StickCamMessage) onMessage,
  ) {
    return _supabase
        .channel('public:stick_cam_messages:session_id=eq.$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'stick_cam_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'session_id',
            value: sessionId,
          ),
          callback: (payload) {
            onMessage(StickCamMessage.fromMap(payload.newRecord));
          },
        )
        .subscribe();
  }

  RealtimeChannel subscribeSession(
    String sessionId,
    Function(StickCamSession) onSessionUpdate,
  ) {
    return _supabase
        .channel('public:stick_cam_sessions:id=eq.$sessionId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'stick_cam_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: sessionId,
          ),
          callback: (payload) {
            onSessionUpdate(StickCamSession.fromMap(payload.newRecord));
          },
        )
        .subscribe();
  }

  Stream<bool> subscribeOtherTyping(String sessionId, String currentUserId) {
    return _supabase
        .from('stick_cam_presence')
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

  Future<void> setTyping(String sessionId, String userId, bool isTyping) async {
    try {
      await _supabase.from('stick_cam_presence').upsert({
        'session_id': sessionId,
        'user_id': userId,
        'typing': isTyping,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silently fail for typing indicators
      print('Failed to set typing: $e');
    }
  }

  // Method to find a matching session
  Future<StickCamSession?> findMatchingSession(
    String userId,
    List<String> interests,
    String mode,
  ) async {
    try {
      final rpc = await _supabase.rpc(
        'find_matching_stick_cam_session',
        params: {
          'p_user_id': userId,
          'p_interests': interests,
          'p_mode': mode,
        },
      );

      if (rpc == null) return null;

      final response = await _supabase
          .from('stick_cam_sessions')
          .select()
          .eq('id', rpc as String)
          .single();

      final session = StickCamSession.fromMap(response);
      return session;
    } catch (e) {
      print('Failed to find matching session: $e');
      return null;
    }
  }

  // Method to connect two users
  Future<void> connectUsers(String sessionId, String bUserId) async {
    try {
      await _supabase.rpc('connect_stick_cam_users', params: {
        'p_session_id': sessionId,
        'p_b_user_id': bUserId,
      });
    } catch (e) {
      throw Exception('Failed to connect users: $e');
    }
  }
}
