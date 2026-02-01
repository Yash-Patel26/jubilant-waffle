import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:gamer_flick/services/core/app_initialization_service.dart';

class GamingInitialLoadingScreen extends StatefulWidget {
  const GamingInitialLoadingScreen({super.key});

  @override
  State<GamingInitialLoadingScreen> createState() =>
      _GamingInitialLoadingScreenState();
}

class _GamingInitialLoadingScreenState extends State<GamingInitialLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late AnimationController _rotationController;
  late AnimationController _textController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _textAnimation;

  final AppInitializationService _initService = AppInitializationService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _listenToInitialization();
  }

  void _listenToInitialization() {
    // Listen for completion
    _initService.progress.addListener(_checkProgress);
  }

  void _checkProgress() {
    if (_initService.isInitialized && mounted) {
      Navigator.of(context).pushReplacementNamed('/splash');
    }
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _pulseController.repeat(reverse: true);
    _glowController.repeat(reverse: true);
    _rotationController.repeat();
    _textController.forward();
  }

  @override
  void dispose() {
    _initService.progress.removeListener(_checkProgress);
    _pulseController.dispose();
    _glowController.dispose();
    _rotationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
              Color(0xFF533483),
            ],
            stops: [0.0, 0.2, 0.5, 0.8, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background overlay
            AnimatedBuilder(
              animation: _glowController,
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

            // Gaming grid pattern
            CustomPaint(
              painter: _GridPainter(),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Enhanced gaming logo
                  AnimatedBuilder(
                    animation:
                        Listenable.merge([_pulseController, _glowController]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
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
                                color: Colors.cyan
                                    .withOpacity(0.4 * _glowAnimation.value),
                                blurRadius: 30 * _glowAnimation.value,
                                spreadRadius: 10 * _glowAnimation.value,
                              ),
                              BoxShadow(
                                color: Colors.purple
                                    .withOpacity(0.3 * _glowAnimation.value),
                                blurRadius: 20 * _glowAnimation.value,
                                spreadRadius: 5 * _glowAnimation.value,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Rotating hexagon frame
                              Transform.rotate(
                                angle: _rotationAnimation.value,
                                child: SizedBox(
                                  width: 100,
                                  height: 100,
                                  child: CustomPaint(
                                    painter: _HexagonPainter(
                                      color: Colors.cyan,
                                      opacity: 0.6 * _glowAnimation.value,
                                    ),
                                  ),
                                ),
                              ),

                              // Logo
                              const Icon(
                                Icons.games,
                                size: 50,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Loading text and dynamic status
                  FadeTransition(
                    opacity: _textAnimation,
                    child: Column(
                      children: [
                        const Text(
                          'INITIALIZING GAMERFLICK',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.cyan,
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        ValueListenableBuilder<String>(
                          valueListenable: _initService.statusMessage,
                          builder: (context, message, child) {
                            return Text(
                              message,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.cyan.withOpacity(0.8),
                                letterSpacing: 1,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<double>(
                          valueListenable: _initService.progress,
                          builder: (context, progress, child) {
                            return Text(
                              '${(progress * 100).toInt()}% Complete',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.6),
                                letterSpacing: 1,
                                fontWeight: FontWeight.w400,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Gaming-style loading indicator
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      return SizedBox(
                        width: 60,
                        height: 60,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer rotating hexagon
                            Transform.rotate(
                              angle: _rotationAnimation.value,
                              child: SizedBox(
                                width: 50,
                                height: 50,
                                child: CustomPaint(
                                  painter: _HexagonPainter(
                                    color: Colors.cyan,
                                    opacity: 0.4 * _glowAnimation.value,
                                  ),
                                ),
                              ),
                            ),

                            // Progress ring tied to internal state
                            ValueListenableBuilder<double>(
                              valueListenable: _initService.progress,
                              builder: (context, progress, child) {
                                return SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: CircularProgressIndicator(
                                    value: progress > 0 ? progress : null,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.cyan.withOpacity(
                                          0.8 * _glowAnimation.value),
                                    ),
                                    strokeWidth: 3,
                                    backgroundColor:
                                        Colors.cyan.withOpacity(0.1),
                                  ),
                                );
                              },
                            ),

                            // Center pulse
                            Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.pink,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.pink.withOpacity(
                                          0.8 * _glowAnimation.value),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Corner gaming elements
            Positioned(
              top: 40,
              left: 40,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.cyan.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.games,
                        size: 24,
                        color: Colors.cyan.withOpacity(0.8),
                      ),
                    ),
                  );
                },
              ),
            ),

            Positioned(
              top: 40,
              right: 40,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 / _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.orange.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.emoji_events,
                        size: 24,
                        color: Colors.orange.withOpacity(0.8),
                      ),
                    ),
                  );
                },
              ),
            ),

            Positioned(
              bottom: 40,
              left: 40,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 / _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.purple.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.people,
                        size: 24,
                        color: Colors.purple.withOpacity(0.8),
                      ),
                    ),
                  );
                },
              ),
            ),

            Positioned(
              bottom: 40,
              right: 40,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.pink.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Icon(
                        Icons.videogame_asset,
                        size: 24,
                        color: Colors.pink.withOpacity(0.8),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.05)
      ..strokeWidth = 0.5;

    const spacing = 60.0;

    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HexagonPainter extends CustomPainter {
  final Color color;
  final double opacity;

  _HexagonPainter({required this.color, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 5;

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
