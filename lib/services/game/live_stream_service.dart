import 'package:supabase_flutter/supabase_flutter.dart';

class LiveStreamService {
  LiveStreamService();

  final SupabaseClient _client = Supabase.instance.client;

  Future<Map<String, dynamic>> startLiveStream({
    required String title,
    String? description,
    required String streamUrl,
    String? gameTag,
    String? thumbnailUrl,
  }) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      throw StateError('User must be signed in to start a live stream');
    }

    final insertPayload = {
      'streamer_id': authUser.id,
      'title': title,
      'description': description,
      'stream_url': streamUrl,
      'thumbnail_url': thumbnailUrl,
      'game_tag': gameTag,
      'is_live': true,
      'start_time': DateTime.now().toUtc().toIso8601String(),
      'viewer_count': 0,
    };

    final created = await _client
        .from('live_streams')
        .insert(insertPayload)
        .select()
        .single();

    return Map<String, dynamic>.from(created);
  }

  Future<void> endLiveStream(String streamId) async {
    await _client.from('live_streams').update({
      'is_live': false,
      'end_time': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', streamId);
  }

  Future<List<Map<String, dynamic>>> fetchLiveStreams({
    bool onlyLive = true,
    int limit = 20,
  }) async {
    var query = _client.from('live_streams').select(
        '*, profiles!live_streams_streamer_id_fkey(id, username, avatar_url, profile_picture_url)');

    if (onlyLive) {
      query = query.eq('is_live', true);
    }

    final response =
        await query.order('viewer_count', ascending: false).limit(limit);
    return (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> joinStream(String streamId) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return;

    await _client.from('stream_viewers').upsert({
      'stream_id': streamId,
      'viewer_id': authUser.id,
      'joined_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'stream_id,viewer_id');

    await _recalculateViewerCount(streamId);
  }

  Future<void> leaveStream(String streamId) async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return;

    await _client
        .from('stream_viewers')
        .delete()
        .eq('stream_id', streamId)
        .eq('viewer_id', authUser.id);

    await _recalculateViewerCount(streamId);
  }

  RealtimeChannel subscribeToViewerChanges({
    required String streamId,
    required void Function() onChanged,
  }) {
    return _client
        .channel('public:stream_viewers:stream_id=eq.$streamId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'stream_viewers',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'stream_id',
            value: streamId,
          ),
          callback: (payload) => onChanged(),
        )
        .subscribe();
  }

  Future<int> getViewerCount(String streamId) async {
    final rows = await _client
        .from('stream_viewers')
        .select('id')
        .eq('stream_id', streamId);
    return (rows as List).length;
  }

  Future<void> _recalculateViewerCount(String streamId) async {
    final count = await getViewerCount(streamId);
    await _client
        .from('live_streams')
        .update({'viewer_count': count}).eq('id', streamId);
  }
}
