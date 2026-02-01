import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/notification/notification_model.dart';
import 'package:gamer_flick/providers/app/notification_provider.dart';
import '../chat/chat_screen.dart';
import '../profile/profile_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

// Enhanced professional icon mapping with more sophisticated icons
IconData getNotificationIcon(String iconKey) {
  switch (iconKey) {
    case 'comment':
      return Icons.chat_bubble_outline_rounded;
    case 'favorite':
      return Icons.favorite_rounded;
    case 'person_add':
      return Icons.person_add_rounded;
    case 'mail':
      return Icons.email_rounded;
    case 'emoji_events':
      return Icons.emoji_events_rounded;
    case 'notifications':
    default:
      return Icons.notifications_rounded;
  }
}

// Enhanced icon mapping with more specific notification types
IconData getEnhancedNotificationIcon(NotificationType type) {
  switch (type) {
    case NotificationType.postComment:
      return Icons.chat_bubble_outline_rounded;
    case NotificationType.postLike:
      return Icons.favorite_rounded;
    case NotificationType.followRequest:
      return Icons.person_add_alt_rounded;
    case NotificationType.newMessage:
      return Icons.mark_email_unread_rounded;
    case NotificationType.tournamentUpdate:
      return Icons.emoji_events_rounded;
    case NotificationType.communityInvite:
      return Icons.group_add_rounded;
    case NotificationType.liveStream:
      return Icons.live_tv_rounded;
    case NotificationType.achievement:
      return Icons.military_tech_rounded;
    case NotificationType.gameInvite:
      return Icons.sports_esports_rounded;
    case NotificationType.systemUpdate:
      return Icons.system_update_rounded;
    case NotificationType.other:
      return Icons.notifications_active_rounded;
  }
}

// Professional color scheme with enhanced gradients
Color getNotificationColor(String colorKey) {
  switch (colorKey) {
    case 'green':
      return const Color(0xFF059669); // Darker emerald green
    case 'red':
      return const Color(0xFFDC2626); // Deeper red
    case 'blue':
      return const Color(0xFF2563EB); // Deeper blue
    case 'purple':
      return const Color(0xFF7C3AED); // Deeper purple
    case 'orange':
      return const Color(0xFFD97706); // Deeper amber
    case 'amber':
      return const Color(0xFFD97706);
    case 'indigo':
      return const Color(0xFF4F46E5); // Deep indigo
    case 'pink':
      return const Color(0xFFEC4899); // Deep pink
    case 'teal':
      return const Color(0xFF0D9488); // Deep teal
    case 'grey':
    default:
      return const Color(0xFF4B5563); // Darker grey
  }
}

// Enhanced background color with better opacity
Color getNotificationBackgroundColor(String colorKey) {
  switch (colorKey) {
    case 'green':
      return const Color(0xFF059669).withOpacity(0.15);
    case 'red':
      return const Color(0xFFDC2626).withOpacity(0.15);
    case 'blue':
      return const Color(0xFF2563EB).withOpacity(0.15);
    case 'purple':
      return const Color(0xFF7C3AED).withOpacity(0.15);
    case 'orange':
      return const Color(0xFFD97706).withOpacity(0.15);
    case 'amber':
      return const Color(0xFFD97706).withOpacity(0.15);
    case 'indigo':
      return const Color(0xFF4F46E5).withOpacity(0.15);
    case 'pink':
      return const Color(0xFFEC4899).withOpacity(0.15);
    case 'teal':
      return const Color(0xFF0D9488).withOpacity(0.15);
    case 'grey':
    default:
      return const Color(0xFF4B5563).withOpacity(0.15);
  }
}

// Professional icon size constants
class NotificationIconSizes {
  static const double small = 16.0;
  static const double medium = 22.0; // Slightly larger for better visibility
  static const double large = 26.0;
  static const double extraLarge = 32.0;
}

// Enhanced icon container styling
class NotificationIconStyle {
  static const double containerSize = 36.0; // Further reduced container size
  static const double borderRadius = 18.0; // Further reduced border radius
  static const double borderWidth = 0.8; // Thinner border
  static const double shadowBlur = 6.0;
  static const double shadowOffset = 1.5;
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Unread', 'Mentions', 'Follows'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final notifier = ref.read(notificationProvider.notifier);
      await notifier.loadNotifications(user.id);
      notifier.subscribeToRealtime(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationState = ref.watch(notificationProvider);
    final notifications = notificationState.notifications;
    final isLoading = notificationState.isLoading;
    final error = notificationState.error;

    int unreadCount = notifications.where((n) => !n.isRead).length;

    List<NotificationModel> filteredNotifications;
    switch (_tabController.index) {
      case 1:
        filteredNotifications = notifications.where((n) => !n.isRead).toList();
        break;
      case 2:
        filteredNotifications = notifications
            .where((n) => n.type == NotificationType.postComment)
            .toList();
        break;
      case 3:
        filteredNotifications = notifications
            .where((n) => n.type == NotificationType.followRequest)
            .toList();
        break;
      default:
        filteredNotifications = notifications;
    }

    return Scaffold(
      backgroundColor:
          theme.colorScheme.surface, // Use theme background color
      appBar: AppBar(
        elevation:
            theme.appBarTheme.elevation, // Use theme elevation (should be 0)
        backgroundColor:
            theme.appBarTheme.backgroundColor, // Use theme app bar background
        surfaceTintColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_rounded,
              color: theme.colorScheme.primary,
              size: 28, // Slightly larger icon
            ),
            const SizedBox(width: 14),
            Text(
              'Notifications',
              style: theme.appBarTheme.titleTextStyle?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: 22, // Adjusted font size
                  ) ??
                  const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Colors.white), // Fallback
            ),
            const SizedBox(width: 12),
            if (unreadCount > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.tertiary, // Use accent color for badge
                      theme.colorScheme.tertiary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.tertiary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '$unreadCount',
                  style: TextStyle(
                    color: theme.colorScheme
                        .onTertiary, // Ensure readable color on accent
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor:
              theme.colorScheme.primary, // Primary accent for indicator
          indicatorWeight: 4, // Slightly thicker indicator
          labelColor:
              theme.colorScheme.primary, // Primary accent for selected label
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant
              .withOpacity(0.7), // Muted unselected label
          labelStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700, // Bolder selected label
                fontSize: 15, // Slightly larger font
              ) ??
              const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14), // Fallback
          unselectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w500,
                fontSize: 14, // Consistent font size
              ) ??
              const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 14), // Fallback
          tabs: _tabs.map((tab) {
            if (tab == 'Unread' && unreadCount > 0) {
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tab),
                    const SizedBox(width: 6), // Slightly more space
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3), // Adjusted padding
                      decoration: BoxDecoration(
                        color: theme.colorScheme
                            .tertiary, // Accent color for unread badge
                        borderRadius: BorderRadius.circular(10), // More rounded
                      ),
                      child: Text(
                        '$unreadCount',
                        style: TextStyle(
                          color: theme
                              .colorScheme.onTertiary, // Readable text color
                          fontSize: 11,
                          fontWeight: FontWeight.w700, // Bolder font
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return Tab(text: tab);
          }).toList(),
          onTap: (_) {
            setState(() {});
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list_rounded,
              color: theme.colorScheme.onSurface
                  .withOpacity(0.8), // Better visibility
              size: 26, // Slightly larger
            ),
            onPressed: () {
              // Implement filter action if needed
            },
            tooltip: 'Filter notifications',
          ),
          IconButton(
            icon: Icon(
              Icons.done_all_rounded,
              color: theme.colorScheme.onSurface
                  .withOpacity(0.8), // Better visibility
              size: 26, // Slightly larger
            ),
            onPressed: () async {
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null) {
                final notifier = ref.read(notificationProvider.notifier);
                await notifier.markAllAsRead(user.id);
              }
            },
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: _buildBody(filteredNotifications, isLoading, error),
      ),
    );
  }

  Widget _buildBody(
    List<NotificationModel> notifications,
    bool isLoading,
    String? error,
  ) {
    final theme = Theme.of(context);
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32), // Larger padding
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.surfaceContainerHighest, // Use card color
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary
                        .withOpacity(0.15), // Primary accent shadow
                    blurRadius: 25, // More blur
                    offset: const Offset(0, 8), // More offset
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                strokeWidth: 4, // Thicker stroke
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary, // Primary color for indicator
                ),
              ),
            ),
            const SizedBox(height: 32), // More space
            Text(
              'Loading notifications...',
              style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ) ??
                  TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32), // Larger padding
              decoration: BoxDecoration(
                color: theme
                    .colorScheme.errorContainer, // Use error container color
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.error
                        .withOpacity(0.3), // Stronger error shadow
                    blurRadius: 25, // More blur
                    offset: const Offset(0, 8), // More offset
                  ),
                ],
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64, // Larger icon
                color: theme.colorScheme.error, // Error color
              ),
            ),
            const SizedBox(height: 32), // More space
            Text(
              'Something went wrong',
              style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme
                        .onErrorContainer, // Color on error container
                  ) ??
                  TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
            ),
            const SizedBox(height: 12), // More space
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 48), // More horizontal padding
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      height: 1.5,
                    ) ??
                    TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      height: 1.4,
                    ),
              ),
            ),
            const SizedBox(height: 32), // More space
            ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: Icon(Icons.refresh_rounded,
                  color: theme.colorScheme.onPrimary), // Icon color from theme
              label: Text('Try Again',
                  style: TextStyle(
                      color: theme
                          .colorScheme.onPrimary)), // Text color from theme
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    theme.colorScheme.primary, // Primary color for button
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16), // Larger padding
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), // More rounded
                ),
                elevation: 8, // More elevation
                shadowColor: theme.colorScheme.primary
                    .withOpacity(0.4), // Primary shadow
              ),
            ),
          ],
        ),
      );
    }

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32), // Larger padding
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.surfaceContainerHighest, // Use card color
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.outline
                        .withOpacity(0.15), // Subtle outline shadow
                    blurRadius: 25, // More blur
                    offset: const Offset(0, 8), // More offset
                  ),
                ],
              ),
              child: Icon(
                Icons.notifications_off_rounded, // Off icon
                size: 64, // Larger icon
                color:
                    theme.colorScheme.onSurface.withOpacity(0.6), // Muted color
              ),
            ),
            const SizedBox(height: 32), // More space
            Text(
              'No notifications yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ) ??
                  TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
            ),
            const SizedBox(height: 12), // More space
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 48), // More horizontal padding
              child: Text(
                'You\'ll see notifications here when someone interacts with your content',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                      height: 1.5,
                    ) ??
                    TextStyle(
                      fontSize: 14,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      height: 1.4,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return NotificationTile(
            notification: notification,
            onTap: () => _handleNotificationTap(notification),
            onMarkAsRead: () => _markAsRead(notification.id),
            onDelete: () => _deleteNotification(notification.id),
          );
        },
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Mark as read when tapped
    _markAsRead(notification.id);

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.postComment:
      case NotificationType.postLike:
        if (notification.relatedId != null) {
          Navigator.pushNamed(
            context,
            '/post-detail',
            arguments: {
              'postId': notification.relatedId,
            },
          );
        } else if (notification.metadata['post_id'] != null) {
          Navigator.pushNamed(
            context,
            '/post-detail',
            arguments: {
              'postId': notification.metadata['post_id'],
            },
          );
        }
        break;
      case NotificationType.newMessage:
        final convId = notification.relatedId ??
            notification.metadata['conversation_id'] as String?;
        if (convId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(conversationId: convId),
            ),
          );
        }
        break;
      case NotificationType.followRequest:
        final targetUserId = notification.senderId ??
            notification.metadata['follower_id'] as String?;
        if (targetUserId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: targetUserId),
            ),
          );
        }
        break;
      case NotificationType.tournamentUpdate:
        if (notification.relatedId != null) {
          Navigator.pushNamed(
            context,
            '/tournament-detail',
            arguments: {'tournamentId': notification.relatedId},
          );
        }
        break;
      case NotificationType.communityInvite:
        if (notification.relatedId != null) {
          Navigator.pushNamed(
            context,
            '/community-detail',
            arguments: {'communityId': notification.relatedId},
          );
        }
        break;
      case NotificationType.liveStream:
        if (notification.relatedId != null) {
          Navigator.pushNamed(
            context,
            '/live-stream',
            arguments: {'streamId': notification.relatedId},
          );
        }
        break;
      case NotificationType.achievement:
        // Show achievement modal or navigate to achievements page
        break;
      case NotificationType.gameInvite:
        if (notification.relatedId != null) {
          Navigator.pushNamed(
            context,
            '/game-invite',
            arguments: {'gameId': notification.relatedId},
          );
        }
        break;
      case NotificationType.systemUpdate:
        // Handle system update notifications
        break;
      case NotificationType.other:
        break;
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    final notifier = ref.read(notificationProvider.notifier);
    await notifier.markAsRead(notificationId);
  }

  Future<void> _deleteNotification(String notificationId) async {
    final notifier = ref.read(notificationProvider.notifier);
    await notifier.deleteNotification(notificationId);
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onMarkAsRead,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error, // Use theme error color
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete_rounded,
            color: theme.colorScheme.onError,
            size: 28), // Use rounded icon and on-error color
      ),
      onDismissed: (direction) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(
            vertical: 0.5, horizontal: 8), // Minimal vertical margin
        decoration: BoxDecoration(
          color: notification.isRead
              ? theme.colorScheme.surfaceContainerHighest // Card color for read
              : theme.colorScheme.primary
                  .withOpacity(0.05), // Even more subtle highlight for unread
          borderRadius: BorderRadius.circular(6), // More compact border radius
          border: Border.all(
            color: notification.isRead
                ? theme.colorScheme.outline
                    .withOpacity(0.04) // Even more subtle border for read
                : theme.colorScheme.primary
                    .withOpacity(0.1), // Even lighter accent border for unread
            width: 1,
          ),
          boxShadow: [
            if (!notification.isRead) // Subtle shadow for unread
              BoxShadow(
                color: theme.colorScheme.primary
                    .withOpacity(0.03), // Further softer shadow
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.01), // Extremely subtle general shadow
              blurRadius: 1,
              offset: const Offset(0, 0.5),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 2), // Minimal padding
          leading: _buildLeadingIcon(theme), // Pass theme to helper
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment
                .center, // Center vertically for better alignment
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.w700, // Bolder unread title
                        color: notification.isRead
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme
                                .onSurface, // Color based on read status
                      ) ??
                      TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.w600,
                        fontSize: 11, // Smallest font size
                        color: notification.isRead
                            ? theme.colorScheme.onSurface.withOpacity(0.8)
                            : theme.colorScheme.onSurface,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(
                  width: 4), // Even less space between title and time
              Text(
                timeago.format(notification.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                      fontSize: 8, // Smallest font for time
                    ) ??
                    TextStyle(
                      fontSize: 8,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.4),
                      fontWeight: FontWeight.w400,
                    ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 0), // Eliminate space
              Text(
                notification.message,
                style: theme.textTheme.bodySmall?.copyWith(
                      color: notification.isRead
                          ? theme.colorScheme.onSurfaceVariant.withOpacity(0.8)
                          : theme.colorScheme.onSurface.withOpacity(0.9),
                      height: 1.0, // Minimal line height
                    ) ??
                    TextStyle(
                      fontSize: 10, // Smallest font size
                      color: notification.isRead
                          ? Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6)
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.8),
                      height: 0.9, // Even more minimal line height
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (notification.senderAvatarUrl != null) ...[
                const SizedBox(
                    height: 2), // Minimal space for avatar if present
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundImage:
                          NetworkImage(notification.senderAvatarUrl!),
                      radius: 10, // Smallest avatar
                    ),
                  ),
                ),
              ],
            ],
          ),
          trailing: null, // Removed trailing as time is in title now
          onTap: onTap,
          onLongPress: () => _showOptions(context),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(ThemeData theme) {
    // Accept theme parameter
    final color = getNotificationColor(notification.type.colorKey);

    return Container(
      width: NotificationIconStyle.containerSize, // Use new smaller size
      height: NotificationIconStyle.containerSize, // Use new smaller size
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.7), // Stronger base color in gradient
            color.withOpacity(0.4), // Fade to slightly lighter shade
            Colors.transparent,
          ],
          stops: const [0.0, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(NotificationIconStyle.borderRadius),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: NotificationIconStyle.shadowBlur,
            offset: const Offset(0, NotificationIconStyle.shadowOffset),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // General subtle shadow
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius:
              BorderRadius.circular(NotificationIconStyle.borderRadius),
          border: Border.all(
            color: color.withOpacity(0.4), // Stronger border color
            width: NotificationIconStyle.borderWidth,
          ),
        ),
        child: Stack(
          children: [
            // Subtle inner glow effect
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(NotificationIconStyle.borderRadius),
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 0.8,
                    colors: [
                      color.withOpacity(0.15), // Slightly stronger inner glow
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Main icon
            Center(
              child: Icon(
                getEnhancedNotificationIcon(notification.type),
                color: theme
                    .colorScheme.onPrimary, // Icon color from theme's onPrimary
                size: NotificationIconSizes.small, // Use smallest icon size
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!notification.isRead)
              ListTile(
                leading: const Icon(Icons.mark_email_read),
                title: const Text('Mark as Read'),
                onTap: () {
                  Navigator.of(context).pop();
                  onMarkAsRead();
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pop();
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
