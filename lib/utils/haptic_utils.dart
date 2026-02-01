import 'dart:io';
import 'package:flutter/services.dart';

/// Utility class for platform-optimized haptic feedback
/// Provides consistent tactile feedback across iOS and Android
class HapticUtils {
  HapticUtils._();

  /// Light tap feedback - for buttons, selections
  static void onTap() {
    if (Platform.isIOS) {
      HapticFeedback.lightImpact();
    } else if (Platform.isAndroid) {
      HapticFeedback.selectionClick();
    }
  }

  /// Selection feedback - for toggles, switches, vote buttons
  static void onSelection() {
    HapticFeedback.selectionClick();
  }

  /// Success feedback - for completed actions, wins
  static void onSuccess() {
    if (Platform.isIOS) {
      HapticFeedback.mediumImpact();
    } else if (Platform.isAndroid) {
      HapticFeedback.heavyImpact();
    }
  }

  /// Error feedback - for failed actions, errors
  static void onError() {
    HapticFeedback.vibrate();
  }

  /// Heavy impact - for important actions like double-tap like
  static void onHeavyImpact() {
    HapticFeedback.heavyImpact();
  }

  /// Medium impact - for moderate feedback
  static void onMediumImpact() {
    HapticFeedback.mediumImpact();
  }

  /// Light impact - for subtle feedback
  static void onLightImpact() {
    HapticFeedback.lightImpact();
  }

  /// Vote feedback - for upvote/downvote actions
  static void onVote() {
    HapticFeedback.selectionClick();
  }

  /// Double tap like feedback
  static void onDoubleTapLike() {
    HapticFeedback.mediumImpact();
  }

  /// Pull to refresh feedback
  static void onPullToRefresh() {
    HapticFeedback.mediumImpact();
  }

  /// Send message feedback
  static void onSendMessage() {
    if (Platform.isIOS) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  /// Navigation feedback - for page transitions
  static void onNavigate() {
    if (Platform.isIOS) {
      HapticFeedback.selectionClick();
    }
  }

  /// Long press feedback
  static void onLongPress() {
    HapticFeedback.mediumImpact();
  }

  /// Swipe action feedback
  static void onSwipe() {
    HapticFeedback.selectionClick();
  }

  /// Tournament match start feedback
  static void onMatchStart() {
    HapticFeedback.heavyImpact();
  }

  /// Tournament win feedback
  static void onTournamentWin() {
    // Double haptic for emphasis
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.heavyImpact();
    });
  }

  /// Tournament loss feedback
  static void onTournamentLoss() {
    HapticFeedback.lightImpact();
  }

  /// Notification received feedback
  static void onNotificationReceived() {
    if (Platform.isIOS) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  /// Achievement unlocked feedback
  static void onAchievementUnlocked() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 150), () {
      HapticFeedback.mediumImpact();
    });
  }

  /// Level up feedback
  static void onLevelUp() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.mediumImpact();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.lightImpact();
    });
  }
}
