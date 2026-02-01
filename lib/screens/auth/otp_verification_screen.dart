import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gamer_flick/services/user/supabase_signup_service.dart';
import '../profile/profile_setup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../../widgets/gaming_backdrop.dart';
import '../../widgets/background_painter.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String password;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();

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

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(_shakeController);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _shakeController.dispose();
    _countdownTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() => _resendCountdown = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
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

  void _shakeFields() {
    _shakeController.forward().then((_) => _shakeController.reset());
  }

  String get _getOtpCode {
    return _otpControllers.map((controller) => controller.text).join();
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-verify when all 6 digits are entered
    if (_getOtpCode.length == 6) {
      _onVerify();
    }
  }

  Future<void> _onVerify() async {
    final otp = _getOtpCode;
    if (otp.length != 6) {
      _shakeFields();
      _showSnackBar('Please enter the complete 6-digit OTP.', isError: true);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    final signupService = SupabaseSignupService();
    try {
      final isValid =
          await signupService.verifyOtp(email: widget.email, otp: otp);
      if (isValid) {
        // Ensure the verified user is logged in and set password
        try {
          await signupService.setPasswordForCurrentUser(widget.password);
        } catch (e) {
          // If update fails because session not established, attempt a sign-in
          try {
            await Supabase.instance.client.auth.signInWithPassword(
              email: widget.email,
              password: widget.password,
            );
          } catch (_) {
            // ignore; we still navigate to profile setup, user can re-login later
          }
        }

        final user = Supabase.instance.client.auth.currentUser;
        if (user != null && mounted) {
          HapticFeedback.heavyImpact();
          _showSnackBar('Verification successful!', isError: false);
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  ProfileSetupScreen(
                email: user.email ?? widget.email,
                password: widget.password,
              ),
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
        } else {
          _showSnackBar(
              'User not authenticated after OTP verification. Please log in again.',
              isError: true);
        }
      } else {
        _shakeFields();
        HapticFeedback.heavyImpact();
        _showSnackBar('Invalid OTP. Please try again.', isError: true);
        // Clear all fields
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      _shakeFields();
      HapticFeedback.heavyImpact();
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onResend() async {
    if (_resendCountdown > 0) return;

    HapticFeedback.lightImpact();
    setState(() => _isResending = true);

    final signupService = SupabaseSignupService();
    try {
      await signupService.sendOtp(widget.email);
      _showSnackBar('OTP resent to your email.', isError: false);
      _startResendCountdown();
    } catch (e) {
      _showSnackBar('Failed to resend OTP. Please try again.', isError: true);
    } finally {
      setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
        backgroundColor: Colors.transparent,
        body: GamingBackdrop(
            child: Stack(
          children: [
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

                            // Title (match login/signup tone)
                            Text(
                              'Verify Your Email',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 8),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                children: [
                                  const TextSpan(text: 'We sent a code to '),
                                  TextSpan(
                                    text: widget.email,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // OTP Verification Card
                            AnimatedBuilder(
                              animation: _shakeAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                    offset: Offset(
                                        _shakeAnimation.value *
                                            10 *
                                            (1 - _shakeAnimation.value),
                                        0),
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 520),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          color: theme.cardColor,
                                          border: Border.all(
                                            color: const Color(0xFF00FFFF)
                                                .withOpacity(0.2),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF00FFFF)
                                                  .withOpacity(0.15),
                                              blurRadius: 40,
                                              spreadRadius: 2,
                                              offset: const Offset(0, 20),
                                            ),
                                            BoxShadow(
                                              color: const Color(0xFF8000FF)
                                                  .withOpacity(0.1),
                                              blurRadius: 30,
                                              spreadRadius: 1,
                                              offset: const Offset(0, 15),
                                            ),
                                            BoxShadow(
                                              color: theme.shadowColor
                                                  .withOpacity(0.2),
                                              blurRadius: 30,
                                              offset: const Offset(0, 15),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20.0, vertical: 16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              // Title with Icon
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          const LinearGradient(
                                                        colors: [
                                                          Color(0xFF6C7FFF),
                                                          Color(0xFF385185)
                                                        ],
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                    child: Icon(
                                                      Icons
                                                          .verified_user_outlined,
                                                      color: theme.colorScheme
                                                          .onPrimary,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    'Enter Verification Code',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 20),

                                              // OTP Input Fields
                                              Wrap(
                                                alignment: WrapAlignment.center,
                                                spacing: 10,
                                                runSpacing: 10,
                                                children:
                                                    List.generate(6, (index) {
                                                  return AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 160),
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      color: theme
                                                          .colorScheme.surface,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      border: Border.all(
                                                        color: _focusNodes[
                                                                    index]
                                                                .hasFocus
                                                            ? theme.colorScheme
                                                                .primary
                                                                .withOpacity(
                                                                    0.6)
                                                            : Colors.white
                                                                .withOpacity(
                                                                    0.06),
                                                        width: 1.2,
                                                      ),
                                                      boxShadow: _focusNodes[
                                                                  index]
                                                              .hasFocus
                                                          ? [
                                                              BoxShadow(
                                                                color: theme
                                                                    .colorScheme
                                                                    .primary
                                                                    .withOpacity(
                                                                        0.22),
                                                                blurRadius: 12,
                                                                spreadRadius:
                                                                    0.5,
                                                                offset:
                                                                    const Offset(
                                                                        0, 6),
                                                              ),
                                                            ]
                                                          : [
                                                              BoxShadow(
                                                                color: Colors
                                                                    .black
                                                                    .withOpacity(
                                                                        0.15),
                                                                blurRadius: 8,
                                                                offset:
                                                                    const Offset(
                                                                        0, 4),
                                                              ),
                                                            ],
                                                    ),
                                                    child: Center(
                                                      child: TextFormField(
                                                        controller:
                                                            _otpControllers[
                                                                index],
                                                        focusNode:
                                                            _focusNodes[index],
                                                        onTap: () =>
                                                            setState(() {}),
                                                        onEditingComplete: () =>
                                                            setState(() {}),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        textAlign:
                                                            TextAlign.center,
                                                        maxLength: 1,
                                                        cursorColor: theme
                                                            .colorScheme
                                                            .primary,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          letterSpacing: 0.8,
                                                        ),
                                                        inputFormatters: [
                                                          FilteringTextInputFormatter
                                                              .digitsOnly,
                                                        ],
                                                        onChanged: (value) =>
                                                            _onOtpChanged(
                                                                value, index),
                                                        decoration:
                                                            const InputDecoration(
                                                          counterText: '',
                                                          border:
                                                              InputBorder.none,
                                                          contentPadding:
                                                              EdgeInsets.zero,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ),

                                              const SizedBox(height: 20),

                                              // Gaming-Themed Verify Button with Neon Effects
                                              Container(
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  gradient:
                                                      const LinearGradient(
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight,
                                                    colors: [
                                                      Color(0xFF00FFFF),
                                                      Color(0xFF8000FF),
                                                      Color(0xFFFF0080),
                                                    ],
                                                  ),
                                                  border: Border.all(
                                                    color:
                                                        const Color(0xFF00FFFF)
                                                            .withOpacity(0.5),
                                                    width: 1,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(
                                                              0xFF00FFFF)
                                                          .withOpacity(0.35),
                                                      blurRadius: 18,
                                                      spreadRadius: 2,
                                                      offset:
                                                          const Offset(0, 8),
                                                    ),
                                                  ],
                                                ),
                                                child: ElevatedButton(
                                                  onPressed: _isLoading
                                                      ? null
                                                      : _onVerify,
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    foregroundColor: theme
                                                        .colorScheme.onPrimary,
                                                    shadowColor:
                                                        Colors.transparent,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14),
                                                    ),
                                                    elevation: 0,
                                                  ),
                                                  child: _isLoading
                                                      ? SizedBox(
                                                          height: 18,
                                                          width: 18,
                                                          child:
                                                              CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor: AlwaysStoppedAnimation<
                                                                    Color>(
                                                                theme
                                                                    .colorScheme
                                                                    .onPrimary),
                                                          ),
                                                        )
                                                      : const Text(
                                                          'Verify',
                                                          style: TextStyle(
                                                            fontSize: 16,
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
                                    ));
                              },
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
        )));
  }
}
