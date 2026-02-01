import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

class AnimatedLogoWidget extends StatefulWidget {
  final double size;
  final bool enableParticles;
  final bool enableGlow;

  const AnimatedLogoWidget({
    super.key,
    this.size = 120,
    this.enableParticles = true,
    this.enableGlow = true,
  });

  @override
  State<AnimatedLogoWidget> createState() => _AnimatedLogoWidgetState();
}

class _AnimatedLogoWidgetState extends State<AnimatedLogoWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _colorController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _particleController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _particleAnimation;

  final List<Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.enableParticles) {
      _generateParticles();
    }
  }

  void _initializeAnimations() {
    // Pulse animation for breathing effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Float animation for subtle movement
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _floatAnimation = Tween<double>(
      begin: -3.0,
      end: 3.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    // Color animation for dynamic colors
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
    _colorAnimation = ColorTween(
      begin: const Color(0xFF00F0FF), // Cyan
      end: const Color(0xFF8E2DE2), // Purple
    ).animate(CurvedAnimation(
      parent: _colorController,
      curve: Curves.easeInOut,
    ));

    // Scale animation for hover effects
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // Rotation animation for dynamic movement
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _particleController,
      curve: Curves.easeOut,
    ));

    // Start the continuous animations
    _pulseController.repeat(reverse: true);
    _floatController.repeat(reverse: true);
    _colorController.repeat(reverse: true);
    _rotationController.repeat();
    _particleController.repeat();
  }

  void _generateParticles() {
    _particles.clear();
    for (int i = 0; i < 8; i++) {
      _particles.add(Particle(
        x: _random.nextDouble() * widget.size,
        y: _random.nextDouble() * widget.size,
        size: _random.nextDouble() * 4 + 2,
        speed: _random.nextDouble() * 2 + 1,
        angle: _random.nextDouble() * 2 * math.pi,
      ));
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
    _colorController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _scaleController.forward(),
      onExit: (_) => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseController,
          _floatController,
          _colorController,
          _scaleController,
          _rotationController,
          _particleController,
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: Transform.scale(
              scale: _pulseAnimation.value * _scaleAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.size * 0.2),
                  boxShadow: [
                    if (widget.enableGlow) ...[
                      BoxShadow(
                        color: _colorAnimation.value?.withAlpha(
                                (_colorAnimation.value!.opacity * 255)
                                    .round()) ??
                            const Color(0xFF00F0FF)
                                .withAlpha((0.4 * 255).round()),
                        blurRadius: 20 + (_pulseAnimation.value * 8),
                        offset: const Offset(0, 6),
                        spreadRadius: _pulseAnimation.value * 3,
                      ),
                      BoxShadow(
                        color: _colorAnimation.value?.withAlpha(
                                (_colorAnimation.value!.opacity * 255)
                                    .round()) ??
                            const Color(0xFF00F0FF)
                                .withAlpha((0.2 * 255).round()),
                        blurRadius: 40 + (_pulseAnimation.value * 12),
                        offset: const Offset(0, 12),
                        spreadRadius: _pulseAnimation.value * 5,
                      ),
                    ],
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _colorAnimation.value?.withAlpha(
                              (_colorAnimation.value!.opacity * 255).round()) ??
                          const Color(0xFF00F0FF)
                              .withAlpha((0.15 * 255).round()),
                      Colors.white.withAlpha((0.95 * 255).round()),
                    ],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.size * 0.2),
                  child: Stack(
                    children: [
                      // Animated background with particles
                      Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 0.8,
                            colors: [
                              _colorAnimation.value?.withOpacity(0.08) ??
                                  const Color(0xFF00F0FF).withOpacity(0.08),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child:
                            widget.enableParticles ? _buildParticles() : null,
                      ),
                      // Logo SVG with rotation
                      Center(
                        child: Transform.rotate(
                          angle:
                              _rotationAnimation.value * 0.1, // Subtle rotation
                          child: SvgPicture.asset(
                            'assets/logo.svg',
                            width: widget.size * 0.75,
                            height: widget.size * 0.75,
                            colorFilter: ColorFilter.mode(
                              _colorAnimation.value ?? const Color(0xFF00F0FF),
                              BlendMode.srcIn,
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
        },
      ),
    );
  }

  Widget _buildParticles() {
    return CustomPaint(
      painter: ParticlePainter(
        particles: _particles,
        animation: _particleAnimation,
        color: _colorAnimation.value ?? const Color(0xFF00F0FF),
      ),
      size: Size(widget.size, widget.size),
    );
  }
}

class Particle {
  double x;
  double y;
  double size;
  double speed;
  double angle;
  double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.angle,
    this.opacity = 1.0,
  });

  void update(double deltaTime) {
    x += math.cos(angle) * speed * deltaTime;
    y += math.sin(angle) * speed * deltaTime;

    // Wrap around edges
    if (x < 0) x = 120;
    if (x > 120) x = 0;
    if (y < 0) y = 120;
    if (y > 120) y = 0;
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Animation<double> animation;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6 * animation.value)
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      final opacity = (0.3 + 0.7 * animation.value) * particle.opacity;
      paint.color = color.withOpacity(opacity);

      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size * animation.value,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}
