import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../home/home_screen.dart';
import 'enter_email_screen.dart';
import 'reset_password_screen.dart';
import '../../widgets/safe_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/repositories/storage/local_storage_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Enhanced gaming-themed custom painter for animated background elements
class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Dark black background base
    final backgroundPaint = Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Gaming neon grid pattern
    final gridPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.03) // Cyan neon
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw gaming grid
    for (int i = 0; i <= 20; i++) {
      final x = size.width * (i / 20);
      final y = size.height * (i / 20);

      // Vertical grid lines
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );

      // Horizontal grid lines
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Gaming circuit board pattern
    final circuitPaint = Paint()
      ..color = const Color(0xFF00FF00).withOpacity(0.04) // Green neon
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw circuit paths
    final circuitPath = Path();
    circuitPath.moveTo(size.width * 0.1, size.height * 0.2);
    circuitPath.lineTo(size.width * 0.3, size.height * 0.2);
    circuitPath.lineTo(size.width * 0.3, size.height * 0.4);
    circuitPath.lineTo(size.width * 0.7, size.height * 0.4);
    circuitPath.lineTo(size.width * 0.7, size.height * 0.6);
    circuitPath.lineTo(size.width * 0.9, size.height * 0.6);

    canvas.drawPath(circuitPath, circuitPaint);

    // Gaming energy orbs with neon glow
    final orbPaint1 = Paint()
      ..color = const Color(0xFFFF0080).withOpacity(0.06) // Pink neon
      ..style = PaintingStyle.fill;

    final orbPaint2 = Paint()
      ..color = const Color(0xFF8000FF).withOpacity(0.05) // Purple neon
      ..style = PaintingStyle.fill;

    final orbPaint3 = Paint()
      ..color = const Color(0xFFFF8000).withOpacity(0.04) // Orange neon
      ..style = PaintingStyle.fill;

    // Multiple gaming orbs
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.2),
      50,
      orbPaint1,
    );

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      70,
      orbPaint2,
    );

    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.8),
      40,
      orbPaint3,
    );

    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.1),
      60,
      orbPaint1,
    );

    // Gaming data streams
    final streamPaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.02) // Cyan neon
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Vertical data streams
    for (int i = 0; i < 8; i++) {
      final x = size.width * (0.1 + i * 0.1);
      final height = size.height * (0.3 + (i % 3) * 0.2);

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, height),
        streamPaint,
      );
    }

    // Gaming power nodes
    final nodePaint = Paint()
      ..color = const Color(0xFFFF0000).withOpacity(0.08) // Red neon
      ..style = PaintingStyle.fill;

    // Power nodes at grid intersections
    for (int i = 1; i < 5; i++) {
      for (int j = 1; j < 5; j++) {
        final x = size.width * (i / 5);
        final y = size.height * (j / 5);

        canvas.drawCircle(
          Offset(x, y),
          8,
          nodePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  late AnimationController _animationController;
  late AnimationController _logoAnimationController;
  late AnimationController _formAnimationController;
  late AnimationController _backgroundAnimationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFloatAnimation;
  late Animation<double> _formScaleAnimation;
  late Animation<double> _backgroundOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadRememberMeState();
  }

  void _initializeAnimations() {
    // Main animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Logo-specific animations
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Form animations
    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Background animations
    _backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Fade in animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Slide up animation for form
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    // Logo scale and float animations
    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
          parent: _logoAnimationController, curve: Curves.elasticOut),
    );

    _logoFloatAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(
          parent: _logoAnimationController, curve: Curves.easeInOut),
    );

    // Form scale animation
    _formScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
          parent: _formAnimationController, curve: Curves.easeOutBack),
    );

    // Background opacity animation
    _backgroundOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _backgroundAnimationController, curve: Curves.easeInOut),
    );

    // Start animations
    _animationController.forward();
    _logoAnimationController.repeat(reverse: true);
    _formAnimationController.forward();
    _backgroundAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _logoAnimationController.dispose();
    _formAnimationController.dispose();
    _backgroundAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Load saved remember me state and credentials
  Future<void> _loadRememberMeState() async {
    try {
      final storageRepo = ref.read(localStorageRepositoryProvider);
      final rememberMe = storageRepo.getBool('remember_me') ?? false;

      if (rememberMe) {
        final savedEmail = storageRepo.getString('saved_email');
        final savedPassword =
            await storageRepo.getSecureString('saved_password');

        if (savedEmail != null && savedPassword != null) {
          setState(() {
            _rememberMe = true;
            _emailController.text = savedEmail;
            _passwordController.text = savedPassword;
          });
        }
      }
    } catch (e) {
      // Silently handle errors to avoid breaking the login flow
    }
  }

  // Save remember me state and credentials
  Future<void> _saveRememberMeState() async {
    try {
      final storageRepo = ref.read(localStorageRepositoryProvider);

      if (_rememberMe) {
        // Save credentials
        await storageRepo.setBool('remember_me', true);
        await storageRepo.setString(
            'saved_email', _emailController.text.trim());
        await storageRepo.setSecureString(
            'saved_password', _passwordController.text.trim());
      } else {
        // Clear saved credentials
        await storageRepo.setBool('remember_me', false);
        await storageRepo.remove('saved_email');
        await storageRepo.removeSecureString('saved_password');
      }
    } catch (e) {
      // Silently handle errors to avoid breaking the login flow
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('Invalid Input'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6C7FFF),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  bool _isValidEmail(String email) {
    // More comprehensive email validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    return emailRegex.hasMatch(email) &&
        email.contains('@') &&
        email.contains('.');
  }

  // Test Supabase connection
  Future<void> _testSupabaseConnection() async {
    try {
      final supabase = Supabase.instance.client;

      // Test basic connection by getting current user (should be null if not logged in)
      final user = supabase.auth.currentUser;

      _showSnackBar('Supabase connection test completed. Check debug console.',
          isError: false);
    } catch (e) {
      _showSnackBar('Supabase connection test failed: $e', isError: true);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional validation before making the API call
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorDialog('Please enter both email and password.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorDialog('Please enter a valid email address.');
      return;
    }

    if (password.length < 6) {
      _showErrorDialog('Password must be at least 6 characters long.');
      return;
    }

    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;

      // Add debug logging

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Save remember me state and credentials if checked
        await _saveRememberMeState();

        HapticFeedback.heavyImpact();
        _showSnackBar("Welcome back!", isError: false);
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else {
        _showSnackBar("Login failed. Please check your credentials.",
            isError: true);
      }
    } on AuthException catch (e) {
      HapticFeedback.heavyImpact();

      String errorMessage;
      switch (e.statusCode) {
        case 400:
          if (e.message.contains('Invalid login credentials')) {
            errorMessage =
                'Invalid email or password. Please check your credentials and try again.';
          } else if (e.message.contains('Email not confirmed')) {
            errorMessage =
                'Please verify your email address before signing in.';
          } else {
            errorMessage =
                'Invalid request. Please check your input and try again.';
          }
          break;
        case 401:
          errorMessage =
              'Authentication failed. Please check your credentials.';
          break;
        case 422:
          errorMessage =
              'Invalid email format. Please enter a valid email address.';
          break;
        case 429:
          errorMessage =
              'Too many login attempts. Please wait a moment before trying again.';
          break;
        default:
          errorMessage = 'Login failed. Please try again later.';
      }

      _showErrorDialog(errorMessage);
    } on Exception {
      HapticFeedback.heavyImpact();
      _showErrorDialog(
          'Login failed. Please check your internet connection and try again.');
    } catch (e) {
      _showSnackBar("An unexpected error occurred.", isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return SafeScaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated background elements
            Positioned.fill(
              child: FadeTransition(
                opacity: _backgroundOpacityAnimation,
                child: CustomPaint(
                  painter: BackgroundPainter(),
                ),
              ),
            ),

            // Main content
            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: size.height * 0.08),

                          // Enhanced Gaming-Themed Logo Section with Real GamerFlick Logo
                          Hero(
                            tag: "logo",
                            child: AnimatedBuilder(
                              animation: _logoAnimationController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(0, _logoFloatAnimation.value),
                                  child: Transform.scale(
                                    scale: _logoScaleAnimation.value,
                                    child: Container(
                                      width: 160,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: RadialGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.1),
                                            Colors.cyan.withOpacity(0.05),
                                            Colors.purple.withOpacity(0.05),
                                          ],
                                        ),
                                        border: Border.all(
                                          color: Colors.cyan.withOpacity(0.3),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          // Primary cyan glow
                                          BoxShadow(
                                            color: Colors.cyan.withOpacity(0.4),
                                            blurRadius: 30,
                                            spreadRadius: 8,
                                            offset: const Offset(0, 15),
                                          ),
                                          // Secondary purple glow
                                          BoxShadow(
                                            color:
                                                Colors.purple.withOpacity(0.3),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                            offset: const Offset(0, 10),
                                          ),
                                          // Tertiary pink glow
                                          BoxShadow(
                                            color: Colors.pink.withOpacity(0.2),
                                            blurRadius: 15,
                                            spreadRadius: 3,
                                            offset: const Offset(0, 5),
                                          ),
                                          // Dark shadow for depth
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.3),
                                            blurRadius: 25,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Outer ring
                                          Container(
                                            width: 140,
                                            height: 140,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.pink
                                                    .withOpacity(0.3),
                                                width: 1,
                                                style: BorderStyle.solid,
                                              ),
                                            ),
                                          ),
                                          // Inner ring
                                          Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.cyan
                                                    .withOpacity(0.4),
                                                width: 1,
                                                style: BorderStyle.solid,
                                              ),
                                            ),
                                          ),
                                          // GamerFlick Logo
                                          SvgPicture.asset(
                                            'assets/logo.svg',
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.contain,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Gaming-Themed Form Container with Neon Effects
                          AnimatedBuilder(
                            animation: _formAnimationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _formScaleAnimation.value,
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 520),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      color: theme.cardColor,
                                      border: Border.all(
                                        color: const Color(0xFF00FFFF)
                                            .withOpacity(
                                                0.2), // Cyan neon border
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        // Primary neon glow
                                        BoxShadow(
                                          color: const Color(0xFF00FFFF)
                                              .withOpacity(0.15),
                                          blurRadius: 40,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 20),
                                        ),
                                        // Secondary neon glow
                                        BoxShadow(
                                          color: const Color(0xFF8000FF)
                                              .withOpacity(0.1),
                                          blurRadius: 30,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 15),
                                        ),
                                        // Dark shadow for depth
                                        BoxShadow(
                                          color: theme.shadowColor
                                              .withOpacity(0.2),
                                          blurRadius: 30,
                                          offset: const Offset(0, 15),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Form(
                                        key: _formKey,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            const SizedBox(height: 8),
                                            ShaderMask(
                                              shaderCallback: (bounds) =>
                                                  LinearGradient(
                                                colors: [
                                                  Colors.cyan,
                                                  Colors.purple,
                                                  Colors.pink,
                                                  Colors.orange,
                                                ],
                                              ).createShader(bounds),
                                              child: Text(
                                                'GamerFlick',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 36,
                                                  color: Colors.white,
                                                  letterSpacing: 2,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.cyan
                                                          .withOpacity(0.8),
                                                      blurRadius: 15,
                                                      offset: Offset(0, 5),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Welcome back to your gaming universe',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: Colors.cyan.shade300,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 24),

                                            // Gaming-Themed Email Field with Neon Effects
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: const Color(0xFF00FFFF)
                                                      .withOpacity(
                                                          0.1), // Subtle cyan border
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFF00FFFF)
                                                            .withOpacity(0.08),
                                                    blurRadius: 15,
                                                    spreadRadius: 1,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                  BoxShadow(
                                                    color: theme.shadowColor
                                                        .withOpacity(0.05),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: TextFormField(
                                                controller: _emailController,
                                                keyboardType:
                                                    TextInputType.emailAddress,
                                                textInputAction:
                                                    TextInputAction.next,
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'Please enter your email';
                                                  }
                                                  if (!_isValidEmail(value)) {
                                                    return 'Please enter a valid email';
                                                  }
                                                  return null;
                                                },
                                                decoration: InputDecoration(
                                                  labelText: 'Email',
                                                  hintText: 'Enter your email',
                                                  prefixIcon: Container(
                                                    margin:
                                                        const EdgeInsets.all(
                                                            12),
                                                    child: Icon(
                                                      Icons.email_outlined,
                                                      color: theme
                                                          .colorScheme.primary,
                                                    ),
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    borderSide: BorderSide(
                                                      color: theme
                                                          .colorScheme.primary,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  filled: true,
                                                  fillColor:
                                                      theme.colorScheme.surface,
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    horizontal: 20,
                                                    vertical: 16,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 20),

                                            // Gaming-Themed Password Field with Neon Effects
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                border: Border.all(
                                                  color: const Color(0xFF00FFFF)
                                                      .withOpacity(
                                                          0.1), // Subtle cyan border
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFF00FFFF)
                                                            .withOpacity(0.08),
                                                    blurRadius: 15,
                                                    spreadRadius: 1,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                  BoxShadow(
                                                    color: theme.shadowColor
                                                        .withOpacity(0.05),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: TextFormField(
                                                controller: _passwordController,
                                                obscureText: _obscurePassword,
                                                textInputAction:
                                                    TextInputAction.done,
                                                onFieldSubmitted: (_) =>
                                                    _login(),
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'Please enter your password';
                                                  }
                                                  if (value.length < 6) {
                                                    return 'Password must be at least 6 characters';
                                                  }
                                                  return null;
                                                },
                                                decoration: InputDecoration(
                                                  labelText: 'Password',
                                                  hintText:
                                                      'Enter your password',
                                                  prefixIcon: Container(
                                                    margin:
                                                        const EdgeInsets.all(
                                                            12),
                                                    child: Icon(
                                                      Icons.lock_outlined,
                                                      color: theme
                                                          .colorScheme.primary,
                                                    ),
                                                  ),
                                                  suffixIcon: IconButton(
                                                    icon: Icon(
                                                      _obscurePassword
                                                          ? Icons
                                                              .visibility_outlined
                                                          : Icons
                                                              .visibility_off_outlined,
                                                      color: theme
                                                          .colorScheme.primary,
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _obscurePassword =
                                                            !_obscurePassword;
                                                      });
                                                    },
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    borderSide: BorderSide.none,
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                    borderSide: BorderSide(
                                                      color: theme
                                                          .colorScheme.primary,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  filled: true,
                                                  fillColor:
                                                      theme.colorScheme.surface,
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    horizontal: 20,
                                                    vertical: 16,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 20),

                                            // Remember Me and Forgot Password Row
                                            LayoutBuilder(
                                              builder: (context, constraints) {
                                                final bool isNarrow =
                                                    constraints.maxWidth < 260;
                                                if (isNarrow) {
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .stretch,
                                                    children: [
                                                      Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Checkbox(
                                                            value: _rememberMe,
                                                            onChanged:
                                                                (value) async {
                                                              setState(() {
                                                                _rememberMe =
                                                                    value ??
                                                                        false;
                                                              });
                                                              await _saveRememberMeState();
                                                            },
                                                            activeColor: theme
                                                                .colorScheme
                                                                .primary,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6),
                                                            ),
                                                          ),
                                                          Flexible(
                                                            child: Text(
                                                              'Remember me',
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: theme
                                                                  .textTheme
                                                                  .bodyMedium
                                                                  ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Align(
                                                        alignment: Alignment
                                                            .centerRight,
                                                        child: TextButton(
                                                          onPressed: () {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const ResetPasswordScreen(),
                                                              ),
                                                            );
                                                          },
                                                          child: Text(
                                                            'Forgot password?',
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              color: theme
                                                                  .colorScheme
                                                                  .primary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }
                                                return Row(
                                                  children: [
                                                    Expanded(
                                                      child: Row(
                                                        children: [
                                                          Checkbox(
                                                            value: _rememberMe,
                                                            onChanged:
                                                                (value) async {
                                                              setState(() {
                                                                _rememberMe =
                                                                    value ??
                                                                        false;
                                                              });
                                                              await _saveRememberMeState();
                                                            },
                                                            activeColor: theme
                                                                .colorScheme
                                                                .primary,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          6),
                                                            ),
                                                          ),
                                                          Flexible(
                                                            child: Text(
                                                              'Remember me',
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: theme
                                                                  .textTheme
                                                                  .bodyMedium
                                                                  ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                const ResetPasswordScreen(),
                                                          ),
                                                        );
                                                      },
                                                      child: Text(
                                                        'Forgot password?',
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          color: theme
                                                              .colorScheme
                                                              .primary,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),

                                            const SizedBox(height: 28),

                                            // Gaming-Themed Sign In Button with Neon Effects
                                            Container(
                                              height: 56,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                gradient: LinearGradient(
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                  colors: [
                                                    const Color(
                                                        0xFF00FFFF), // Cyan neon
                                                    const Color(
                                                        0xFF8000FF), // Purple neon
                                                    const Color(
                                                        0xFFFF0080), // Pink neon
                                                  ],
                                                ),
                                                border: Border.all(
                                                  color: const Color(0xFF00FFFF)
                                                      .withOpacity(
                                                          0.5), // Bright cyan border
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  // Primary neon glow
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFF00FFFF)
                                                            .withOpacity(0.4),
                                                    blurRadius: 25,
                                                    spreadRadius: 3,
                                                    offset: const Offset(0, 12),
                                                  ),
                                                  // Secondary neon glow
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFF8000FF)
                                                            .withOpacity(0.3),
                                                    blurRadius: 20,
                                                    spreadRadius: 2,
                                                    offset: const Offset(0, 8),
                                                  ),
                                                  // Tertiary neon glow
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFFFF0080)
                                                            .withOpacity(0.2),
                                                    blurRadius: 15,
                                                    spreadRadius: 1,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: ElevatedButton(
                                                onPressed:
                                                    _isLoading ? null : _login,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  foregroundColor: theme
                                                      .colorScheme.onPrimary,
                                                  shadowColor:
                                                      Colors.transparent,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                child: _isLoading
                                                    ? SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                  Color>(
                                                            theme.colorScheme
                                                                .onPrimary,
                                                          ),
                                                        ),
                                                      )
                                                    : Text(
                                                        'Sign In',
                                                        style: theme.textTheme
                                                            .labelLarge
                                                            ?.copyWith(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // Enhanced Gaming-Themed Sign Up Section
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              color: Colors.white.withOpacity(0.05),
                              border: Border.all(
                                color: Colors.purple.withOpacity(0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                Text(
                                  "Don't have an account?",
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation,
                                                secondaryAnimation) =>
                                            const EnterEmailScreen(),
                                        transitionsBuilder: (context, animation,
                                            secondaryAnimation, child) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(1.0, 0.0),
                                              end: Offset.zero,
                                            ).animate(animation),
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.purple.withOpacity(0.4),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      'Sign up',
                                      style: TextStyle(
                                        color: Colors.purple.shade300,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        letterSpacing: 0.5,
                                        shadows: [
                                          Shadow(
                                            color:
                                                Colors.purple.withOpacity(0.6),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: size.height * 0.05),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
