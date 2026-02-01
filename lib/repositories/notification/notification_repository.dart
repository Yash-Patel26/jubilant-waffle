import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/models/notification/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class INotificationRepository {
  Future<List<NotificationModel>> fetchNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<int> getUnreadCount(String userId);
  RealtimeChannel subscribeToNotifications(
    String userId,
    void Function(NotificationModel notification) onNewNotification,
  );
  Future<void> deleteNotification(String notificationId);
  Future<void> deleteAllNotifications(String userId);
  Future<void> createNotification({
    required String userUuid,
    required String notificationType,
    required String titleParam,
    required String messageParam,
    Map<String, dynamic>? metadataParam,
  });
}

class SupabaseNotificationRepository implements INotificationRepository {
  final SupabaseClient _client;

  SupabaseNotificationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List)
          .map((e) => NotificationModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true}).eq('id', notificationId);
    } catch (e) {}
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {}
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  @override
  RealtimeChannel subscribeToNotifications(
    String userId,
    void Function(NotificationModel notification) onNewNotification,
  ) {
    return _client
        .channel('public:notifications:user_id=eq.$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final newNotification = NotificationModel.fromMap(
                Map<String, dynamic>.from(payload.newRecord),
              );
              onNewNotification(newNotification);
            } catch (e) {}
          },
        )
        .subscribe();
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _client.from('notifications').delete().eq('id', notificationId);
    } catch (e) {}
  }

  @override
  Future<void> deleteAllNotifications(String userId) async {
    try {
      await _client.from('notifications').delete().eq('user_id', userId);
    } catch (e) {}
  }

  @override
  Future<void> createNotification({
    required String userUuid,
    required String notificationType,
    required String titleParam,
    required String messageParam,
    Map<String, dynamic>? metadataParam,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userUuid,
        'type': notificationType,
        'title': titleParam,
        'message': messageParam,
        'data': metadataParam ?? {},
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {}
  }
}

final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return SupabaseNotificationRepository(client: Supabase.instance.client);
});
