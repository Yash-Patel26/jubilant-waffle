import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/models/notification/notification_model.dart';
import 'package:gamer_flick/repositories/notification/notification_repository.dart';
import 'package:gamer_flick/utils/error_handler.dart';
import 'package:gamer_flick/services/core/navigation_service.dart';

class EnhancedNotificationService {
  final INotificationRepository _repository;
  final SupabaseClient _client = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isInitialized = false;

  EnhancedNotificationService(this._repository);

  /// Initialize notification services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase messaging
      await _initializeFirebaseMessaging();

      // Request permissions
      await _requestPermissions();

      _isInitialized = true;
    } catch (e) {
      ErrorHandler.logError('Failed to initialize notification service', e);
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Note: Background message handler must be a top-level function
    // and is usually set in main.dart
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          await _saveFCMToken(token);
        }
      }
    } catch (e) {
      ErrorHandler.logError('Failed to request notification permissions', e);
    }
  }

  /// Save FCM token to user profile
  Future<void> _saveFCMToken(String token) async {
    try {
      final user = _client.auth.currentUser;
      if (user != null) {
        await _client.from('profiles').update({
          'fcm_token': token,
          'notifications_enabled': true,
        }).eq('id', user.id);
      }
    } catch (e) {
      ErrorHandler.logError('Failed to save FCM token', e);
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      _handleNotificationPayload(response.payload);
    }
  }

  /// Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'New Notification',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tap from Firebase
  void _handleNotificationTap(RemoteMessage message) {
    _handleNotificationPayload(message.data);
  }

  /// Handle notification payload and navigate
  void _handleNotificationPayload(dynamic payload) {
    // Logic for navigation based on payload
    // This often involves checking type, targetId, etc.
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String? imageUrl,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default',
      importance: Importance.max,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload,
    );
  }

  // Delegate repository methods
  Future<void> markAsRead(String notificationId) => _repository.markAsRead(notificationId);
  Future<void> markAllAsRead(String userId) => _repository.markAllAsRead(userId);
  Future<void> deleteNotification(String notificationId) => _repository.deleteNotification(notificationId);
  Future<int> getUnreadCount(String userId) => _repository.getUnreadCount(userId);

  Future<void> createInAppNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    await _repository.createNotification(
      userUuid: userId,
      notificationType: type,
      titleParam: title,
      messageParam: message,
      metadataParam: metadata,
    );
  }
}

final enhancedNotificationServiceProvider = Provider<EnhancedNotificationService>((ref) {
  return EnhancedNotificationService(ref.watch(notificationRepositoryProvider));
});
