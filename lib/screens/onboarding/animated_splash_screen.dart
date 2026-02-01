import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;

// Enhanced Particle class for gaming effects
class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double life;
  double maxLife;
  double rotation;
  double rotationSpeed;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.life,
    required this.maxLife,
    required this.rotation,
    required this.rotationSpeed,
  });

  void update() {
    x += vx;
    y += vy;
    life -= 1;
    rotation += rotationSpeed;
  }

  bool isDead() => life <= 0;
}

// Gaming Grid Painter
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.1)
      ..strokeWidth = 1;

    final spacing = 50.0;

    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Particle Painter
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Guard against invalid numbers and out-of-bounds particles
      if (!particle.x.isFinite ||
          !particle.y.isFinite ||
          !particle.size.isFinite ||
          !particle.life.isFinite ||
          !particle.maxLife.isFinite ||
          particle.maxLife <= 0) {
        continue;
      }

      // Skip particles far outside the canvas to avoid excessive work
      if (particle.x < -100 ||
          particle.x > size.width + 100 ||
          particle.y < -100 ||
          particle.y > size.height + 100) {
        continue;
      }

      final opacity = (particle.life / particle.maxLife).clamp(0.0, 1.0);
      final safeSize = particle.size.clamp(0.5, 6.0);
      final rotation = particle.rotation.isFinite ? particle.rotation : 0.0;

      final paint = Paint()
        ..color = particle.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(particle.x, particle.y);
      canvas.rotate(rotation);

      // Draw different particle shapes
      if (safeSize > 3) {
        // Larger particles as diamonds
        final path = Path();
        path.moveTo(0, -safeSize);
        path.lineTo(safeSize, 0);
        path.lineTo(0, safeSize);
        path.lineTo(-safeSize, 0);
        path.close();
        canvas.drawPath(path, paint);
      } else {
        // Smaller particles as circles
        canvas.drawCircle(Offset.zero, safeSize, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Gaming Hexagon Painter
class HexagonPainter extends CustomPainter {
  final Color color;
  final double opacity;

  HexagonPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  _AnimatedSplashScreenState createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _textAnimationController;
  late AnimationController _particleAnimationController;
  late AnimationController _glowAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _hexagonAnimationController;
  late AnimationController _gridAnimationController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _hexagonRotationAnimation;
  late Animation<double> _gridOpacityAnimation;

  // Enhanced particle system
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();
  DateTime _lastParticleUpdate = DateTime.now();
  static const Duration _particleUpdateInterval = Duration(milliseconds: 50);
  bool _isDisposed = false;
  bool _hasNavigated = false;
  late final DateTime _splashStartTime;

  void _runAfter(Duration delay, void Function() action) {
    Future.delayed(delay, () {
      if (!mounted || _isDisposed) return;
      action();
    });
  }

  @override
  void initState() {
    super.initState();
    _splashStartTime = DateTime.now();

    _logoAnimationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _textAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _particleAnimationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _glowAnimationController = AnimationController(
      duration: Duration(milliseconds: 2500),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _hexagonAnimationController = AnimationController(
      duration: Duration(milliseconds: 3000),
      vsync: this,
    );

    _gridAnimationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.easeInOut,
    ));

    _textSlideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeOutBack,
    ));

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowAnimationController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    _hexagonRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _hexagonAnimationController,
      curve: Curves.linear,
    ));

    _gridOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gridAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start animations (guarded against dispose)
    _logoAnimationController.forward();
    _runAfter(const Duration(milliseconds: 500), () {
      _textAnimationController.forward();
    });
    _runAfter(const Duration(milliseconds: 300), () {
      _particleAnimationController.repeat();
    });
    _runAfter(const Duration(milliseconds: 200), () {
      _glowAnimationController.repeat(reverse: true);
    });
    _runAfter(const Duration(milliseconds: 400), () {
      _pulseAnimationController.repeat(reverse: true);
    });
    _runAfter(const Duration(milliseconds: 600), () {
      _hexagonAnimationController.repeat();
    });
    _runAfter(const Duration(milliseconds: 100), () {
      _gridAnimationController.forward();
    });

    // Initialize particles
    _initializeParticles();

    // Start the app initialization process
    _initializeApp();
  }

  void _initializeParticles() {
    for (int i = 0; i < 30; i++) {
      _particles.add(Particle(
        x: _random.nextDouble() * 400,
        y: _random.nextDouble() * 800,
        vx: (_random.nextDouble() - 0.5) * 2,
        vy: (_random.nextDouble() - 0.5) * 2,
        size: _random.nextDouble() * 4 + 1,
        color: [
          Colors.cyan,
          Colors.purple,
          Colors.pink,
          Colors.orange,
          Colors.blue,
          Colors.green,
        ][_random.nextInt(6)],
        life: _random.nextDouble() * 100 + 50,
        maxLife: _random.nextDouble() * 100 + 50,
        rotation: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
      ));
    }
  }

  void _updateParticles() {
    final now = DateTime.now();
    if (now.difference(_lastParticleUpdate) < _particleUpdateInterval) {
      return;
    }
    _lastParticleUpdate = now;

    if (_particles.length > 40) {
      _particles.clear();
      _initializeParticles();
      return;
    }

    for (int i = _particles.length - 1; i >= 0; i--) {
      final particle = _particles[i];
      particle.update();

      if (particle.x < -50 ||
          particle.x > 450 ||
          particle.y < -50 ||
          particle.y > 850) {
        particle.life = 0;
      }

      if (particle.isDead()) {
        _particles.removeAt(i);
        _particles.add(Particle(
          x: _random.nextDouble() * 400,
          y: _random.nextDouble() * 800,
          vx: (_random.nextDouble() - 0.5) * 2,
          vy: (_random.nextDouble() - 0.5) * 2,
          size: _random.nextDouble() * 4 + 1,
          color: [
            Colors.cyan,
            Colors.purple,
            Colors.pink,
            Colors.orange,
            Colors.blue,
            Colors.green,
          ][_random.nextInt(6)],
          life: _random.nextDouble() * 100 + 50,
          maxLife: _random.nextDouble() * 100 + 50,
          rotation: _random.nextDouble() * 2 * math.pi,
          rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
        ));
      }
    }
  }

  void _initializeApp() async {
    try {
      final auth = Supabase.instance.client.auth;

      // 1) Check current session
      final currentUser = auth.currentUser;
      if (currentUser != null) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pushReplacementNamed(context, '/Home');
          });
        }
        return;
      }

      // 2) Try to get initial session from stream
      try {
        final initial = await auth.onAuthStateChange.first.timeout(
          const Duration(seconds: 3),
        );
        if (initial.session?.user != null) {
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.pushReplacementNamed(context, '/Home');
            });
          }
          return;
        }
      } catch (_) {
        // Ignore timeout or stream errors and continue to fallback path
      }

      // 3) Fallback: try one refresh
      try {
        await auth.refreshSession();
      } catch (_) {}

      // Enforce a minimum visible duration for this splash
      final minDuration = const Duration(milliseconds: 1600);
      final elapsed = DateTime.now().difference(_splashStartTime);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }

      if (!mounted || _isDisposed || _hasNavigated) return;

      final userAfterRefresh = auth.currentUser;
      _hasNavigated = true;
      if (userAfterRefresh != null) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pushReplacementNamed(context, '/Home');
          });
        }
      } else {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pushReplacementNamed(context, '/welcome');
          });
        }
      }
    } catch (e) {
      // If there's an error checking user status, default to welcome screen
      if (mounted && !_hasNavigated) {
        _hasNavigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pushReplacementNamed(context, '/welcome');
        });
      }
    }
  }

  Future<void> _checkUserStatusAndNavigate() async {
    try {
      final auth = Supabase.instance.client.auth;

      // 1) Try to use existing user (fast path)
      final existingUser = auth.currentUser;
      if (existingUser != null) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pushReplacementNamed(context, '/Home');
          });
        }
        return;
      }

      // 2) Wait briefly for initial session rehydration event (web/android reliability)
      try {
        final initial = await auth.onAuthStateChange.first.timeout(
          const Duration(seconds: 3),
        );
        if (initial.session?.user != null) {
          Navigator.pushReplacementNamed(context, '/Home');
          return;
        }
      } catch (_) {
        // Ignore timeout or stream errors and continue to fallback path
      }

      // 3) Fallback: try one refresh
      try {
        await auth.refreshSession();
      } catch (_) {}

      final userAfterRefresh = auth.currentUser;
      if (userAfterRefresh != null) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pushReplacementNamed(context, '/Home');
          });
        }
      } else {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pushReplacementNamed(context, '/welcome');
          });
        }
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pushReplacementNamed(context, '/welcome');
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Best-effort stop before dispose to avoid post-dispose callbacks
    try {
      _logoAnimationController.stop();
    } catch (_) {}
    try {
      _textAnimationController.stop();
    } catch (_) {}
    try {
      _particleAnimationController.stop();
    } catch (_) {}
    try {
      _glowAnimationController.stop();
    } catch (_) {}
    try {
      _pulseAnimationController.stop();
    } catch (_) {}
    try {
      _hexagonAnimationController.stop();
    } catch (_) {}
    try {
      _gridAnimationController.stop();
    } catch (_) {}
    _logoAnimationController.dispose();
    _textAnimationController.dispose();
    _particleAnimationController.dispose();
    _glowAnimationController.dispose();
    _pulseAnimationController.dispose();
    _hexagonAnimationController.dispose();
    _gridAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Enhanced Animated Background with Gaming Aesthetics
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A0A0A), // Deepest black
                  Color(0xFF1A1A2E), // Dark blue-black
                  Color(0xFF16213E), // Navy blue
                  Color(0xFF0F3460), // Deep blue
                  Color(0xFF533483), // Purple accent
                ],
                stops: [0.0, 0.2, 0.5, 0.8, 1.0],
              ),
            ),
          ),

          // Animated gradient overlay for dynamic effect
          AnimatedBuilder(
            animation: _glowAnimationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      Colors.cyan.withOpacity(0.1 * _glowAnimation.value),
                      Colors.purple.withOpacity(0.05 * _glowAnimation.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),

          // Particle System
          AnimatedBuilder(
            animation: _particleAnimationController,
            builder: (context, child) {
              if (mounted && _particles.isNotEmpty) {
                _updateParticles();
              }
              return CustomPaint(
                painter: ParticlePainter(_particles),
                size: Size.infinite,
              );
            },
          ),

          // Gaming Grid Effect
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(),
            ),
          ),

          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Enhanced Gaming Logo with Hexagon Frame
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _logoAnimationController,
                    _glowAnimationController,
                    _pulseAnimationController,
                    _hexagonAnimationController,
                  ]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScaleAnimation.value * _pulseAnimation.value,
                      child: Opacity(
                        opacity: _logoOpacityAnimation.value,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Rotating hexagon frame
                            Transform.rotate(
                              angle: _hexagonRotationAnimation.value,
                              child: SizedBox(
                                width: 200,
                                height: 200,
                                child: CustomPaint(
                                  painter: HexagonPainter(
                                    color: Colors.cyan,
                                    opacity: 0.6 * _glowAnimation.value,
                                  ),
                                ),
                              ),
                            ),

                            // Inner hexagon frame
                            Transform.rotate(
                              angle: -_hexagonRotationAnimation.value * 0.5,
                              child: SizedBox(
                                width: 160,
                                height: 160,
                                child: CustomPaint(
                                  painter: HexagonPainter(
                                    color: Colors.purple,
                                    opacity: 0.4 * _glowAnimation.value,
                                  ),
                                ),
                              ),
                            ),

                            // Main logo container with enhanced effects
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.9),
                                    Colors.cyan.withOpacity(0.3),
                                    Colors.purple.withOpacity(0.2),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.cyan.withOpacity(
                                        0.4 * _glowAnimation.value),
                                    blurRadius: 40 * _glowAnimation.value,
                                    spreadRadius: 15 * _glowAnimation.value,
                                  ),
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(
                                        0.3 * _glowAnimation.value),
                                    blurRadius: 30 * _glowAnimation.value,
                                    spreadRadius: 10 * _glowAnimation.value,
                                  ),
                                  BoxShadow(
                                    color: Colors.pink.withOpacity(
                                        0.2 * _glowAnimation.value),
                                    blurRadius: 20 * _glowAnimation.value,
                                    spreadRadius: 5 * _glowAnimation.value,
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Animated outer ring
                                  AnimatedBuilder(
                                    animation: _pulseAnimationController,
                                    builder: (context, child) {
                                      return Container(
                                        width: 130,
                                        height: 130,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.cyan.withOpacity(
                                                0.6 * _pulseAnimation.value),
                                            width: 2,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // Animated inner ring
                                  AnimatedBuilder(
                                    animation: _pulseAnimationController,
                                    builder: (context, child) {
                                      return Container(
                                        width: 110,
                                        height: 110,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.pink.withOpacity(0.4 *
                                                (1.0 / _pulseAnimation.value)),
                                            width: 1.5,
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // GamerFlick Logo with enhanced styling
                                  SizedBox(
                                    width: 90,
                                    height: 90,
                                    child: SvgPicture.asset(
                                      'assets/logo.svg',
                                      fit: BoxFit.contain,
                                      colorFilter: ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 50),

                // Enhanced Gaming Text with Dynamic Effects
                SlideTransition(
                  position: _textSlideAnimation,
                  child: FadeTransition(
                    opacity: _textOpacityAnimation,
                    child: Column(
                      children: [
                        // Main title with enhanced gaming effects
                        AnimatedBuilder(
                          animation: _glowAnimationController,
                          builder: (context, child) {
                            return ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [
                                  Colors.cyan,
                                  Colors.purple,
                                  Colors.pink,
                                  Colors.orange,
                                  Colors.cyan,
                                ],
                                stops: [
                                  0.0,
                                  0.25,
                                  0.5,
                                  0.75,
                                  1.0,
                                ],
                                transform: GradientRotation(
                                    _glowAnimation.value * 2 * math.pi),
                              ).createShader(bounds),
                              child: Text(
                                'GamerFlick',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 4,
                                  shadows: [
                                    Shadow(
                                      color: Colors.cyan.withOpacity(
                                          0.9 * _glowAnimation.value),
                                      blurRadius: 15 * _glowAnimation.value,
                                      offset: Offset(0, 3),
                                    ),
                                    Shadow(
                                      color: Colors.purple.withOpacity(
                                          0.6 * _glowAnimation.value),
                                      blurRadius: 10 * _glowAnimation.value,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 20),

                        // Animated tagline with gaming effects
                        AnimatedBuilder(
                          animation: _pulseAnimationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 0.95 + (0.05 * _pulseAnimation.value),
                              child: Text(
                                'LEVEL UP YOUR GAMING',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white.withOpacity(0.95),
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w700,
                                  shadows: [
                                    Shadow(
                                      color: Colors.cyan.withOpacity(0.5),
                                      blurRadius: 5,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 12),

                        // Gaming motto with enhanced styling
                        AnimatedBuilder(
                          animation: _glowAnimationController,
                          builder: (context, child) {
                            return Text(
                              'CONNECT • COMPETE • CONQUER',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.cyan
                                    .withOpacity(0.8 * _glowAnimation.value),
                                letterSpacing: 2,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    color: Colors.cyan.withOpacity(
                                        0.3 * _glowAnimation.value),
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 60),

                // Enhanced Gaming Loading Animation
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _textAnimationController,
                    _pulseAnimationController,
                    _glowAnimationController,
                  ]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textOpacityAnimation.value,
                      child: Column(
                        children: [
                          // Multi-layered gaming loading indicator
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer rotating hexagon
                                Transform.rotate(
                                  angle: _glowAnimation.value * 2 * math.pi,
                                  child: SizedBox(
                                    width: 70,
                                    height: 70,
                                    child: CustomPaint(
                                      painter: HexagonPainter(
                                        color: Colors.cyan,
                                        opacity: 0.4 * _pulseAnimation.value,
                                      ),
                                    ),
                                  ),
                                ),

                                // Middle ring with progress
                                SizedBox(
                                  width: 55,
                                  height: 55,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.cyan.withOpacity(
                                          0.8 * _glowAnimation.value),
                                    ),
                                    strokeWidth: 3,
                                    backgroundColor:
                                        Colors.cyan.withOpacity(0.1),
                                  ),
                                ),

                                // Inner ring with reverse progress
                                Transform.rotate(
                                  angle: math.pi,
                                  child: SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.purple.withOpacity(
                                            0.6 * _pulseAnimation.value),
                                      ),
                                      strokeWidth: 2,
                                      backgroundColor:
                                          Colors.purple.withOpacity(0.1),
                                    ),
                                  ),
                                ),

                                // Center logo asset instead of icon
                                Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Colors.pink,
                                          Colors.purple,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.pink.withOpacity(
                                              0.8 * _glowAnimation.value),
                                          blurRadius: 10 * _glowAnimation.value,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                    child: SvgPicture.asset(
                                      'assets/logo.svg',
                                      width: 8,
                                      height: 8,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 25),

                          // Enhanced loading text with gaming terminology
                          AnimatedBuilder(
                            animation: _glowAnimationController,
                            builder: (context, child) {
                              return Column(
                                children: [
                                  Text(
                                    'INITIALIZING GAMING UNIVERSE',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w600,
                                      shadows: [
                                        Shadow(
                                          color: Colors.cyan.withOpacity(
                                              0.5 * _glowAnimation.value),
                                          blurRadius: 3,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Loading assets... • Connecting servers... • Ready to play!',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.cyan.withOpacity(
                                          0.6 * _glowAnimation.value),
                                      letterSpacing: 1,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Enhanced Corner Gaming Elements
          Positioned(
            top: 60,
            left: 60,
            child: AnimatedBuilder(
              animation: Listenable.merge(
                  [_pulseAnimationController, _glowAnimationController]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.cyan.withOpacity(0.2 * _glowAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.games,
                      size: 28,
                      color:
                          Colors.cyan.withOpacity(0.7 * _glowAnimation.value),
                    ),
                  ),
                );
              },
            ),
          ),

          Positioned(
            top: 60,
            right: 60,
            child: AnimatedBuilder(
              animation: Listenable.merge(
                  [_pulseAnimationController, _glowAnimationController]),
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 / _pulseAnimation.value,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.orange.withOpacity(0.2 * _glowAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.emoji_events,
                      size: 28,
                      color:
                          Colors.orange.withOpacity(0.7 * _glowAnimation.value),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom corner elements
          Positioned(
            bottom: 60,
            left: 60,
            child: AnimatedBuilder(
              animation: Listenable.merge(
                  [_pulseAnimationController, _glowAnimationController]),
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 / _pulseAnimation.value,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.purple.withOpacity(0.2 * _glowAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.people,
                      size: 28,
                      color:
                          Colors.purple.withOpacity(0.7 * _glowAnimation.value),
                    ),
                  ),
                );
              },
            ),
          ),

          Positioned(
            bottom: 60,
            right: 60,
            child: AnimatedBuilder(
              animation: Listenable.merge(
                  [_pulseAnimationController, _glowAnimationController]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.pink.withOpacity(0.2 * _glowAnimation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.videogame_asset,
                      size: 28,
                      color:
                          Colors.pink.withOpacity(0.7 * _glowAnimation.value),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
