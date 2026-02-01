import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LogoWidget extends StatefulWidget {
  final double size;
  final bool enableAnimations;

  const LogoWidget({
    super.key,
    this.size = 120,
    this.enableAnimations = true,
  });

  @override
  State<LogoWidget> createState() => _LogoWidgetState();
}

class _LogoWidgetState extends State<LogoWidget> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _floatController;
  late AnimationController _colorController;
  late AnimationController _scaleController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _floatAnimation;
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
      begin: -2.0,
      end: 2.0,
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
    _floatController.repeat(reverse: true);
    _colorController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _floatController.dispose();
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
          _floatController,
          _colorController,
          _scaleController,
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
                    BoxShadow(
                      color: _colorAnimation.value?.withValues(alpha: 0.3) ??
                          Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12 + (_pulseAnimation.value * 4),
                      offset: const Offset(0, 4),
                      spreadRadius: _pulseAnimation.value * 2,
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _colorAnimation.value?.withValues(alpha: 0.1) ??
                          const Color(0xFF6C7FFF).withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.9),
                    ],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(widget.size * 0.2),
                  child: Stack(
                    children: [
                      // Animated background
                      Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 0.8,
                            colors: [
                              _colorAnimation.value?.withValues(alpha: 0.05) ??
                                  const Color(0xFF6C7FFF)
                                      .withValues(alpha: 0.05),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      // Logo SVG
                      Center(
                        child: SvgPicture.asset(
                          'assets/logo.svg',
                          width: widget.size * 0.8,
                          height: widget.size * 0.8,
                          colorFilter: ColorFilter.mode(
                            _colorAnimation.value ?? const Color(0xFF6C7FFF),
                            BlendMode.srcIn,
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

  Widget _buildStaticLogo() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SvgPicture.asset(
        'assets/logo.svg',
        width: widget.size,
        height: widget.size,
      ),
    );
  }
}
