import 'package:flutter/material.dart';

class AnimatedHeaderLogo extends StatefulWidget {
  final double size;
  final bool enableAnimations;

  const AnimatedHeaderLogo({
    super.key,
    this.size = 32,
    this.enableAnimations = true,
  });

  @override
  State<AnimatedHeaderLogo> createState() => _AnimatedHeaderLogoState();
}

class _AnimatedHeaderLogoState extends State<AnimatedHeaderLogo>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _colorController;
  late AnimationController _scaleController;

  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    if (widget.enableAnimations) {
      _initializeAnimations();
    }
  }

  void _initializeAnimations() {
    // Pulse animation for breathing effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Color animation for dynamic colors
    _colorController = AnimationController(
      duration: const Duration(milliseconds: 5000),
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
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));

    // Start the continuous animations
    _pulseController.repeat(reverse: true);
    _colorController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _colorController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableAnimations) {
      return _buildStaticLogo();
    }

    return MouseRegion(
      onEnter: (_) => _scaleController.forward(),
      onExit: (_) => _scaleController.reverse(),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseController,
          _colorController,
          _scaleController,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value * _scaleAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _colorAnimation.value ?? const Color(0xFFE91E63),
                    _colorAnimation.value?.withOpacity(0.8) ??
                        const Color(0xFF9C27B0),
                  ],
                ),
                borderRadius: BorderRadius.circular(widget.size * 0.25),
                boxShadow: [
                  BoxShadow(
                    color: _colorAnimation.value?.withOpacity(0.4) ??
                        const Color(0xFFE91E63).withOpacity(0.4),
                    blurRadius: 8 + (_pulseAnimation.value * 4),
                    offset: const Offset(0, 2),
                    spreadRadius: _pulseAnimation.value * 2,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.gamepad,
                  color: Colors.white,
                  size: widget.size * 0.6,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStaticLogo() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
        ),
        borderRadius: BorderRadius.circular(widget.size * 0.25),
      ),
      child: Center(
        child: Icon(
          Icons.gamepad,
          color: Colors.white,
          size: widget.size * 0.6,
        ),
      ),
    );
  }
}
