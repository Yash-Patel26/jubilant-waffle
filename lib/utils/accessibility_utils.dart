import 'package:flutter/material.dart';

/// Utility class for accessibility features
/// Helps respect user preferences for reduced motion and other accessibility settings
class AccessibilityUtils {
  AccessibilityUtils._();

  /// Check if user has enabled reduced motion in system settings
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Get animation duration respecting reduced motion preference
  /// Returns Duration.zero if reduced motion is enabled
  static Duration getAnimationDuration(BuildContext context, Duration normal) {
    if (shouldReduceMotion(context)) {
      return Duration.zero;
    }
    return normal;
  }

  /// Get animation curve respecting reduced motion preference
  /// Returns linear curve if reduced motion is enabled
  static Curve getAnimationCurve(BuildContext context, [Curve? normal]) {
    if (shouldReduceMotion(context)) {
      return Curves.linear;
    }
    return normal ?? Curves.easeInOut;
  }

  /// Check if user prefers high contrast
  static bool prefersHighContrast(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }

  /// Check if bold text is enabled
  static bool usesBoldText(BuildContext context) {
    return MediaQuery.of(context).boldText;
  }

  /// Get text scale factor
  static double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaler.scale(1.0);
  }

  /// Check if text is scaled significantly (>1.3x)
  static bool hasLargeTextScale(BuildContext context) {
    return getTextScaleFactor(context) > 1.3;
  }

  /// Get safe font size that respects text scaling but has max limit
  static double getSafeFontSize(
    BuildContext context,
    double baseSize, {
    double maxScale = 1.5,
  }) {
    final scale = getTextScaleFactor(context).clamp(1.0, maxScale);
    return baseSize * scale;
  }

  /// Check if screen reader is likely active (based on accessibility features)
  static bool isScreenReaderLikelyActive(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }

  /// Get touch target size (minimum 48x48 for accessibility)
  static double getMinTouchTargetSize(BuildContext context) {
    // Standard minimum is 48, but we increase if text scaling is large
    if (hasLargeTextScale(context)) {
      return 56;
    }
    return 48;
  }

  /// Build semantic label for game statistics
  static String buildGameStatsSemantic({
    required String gameName,
    required int wins,
    required int losses,
    required double winRate,
  }) {
    return '$gameName. $wins wins, $losses losses. Win rate ${winRate.toStringAsFixed(1)} percent.';
  }

  /// Build semantic label for tournament
  static String buildTournamentSemantic({
    required String name,
    required String status,
    required int participants,
    String? prize,
  }) {
    final prizeText = prize != null ? 'Prize: $prize.' : '';
    return '$name tournament. Status: $status. $participants participants. $prizeText';
  }

  /// Build semantic label for post
  static String buildPostSemantic({
    required String authorName,
    required String content,
    required int likes,
    required int comments,
    required String timeAgo,
  }) {
    return 'Post by $authorName, $timeAgo. $content. $likes likes, $comments comments.';
  }

  /// Build semantic label for leaderboard entry
  static String buildLeaderboardEntrySemantic({
    required int rank,
    required String username,
    required int score,
    String? change,
  }) {
    final changeText = change != null ? 'Rank change: $change.' : '';
    return 'Rank $rank. $username. Score: $score. $changeText';
  }
}

/// Extension for easy access to accessibility utils
extension AccessibilityExtension on BuildContext {
  bool get shouldReduceMotion => AccessibilityUtils.shouldReduceMotion(this);
  bool get prefersHighContrast => AccessibilityUtils.prefersHighContrast(this);
  bool get hasLargeTextScale => AccessibilityUtils.hasLargeTextScale(this);
  double get textScaleFactor => AccessibilityUtils.getTextScaleFactor(this);

  Duration animationDuration(Duration normal) =>
      AccessibilityUtils.getAnimationDuration(this, normal);

  Curve animationCurve([Curve? normal]) =>
      AccessibilityUtils.getAnimationCurve(this, normal);
}

/// A widget that automatically adjusts for reduced motion
class ReducedMotionBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, bool reduceMotion) builder;

  const ReducedMotionBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, context.shouldReduceMotion);
  }
}

/// AnimatedContainer that respects reduced motion
class AccessibleAnimatedContainer extends StatelessWidget {
  final Duration duration;
  final Curve curve;
  final Widget child;
  final AlignmentGeometry? alignment;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Decoration? decoration;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? margin;
  final Matrix4? transform;
  final AlignmentGeometry? transformAlignment;
  final Clip clipBehavior;

  const AccessibleAnimatedContainer({
    super.key,
    required this.duration,
    this.curve = Curves.linear,
    required this.child,
    this.alignment,
    this.padding,
    this.color,
    this.decoration,
    this.width,
    this.height,
    this.constraints,
    this.margin,
    this.transform,
    this.transformAlignment,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    final actualDuration = context.animationDuration(duration);
    final actualCurve = context.animationCurve(curve);

    return AnimatedContainer(
      duration: actualDuration,
      curve: actualCurve,
      alignment: alignment,
      padding: padding,
      color: color,
      decoration: decoration,
      width: width,
      height: height,
      constraints: constraints,
      margin: margin,
      transform: transform,
      transformAlignment: transformAlignment,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

/// AnimatedOpacity that respects reduced motion
class AccessibleAnimatedOpacity extends StatelessWidget {
  final double opacity;
  final Duration duration;
  final Curve curve;
  final Widget child;

  const AccessibleAnimatedOpacity({
    super.key,
    required this.opacity,
    required this.duration,
    this.curve = Curves.linear,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (context.shouldReduceMotion) {
      return Opacity(opacity: opacity, child: child);
    }

    return AnimatedOpacity(
      opacity: opacity,
      duration: duration,
      curve: curve,
      child: child,
    );
  }
}

/// AnimatedScale that respects reduced motion
class AccessibleAnimatedScale extends StatelessWidget {
  final double scale;
  final Duration duration;
  final Curve curve;
  final Widget child;
  final Alignment alignment;

  const AccessibleAnimatedScale({
    super.key,
    required this.scale,
    required this.duration,
    this.curve = Curves.linear,
    required this.child,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    if (context.shouldReduceMotion) {
      return Transform.scale(scale: scale, alignment: alignment, child: child);
    }

    return AnimatedScale(
      scale: scale,
      duration: duration,
      curve: curve,
      alignment: alignment,
      child: child,
    );
  }
}
