import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/logo_widget.dart';
import 'package:gamer_flick/services/user/supabase_signup_service.dart';
import '../home/home_screen.dart';
import 'game_details_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GameSelectionScreen extends StatefulWidget {
  final String username;
  final String email;
  final String password;

  const GameSelectionScreen({
    super.key,
    required this.username,
    required this.email,
    required this.password,
  });

  @override
  State<GameSelectionScreen> createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen>
    with TickerProviderStateMixin {
  String? _selectedGame;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Hardcoded games with images
  final Map<String, Map<String, dynamic>> _games = {
    'BGMI': {
      'image':
          'https://upload.wikimedia.org/wikipedia/en/thumb/6/63/Battleground_Mobile_India.webp/240px-Battleground_Mobile_India.webp.png',
      'color': const Color(0xFFFF6B35),
      'description': 'Battlegrounds Mobile India',
      'genre': 'Battle Royale',
    },
    'Valorant': {
      'image':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/Valorant_logo_-_pink_color_version.svg/1280px-Valorant_logo_-_pink_color_version.svg.png',
      'color': const Color(0xFFFF4655),
      'description': 'Tactical FPS Game',
      'genre': 'Tactical FPS',
    },
    'Apex Legends': {
      'image':
          'https://encrypted-tbn3.gstatic.com/images?q=tbn:ANd9GcTb3m_BWQxdS_09torGZNfNx6rLwPG0KJLZmN4hXASgPTGHP8B3',
      'color': const Color(0xFFFF6600),
      'description': 'Battle Royale Shooter',
      'genre': 'Battle Royale',
    },
    'PUBG Mobile': {
      'image':
          'https://upload.wikimedia.org/wikipedia/en/thumb/4/44/PlayerUnknown%27s_Battlegrounds_Mobile.webp/180px-PlayerUnknown%27s_Battlegrounds_Mobile.webp.png',
      'color': const Color(0xFFF2A900),
      'description': 'Battle Royale Mobile',
      'genre': 'Battle Royale',
    },
    'Free Fire': {
      'image':
          'https://upload.wikimedia.org/wikipedia/commons/9/9a/Free_fire.jpg',
      'color': const Color(0xFF00D4FF),
      'description': 'Survival Shooter',
      'genre': 'Battle Royale',
    },
    'Call of Duty': {
      'image':
          'https://upload.wikimedia.org/wikipedia/en/7/7c/Call_Of_Duty_%282003%29%2CCover%2CUpdated.jpg',
      'color': const Color(0xFF0066CC),
      'description': 'First Person Shooter',
      'genre': 'FPS',
    },
  };

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

  Future<void> _onFinishSetup() async {
    if (_selectedGame == null) {
      _showSnackBar('Please select a game to continue', isError: true);
      return;
    }

    HapticFeedback.lightImpact();

    // Navigate to game details screen instead of directly finishing setup
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            GameDetailsScreen(
          selectedGame: _selectedGame!,
          gameColor: _games[_selectedGame]!['color'],
          username: widget.username,
          email: widget.email,
          password: widget.password,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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

    // If user completed game details, proceed with signup
    if (result != null && result is Map<String, String>) {
      await _completeSignup(result['gameName']!, result['gameId']!);
    }
  }

  Future<void> _completeSignup(String gameName, String gameId) async {
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
        username: widget.username,
        email: user.email!,
        avatarUrl: null,
        preferredGame: _selectedGame,
        gameId: gameId,
      );

      if (mounted) {
        HapticFeedback.heavyImpact();
        _showSnackBar('Profile setup complete! Welcome to GamerFlick!');
        await Future.delayed(const Duration(seconds: 1));
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
          (route) => false,
        );
      }
    } catch (e) {
      _showSnackBar('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Removed skip option to enforce selecting a game during profile creation

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
                    AppTheme.cardColor.withOpacity(0.9),
                  ]
                : [Colors.blue[50]!, Colors.indigo[50]!],
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
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        // Back Button
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.glowCyan.withOpacity(0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.glowCyan.withOpacity(0.1),
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
                                color: AppTheme.glowCyan,
                              ),
                            ),
                          ),
                        ),
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
                            'Choose Your Game',
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
                          'Select your preferred game to connect with other players',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        // Game Selection Container
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: AppTheme.cardColor,
                            border: Border.all(
                              color: AppTheme.borderColor,
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
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header
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
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.glowCyan
                                                .withOpacity(0.3),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.videogame_asset_outlined,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Select Game',
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
                                // Games Grid
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1.4,
                                  ),
                                  itemCount: _games.length,
                                  itemBuilder: (context, index) {
                                    final gameEntry =
                                        _games.entries.elementAt(index);
                                    final gameName = gameEntry.key;
                                    final gameData = gameEntry.value;
                                    final isSelected =
                                        _selectedGame == gameName;

                                    return GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          _selectedGame = gameName;
                                        });
                                      },
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 200),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color: isSelected
                                                ? gameData['color'] as Color
                                                : AppTheme.borderColor,
                                            width: isSelected ? 3 : 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isSelected
                                                  ? (gameData['color'] as Color)
                                                      .withOpacity(0.3)
                                                  : AppTheme.shadowColor,
                                              blurRadius: isSelected ? 15 : 5,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                          color: AppTheme.cardColor,
                                        ),
                                        child: Column(
                                          children: [
                                            // Game Image
                                            Expanded(
                                              flex: 7,
                                              child: ClipRRect(
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                  top: Radius.circular(16),
                                                ),
                                                child: Stack(
                                                  fit: StackFit.expand,
                                                  children: [
                                                    Image.network(
                                                      gameData['image'],
                                                      fit: BoxFit.cover,
                                                      loadingBuilder: (context,
                                                          child,
                                                          loadingProgress) {
                                                        if (loadingProgress ==
                                                            null) {
                                                          return child;
                                                        }
                                                        return Container(
                                                          color:
                                                              AppTheme.surfaceColor,
                                                          child: Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              value: loadingProgress
                                                                          .expectedTotalBytes !=
                                                                      null
                                                                  ? loadingProgress
                                                                          .cumulativeBytesLoaded /
                                                                      loadingProgress
                                                                          .expectedTotalBytes!
                                                                  : null,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        final color = gameData['color'] as Color;
                                                        return Container(
                                                          color:
                                                              color.withOpacity(0.1),
                                                          child: Icon(
                                                            Icons.videogame_asset,
                                                            size: 32,
                                                            color: color,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                    if (isSelected)
                                                      Container(
                                                        color: (gameData['color'] as Color)
                                                            .withOpacity(0.2),
                                                        child: Center(
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(6),
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  AppTheme.cardColor,
                                                              shape: BoxShape
                                                                  .circle,
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: AppTheme.shadowColorDark,
                                                                  blurRadius: 8,
                                                                  offset:
                                                                      const Offset(
                                                                          0, 2),
                                                                ),
                                                              ],
                                                            ),
                                                            child: Icon(
                                                              Icons.check,
                                                              color: gameData[
                                                                  'color'] as Color,
                                                              size: 20,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // Game Info
                                            Container(
                                              height: 40,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6.0,
                                                vertical: 4.0,
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      gameName,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isSelected
                                                            ? gameData['color'] as Color
                                                            : AppTheme.textColor,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  if (isSelected)
                                                    Flexible(
                                                      child: Container(
                                                        margin: const EdgeInsets
                                                            .only(top: 2),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 4,
                                                          vertical: 1,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              (gameData['color'] as Color)
                                                                  .withOpacity(
                                                                      0.1),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                        ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .check_circle,
                                                              size: 8,
                                                              color: gameData[
                                                                  'color'] as Color,
                                                            ),
                                                            const SizedBox(
                                                                width: 2),
                                                            Flexible(
                                                              child: Text(
                                                                'Selected',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize: 6,
                                                                  color: gameData[
                                                                      'color'] as Color,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    )
                                                    else
                                                    Flexible(
                                                      child: Text(
                                                        gameData['genre'],
                                                        style: TextStyle(
                                                          fontSize: 8,
                                                          color:
                                                              AppTheme.textSecondaryColor,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
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
                                // Selected Game Info (without ID input)
                                if (_selectedGame != null) ...[
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _games[_selectedGame]!['color']
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _games[_selectedGame]!['color']
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.videogame_asset,
                                              color: _games[_selectedGame]![
                                                  'color'],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Selected: $_selectedGame',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: _games[_selectedGame]![
                                                    'color'],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _games[_selectedGame]!['description'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 32),
                                // Continue Button (full width)
                                SizedBox(
                                  height: 56,
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed:
                                        (_selectedGame != null && !_isLoading)
                                            ? _onFinishSetup
                                            : null,
                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: _selectedGame != null
                                          ? _games[_selectedGame]!['color'] as Color
                                          : AppTheme.textDisabledColor,
                                    ),
                                    child: _isLoading
                                        ? CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    AppTheme.textColor),
                                          )
                                        : Text(
                                            'Continue',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                              color: _selectedGame != null
                                                  ? Colors.white
                                                  : AppTheme.textSecondaryColor,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
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
