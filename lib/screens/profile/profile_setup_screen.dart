import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/logo_widget.dart';
import 'package:gamer_flick/services/user/supabase_signup_service.dart';
import '../games/game_selection_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String email;
  final String password;

  const ProfileSetupScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();

  String? _avatarUrl;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _usernameError;
  String? _emailError;
  List<String> _usernameSuggestions = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.email;

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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: AppTheme.textColor,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _onFinish() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    final signupService = SupabaseSignupService();
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null || user.email == null) {
      _showSnackBar(
          'User not authenticated or missing ID/email. Please log in again.',
          isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      await signupService.storeProfileData(
        userId: user.id,
        username: _usernameController.text.trim(),
        email: user.email!,
        avatarUrl: _avatarUrl,
        preferredGame: null,
        gameId: null,
      );

      if (mounted) {
        HapticFeedback.heavyImpact();
        _showSnackBar('Profile setup complete!');
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                GameSelectionScreen(
              username: _usernameController.text.trim(),
              email: _emailController.text.trim(),
              password: widget.password,
            ), // Changed to GameSelectionScreen
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
          (route) => false,
        );
      }
    } catch (e) {
      final error = e.toString();
      if (error.contains('Username already exists')) {
        setState(() {
          _usernameError = 'Username already exists';
          _usernameSuggestions =
              _generateUsernameSuggestions(_usernameController.text.trim());
        });
        _usernameFocusNode.requestFocus();
      } else if (error.contains('Email already exists')) {
        setState(() => _emailError = 'Email already exists');
        _emailFocusNode.requestFocus();
      } else {
        _showSnackBar(error, isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onAvatarUploaded(String url) async {
    setState(() {
      _isLoading = true;
      _usernameError = null;
      _emailError = null;
    });

    final signupService = SupabaseSignupService();
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null || user.email == null) {
      _showSnackBar(
          'User not authenticated or missing ID/email. Please log in again.',
          isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      await signupService.storeProfileData(
        userId: user.id,
        username: _usernameController.text.trim(),
        email: user.email!,
        avatarUrl: url,
        preferredGame: null,
        gameId: null,
      );

      if (mounted) {
        _showSnackBar('Profile setup complete!');
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => GameSelectionScreen(
                    username: _usernameController.text.trim(),
                    email: _emailController.text.trim(),
                    password: widget.password,
                  )), // Changed to GameSelectionScreen
          (route) => false,
        );
      }
    } catch (e) {
      final error = e.toString();
      if (error.contains('Username already exists')) {
        setState(() {
          _usernameError = 'Username already exists';
          _usernameSuggestions =
              _generateUsernameSuggestions(_usernameController.text.trim());
        });
        _usernameFocusNode.requestFocus();
      } else if (error.contains('Email already exists')) {
        setState(() => _emailError = 'Email already exists');
        _emailFocusNode.requestFocus();
      } else {
        _showSnackBar(error, isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onSkipAvatar() async {
    setState(() {
      _isLoading = true;
      _usernameError = null;
      _emailError = null;
    });

    final signupService = SupabaseSignupService();
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null || user.email == null) {
      _showSnackBar(
          'User not authenticated or missing ID/email. Please log in again.',
          isError: true);
      setState(() => _isLoading = false);
      return;
    }

    try {
      await signupService.storeProfileData(
        userId: user.id,
        username: _usernameController.text.trim(),
        email: user.email!,
        avatarUrl: null,
        preferredGame: null,
        gameId: null,
      );

      if (mounted) {
        _showSnackBar('Profile setup complete!');
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => GameSelectionScreen(
                    username: _usernameController.text.trim(),
                    email: _emailController.text.trim(),
                    password: widget.password,
                  )), // Changed to GameSelectionScreen
          (route) => false,
        );
      }
    } catch (e) {
      final error = e.toString();
      if (error.contains('Username already exists')) {
        setState(() {
          _usernameError = 'Username already exists';
          _usernameSuggestions =
              _generateUsernameSuggestions(_usernameController.text.trim());
        });
        _usernameFocusNode.requestFocus();
      } else if (error.contains('Email already exists')) {
        setState(() => _emailError = 'Email already exists');
        _emailFocusNode.requestFocus();
      } else {
        _showSnackBar(error, isError: true);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<String> _generateUsernameSuggestions(String base) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      '$base$now',
      '${base}_123',
      '${base}_official',
      '${base}1',
      '${base}01',
      '${base}_the',
      '${base}_real',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppTheme.backgroundColor,
                    AppTheme.surfaceColor,
                    AppTheme.cardColor.withOpacity(0.8),
                  ]
                : [
                    theme.colorScheme.primary.withOpacity(0.05),
                    theme.colorScheme.secondary.withOpacity(0.05)
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),

                        // Logo Section with Hero Animation
                        Hero(
                          tag: "logo",
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.cardColor,
                              border: Border.all(
                                color: AppTheme.glowCyan.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.glowCyan.withOpacity(0.15),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const LogoWidget(size: 90),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Title
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              AppTheme.glowCyan,
                              AppTheme.glowPurple,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'Complete Your Profile',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 8),
                        Text(
                          'Tell us about yourself to get started',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 40),

                        // Profile Setup Card
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: AppTheme.cardColor,
                            border: Border.all(
                              color: AppTheme.borderColor,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.glowCyan.withOpacity(0.08),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: !_isLoading
                                ? Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Header with Icon
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    AppTheme.glowCyan,
                                                    AppTheme.glowPurple,
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme.glowCyan
                                                        .withOpacity(0.3),
                                                    blurRadius: 8,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.person_add_outlined,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'Profile Setup',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.glowPurple,
                                                  ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 32),

                                        // Username Field
                                        TextFormField(
                                          controller: _usernameController,
                                          focusNode: _usernameFocusNode,
                                          decoration: InputDecoration(
                                            labelText: 'Username',
                                            hintText:
                                                'Choose a unique username',
                                            prefixIcon: const Icon(
                                                Icons.account_circle_outlined),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: theme.dividerColor),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: theme.dividerColor),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  width: 2),
                                            ),
                                            filled: true,
                                            fillColor:
                                                theme.colorScheme.surface,
                                            errorText: _usernameError,
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Please enter your username';
                                            }
                                            if (value.trim().length < 3) {
                                              return 'Username must be at least 3 characters';
                                            }
                                            return null;
                                          },
                                        ),

                                        // Username Suggestions
                                        if (_usernameSuggestions.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                top: 12.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Suggestions:',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme.textSecondaryColor,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  children: _usernameSuggestions
                                                      .map((suggestion) {
                                                    return ActionChip(
                                                      label: Text(
                                                        suggestion,
                                                        style: const TextStyle(
                                                            fontSize: 12),
                                                      ),
                                                      backgroundColor: theme
                                                          .colorScheme.primary
                                                          .withOpacity(0.1),
                                                      labelStyle: TextStyle(
                                                          color: theme
                                                              .colorScheme
                                                              .primary),
                                                      onPressed: () {
                                                        setState(() {
                                                          _usernameController
                                                                  .text =
                                                              suggestion;
                                                          _usernameError = null;
                                                          _usernameSuggestions =
                                                              [];
                                                        });
                                                        _usernameFocusNode
                                                            .requestFocus();
                                                      },
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            ),
                                          ),

                                        const SizedBox(height: 20),

                                        // Password Field
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: _obscurePassword,
                                          decoration: InputDecoration(
                                            labelText: 'Password',
                                            hintText:
                                                'Create a secure password',
                                            prefixIcon:
                                                const Icon(Icons.lock_outlined),
                                            suffixIcon: IconButton(
                                              icon: Icon(_obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword =
                                                      !_obscurePassword;
                                                });
                                              },
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: theme.dividerColor),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: theme.dividerColor),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  width: 2),
                                            ),
                                            filled: true,
                                            fillColor: AppTheme.surfaceColor,
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter your password';
                                            }
                                            if (value.length < 6) {
                                              return 'Password must be at least 6 characters long';
                                            }
                                            return null;
                                          },
                                        ),

                                        const SizedBox(height: 20),

                                        // Confirm Password Field
                                        TextFormField(
                                          controller:
                                              _confirmPasswordController,
                                          obscureText: _obscureConfirmPassword,
                                          decoration: InputDecoration(
                                            labelText: 'Confirm Password',
                                            hintText: 'Re-enter your password',
                                            prefixIcon:
                                                const Icon(Icons.lock_outline),
                                            suffixIcon: IconButton(
                                              icon: Icon(_obscureConfirmPassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined),
                                              onPressed: () {
                                                setState(() {
                                                  _obscureConfirmPassword =
                                                      !_obscureConfirmPassword;
                                                });
                                              },
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: theme.dividerColor),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: theme.dividerColor),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color:
                                                      theme.colorScheme.primary,
                                                  width: 2),
                                            ),
                                            filled: true,
                                            fillColor:
                                                theme.colorScheme.surface,
                                          ),
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
                                        ),

                                        const SizedBox(height: 20),

                                        // Email Field (Read-only)
                                        TextFormField(
                                          controller: _emailController,
                                          focusNode: _emailFocusNode,
                                          readOnly: true,
                                          decoration: InputDecoration(
                                            labelText: 'Email',
                                            prefixIcon: const Icon(
                                                Icons.email_outlined),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: theme.dividerColor),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide(
                                                  color: theme.dividerColor),
                                            ),
                                            filled: true,
                                            fillColor: AppTheme.surfaceColor,
                                            errorText: _emailError,
                                          ),
                                        ),

                                        const SizedBox(height: 32),

                                        // Finish Button
                                        Container(
                                          height: 56,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            gradient: LinearGradient(
                                              colors: [
                                                AppTheme.glowCyan,
                                                AppTheme.glowPurple,
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.glowCyan
                                                    .withOpacity(0.3),
                                                blurRadius: 15,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed:
                                                _isLoading ? null : _onFinish,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
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
                                                                  .onPrimary),
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'Complete Setup',
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: theme
                                                              .colorScheme
                                                              .onPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Icon(Icons.check_circle,
                                                          color: theme
                                                              .colorScheme
                                                              .onPrimary),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Avatar Upload Section
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  AppTheme.glowCyan,
                                                  AppTheme.glowPurple,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppTheme.glowCyan
                                                      .withOpacity(0.3),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt_outlined,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Upload Avatar',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.glowPurple,
                                                ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 24),

                                      if (_isLoading)
                                        Center(
                                          child: Column(
                                            children: [
                                              const CircularProgressIndicator(),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Setting up your profile...',
                                                style: TextStyle(
                                                  color: AppTheme.textSecondaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      const SizedBox(height: 24),

                                      // Skip Button
                                      Container(
                                        height: 56,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: AppTheme.glowCyan),
                                        ),
                                        child: ElevatedButton(
                                          onPressed:
                                              _isLoading ? null : _onSkipAvatar,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Skip for Now',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.glowCyan,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Icon(Icons.skip_next,
                                                  color: AppTheme.glowCyan),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
      ),
    );
  }
}
