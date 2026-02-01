import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gamer_flick/theme/app_theme.dart';
import 'package:gamer_flick/utils/haptic_utils.dart';

/// A widget that wraps content and adds double-tap to like functionality
/// with Instagram-style heart animation
class DoubleTapLikeWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onDoubleTap;
  final bool isLiked;
  final Duration animationDuration;
  final Color? heartColor;
  final double heartSize;

  const DoubleTapLikeWidget({
    super.key,
    required this.child,
    required this.onDoubleTap,
    required this.isLiked,
    this.animationDuration = const Duration(milliseconds: 800),
    this.heartColor,
    this.heartSize = 100,
  });

  @override
  State<DoubleTapLikeWidget> createState() => _DoubleTapLikeWidgetState();
}

class _DoubleTapLikeWidgetState extends State<DoubleTapLikeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _showHeart = false;
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    // Scale animation: grow, bounce, shrink
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.4, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_controller);

    // Opacity animation: fade in, stay, fade out
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 30,
      ),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showHeart = false;
          _tapPosition = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap(TapDownDetails? details) {
    // Trigger callback if not already liked
    if (!widget.isLiked) {
      widget.onDoubleTap();
    }

    // Haptic feedback
    HapticUtils.onDoubleTapLike();

    // Show animation
    setState(() {
      _showHeart = true;
      _tapPosition = details?.localPosition;
    });

    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _tapPosition = details.localPosition,
      onDoubleTap: () => _handleDoubleTap(null),
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          if (_showHeart) _buildHeartAnimation(),
        ],
      ),
    );
  }

  Widget _buildHeartAnimation() {
    final heartColor = widget.heartColor ?? AppTheme.secondaryColor;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: [
              // Main heart
              Center(
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: _HeartIcon(
                      color: heartColor,
                      size: widget.heartSize,
                    ),
                  ),
                ),
              ),

              // Particle effects
              if (_scaleAnimation.value > 0.5)
                ..._buildParticles(heartColor),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildParticles(Color color) {
    final particles = <Widget>[];
    final random = Random(42); // Fixed seed for consistent particles

    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * pi;
      final distance = 60 + random.nextDouble() * 40;
      final size = 6 + random.nextDouble() * 8;
      final delay = random.nextDouble() * 0.3;

      particles.add(
        Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final progress = ((_controller.value - delay) / (1 - delay))
                  .clamp(0.0, 1.0);
              final particleOpacity = progress < 0.7
                  ? progress / 0.7
                  : 1 - ((progress - 0.7) / 0.3);

              return Transform.translate(
                offset: Offset(
                  cos(angle) * distance * progress,
                  sin(angle) * distance * progress - (20 * progress),
                ),
                child: Opacity(
                  opacity: particleOpacity.clamp(0.0, 1.0) *
                      _opacityAnimation.value,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return particles;
  }
}

class _HeartIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _HeartIcon({
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Icon(
        Icons.favorite,
        color: color,
        size: size,
        shadows: [
          Shadow(
            color: color.withOpacity(0.8),
            blurRadius: 20,
          ),
        ],
      ),
    );
  }
}

/// A simpler like button with animation
class AnimatedLikeButton extends StatefulWidget {
  final bool isLiked;
  final VoidCallback onTap;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const AnimatedLikeButton({
    super.key,
    required this.isLiked,
    required this.onTap,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  State<AnimatedLikeButton> createState() => _AnimatedLikeButtonState();
}

class _AnimatedLikeButtonState extends State<AnimatedLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticUtils.onVote();
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.activeColor ?? AppTheme.secondaryColor;
    final inactiveColor = widget.inactiveColor ?? AppTheme.textSecondaryColor;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                widget.isLiked ? Icons.favorite : Icons.favorite_border,
                color: widget.isLiked ? activeColor : inactiveColor,
                size: widget.size,
                shadows: widget.isLiked
                    ? [
                        Shadow(
                          color: activeColor.withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
