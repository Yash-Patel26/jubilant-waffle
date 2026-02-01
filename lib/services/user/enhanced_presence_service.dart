import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/utils/error_handler.dart';

/// Enhanced Presence Service using Supabase Realtime
/// Provides real-time online status, typing indicators, and activity tracking
class EnhancedPresenceService {
  static final EnhancedPresenceService _instance = EnhancedPresenceService._internal();
  factory EnhancedPresenceService() => _instance;
  EnhancedPresenceService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // Active channels
  RealtimeChannel? _presenceChannel;
  RealtimeChannel? _typingChannel;
  Timer? _heartbeatTimer;
  Timer? _activityTimer;

  // Current user state
  String? _currentUserId;
  UserStatus _currentStatus = UserStatus.offline;
  DateTime? _lastActivity;

  // Subscriptions
  final _statusController = StreamController<Map<String, UserPresence>>.broadcast();
  final _typingController = StreamController<Map<String, TypingIndicator>>.broadcast();

  // Presence cache
  final Map<String, UserPresence> _presenceCache = {};
  final Map<String, TypingIndicator> _typingCache = {};

  /// Stream of user presence updates
  Stream<Map<String, UserPresence>> get presenceStream => _statusController.stream;

  /// Stream of typing indicators
  Stream<Map<String, TypingIndicator>> get typingStream => _typingController.stream;

  /// Current user's status
  UserStatus get currentStatus => _currentStatus;

  // === Initialization ===

  /// Initialize presence tracking for current user
  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    _lastActivity = DateTime.now();

    // Join global presence channel
    await _joinPresenceChannel();

    // Start heartbeat for keepalive
    _startHeartbeat();

    // Set initial status
    await setStatus(UserStatus.online);
  }

  /// Join the presence channel for real-time updates
  Future<void> _joinPresenceChannel() async {
    try {
      _presenceChannel = _client.channel(
        'presence:global',
        opts: const RealtimeChannelConfig(self: true),
      );

      _presenceChannel!
          .onPresenceSync((payload) {
            _handlePresenceSync(payload);
          })
          .onPresenceJoin((payload) {
            _handlePresenceJoin(payload);
          })
          .onPresenceLeave((payload) {
            _handlePresenceLeave(payload);
          })
          .subscribe((status, [error]) async {
            if (status == RealtimeSubscribeStatus.subscribed) {
              // Track presence with user data
              await _presenceChannel!.track({
                'user_id': _currentUserId,
                'status': _currentStatus.name,
                'last_seen': DateTime.now().toIso8601String(),
                'online_at': DateTime.now().toIso8601String(),
              });
            }
          });
    } catch (e) {
      ErrorHandler.logError('Failed to join presence channel', e);
    }
  }

  void _handlePresenceSync(RealtimePresenceSyncPayload payload) {
    _presenceCache.clear();
    final joiners = (payload as dynamic).joiners as List<dynamic>? ?? [];
    for (final presence in joiners) {
      final map = presence is Map ? Map<String, dynamic>.from(presence as Map) : null;
      if (map == null) continue;
      final userId = map['user_id'] as String?;
      if (userId != null) {
        _presenceCache[userId] = UserPresence(
          oderId: userId,
          status: UserStatus.values.firstWhere(
            (s) => s.name == map['status'],
            orElse: () => UserStatus.online,
          ),
          lastSeen: DateTime.tryParse(map['last_seen']?.toString() ?? '') ?? DateTime.now(),
          onlineAt: DateTime.tryParse(map['online_at']?.toString() ?? ''),
        );
      }
    }
    _statusController.add(Map.from(_presenceCache));
  }

  void _handlePresenceJoin(RealtimePresenceJoinPayload payload) {
    final joiners = (payload as dynamic).joiners as List<dynamic>? ?? [];
    for (final presence in joiners) {
      final map = presence is Map ? Map<String, dynamic>.from(presence as Map) : null;
      if (map == null) continue;
      final userId = map['user_id'] as String?;
      if (userId != null) {
        _presenceCache[userId] = UserPresence(
          oderId: userId,
          status: UserStatus.online,
          lastSeen: DateTime.now(),
          onlineAt: DateTime.now(),
        );
      }
    }
    _statusController.add(Map.from(_presenceCache));
  }

  void _handlePresenceLeave(RealtimePresenceLeavePayload payload) {
    final leavers = (payload as dynamic).leftPresences as List<dynamic>? ?? (payload as dynamic).leavers as List<dynamic>? ?? [];
    for (final presence in leavers) {
      final map = presence is Map ? presence as Map<String, dynamic> : null;
      final userId = map?['user_id'] as String? ?? (payload as dynamic).userId as String?;
      if (userId != null) _presenceCache.remove(userId);
    }
    _statusController.add(Map.from(_presenceCache));
  }

  // === Status Management ===

  /// Set the current user's status
  Future<void> setStatus(UserStatus status) async {
    _currentStatus = status;
    _lastActivity = DateTime.now();

    try {
      // Update presence channel
      if (_presenceChannel != null) {
        await _presenceChannel!.track({
          'user_id': _currentUserId,
          'status': status.name,
          'last_seen': DateTime.now().toIso8601String(),
          'online_at': _presenceCache[_currentUserId]?.onlineAt?.toIso8601String(),
        });
      }

      // Also update database for persistence
      await _updateDatabasePresence(status);
    } catch (e) {
      ErrorHandler.logError('Failed to set status', e);
    }
  }

  Future<void> _updateDatabasePresence(UserStatus status) async {
    try {
      await _client.from('presence').upsert({
        'user_id': _currentUserId,
        'is_online': status != UserStatus.offline,
        'status': status.name,
        'last_seen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Presence table might not exist, that's okay
    }
  }

  /// Mark user as away (automatic based on inactivity)
  void _checkActivityTimeout() {
    if (_lastActivity == null || _currentStatus == UserStatus.offline) return;

    final inactiveDuration = DateTime.now().difference(_lastActivity!);

    if (inactiveDuration > const Duration(minutes: 5) &&
        _currentStatus == UserStatus.online) {
      setStatus(UserStatus.away);
    } else if (inactiveDuration > const Duration(minutes: 15) &&
        _currentStatus == UserStatus.away) {
      setStatus(UserStatus.idle);
    }
  }

  /// Record user activity (call on user interactions)
  void recordActivity() {
    _lastActivity = DateTime.now();
    if (_currentStatus != UserStatus.online &&
        _currentStatus != UserStatus.doNotDisturb) {
      setStatus(UserStatus.online);
    }
  }

  // === Heartbeat ===

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendHeartbeat();
    });

    _activityTimer?.cancel();
    _activityTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkActivityTimeout();
    });
  }

  Future<void> _sendHeartbeat() async {
    if (_currentUserId == null || _currentStatus == UserStatus.offline) return;

    try {
      await _presenceChannel?.track({
        'user_id': _currentUserId,
        'status': _currentStatus.name,
        'last_seen': DateTime.now().toIso8601String(),
        'online_at': _presenceCache[_currentUserId]?.onlineAt?.toIso8601String(),
      });
    } catch (e) {
      // Silent failure for heartbeat
    }
  }

  // === Typing Indicators ===

  /// Join a conversation typing channel
  Future<RealtimeChannel> joinTypingChannel(String conversationId) async {
    final channelName = 'typing:$conversationId';

    final channel = _client.channel(
      channelName,
      opts: const RealtimeChannelConfig(self: true),
    );

    channel
        .onPresenceSync((payload) {
          _handleTypingSync(conversationId, payload);
        })
        .onPresenceJoin((payload) {
          _handleTypingJoin(conversationId, payload);
        })
        .onPresenceLeave((payload) {
          _handleTypingLeave(conversationId, payload);
        })
        .subscribe();

    return channel;
  }

  void _handleTypingSync(String conversationId, RealtimePresenceSyncPayload payload) {
    _typingCache.removeWhere((key, value) => value.conversationId == conversationId);
    final presences = (payload as dynamic).joiners as List<dynamic>? ?? [];
    for (final presence in presences) {
      final map = presence is Map ? Map<String, dynamic>.from(presence as Map) : null;
      if (map == null) continue;
      final userId = map['user_id'] as String?;
      final isTyping = map['is_typing'] as bool? ?? false;
      if (userId != null && isTyping && userId != _currentUserId) {
        _typingCache['$conversationId:$userId'] = TypingIndicator(
          conversationId: conversationId,
          oderId: userId,
          startedAt: DateTime.now(),
        );
      }
    }
    _typingController.add(Map.from(_typingCache));
  }

  void _handleTypingJoin(String conversationId, RealtimePresenceJoinPayload payload) {
    final newPresences = (payload as dynamic).joiners as List<dynamic>? ?? [];
    for (final presence in newPresences) {
      final map = presence is Map ? Map<String, dynamic>.from(presence as Map) : null;
      if (map == null) continue;
      final userId = map['user_id'] as String?;
      final isTyping = map['is_typing'] as bool? ?? false;
      if (userId != null && isTyping && userId != _currentUserId) {
        _typingCache['$conversationId:$userId'] = TypingIndicator(
          conversationId: conversationId,
          oderId: userId,
          startedAt: DateTime.now(),
        );
      }
    }
    _typingController.add(Map.from(_typingCache));
  }

  void _handleTypingLeave(String conversationId, RealtimePresenceLeavePayload payload) {
    final leftPresences = (payload as dynamic).leftPresences as List<dynamic>? ?? (payload as dynamic).leavers as List<dynamic>? ?? [];
    for (final presence in leftPresences) {
      final map = presence is Map ? presence as Map<String, dynamic> : null;
      final userId = map?['user_id'] as String?;
      if (userId != null) _typingCache.remove('$conversationId:$userId');
    }
    _typingController.add(Map.from(_typingCache));
  }

  /// Start typing indicator
  Future<void> startTyping(RealtimeChannel channel) async {
    try {
      await channel.track({
        'user_id': _currentUserId,
        'is_typing': true,
        'started_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      ErrorHandler.logError('Failed to start typing', e);
    }
  }

  /// Stop typing indicator
  Future<void> stopTyping(RealtimeChannel channel) async {
    try {
      await channel.track({
        'user_id': _currentUserId,
        'is_typing': false,
      });
    } catch (e) {
      // Silent failure
    }
  }

  // === User Presence Queries ===

  /// Get presence for a specific user
  UserPresence? getPresence(String userId) {
    return _presenceCache[userId];
  }

  /// Check if user is online
  bool isOnline(String userId) {
    final presence = _presenceCache[userId];
    return presence?.status == UserStatus.online ||
        presence?.status == UserStatus.away;
  }

  /// Get online users from a list
  List<String> getOnlineUsers(List<String> userIds) {
    return userIds.where((id) => isOnline(id)).toList();
  }

  /// Get online count for a list of users
  int getOnlineCount(List<String> userIds) {
    return getOnlineUsers(userIds).length;
  }

  /// Subscribe to presence updates for specific users
  Stream<UserPresence?> watchUserPresence(String userId) {
    return presenceStream.map((cache) => cache[userId]);
  }

  /// Get users typing in a conversation
  List<TypingIndicator> getTypingUsers(String conversationId) {
    return _typingCache.values
        .where((t) => t.conversationId == conversationId)
        .toList();
  }

  // === Community Presence ===

  /// Get online members count for a community
  Future<int> getCommunityOnlineCount(String communityId) async {
    try {
      // Get community members
      final members = await _client
          .from('community_members')
          .select('user_id')
          .eq('community_id', communityId)
          .eq('is_banned', false);

      final memberIds = (members as List)
          .map((m) => m['user_id'] as String)
          .toList();

      return getOnlineCount(memberIds);
    } catch (e) {
      return 0;
    }
  }

  /// Join community presence channel for real-time online count
  Future<RealtimeChannel> joinCommunityPresence(
    String communityId,
    void Function(int onlineCount) onUpdate,
  ) async {
    final channel = _client.channel(
      'presence:community:$communityId',
      opts: const RealtimeChannelConfig(self: true),
    );

    channel
        .onPresenceSync((payload) {
          final joiners = (payload as dynamic).joiners as List<dynamic>? ?? [];
          onUpdate(joiners.length);
        })
        .subscribe((status, [error]) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            await channel.track({
              'user_id': _currentUserId,
              'joined_at': DateTime.now().toIso8601String(),
            });
          }
        });

    return channel;
  }

  // === Cleanup ===

  /// Go offline and cleanup
  Future<void> goOffline() async {
    await setStatus(UserStatus.offline);
    _heartbeatTimer?.cancel();
    _activityTimer?.cancel();

    try {
      await _presenceChannel?.untrack();
      await _presenceChannel?.unsubscribe();
    } catch (e) {
      // Silent cleanup failure
    }
  }

  /// Full cleanup
  Future<void> dispose() async {
    await goOffline();

    _statusController.close();
    _typingController.close();
    _presenceCache.clear();
    _typingCache.clear();
  }
}

/// User presence data
class UserPresence {
  final String oderId;
  final UserStatus status;
  final DateTime lastSeen;
  final DateTime? onlineAt;
  final String? customStatus;

  const UserPresence({
    required this.oderId,
    required this.status,
    required this.lastSeen,
    this.onlineAt,
    this.customStatus,
  });

  // Alias for backward compatibility
  String get userId => oderId;

  /// Get human-readable last seen text
  String get lastSeenText {
    if (status == UserStatus.online) return 'Online';

    final diff = DateTime.now().difference(lastSeen);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return 'Long ago';
  }
}

/// Typing indicator data
class TypingIndicator {
  final String conversationId;
  final String oderId;
  final DateTime startedAt;

  const TypingIndicator({
    required this.conversationId,
    required this.oderId,
    required this.startedAt,
  });

  // Alias for backward compatibility
  String get userId => oderId;

  /// Check if typing indicator is stale (> 5 seconds)
  bool get isStale {
    return DateTime.now().difference(startedAt) > const Duration(seconds: 5);
  }
}

/// User status options
enum UserStatus {
  online,
  away,
  idle,
  doNotDisturb,
  invisible,
  offline,
}

extension UserStatusExtension on UserStatus {
  String get displayName {
    switch (this) {
      case UserStatus.online:
        return 'Online';
      case UserStatus.away:
        return 'Away';
      case UserStatus.idle:
        return 'Idle';
      case UserStatus.doNotDisturb:
        return 'Do Not Disturb';
      case UserStatus.invisible:
        return 'Invisible';
      case UserStatus.offline:
        return 'Offline';
    }
  }

  String get emoji {
    switch (this) {
      case UserStatus.online:
        return '🟢';
      case UserStatus.away:
        return '🟡';
      case UserStatus.idle:
        return '🟠';
      case UserStatus.doNotDisturb:
        return '🔴';
      case UserStatus.invisible:
        return '⚪';
      case UserStatus.offline:
        return '⚫';
    }
  }

  bool get isAvailable {
    return this == UserStatus.online || this == UserStatus.away;
  }
}
