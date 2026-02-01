import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/models/notification/notification_model.dart';
import 'package:gamer_flick/repositories/notification/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationState({
    required this.notifications,
    required this.unreadCount,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final INotificationRepository _repository;
  RealtimeChannel? _channel;
  void Function(NotificationModel notification)? onNewNotification;

  NotificationNotifier(this._repository)
      : super(NotificationState(notifications: [], unreadCount: 0));

  Future<void> loadNotifications(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final notifications = await _repository.fetchNotifications(userId);
      final unreadCount = await _repository.getUnreadCount(userId);

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void subscribeToRealtime(String userId) {
    _channel?.unsubscribe();
    _channel = _repository.subscribeToNotifications(userId, (notification) {
      state = state.copyWith(
        notifications: [notification, ...state.notifications],
        unreadCount: state.unreadCount + 1,
      );

      if (onNewNotification != null) {
        onNewNotification!(notification);
      }
    });
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);

      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();

      final newUnreadCount = updatedNotifications
          .where((notification) => !notification.isRead)
          .length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _repository.markAllAsRead(userId);

      final updatedNotifications = state.notifications
          .map((notification) => notification.copyWith(isRead: true))
          .toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _repository.deleteNotification(notificationId);

      final updatedNotifications = state.notifications
          .where((notification) => notification.id != notificationId)
          .toList();

      final newUnreadCount = updatedNotifications
          .where((notification) => !notification.isRead)
          .length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteAllNotifications(String userId) async {
    try {
      await _repository.deleteAllNotifications(userId);
      state = state.copyWith(notifications: [], unreadCount: 0);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
  (ref) => NotificationNotifier(ref.watch(notificationRepositoryProvider)),
);

// Provider for unread count only
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});

// Provider for notifications list only
final notificationsListProvider = Provider<List<NotificationModel>>((ref) {
  return ref.watch(notificationProvider).notifications;
});
