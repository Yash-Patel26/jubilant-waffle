import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/profile/profile_screen.dart';
import 'package:gamer_flick/models/core/profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PersistentLayout extends ConsumerStatefulWidget {
  final Widget child;
  final int initialSelectedIndex;

  const PersistentLayout({
    super.key,
    required this.child,
    this.initialSelectedIndex = 0,
  });

  @override
  ConsumerState<PersistentLayout> createState() => _PersistentLayoutState();
}

class _PersistentLayoutState extends ConsumerState<PersistentLayout>
    with TickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _animationController;
  late Animation<double> _animation;
  Profile? _userProfile;
  final bool _isLoading = true;

  // Navigation items with enhanced structure
  final List<Map<String, dynamic>> _navigationItems = [
    {
      'label': 'HOME',
      'icon': Icons.home_rounded,
      'color': const Color(0xFF6366F1),
      'widget': null, // Will be handled by child
    },
    {
      'label': 'REELS',
      'icon': Icons.video_library_rounded,
      'color': const Color(0xFF22D3EE),
      'widget': null,
    },
    {
      'label': 'SEARCH',
      'icon': Icons.search_rounded,
      'color': const Color(0xFFEF4444),
      'widget': null,
    },
    {
      'label': 'STICK CAM',
      'icon': Icons.videocam_rounded,
      'color': const Color(0xFF10B981),
      'widget': null,
    },
    {
      'label': 'TOURNAMENTS',
      'icon': Icons.emoji_events_rounded,
      'color': const Color(0xFF8B5CF6),
      'widget': null,
    },
    {
      'label': 'CREATE EVENT',
      'icon': Icons.event_rounded,
      'color': const Color(0xFF06B6D4),
      'widget': null,
    },
    {
      'label': 'CREATE REEL',
      'icon': Icons.video_library_rounded,
      'color': const Color(0xFFF59E0B),
      'widget': null,
    },
    {
      'label': 'COMMUNITIES',
      'icon': Icons.groups_rounded,
      'color': const Color(0xFFEC4899),
      'widget': null,
    },
    {
      'label': 'LEADERBOARD',
      'icon': Icons.leaderboard_rounded,
      'color': const Color(0xFFF97316),
      'widget': null,
    },
    {
      'label': 'NOTIFICATIONS',
      'icon': Icons.notifications_rounded,
      'color': const Color(0xFF84CC16),
      'widget': null,
    },
    {
      'label': 'INBOX',
      'icon': Icons.inbox_rounded,
      'color': const Color(0xFF6366F1),
      'widget': null,
    },
    {
      'label': 'PROFILE',
      'icon': Icons.person_rounded,
      'color': const Color(0xFF22D3EE),
      'widget': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }


  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToScreen(int index) {
    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }

    final item = _navigationItems[index];
    final label = item['label'] as String;

    switch (label) {
      case 'HOME':
        Navigator.of(context).pushReplacementNamed('/Home');
        break;
      case 'REELS':
        Navigator.of(context).pushReplacementNamed('/reels');
        break;
      case 'UPLOAD':
        Navigator.of(context).pushReplacementNamed('/upload');
        break;
      case 'SEARCH':
        Navigator.of(context).pushReplacementNamed('/advanced-search');
        break;
      case 'STICK CAM':
        Navigator.of(context).pushReplacementNamed('/stick-cam');
        break;
      case 'TOURNAMENTS':
        Navigator.of(context).pushReplacementNamed('/tournaments');
        break;
      case 'CREATE EVENT':
        Navigator.of(context).pushReplacementNamed('/create-event');
        break;
      case 'CREATE REEL':
        Navigator.of(context).pushReplacementNamed('/create-reel');
        break;
      case 'COMMUNITIES':
        Navigator.of(context).pushReplacementNamed('/communities');
        break;
      case 'LEADERBOARD':
        Navigator.of(context).pushReplacementNamed('/leaderboard');
        break;
      case 'NOTIFICATIONS':
        Navigator.of(context).pushReplacementNamed('/notifications');
        break;
      case 'INBOX':
        Navigator.of(context).pushReplacementNamed('/inbox');
        break;
      case 'PROFILE':
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ProfileScreen(userId: user.id),
            ),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;

    print('DEBUG: Screen width: $screenWidth, isDesktop: $isDesktop');

    if (isDesktop) {
      print('DEBUG: Using desktop layout');
      return Row(
        children: [
          // Desktop Sidebar
          _buildDesktopSidebar(),
          // Main Content
          Expanded(
            child: widget.child,
          ),
        ],
      );
    } else {
      print('DEBUG: Using mobile layout');
      // Mobile Layout - Show sidebar as drawer
      return Scaffold(
        body: widget.child,
        drawer: _buildMobileDrawer(),
        // Removed AppBar to avoid duplicate headers - enhanced header is now in HomeScreen
      );
    }
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0A0A0A),
            Color(0xFF1A1A1A),
            Color(0xFF0F0F0F),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Vertical neon accent strip
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF22D3EE),
                    Color(0xFFF59E0B),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),

          // Retro scanline overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _SidebarScanlinePainter(),
            ),
          ),

          // Content
          Column(
            children: [
              const SizedBox(height: 24),
              // Logo and Brand
              _buildNeonBrand(),
              const SizedBox(height: 32),

              // Navigation Sections
              _buildSectionHeader('Explore'),
              const SizedBox(height: 16),
              ..._buildNavigationItems(0, 5),

              const SizedBox(height: 24),
              _buildSectionHeader('Community'),
              const SizedBox(height: 16),
              ..._buildNavigationItems(5, 10),

              const SizedBox(height: 24),
              _buildSectionHeader('Account'),
              const SizedBox(height: 16),
              ..._buildNavigationItems(10, 13),

              const Spacer(),

              // Premium CTA
              _buildPremiumCta(),

              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0A0A0A),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF22D3EE),
                ],
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : _userProfile?.profilePicture != null
                          ? ClipOval(
                              child: Image.network(
                                _userProfile!.profilePicture!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 24,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isLoading
                            ? 'Loading...'
                            : _userProfile?.displayName ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isLoading
                            ? ''
                            : '@${_userProfile?.username ?? 'username'}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Navigation Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                final isSelected = _selectedIndex == index;

                return ListTile(
                  leading: Icon(
                    item['icon'],
                    color: isSelected
                        ? item['color']
                        : Colors.white.withOpacity(0.7),
                  ),
                  title: Text(
                    item['label'],
                    style: TextStyle(
                      color: isSelected ? item['color'] : Colors.white,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onTap: () {
                    _navigateToScreen(index);
                    Navigator.of(context).pop(); // Close drawer
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Row(
      children: [
        // Logo
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF6366F1),
                Color(0xFF22D3EE),
              ],
            ),
          ),
          child: const Icon(
            Icons.games,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'GamerFlick',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileActionIcon({
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
    bool showDot = false,
  }) {
    return _MobileActionIcon(
      icon: icon,
      colors: colors,
      onTap: onTap,
      showDot: showDot,
    );
  }

  Widget _buildNeonBrand() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Logo with animated halo
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer halo
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6366F1)
                              .withOpacity(0.3 * _animation.value),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Logo circle
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF22D3EE),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.games,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Brand name with animated underline
          const Text(
            'GamerFlick',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),

          // Animated neon underline
          _NeonSweepUnderline(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNavigationItems(int startIndex, int endIndex) {
    return _navigationItems
        .sublist(startIndex, endIndex)
        .asMap()
        .entries
        .map((entry) {
      final index = startIndex + entry.key;
      final item = entry.value;
      final isSelected = _selectedIndex == index;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Tooltip(
          message: item['label'],
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _navigateToScreen(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          item['color'].withOpacity(0.2),
                          item['color'].withOpacity(0.1),
                        ],
                      )
                    : null,
                color: isSelected ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: item['color'].withOpacity(0.5),
                        width: 1,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // Left accent bar
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 3,
                    height: 20,
                    decoration: BoxDecoration(
                      color: isSelected ? item['color'] : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    item['icon'],
                    color: isSelected
                        ? item['color']
                        : Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['label'],
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.8),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildPremiumCta() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF59E0B),
            Color(0xFFEF4444),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.workspace_premium,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Go Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Unlock exclusive features and remove ads',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              Navigator.of(context).pushNamed('/premium');
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Upgrade Now',
                style: TextStyle(
                  color: Colors.white,
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
}

// Custom painter for sidebar scanline effect
class _SidebarScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (double i = 0; i < size.height; i += 4) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated neon sweep underline
class _NeonSweepUnderline extends StatefulWidget {
  @override
  State<_NeonSweepUnderline> createState() => _NeonSweepUnderlineState();
}

class _NeonSweepUnderlineState extends State<_NeonSweepUnderline>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _SweepPainter(_animation.value),
          size: const Size(120, 4),
        );
      },
    );
  }
}

class _SweepPainter extends CustomPainter {
  final double progress;

  _SweepPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF6366F1),
          const Color(0xFF22D3EE),
          const Color(0xFF6366F1),
        ],
        stops: [
          (progress - 0.3).clamp(0.0, 1.0),
          progress,
          (progress + 0.3).clamp(0.0, 1.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height / 2)
      ..lineTo(size.width, size.height / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Mobile Action Icon with animations and haptic feedback
class _MobileActionIcon extends StatefulWidget {
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;
  final bool showDot;

  const _MobileActionIcon({
    required this.icon,
    required this.colors,
    required this.onTap,
    this.showDot = false,
  });

  @override
  State<_MobileActionIcon> createState() => _MobileActionIconState();
}

class _MobileActionIconState extends State<_MobileActionIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (mounted) setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    if (mounted) setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (mounted) setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.colors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.colors.first
                        .withOpacity(_isPressed ? 0.2 : 0.35),
                    blurRadius: _isPressed ? 4 : 8,
                    spreadRadius: _isPressed ? 0 : 1,
                    offset: Offset(0, _isPressed ? 1 : 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: _isPressed ? 16 : 18,
                    ),
                  ),
                  if (widget.showDot)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x80FFFFFF),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
