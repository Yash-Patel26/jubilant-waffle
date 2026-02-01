import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gamer_flick/models/ui/onboarding_page_data.dart';

class EnhancedWelcomeScreen extends StatefulWidget {
  const EnhancedWelcomeScreen({super.key});

  @override
  _EnhancedWelcomeScreenState createState() => _EnhancedWelcomeScreenState();
}

class _EnhancedWelcomeScreenState extends State<EnhancedWelcomeScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  int _currentPage = 0;
  bool _isLastPage = false;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: "Welcome to GamerFlick",
      subtitle: "Your Ultimate Gaming Social Hub",
      description:
          "Connect with gamers worldwide, discover new gaming communities, and showcase your epic moments.",
      animationAsset: "🎮",
      backgroundColor: Color(0xFF1A1A2E),
      accentColor: Color(0xFF16213E),
      textColor: Colors.white,
    ),
    OnboardingPageData(
      title: "Showcase Epic Moments",
      subtitle: "Highlight Your Best Plays",
      description:
          "Capture and showcase your greatest gaming achievements with stories, reels, and highlight posts.",
      animationAsset: "🏆",
      backgroundColor: Color(0xFF0F3460),
      accentColor: Color(0xFF16213E),
      textColor: Colors.white,
    ),
    OnboardingPageData(
      title: "Join Gaming Communities",
      subtitle: "Find Your Gaming Tribe",
      description:
          "Discover communities for your favorite games and participate in tournaments.",
      animationAsset: "👥",
      backgroundColor: Color(0xFF16213E),
      accentColor: Color(0xFF533483),
      textColor: Colors.white,
    ),
    OnboardingPageData(
      title: "Connect & Compete",
      subtitle: "Level Up Together",
      description:
          "Follow pro players, chat with friends, and compete in challenges to become the ultimate gamer.",
      animationAsset: "🚀",
      backgroundColor: Color(0xFF533483),
      accentColor: Color(0xFF7209B7),
      textColor: Colors.white,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _buttonAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
    _buttonAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color top = isDark
        ? _pages[_currentPage].backgroundColor
        : Theme.of(context).colorScheme.surface.withOpacity(0.98);
    final Color bottom = isDark
        ? _pages[_currentPage].accentColor
        : Theme.of(context).colorScheme.primary.withOpacity(0.08);

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
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopSection(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index], index);
                  },
                ),
              ),
              _buildBottomSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button with gaming aesthetics
          AnimatedOpacity(
            duration: Duration(milliseconds: 300),
            opacity: _currentPage > 0 ? 1.0 : 0.0,
            child: GestureDetector(
              onTap: _currentPage > 0 ? _previousPage : null,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.cyan.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.cyan,
                  size: 20,
                ),
              ),
            ),
          ),
          // Enhanced GamerFlick Logo
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.cyan.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/logo.svg',
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                ),
                SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.cyan,
                      Colors.purple,
                      Colors.pink,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    'GamerFlick',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Skip button with gaming aesthetics
          GestureDetector(
            onTap: _skipOnboarding,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.purple.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                'Skip',
                style: TextStyle(
                  color: Colors.purple.shade300,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPageData pageData, int index) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Enhanced circular logo container with gaming aesthetics
                Container(
                  width: 180,
                  height: 180,
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
                        color: Colors.cyan.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
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
                            color: Colors.pink.withOpacity(0.3),
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
                            color: Colors.cyan.withOpacity(0.4),
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

                SizedBox(height: 40),

                // Enhanced Title with gaming aesthetics
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.cyan,
                      Colors.purple,
                      Colors.pink,
                      Colors.orange,
                    ],
                  ).createShader(bounds),
                  child: Text(
                    pageData.title,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          color: Colors.cyan.withOpacity(0.8),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 16),

                // Enhanced Subtitle with gaming aesthetics
                Text(
                  pageData.subtitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.cyan.shade300,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 16),

                // Enhanced Description with gaming aesthetics
                Text(
                  pageData.description,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Enhanced Page Indicators with gaming aesthetics
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 6),
                height: 10,
                width: _currentPage == index ? 40 : 10,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? Colors.cyan
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(5),
                  boxShadow: _currentPage == index
                      ? [
                          BoxShadow(
                            color: Colors.cyan.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),

          SizedBox(height: 40),

          // Enhanced Continue Button with gaming aesthetics
          ScaleTransition(
            scale: _scaleAnimation,
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.cyan,
                      Colors.purple,
                      Colors.pink,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 3,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLastPage ? _finishOnboarding : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    foregroundColor: Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLastPage ? 'Get Started' : 'Continue',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
      _isLastPage = page == _pages.length - 1;
    });

    HapticFeedback.lightImpact();
    _animationController.reset();
    _animationController.forward();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
    HapticFeedback.mediumImpact();
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
    HapticFeedback.lightImpact();
  }

  void _skipOnboarding() async {
    try {
      final auth = Supabase.instance.client.auth;
      // Prefer existing session without forcing a refresh (better offline behavior)
      final existingUser = auth.currentUser;
      if (existingUser != null) {
        Navigator.pushReplacementNamed(context, '/Home');
      } else {
        // Try one refresh attempt before sending to login
        try {
          await auth.refreshSession();
        } catch (_) {}
        final user = auth.currentUser;
        if (user != null) {
          Navigator.pushReplacementNamed(context, '/Home');
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      // If there's an error, default to login
      Navigator.pushReplacementNamed(context, '/login');
    }
    HapticFeedback.mediumImpact();
  }

  void _finishOnboarding() async {
    try {
      final auth = Supabase.instance.client.auth;
      final existingUser = auth.currentUser;
      if (existingUser != null) {
        Navigator.pushReplacementNamed(context, '/Home');
      } else {
        try {
          await auth.refreshSession();
        } catch (_) {}
        final user = auth.currentUser;
        if (user != null) {
          Navigator.pushReplacementNamed(context, '/Home');
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      // If there's an error, default to login
      Navigator.pushReplacementNamed(context, '/login');
    }
    HapticFeedback.heavyImpact();
  }
}
