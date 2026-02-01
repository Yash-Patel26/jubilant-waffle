import 'package:flutter/material.dart';
import 'package:gamer_flick/models/core/user_with_stories.dart';

class StoryCircle extends StatefulWidget {
  final UserWithStories userWithStories;
  final VoidCallback onTap;
  final double? size;
  final bool isLive;

  const StoryCircle({
    super.key,
    required this.userWithStories,
    required this.onTap,
    this.size,
    this.isLive = false,
  });

  @override
  State<StoryCircle> createState() => _StoryCircleState();
}

class _StoryCircleState extends State<StoryCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userWithStories.user;
    final avatarUrl = user.profilePicture;
    final circleSize = widget.size ?? 88.0;
    final avatarRadius = (circleSize - 16) / 2;
    final hasStories = widget.userWithStories.stories.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: _isHovered ? (Matrix4.identity()..scale(1.05)) : null,
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Stack(
              children: [
                // Main story circle with animated gradient
                Container(
                  width: circleSize,
                  height: circleSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: hasStories
                          ? [
                              const Color(0xFF6366F1),
                              const Color(0xFF22D3EE),
                              const Color(0xFFF59E0B),
                              const Color(0xFFEF4444),
                            ]
                          : [
                              Colors.grey.shade600,
                              Colors.grey.shade500,
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: hasStories
                            ? const Color(0xFF6366F1).withOpacity(0.4)
                            : Colors.grey.withOpacity(0.3),
                        blurRadius: _isHovered ? 20 : 12,
                        spreadRadius: _isHovered ? 2 : 1,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F0F0F),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Stack(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: avatarRadius,
                              backgroundColor: Colors.grey.shade800,
                              backgroundImage:
                                  (avatarUrl != null && avatarUrl.isNotEmpty)
                                      ? NetworkImage(avatarUrl)
                                      : null,
                              onBackgroundImageError: (exception, stackTrace) {
                                // Handle image loading error silently
                              },
                              child: (avatarUrl == null || avatarUrl.isEmpty)
                                  ? Icon(
                                      Icons.person,
                                      color: Colors.grey.shade400,
                                      size: avatarRadius * 0.6,
                                    )
                                  : null,
                            ),

                            // Live indicator
                            if (widget.isLive)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFEF4444)
                                            .withOpacity(0.6),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Text(
                                        'LIVE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Animated progress ring for stories
                if (hasStories)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _StoryProgressPainter(
                            progress: _rotationAnimation.value,
                            hasStories: hasStories,
                            isHovered: _isHovered,
                          ),
                        );
                      },
                    ),
                  ),

                // Story count indicator
                if (hasStories && widget.userWithStories.stories.length > 1)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        '${widget.userWithStories.stories.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Hover effect overlay
                if (_isHovered)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryProgressPainter extends CustomPainter {
  final double progress;
  final bool hasStories;
  final bool isHovered;

  _StoryProgressPainter({
    required this.progress,
    required this.hasStories,
    required this.isHovered,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!hasStories) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = isHovered ? 3.0 : 2.0;

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = const Color(0xFF22D3EE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -90 * (3.14159 / 180), // Start from top
      progress * 2 * 3.14159, // Full circle
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
