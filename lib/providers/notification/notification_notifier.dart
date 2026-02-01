import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/notification/notification_model.dart';
import 'package:gamer_flick/repositories/notification/notification_repository.dart';
import 'package:gamer_flick/providers/user/user_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
final notificationRepositoryProvider = Provider<INotificationRepository>((ref) {
  return SupabaseNotificationRepository();
});

final notificationsProvider = AsyncNotifierProvider<NotificationNotifier, List<NotificationModel>>(() {
  return NotificationNotifier();
});

class NotificationNotifier extends AsyncNotifier<List<NotificationModel>> {
  RealtimeChannel? _channel;

  @override
  Future<List<NotificationModel>> build() async {
    final user = ref.watch(userProvider).value;
    if (user == null) {
      _unsubscribe();
      return [];
    }
    
    _subscribe(user.id);
    
    return ref.read(notificationRepositoryProvider).fetchNotifications(user.id);
  }

  void _subscribe(String userId) {
    _unsubscribe();
    _channel = ref.read(notificationRepositoryProvider).subscribeToNotifications(
      userId,
      (notification) {
        addNotification(notification);
      },
    );
  }

  void _unsubscribe() {
    _channel?.unsubscribe();
    _channel = null;
  }

  Future<void> refresh() async {
    final user = ref.read(userProvider).value;
    if (user == null) return;
    
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(notificationRepositoryProvider).fetchNotifications(user.id));
  }

  Future<void> markAsRead(String notificationId) async {
    await ref.read(notificationRepositoryProvider).markAsRead(notificationId);
    state = await AsyncValue.guard(() async {
      final current = state.value ?? [];
      return current.map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n).toList();
    });
  }

  Future<void> markAllAsRead() async {
    final user = ref.read(userProvider).value;
    if (user == null) return;

    await ref.read(notificationRepositoryProvider).markAllAsRead(user.id);
    state = await AsyncValue.guard(() async {
      final current = state.value ?? [];
      return current.map((n) => n.copyWith(isRead: true)).toList();
    });
  }

  void addNotification(NotificationModel notification) {
    final current = state.value ?? [];
    state = AsyncValue.data([notification, ...current]);
  }
}

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(userProvider).value;
  if (user == null) return 0;
  
  // We can derive this from notificationsProvider if it's already loaded
  final notifications = ref.watch(notificationsProvider).value;
  if (notifications != null) {
    return notifications.where((n) => !n.isRead).length;
  }
  
  return ref.read(notificationRepositoryProvider).getUnreadCount(user.id);
});
