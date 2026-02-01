import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:gamer_flick/services/core/navigation_service.dart';
import 'package:gamer_flick/widgets/animated_logo_widget.dart';
import 'package:gamer_flick/widgets/safe_scaffold.dart';
import 'package:gamer_flick/widgets/persistent_layout.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/tournament/tournaments_screen.dart';
import 'theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/config/environment.dart';
import 'package:gamer_flick/repositories/storage/storage_repository.dart';
import 'package:gamer_flick/services/core/app_initialization_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:gamer_flick/providers/user/user_notifier.dart';
import 'package:gamer_flick/providers/game/leaderboard_notifier.dart';
import 'package:gamer_flick/repositories/user/user_repository.dart';
import 'screens/onboarding/enhanced_welcome_screen.dart';
import 'screens/onboarding/animated_splash_screen.dart';
import 'screens/shared/upload_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/post/post_detail_screen.dart';
import 'screens/reels/reel_detail_screen.dart';
import 'screens/search/advanced_search_screen.dart';
import 'package:gamer_flick/providers/notification/notification_notifier.dart';
import 'package:gamer_flick/repositories/storage/local_storage_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/live/live_stream_viewer_screen.dart';
import 'screens/home/premium_screen.dart';
import 'screens/tournament/tournament_detail_screen.dart';
import 'screens/chat/random_chat_screen.dart';
import 'screens/post/create_post_screen.dart';
import 'screens/reels/reels_screen.dart';
import 'screens/live/stick_cam_screen.dart';
import 'screens/community/communities_screen.dart';
import 'screens/community/community_creation_screen.dart';
import 'screens/games/leaderboard_screen.dart';
import 'screens/home/notifications_screen.dart';
import 'screens/chat/inbox_screen.dart';
import 'screens/event/create_event_screen.dart';
import 'screens/reels/create_reel_screen.dart';
import 'dart:math' as math;
import 'widgets/auth_listener.dart';

// Helper function to wrap authenticated screens with PersistentLayout
Widget _wrapWithPersistentLayout(Widget screen, {int initialIndex = 0}) {
  return PersistentLayout(
    initialSelectedIndex: initialIndex,
    child: screen,
  );
}

// Gaming-themed initial loading screen
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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Listen to initialization service progress
    final appInit = AppInitializationService();
    
    // In case development needs a bit of visibility, we can wait logic here
    // but the actual navigation should depend on initialization completion.
    
    // We already call appInit.initialize() in main(), so we just wait for it here
    while (!appInit.isInitialized && appInit.isInitializing) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Small extra delay to ensure UI frame is ready and to show final complete state
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/splash');
      });
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
        decoration: BoxDecoration(
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
                              Icon(
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

                  SizedBox(height: 40),

                  // Loading text
                  FadeTransition(
                    opacity: _textAnimation,
                    child: Column(
                      children: [
                        Text(
                          'INITIALIZING GAMERFLICK',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.cyan.withOpacity(0.8),
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Preparing your gaming universe...',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.cyan.withOpacity(0.8),
                            letterSpacing: 1,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, child) {
                            return Text(
                              'Loading assets... • Connecting servers... • Ready to play!',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.cyan
                                    .withOpacity(0.6 * _glowAnimation.value),
                                letterSpacing: 1,
                                fontWeight: FontWeight.w400,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 50),

                  // Gaming-style loading indicator
                  ValueListenableBuilder<double>(
                    valueListenable: AppInitializationService().progress,
                    builder: (context, progress, child) {
                      return Column(
                        children: [
                          Container(
                            width: 200,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.cyan.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress.clamp(0.01, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.cyan,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.cyan.withOpacity(0.5),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
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
                                    // Progress ring
                                    SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(
                                        value: progress > 0 ? progress : null,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.cyan
                                              .withOpacity(0.8 * _glowAnimation.value),
                                        ),
                                        strokeWidth: 3,
                                        backgroundColor: Colors.cyan.withOpacity(0.1),
                                      ),
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
                      padding: EdgeInsets.all(6),
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
                      padding: EdgeInsets.all(6),
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

            // Bottom corner elements for more gaming aesthetic
            Positioned(
              bottom: 40,
              left: 40,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 / _pulseAnimation.value,
                    child: Container(
                      padding: EdgeInsets.all(6),
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
                      padding: EdgeInsets.all(6),
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

// Grid painter for gaming aesthetic
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.05)
      ..strokeWidth = 0.5;

    final spacing = 60.0;

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

// Hexagon painter for gaming aesthetic
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar configuration for eye-friendly dark mode
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF121212), // Match app background
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  // Initialize app services
  final appInit = AppInitializationService();

  try {
    await appInit.initialize();
  } catch (e) {
    // Log error but continue with app startup
    print('App initialization failed: $e');
  }

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );

    // Verify storage buckets exist after Supabase initialization
    try {
      final storageRepo = SupabaseStorageRepository(Supabase.instance.client);
      await storageRepo.ensureStorageBucketsExist();
    } catch (e) {
      print('Warning: Storage bucket verification failed: $e');
    }
  } catch (e) {
    print('Failed to initialize Supabase: $e');
    // Continue with app initialization even if Supabase fails
  }

  // Initialize timezone data
  tz.initializeTimeZones();

  // Initialize Local Storage
  final prefs = await SharedPreferences.getInstance();
  final localStorageRepo = SharedPreferencesLocalStorageRepository();
  // initialize() will be called via the override below

  runApp(
    ProviderScope(
      overrides: [
        localStorageRepositoryProvider.overrideWithValue(localStorageRepo..initialize()),
      ],
      child: const MyApp(),
    ),
  );
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateBasedOnAuth();
  }

  Future<void> _navigateBasedOnAuth() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      Navigator.of(context).pushReplacementNamed('/Home');
    } else {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedLogoWidget(
          size: 140,
          enableParticles: true,
          enableGlow: true,
        ),
      ),
    );
  }
}

// AuthListener moved to widgets/auth_listener.dart

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch notifications to initialize the notifier and subscription
    ref.watch(notificationsProvider);

    return AuthListener(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: Environment.appName,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        debugShowCheckedModeBanner: false,
        // Ensure we always show the initial loading first and then splash.
        // If you want to skip the preloader, switch back to '/splash'.
        initialRoute: '/initial-loading',
        routes: {
          '/': (context) =>
              GamingInitialLoadingScreen(), // Root shows preloader
          '/initial-loading': (context) => GamingInitialLoadingScreen(),
          '/splash': (context) => AnimatedSplashScreen(),
          '/welcome': (context) => EnhancedWelcomeScreen(),
          '/login': (context) =>
              LoginScreen(), // Replace with your actual login screen
          '/Home': (context) => _wrapWithPersistentLayout(const HomeScreen()),
          '/upload': (context) =>
              _wrapWithPersistentLayout(const UploadScreen()),
          '/chat': (context) => _wrapWithPersistentLayout(const ChatScreen()),
          '/tournaments': (context) =>
              _wrapWithPersistentLayout(const TournamentsScreen()),
          '/advanced-search': (context) =>
              _wrapWithPersistentLayout(const AdvancedSearchScreen()),
          '/live-viewer': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>?;
            final stream = args?['stream'] as Map<String, dynamic>?;
            if (stream == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Live Stream')),
                body: const Center(child: Text('Stream data missing')),
              );
            }
            return LiveStreamViewerScreen(stream: stream);
          },
          '/premium': (context) =>
              _wrapWithPersistentLayout(const PremiumScreen()),
          '/create-community': (context) =>
              _wrapWithPersistentLayout(const CommunityCreationScreen()),
          '/random-chat': (context) =>
              _wrapWithPersistentLayout(const RandomChatScreen()),
          '/create-post': (context) =>
              _wrapWithPersistentLayout(const CreatePostScreen()),
          // New routes for sidebar navigation
          '/reels': (context) => _wrapWithPersistentLayout(const ReelsScreen()),
          '/stick-cam': (context) =>
              _wrapWithPersistentLayout(const StickCamScreen()),
          '/create-event': (context) =>
              _wrapWithPersistentLayout(const CreateEventScreen()),
          '/create-reel': (context) =>
              _wrapWithPersistentLayout(const CreateReelScreen()),
          '/communities': (context) =>
              _wrapWithPersistentLayout(const CommunitiesScreen()),
          '/leaderboard': (context) =>
              _wrapWithPersistentLayout(const LeaderboardScreen()),
          '/notifications': (context) =>
              _wrapWithPersistentLayout(const NotificationsScreen()),
          '/inbox': (context) => _wrapWithPersistentLayout(const InboxScreen()),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/post-detail') {
            final args = settings.arguments as Map<String, dynamic>?;
            final postId = args?['postId'] as String?;
            final post = args?['post'] as Map<String, dynamic>?;

            if (post != null) {
              return MaterialPageRoute(
                builder: (context) =>
                    _wrapWithPersistentLayout(PostDetailScreen(post: post)),
              );
            } else if (postId != null) {
              return MaterialPageRoute(
                builder: (context) => _wrapWithPersistentLayout(
                    FutureBuilder<Map<String, dynamic>?>(
                  future: Supabase.instance.client
                      .from('posts')
                      .select(
                          '*, profiles!posts_user_id_fkey(*), post_likes(*), comments(*)')
                      .eq('id', postId)
                      .maybeSingle(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Scaffold(
                        appBar: AppBar(title: const Text('Post Detail')),
                        body: const Center(child: CircularProgressIndicator()),
                      );
                    }
                    final data = snapshot.data;
                    if (data == null) {
                      return Scaffold(
                        appBar: AppBar(title: const Text('Post Detail')),
                        body: const Center(child: Text('Post not found')),
                      );
                    }
                    return PostDetailScreen(post: data);
                  },
                )),
              );
            }
          } else if (settings.name == '/reel-detail') {
            final args = settings.arguments as Map<String, dynamic>?;
            final reelId = args?['reelId'] as String?;
            final reel = args?['reel'] as Map<String, dynamic>?;

            if (reel != null) {
              return MaterialPageRoute(
                builder: (context) =>
                    _wrapWithPersistentLayout(ReelDetailScreen(reel: reel)),
              );
            } else if (reelId != null) {
              // If only reelId is provided, you might want to fetch the reel data
              // For now, return a placeholder or error screen
              return MaterialPageRoute(
                builder: (context) => _wrapWithPersistentLayout(Scaffold(
                  appBar: AppBar(title: const Text('Reel Detail')),
                  body: const Center(
                    child: Text('Reel not found or loading...'),
                  ),
                )),
              );
            }
          } else if (settings.name == '/tournament-details') {
            final tournament = settings.arguments as dynamic;
            if (tournament != null) {
              // Extract tournament ID from the tournament object
              String tournamentId;
              if (tournament is Map<String, dynamic>) {
                tournamentId = tournament['id'] as String? ?? '';
              } else {
                // If it's a Tournament model object, try to access its id property
                tournamentId = tournament.id ?? '';
              }

              if (tournamentId.isNotEmpty) {
                return MaterialPageRoute(
                  builder: (context) => _wrapWithPersistentLayout(
                      TournamentDetailScreen(tournamentId: tournamentId)),
                );
              }
            }
            // Fallback for invalid tournament data
            return MaterialPageRoute(
              builder: (context) => _wrapWithPersistentLayout(Scaffold(
                appBar: AppBar(title: const Text('Tournament Details')),
                body: const Center(
                  child: Text('Tournament not found or invalid data'),
                ),
              )),
            );
          }
          return null;
        },
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.0)),
            child: child!,
          );
        },
      ),
    );
  }
}
