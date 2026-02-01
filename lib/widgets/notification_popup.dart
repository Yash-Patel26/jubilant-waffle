import 'package:flutter/material.dart';
import 'package:gamer_flick/models/notification/notification_model.dart';

IconData getNotificationIcon(String iconKey) {
  switch (iconKey) {
    case 'comment':
      return Icons.comment;
    case 'favorite':
      return Icons.favorite;
    case 'person_add':
      return Icons.person_add;
    case 'mail':
      return Icons.mail;
    case 'emoji_events':
      return Icons.emoji_events;

    case 'notifications':
    default:
      return Icons.notifications;
  }
}

Color getNotificationColor(String colorKey) {
  switch (colorKey) {
    case 'green':
      return Colors.green;
    case 'red':
      return Colors.red;
    case 'blue':
      return Colors.blue;
    case 'purple':
      return Colors.purple;
    case 'orange':
      return Colors.orange;
    case 'amber':
      return Colors.amber;
    case 'grey':
    default:
      return Colors.grey;
  }
}

class NotificationPopup extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationPopup({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: getNotificationColor(
          notification.type.colorKey,
        ).withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        getNotificationIcon(notification.type.iconKey),
        color: getNotificationColor(notification.type.colorKey),
        size: 20,
      ),
    );
  }
}
