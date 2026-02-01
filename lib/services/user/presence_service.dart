import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// PresenceService handles online/offline and typing status using Supabase Realtime.
/// If Realtime Presence extension is not enabled, fallback to a 'presence' table.
class PresenceService {
  final SupabaseClient _client = Supabase.instance.client;

  // Online status stream for a user (using a 'presence' table fallback)
  Stream<bool> onlineStatus(String userId) {
    // Poll the presence table for updates (every 5 seconds)
    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      final res = await _client
          .from('presence')
          .select('is_online, last_seen')
          .eq('user_id', userId)
          .maybeSingle();
      if (res == null) return false;
      return res['is_online'] == true;
    }).distinct();
  }

  // Set the current user as online (call on app start/foreground)
  Future<void> setOnline(String userId) async {
    await _client.from('presence').upsert({
      'user_id': userId,
      'is_online': true,
      'last_seen': DateTime.now().toIso8601String(),
    });
  }

  // Set the current user as offline (call on app close/background)
  Future<void> setOffline(String userId) async {
    await _client.from('presence').upsert({
      'user_id': userId,
      'is_online': false,
      'last_seen': DateTime.now().toIso8601String(),
    });
  }

  // Typing status stream for a conversation (using a 'typing' table fallback)
  Stream<bool> typingStatus(String conversationId, String userId) {
    // Poll the typing table for updates (every 2 seconds)
    return Stream.periodic(const Duration(seconds: 2)).asyncMap((_) async {
      final res = await _client
          .from('typing')
          .select('is_typing, updated_at')
          .eq('conversation_id', conversationId)
          .neq('user_id', userId) // Only others' typing
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (res == null) return false;
      return res['is_typing'] == true;
    }).distinct();
  }

  // Set typing status for the current user in a conversation
  Future<void> setTyping(
      String conversationId, String userId, bool isTyping) async {
    await _client.from('typing').upsert({
      'conversation_id': conversationId,
      'user_id': userId,
      'is_typing': isTyping,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
