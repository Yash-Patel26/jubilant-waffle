import 'package:flutter/material.dart';

class GamingBackdrop extends StatelessWidget {
  final Widget child;
  final bool showGrid;
  final bool showOrbs;
  final bool animateGlow;

  const GamingBackdrop({
    super.key,
    required this.child,
    this.showGrid = true,
    this.showOrbs = true,
    this.animateGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient
        Container(
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
        ),

        // Subtle animated radial glow
        if (animateGlow) const _AnimatedGlowOverlay(),

        // Optional grid and orbs
        if (showGrid || showOrbs)
          IgnorePointer(
            ignoring: true,
            child: CustomPaint(
              painter:
                  _GamingDecorPainter(showGrid: showGrid, showOrbs: showOrbs),
              size: Size.infinite,
            ),
          ),

        // Page content
        Positioned.fill(child: child),
      ],
    );
  }
}

class _AnimatedGlowOverlay extends StatefulWidget {
  const _AnimatedGlowOverlay();

  @override
  State<_AnimatedGlowOverlay> createState() => _AnimatedGlowOverlayState();
}

class _AnimatedGlowOverlayState extends State<_AnimatedGlowOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _glow = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.3,
              colors: [
                Colors.cyan.withOpacity(0.08 * _glow.value),
                Colors.purple.withOpacity(0.04 * _glow.value),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GamingDecorPainter extends CustomPainter {
  final bool showGrid;
  final bool showOrbs;

  _GamingDecorPainter({required this.showGrid, required this.showOrbs});

  @override
  void paint(Canvas canvas, Size size) {
    if (showGrid) {
      final gridPaint = Paint()
        ..color = const Color(0xFF00FFFF).withOpacity(0.05)
        ..strokeWidth = 0.6;

      const spacing = 64.0;
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      }
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }

    if (showOrbs) {
      final cyanOrb = Paint()
        ..color = const Color(0xFF00FFFF).withOpacity(0.06)
        ..style = PaintingStyle.fill;
      final purpleOrb = Paint()
        ..color = const Color(0xFF8000FF).withOpacity(0.05)
        ..style = PaintingStyle.fill;
      final pinkOrb = Paint()
        ..color = const Color(0xFFFF0080).withOpacity(0.05)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
          Offset(size.width * 0.18, size.height * 0.22), 80, cyanOrb);
      canvas.drawCircle(
          Offset(size.width * 0.85, size.height * 0.72), 110, purpleOrb);
      canvas.drawCircle(
          Offset(size.width * 0.10, size.height * 0.82), 70, pinkOrb);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
