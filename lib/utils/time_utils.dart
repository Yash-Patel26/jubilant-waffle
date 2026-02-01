import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:intl/intl.dart';

class TimeUtils {
  static const String istTimeZone = 'Asia/Kolkata';

  /// Convert UTC DateTime to IST DateTime
  static DateTime toIST(DateTime utcDateTime) {
    try {
      final istLocation = tz.getLocation(istTimeZone);
      final istTime = tz.TZDateTime.from(utcDateTime, istLocation);
      return istTime;
    } catch (e) {
      // Fallback: manually add IST offset (UTC+5:30)
      return utcDateTime.add(const Duration(hours: 5, minutes: 30));
    }
  }

  /// Format time in IST for display
  static String formatTimeIST(BuildContext context, DateTime utcDateTime) {
    try {
      final istTime = toIST(utcDateTime);
      final time = TimeOfDay.fromDateTime(istTime);
      return time.format(context);
    } catch (e) {
      // Fallback to local time if conversion fails
      final time = TimeOfDay.fromDateTime(utcDateTime);
      return time.format(context);
    }
  }

  /// Format date and time in IST
  static String formatDateTimeIST(DateTime utcDateTime) {
    try {
      final istTime = toIST(utcDateTime);
      return DateFormat.yMMMd().add_jm().format(istTime);
    } catch (e) {
      // Fallback to local time if conversion fails
      return DateFormat.yMMMd().add_jm().format(utcDateTime);
    }
  }

  /// Format relative time ago in IST
  static String formatTimeAgoIST(DateTime utcDateTime) {
    try {
      final istTime = toIST(utcDateTime);
      final now = DateTime.now();
      final difference = now.difference(istTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'now';
      }
    } catch (e) {
      // Fallback to original logic
      final now = DateTime.now();
      final difference = now.difference(utcDateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'now';
      }
    }
  }
}
