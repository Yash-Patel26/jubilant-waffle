import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gamer_flick/theme/app_theme.dart';
import 'package:gamer_flick/utils/haptic_utils.dart';

/// In-app notification toast that slides down from the top
/// Supports swipe-to-dismiss and tap-to-navigate
class InAppNotificationToast {
  static OverlayEntry? _currentEntry;
  static bool _isShowing = false;

  /// Show an in-app notification toast
  static void show(
    BuildContext context, {
    required String title,
    required String body,
    String? avatarUrl,
    IconData? icon,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
    Color? accentColor,
  }) {
    // Dismiss current if any
    dismiss();

    final overlay = Overlay.of(context);

    _currentEntry = OverlayEntry(
      builder: (context) => _NotificationToastWidget(
        title: title,
        body: body,
        avatarUrl: avatarUrl,
        icon: icon,
        accentColor: accentColor,
        onTap: () {
          dismiss();
          onTap?.call();
        },
        onDismiss: dismiss,
      ),
    );

    overlay.insert(_currentEntry!);
    _isShowing = true;

    // Haptic feedback
    HapticUtils.onNotificationReceived();

    // Auto dismiss after duration
    Future.delayed(duration, () {
      if (_isShowing) {
        dismiss();
      }
    });
  }

  /// Dismiss the current notification
  static void dismiss() {
    _currentEntry?.remove();
    _currentEntry = null;
    _isShowing = false;
  }

  /// Check if notification is currently showing
  static bool get isShowing => _isShowing;
}

class _NotificationToastWidget extends StatefulWidget {
  final String title;
  final String body;
  final String? avatarUrl;
  final IconData? icon;
  final Color? accentColor;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationToastWidget({
    required this.title,
    required this.body,
    this.avatarUrl,
    this.icon,
    this.accentColor,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationToastWidget> createState() =>
      _NotificationToastWidgetState();
}

class _NotificationToastWidgetState extends State<_NotificationToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;
  double _dragOffset = 0;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    if (_isDismissing) return;
    _isDismissing = true;

    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: GestureDetector(
            onTap: widget.onTap,
            onVerticalDragUpdate: (details) {
              setState(() {
                _dragOffset += details.delta.dy;
              });
            },
            onVerticalDragEnd: (details) {
              if (_dragOffset < -30 || details.velocity.pixelsPerSecond.dy < -500) {
                _handleDismiss();
              } else {
                setState(() => _dragOffset = 0);
              }
            },
            child: Transform.translate(
              offset: Offset(0, _dragOffset.clamp(-100, 0)),
              child: Opacity(
                opacity: (1 - (_dragOffset.abs() / 100)).clamp(0.5, 1.0),
                child: _buildNotificationCard(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard() {
    final accentColor = widget.accentColor ?? AppTheme.primaryColor;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: accentColor.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
          border: Border.all(
            color: accentColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar or Icon
            _buildLeading(accentColor),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Dismiss hint
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.keyboard_arrow_up,
                  color: AppTheme.textSecondaryColor.withOpacity(0.5),
                  size: 20,
                ),
                Text(
                  'Swipe',
                  style: TextStyle(
                    fontSize: 8,
                    color: AppTheme.textSecondaryColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeading(Color accentColor) {
    if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: accentColor.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: CircleAvatar(
          radius: 22,
          backgroundImage: CachedNetworkImageProvider(widget.avatarUrl!),
          backgroundColor: AppTheme.surfaceColor,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(0.3),
            accentColor.withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: accentColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Icon(
        widget.icon ?? Icons.notifications,
        color: accentColor,
        size: 20,
      ),
    );
  }
}

/// Helper class for common notification types
class NotificationToastHelper {
  static void showLike(
    BuildContext context, {
    required String username,
    required String postType,
    String? avatarUrl,
    VoidCallback? onTap,
  }) {
    InAppNotificationToast.show(
      context,
      title: '$username liked your $postType',
      body: 'Tap to view',
      avatarUrl: avatarUrl,
      icon: Icons.favorite,
      accentColor: AppTheme.secondaryColor,
      onTap: onTap,
    );
  }

  static void showComment(
    BuildContext context, {
    required String username,
    required String comment,
    String? avatarUrl,
    VoidCallback? onTap,
  }) {
    InAppNotificationToast.show(
      context,
      title: '$username commented',
      body: comment,
      avatarUrl: avatarUrl,
      icon: Icons.chat_bubble,
      accentColor: AppTheme.primaryColor,
      onTap: onTap,
    );
  }

  static void showFollow(
    BuildContext context, {
    required String username,
    String? avatarUrl,
    VoidCallback? onTap,
  }) {
    InAppNotificationToast.show(
      context,
      title: 'New follower',
      body: '$username started following you',
      avatarUrl: avatarUrl,
      icon: Icons.person_add,
      accentColor: AppTheme.primaryColor,
      onTap: onTap,
    );
  }

  static void showTournament(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onTap,
  }) {
    InAppNotificationToast.show(
      context,
      title: title,
      body: message,
      icon: Icons.emoji_events,
      accentColor: AppTheme.primaryColor,
      onTap: onTap,
    );
  }

  static void showMatchReady(
    BuildContext context, {
    required String opponentName,
    VoidCallback? onTap,
  }) {
    InAppNotificationToast.show(
      context,
      title: 'Match Ready!',
      body: 'Your match against $opponentName is starting',
      icon: Icons.sports_esports,
      accentColor: AppTheme.successColor,
      onTap: onTap,
      duration: const Duration(seconds: 10),
    );
  }

  static void showAchievement(
    BuildContext context, {
    required String achievementName,
    VoidCallback? onTap,
  }) {
    HapticUtils.onAchievementUnlocked();
    InAppNotificationToast.show(
      context,
      title: 'Achievement Unlocked!',
      body: achievementName,
      icon: Icons.military_tech,
      accentColor: Colors.amber,
      onTap: onTap,
      duration: const Duration(seconds: 5),
    );
  }

  static void showMessage(
    BuildContext context, {
    required String senderName,
    required String message,
    String? avatarUrl,
    VoidCallback? onTap,
  }) {
    InAppNotificationToast.show(
      context,
      title: senderName,
      body: message,
      avatarUrl: avatarUrl,
      icon: Icons.message,
      accentColor: AppTheme.primaryColor,
      onTap: onTap,
    );
  }
}
