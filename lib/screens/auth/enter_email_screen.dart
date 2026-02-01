import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamer_flick/services/user/supabase_signup_service.dart';
import 'otp_verification_screen.dart';
import '../../widgets/gaming_backdrop.dart';
import '../../widgets/background_painter.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EnterEmailScreen extends StatefulWidget {
  const EnterEmailScreen({super.key});

  @override
  State<EnterEmailScreen> createState() => _EnterEmailScreenState();
}

class _EnterEmailScreenState extends State<EnterEmailScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutBack));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  Future<void> _onContinue() async {
    if (!_formKey.currentState!.validate()) return;

    HapticFeedback.lightImpact();

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() => _isLoading = true);

    final signupService = SupabaseSignupService();
    try {
      await signupService.sendOtp(email);
      if (mounted) {
        HapticFeedback.heavyImpact();
        _showSnackBar('OTP sent successfully!', isError: false);
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                OtpVerificationScreen(email: email, password: password),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GamingBackdrop(
        child: Stack(
          children: [
            // Match login: full-screen animated background painter
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundPainter(),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),

                            // Back Button
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    Navigator.of(context).pop();
                                  },
                                  icon: Icon(
                                    Icons.arrow_back_ios_new,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Logo Section styled like login
                            Hero(
                              tag: "logo",
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
                                    BoxShadow(
                                      color: Colors.cyan.withOpacity(0.4),
                                      blurRadius: 30,
                                      spreadRadius: 8,
                                      offset: const Offset(0, 15),
                                    ),
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                      offset: const Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: Colors.pink.withOpacity(0.2),
                                      blurRadius: 15,
                                      spreadRadius: 3,
                                      offset: const Offset(0, 5),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 25,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 140,
                                      height: 140,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.pink.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.cyan.withOpacity(0.4),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    // Center logo (same as login)
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

                            const SizedBox(height: 24),

                            const SizedBox(height: 24),

                            // Gaming-Themed Form Container with Neon Effects
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  color: theme.cardColor,
                                  border: Border.all(
                                    color: const Color(0xFF00FFFF)
                                        .withOpacity(0.2), // Cyan neon border
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
                                      color: theme.shadowColor.withOpacity(0.2),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const SizedBox(height: 8),
                                        ShaderMask(
                                          shaderCallback: (bounds) =>
                                              const LinearGradient(
                                            colors: [
                                              Colors.cyan,
                                              Colors.purple,
                                              Colors.pink,
                                              Colors.orange,
                                            ],
                                          ).createShader(bounds),
                                          child: const Text(
                                            'Create Account',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 32,
                                              color: Colors.white,
                                              letterSpacing: 1.2,
                                              shadows: [
                                                Shadow(
                                                  color: Color(0xFF00FFFF),
                                                  blurRadius: 14,
                                                  offset: Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 8),
                                        Text(
                                          'Enter your email and password to get started',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: theme
                                                .textTheme.bodyMedium?.color
                                                ?.withOpacity(0.7),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                          ),
                                        ),

                                        const SizedBox(height: 32),

                                        // Enhanced Email Field
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: const Color(0xFF00FFFF)
                                                  .withOpacity(0.1),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF00FFFF)
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
                                            onFieldSubmitted: (_) =>
                                                _onContinue(),
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
                                              labelText: 'Email Address',
                                              hintText:
                                                  'your.email@example.com',
                                              prefixIcon: Container(
                                                margin:
                                                    const EdgeInsets.all(12),
                                                child: Icon(
                                                  Icons.email_outlined,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide.none,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide.none,
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  width: 2,
                                                ),
                                              ),
                                              filled: true,
                                              fillColor:
                                                  theme.colorScheme.surface,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 16,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 24),

                                        // Enhanced Password Field
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: const Color(0xFF00FFFF)
                                                  .withOpacity(0.1),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF00FFFF)
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
                                                TextInputAction.next,
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please enter a password';
                                              }
                                              if (!_isValidPassword(value)) {
                                                return 'Password must be at least 6 characters';
                                              }
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                              labelText: 'Password',
                                              hintText: 'Enter your password',
                                              prefixIcon: Container(
                                                margin:
                                                    const EdgeInsets.all(12),
                                                child: Icon(
                                                  Icons.lock_outlined,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                              ),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _obscurePassword
                                                      ? Icons
                                                          .visibility_outlined
                                                      : Icons
                                                          .visibility_off_outlined,
                                                  color:
                                                      theme.colorScheme.primary,
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
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide.none,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide.none,
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  width: 2,
                                                ),
                                              ),
                                              filled: true,
                                              fillColor:
                                                  theme.colorScheme.surface,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 16,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 24),

                                        // Enhanced Confirm Password Field
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: const Color(0xFF00FFFF)
                                                  .withOpacity(0.1),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF00FFFF)
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
                                            controller:
                                                _confirmPasswordController,
                                            obscureText:
                                                _obscureConfirmPassword,
                                            textInputAction:
                                                TextInputAction.done,
                                            onFieldSubmitted: (_) =>
                                                _onContinue(),
                                            validator: (value) {
                                              if (value == null ||
                                                  value.isEmpty) {
                                                return 'Please confirm your password';
                                              }
                                              if (value !=
                                                  _passwordController.text) {
                                                return 'Passwords do not match';
                                              }
                                              return null;
                                            },
                                            decoration: InputDecoration(
                                              labelText: 'Confirm Password',
                                              hintText: 'Confirm your password',
                                              prefixIcon: Container(
                                                margin:
                                                    const EdgeInsets.all(12),
                                                child: Icon(
                                                  Icons.lock_outlined,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                              ),
                                              suffixIcon: IconButton(
                                                icon: Icon(
                                                  _obscureConfirmPassword
                                                      ? Icons
                                                          .visibility_outlined
                                                      : Icons
                                                          .visibility_off_outlined,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    _obscureConfirmPassword =
                                                        !_obscureConfirmPassword;
                                                  });
                                                },
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide.none,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide.none,
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                borderSide: BorderSide(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  width: 2,
                                                ),
                                              ),
                                              filled: true,
                                              fillColor:
                                                  theme.colorScheme.surface,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 16,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 28),

                                        // Gaming-Themed Continue Button with Neon Effects
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
                                                color: const Color(0xFF00FFFF)
                                                    .withOpacity(0.4),
                                                blurRadius: 25,
                                                spreadRadius: 3,
                                                offset: const Offset(0, 12),
                                              ),
                                              // Secondary neon glow
                                              BoxShadow(
                                                color: const Color(0xFF8000FF)
                                                    .withOpacity(0.3),
                                                blurRadius: 20,
                                                spreadRadius: 2,
                                                offset: const Offset(0, 8),
                                              ),
                                              // Tertiary neon glow
                                              BoxShadow(
                                                color: const Color(0xFFFF0080)
                                                    .withOpacity(0.2),
                                                blurRadius: 15,
                                                spreadRadius: 1,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed:
                                                _isLoading ? null : _onContinue,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              foregroundColor:
                                                  theme.colorScheme.onPrimary,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
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
                                                    'Continue',
                                                    style: theme
                                                        .textTheme.labelLarge
                                                        ?.copyWith(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                          ),
                                        ),

                                        const SizedBox(height: 24),

                                        // Terms and Privacy
                                        Text(
                                          'By continuing, you agree to our Terms of Service and Privacy Policy',
                                          textAlign: TextAlign.center,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme
                                                .textTheme.bodySmall?.color
                                                ?.withOpacity(0.6),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Enhanced Sign In Section
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
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Already have an account? ",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.7),
                                      fontSize: 16,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(
                                      'Sign in',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
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
