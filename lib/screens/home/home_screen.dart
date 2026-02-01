import 'package:flutter/material.dart';
import 'home_feed_screen.dart';

import '../search/search_screen.dart';
import '../../widgets/safe_scaffold.dart';

import '../profile/profile_screen.dart';
import '../settings/settings_screen.dart';
import '../tournament/tournaments_screen.dart';
import '../community/communities_screen.dart';
import '../games/leaderboard_screen.dart';
import '../games/games_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../event/create_event_screen.dart';
import '../reels/create_reel_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/providers/app/notification_provider.dart';
import 'package:gamer_flick/models/notification/notification_model.dart';
import 'package:gamer_flick/providers/user/user_notifier.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'notifications_screen.dart';
import '../chat/inbox_screen.dart';
import '../live/stick_cam_screen.dart';
import '../profile/followers_following_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  int _unreadMessagesCount = 0;
  RealtimeChannel? _messagesChannel;
  bool _notificationsInitialized = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _hoveredSidebarIndex = -1;
  late AnimationController _haloController;
  late Animation<double> _haloProgress;

  // Cache for widget instances to prevent recreation
  final Map<int, Widget> _widgetCache = {};

  // Indices for primary nav items
  static const List<int> _primaryMobileIndices = [
    0, // Home
    2, // Communities
    3, // Tournaments
    5, // Profile
  ];

  // No longer needed: local state managed by Riverpod

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _haloController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _haloProgress = CurvedAnimation(
      parent: _haloController,
      curve: Curves.easeInOut,
    );

    _fetchUnreadMessages();
    _subscribeToMessages();
    // Profile loading handled by userProfileProvider.watch in build()
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_notificationsInitialized) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        Future.microtask(() {
          final notifier = ref.read(notificationProvider.notifier);
          notifier.loadNotifications(userId);
          notifier.subscribeToRealtime(userId);
          notifier.onNewNotification = (notif) {
            final context = this.context;
            if (context.mounted) {
              final type = notif.type;
              final senderName = notif.senderName ?? '';
              final senderId = notif.senderId ?? '';
              Icon icon;
              switch (type) {
                case NotificationType.postComment:
                  icon = const Icon(Icons.comment, color: Colors.green);
                  break;
                case NotificationType.postLike:
                  icon = const Icon(Icons.favorite, color: Colors.red);
                  break;
                case NotificationType.followRequest:
                  icon = const Icon(Icons.person_add, color: Colors.blue);
                  break;
                case NotificationType.newMessage:
                  icon = const Icon(Icons.mail, color: Colors.purple);
                  break;
                case NotificationType.tournamentUpdate:
                  icon = const Icon(Icons.emoji_events, color: Colors.orange);
                  break;
                default:
                  icon = const Icon(Icons.notifications, color: Colors.grey);
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      icon,
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              senderName.isNotEmpty ? senderName : 'Someone',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _getNotificationText(notif),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'View',
                    onPressed: () {
                      _handleNotificationTap(notif, senderId);
                    },
                  ),
                ),
              );
            }
          };
        });
        _notificationsInitialized = true;
      }
    }
  }

  String _getNotificationText(NotificationModel notif) {
    switch (notif.type) {
      case NotificationType.postComment:
        return 'commented on your post';
      case NotificationType.postLike:
        return 'liked your post';
      case NotificationType.followRequest:
        return 'wants to follow you';
      case NotificationType.newMessage:
        return 'sent you a message';
      case NotificationType.tournamentUpdate:
        return 'tournament has been updated';
      default:
        return 'interacted with your content';
    }
  }

  void _handleNotificationTap(NotificationModel notif, String senderId) {
    switch (notif.type) {
      case NotificationType.newMessage:
        setState(() => _selectedIndex = 3);
        break;
      case NotificationType.followRequest:
        break;
      default:
        break;
    }
  }

  void _subscribeToMessages() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    _messagesChannel = Supabase.instance.client
        .channel('public:messages:receiver_id=eq.$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.neq,
            column: 'sender_id',
            value: userId,
          ),
          callback: (payload) {
            _fetchUnreadMessages();
          },
        )
        .subscribe();
  }

  Future<void> _fetchUnreadMessages() async {
    if (mounted) {
      setState(() {
        _unreadMessagesCount = 0;
      });
    }
  }

  @override
  void dispose() {
    _messagesChannel?.unsubscribe();
    _animationController.dispose();
    _haloController.dispose();
    super.dispose();
  }

  // Removed manual loading methods: profile managed by Riverpod

  static final List<Map<String, dynamic>> _navigationItems = [
    {
      'icon': Icons.home_rounded,
      'label': 'Home',
      'widget': const HomeFeedScreen(),
      'color': Colors.blue
    },
    {
      'icon': Icons.search_rounded,
      'label': 'Search',
      'widget': const SearchScreen(),
      'color': Colors.green
    },

    {
      'icon': Icons.group_rounded,
      'label': 'Communities',
      'widget': const CommunitiesScreen(),
      'color': Colors.teal
    },
    {
      'icon': Icons.emoji_events_rounded,
      'label': 'Tournaments',
      'widget': const TournamentsScreen(),
      'color': Colors.amber
    },


    {
      'icon': Icons.settings_rounded,
      'label': 'Settings',
      'widget': const SettingsScreen(),
      'color': Colors.grey
    },
    {
      'icon': Icons.person_rounded,
      'label': 'Profile',
      'widget': null,
      'color': Colors.indigo
    },
    {
      'icon': Icons.gamepad_rounded,
      'label': 'Games',
      'widget': const GamesScreen(),
      'color': Colors.deepPurple
    },
    {
      'icon': Icons.videocam_rounded,
      'label': 'Game Meet',
      'widget': const StickCamScreen(),
      'color': Colors.green
    },
  ];

  // Quick access tabs for the top bar
  static final List<Map<String, dynamic>> _quickAccessTabs = [
    {'label': 'HOME', 'icon': Icons.home_rounded},
    {'label': 'STICK CAM', 'icon': Icons.videocam_rounded},
    {'label': 'FRIENDS', 'icon': Icons.people_rounded},
    {'label': 'REEL', 'icon': Icons.video_library_rounded},
  ];

  Widget _getCurrentWidget() {
    if (_widgetCache.containsKey(_selectedIndex)) {
      return _widgetCache[_selectedIndex]!;
    }

    Widget widget;

    if (_navigationItems[_selectedIndex]['label'] == 'Communities') {
      widget = const CommunitiesScreen();
    } else if (_navigationItems[_selectedIndex]['widget'] == null) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        widget = ProfileScreen(userId: user.id);
      } else {
        widget = const Center(child: Text('Please log in'));
      }
    } else {
      widget = _navigationItems[_selectedIndex]['widget'] as Widget;
    }

    _widgetCache[_selectedIndex] = widget;
    return widget;
  }

  void _showMoreMenu(BuildContext context) {
    final theme = Theme.of(context);
    final moreIndices = List.generate(_navigationItems.length, (i) => i)
        .where((i) => !_primaryMobileIndices.contains(i))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: moreIndices.length,
                itemBuilder: (context, index) {
                  final i = moreIndices[index];
                  final item = _navigationItems[i];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item['icon'],
                        color: item['color'],
                        size: 20,
                      ),
                    ),
                    title: Text(
                      item['label'],
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() => _selectedIndex = i);
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMoreDropdown(
      BuildContext context, Offset globalPosition) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final moreIndices = List.generate(_navigationItems.length, (i) => i)
        .where((i) => !_primaryMobileIndices.contains(i))
        .toList();

    final selected = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        overlay.size.width - globalPosition.dx,
        overlay.size.height - globalPosition.dy,
      ),
      items: moreIndices.map((i) {
        final item = _navigationItems[i];
        return PopupMenuItem<int>(
          value: i,
          child: Row(
            children: [
              Icon(item['icon'], color: item['color'], size: 20),
              const SizedBox(width: 12),
              Text(item['label']),
            ],
          ),
        );
      }).toList(),
    );

    if (!mounted) return;
    if (selected != null) {
      setState(() => _selectedIndex = selected);
    }
  }

  void _navigateToProfile() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _selectedIndex =
            _navigationItems.indexWhere((item) => item['widget'] == null);
      });
    }
  }

  void _openSearchDrawer() {
    final theme = Theme.of(context);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Search',
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 380,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(5, 0),
                  ),
                ],
              ),
              child: const SearchScreen(),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;

    // Watch the user profile provider
    final userProfileAsync = ref.watch(userProfileProvider);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: isDesktop ? _buildDesktopLayout(theme) : _buildMobileLayout(theme),
    );
  }

  Widget _buildMobileLayout(ThemeData theme) {
    return SafeScaffold(
      body: Column(
        children: [
          // Enhanced Mobile Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Logo and Title
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: SvgPicture.asset(
                        'assets/logo.svg',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
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
                ),
                const Spacer(),
                // Action Icons
                Row(
                  children: [
                    // Search
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.35),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            print('DEBUG: Search icon tapped from HomeScreen');
                            _openSearchDrawer();
                          },
                          child: const Center(
                            child: Icon(
                              Icons.search_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Notifications
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.35),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            print(
                                'DEBUG: Notifications icon tapped from HomeScreen');
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationsScreen(),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              const Center(
                                child: Icon(
                                  Icons.notifications_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Inbox
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF10B981), Color(0xFF059669)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.35),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            print('DEBUG: Inbox icon tapped from HomeScreen');
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const InboxScreen(),
                              ),
                            );
                          },
                          child: const Center(
                            child: Icon(
                              Icons.chat_bubble_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: _getCurrentWidget(),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 110,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                ..._primaryMobileIndices.map((i) {
                  final item = _navigationItems[i];
                  final isSelected = _selectedIndex == i;
                  final hasBadge = item['label'] == 'Notifications' &&
                      ref.watch(unreadNotificationCountProvider) > 0;

                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: GestureDetector(
                        onTap: () {
                          if ((item['label'] as String).toLowerCase() ==
                              'search') {
                            _openSearchDrawer();
                            return;
                          }
                          setState(() {
                            _selectedIndex = i;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? item['color'].withOpacity(0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected
                                ? Border.all(
                                    color: item['color'].withOpacity(0.4),
                                    width: 2,
                                  )
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: item['color'].withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                transform: Matrix4.identity()
                                  ..scale(isSelected ? 1.1 : 1.0),
                                child: Stack(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? item['color']
                                            : theme.colorScheme.onSurfaceVariant
                                                .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        item['icon'],
                                        color: isSelected
                                            ? Colors.white
                                            : item['color'],
                                        size: isSelected ? 24 : 20,
                                      ),
                                    ),
                                    if (hasBadge)
                                      Positioned(
                                        right: -2,
                                        top: -2,
                                        child: Container(
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.error,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: theme.colorScheme.surface,
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: theme.colorScheme.error
                                                    .withOpacity(0.4),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          child: Text(
                                            '${ref.watch(unreadNotificationCountProvider)}',
                                            style: TextStyle(
                                              color: theme.colorScheme.onError,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  margin: const EdgeInsets.only(top: 4),
                                  height: 2,
                                  width: 20,
                                  decoration: BoxDecoration(
                                    color: item['color'],
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: GestureDetector(
                      onTapDown: (details) =>
                          _showMoreDropdown(context, details.globalPosition),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.more_horiz_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                                size: 24,
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
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(ThemeData theme) {
    return SafeScaffold(
      body: Row(
        children: [
          // Left Navigation Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF111216),
                  Color(0xFF0D0E12),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.08),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
              border: Border(
                right: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildDesktopHeader(theme),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _navigationItems.length,
                        itemBuilder: (context, index) {
                          final item = _navigationItems[index];
                          final isSelected = _selectedIndex == index;

                          final bool isHovered = _hoveredSidebarIndex == index;
                          final Color accentColor = (item['color'] as Color?) ??
                              const Color(0xFF6366F1);

                          String? sectionLabel;
                          if (index == 0) sectionLabel = 'Explore';
                          if (index == 3) sectionLabel = 'Community';
                          if (index == 7) sectionLabel = 'Account';

                          final tile = Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 2),
                            child: MouseRegion(
                              onEnter: (_) => setState(() {
                                _hoveredSidebarIndex = index;
                              }),
                              onExit: (_) => setState(() {
                                _hoveredSidebarIndex = -1;
                              }),
                              child: Material(
                                color: Colors.transparent,
                                child: Tooltip(
                                  message: item['label'],
                                  waitDuration:
                                      const Duration(milliseconds: 400),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.outline
                                          .withOpacity(0.2),
                                    ),
                                  ),
                                  textStyle: const TextStyle(fontSize: 11),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      if ((item['label'] as String)
                                              .toLowerCase() ==
                                          'search') {
                                        _openSearchDrawer();
                                        return;
                                      }
                                      setState(() {
                                        _selectedIndex = index;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      curve: Curves.easeOut,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: isSelected || isHovered
                                            ? LinearGradient(
                                                colors: [
                                                  accentColor.withOpacity(0.18),
                                                  const Color(0xFF2A2A2A),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : null,
                                        color: (isSelected || isHovered)
                                            ? const Color(0xFF1F2026)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        border: (isSelected || isHovered)
                                            ? Border.all(
                                                color: accentColor
                                                    .withOpacity(0.35),
                                                width: 1,
                                              )
                                            : null,
                                        boxShadow: (isSelected || isHovered)
                                            ? [
                                                BoxShadow(
                                                  color: accentColor
                                                      .withOpacity(isSelected
                                                          ? 0.35
                                                          : 0.22),
                                                  blurRadius: 16,
                                                  spreadRadius: 1,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 180),
                                            width: 4,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: (isSelected || isHovered)
                                                  ? accentColor
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            item['icon'],
                                            color: isSelected
                                                ? accentColor
                                                : Colors.white
                                                    .withOpacity(0.75),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 14),
                                          Text(
                                            item['label'],
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white
                                                      .withOpacity(0.82),
                                              fontSize: 14,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );

                          if (sectionLabel != null) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 10, 18, 6),
                                  child: Text(
                                    sectionLabel,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.55),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                tile,
                              ],
                            );
                          }

                          return tile;
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: _buildPremiumCta(theme),
                    ),
                    _buildDesktopFooter(theme),
                  ],
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.35),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter:
                          _SidebarScanlinePainter(spacing: 3, opacity: 0.035),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main Content Area with Top Bar
          Expanded(
            child: Stack(
              children: [
                // Fixed header overlay
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildTopBar(theme),
                ),
                // Scrollable content placed below the fixed header
                Positioned.fill(
                  top: 80, // match header height in _buildTopBar
                  child: _getCurrentWidget(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Logo with animated halo (centered)
          AnimatedBuilder(
            animation: _haloProgress,
            builder: (context, _) {
              final double intensity = 0.15 + 0.25 * _haloProgress.value;
              final double blur = 18 + 24 * _haloProgress.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Soft animated halo
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(intensity),
                          blurRadius: blur,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: const Color(0xFF22D3EE)
                              .withOpacity(intensity * 0.6),
                          blurRadius: blur * 0.85,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(42),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.25),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ClipOval(
                      child: SvgPicture.asset(
                        'assets/logo.svg',
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          // Branding under the circle (centered)
          _buildNeonBrand(theme),
          const SizedBox(height: 8),
          // Online status pill (centered below branding)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 3,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'ONLINE',
                  style: TextStyle(
                    color: const Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A1A),
            Color(0xFF0F0F0F),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          // Centered Quick Access Tabs
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _quickAccessTabs.map((tab) {
                  final isSelected =
                      tab['label'] == 'HOME'; // Default to Home selected
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () =>
                            _onHeaderTabSelected(tab['label'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF6366F1),
                                      Color(0xFF22D3EE),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isSelected ? null : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 1.5,
                                  )
                                : Border.all(
                                    color: Colors.white.withOpacity(0.08),
                                    width: 1,
                                  ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF6366F1)
                                          .withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 3,
                                      offset: const Offset(0, 6),
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFF22D3EE)
                                          .withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                tab['icon'] ?? Icons.circle,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.6),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tab['label'],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.8),
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 14,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Right side icons with enhanced styling
          Row(
            children: [
              _buildIconContainer(
                child: PopupMenuButton<Object?>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF6366F1),
                          Color(0xFF22D3EE),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.more_horiz,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  offset: const Offset(0, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: const Color(0xFF0A0A0A),
                  elevation: 25,
                  onSelected: (value) async {
                    if (value is String) {
                      switch (value) {
                        case 'action:leaderboard':
                          _navigateToLeaderboard();
                          return;
                        case 'action:edit_profile':
                          await _navigateToEditProfile();
                          return;
                        case 'action:premium':
                          _navigateToPremium();
                          return;
                        case 'action:create_event':
                          _navigateToCreateEvent();
                          return;
                        case 'action:create_reel':
                          _navigateToCreateReel();
                          return;
                      }
                    }
                    if (value is int) {
                      final label = (_navigationItems[value]['label'] as String)
                          .toLowerCase();
                      if (label == 'search') {
                        _openSearchDrawer();
                        return;
                      }
                      setState(() => _selectedIndex = value);
                    }
                  },
                  itemBuilder: (context) => <PopupMenuEntry<Object?>>[
                    _buildEnhancedMenuItem(
                      icon: Icons.leaderboard_rounded,
                      label: 'Leaderboard',
                      color: const Color(0xFFF59E0B),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                      ),
                      description: 'View top players',
                      value: 'action:leaderboard',
                    ),
                    _buildEnhancedMenuItem(
                      icon: Icons.edit_rounded,
                      label: 'Edit Profile',
                      color: const Color(0xFF3B82F6),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      ),
                      description: 'Customize your profile',
                      value: 'action:edit_profile',
                    ),
                    _buildEnhancedMenuItem(
                      icon: Icons.workspace_premium_rounded,
                      label: 'Premium',
                      color: const Color(0xFF8B5CF6),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                      ),
                      description: 'Unlock exclusive features',
                      isPremium: true,
                      value: 'action:premium',
                    ),
                    _buildEnhancedMenuItem(
                      icon: Icons.event_rounded,
                      label: 'Create Event',
                      color: const Color(0xFF06B6D4),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
                      ),
                      description: 'Organize tournaments',
                      value: 'action:create_event',
                    ),
                    _buildEnhancedMenuItem(
                      icon: Icons.video_library_rounded,
                      label: 'Create Reel',
                      color: const Color(0xFFEF4444),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                      ),
                      description: 'Share gaming moments',
                      value: 'action:create_reel',
                    ),
                  ],
                ),
                hasNotification: false,
              ),
              const SizedBox(width: 12),
              _buildIconContainer(
                child: IconButton(
                  onPressed: () => _navigateToNotifications(),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFEF4444),
                          Color(0xFFDC2626),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                hasNotification: true,
              ),
              const SizedBox(width: 12),
              _buildIconContainer(
                child: IconButton(
                  onPressed: () => _navigateToChat(),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF10B981),
                          Color(0xFF059669),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                hasNotification: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconContainer({
    required Widget child,
    required bool hasNotification,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A2A2A),
            Color(0xFF1F1F1F),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          child,
          if (hasNotification)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Header tab navigation methods
  void _onHeaderTabSelected(String tabLabel) {
    print('Header tab selected: $tabLabel');

    switch (tabLabel) {
      case 'HOME':
        setState(() {
          _selectedIndex = 0; // Home index
        });
        break;
      case 'SEARCH':
        _openSearchDrawer();
        break;
      case 'STICK CAM':
        _navigateToStickCam();
        break;
      case 'FRIENDS':
        _navigateToFriends();
        break;
      case 'REEL':
        setState(() {
          _selectedIndex = 3; // Reel index
        });
        break;
    }
  }

  void _navigateToStickCam() {
    print('Navigating to Stick Cam');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const StickCamScreen(),
      ),
    );
  }

  void _navigateToFriends() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to view connections')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Connections'),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Followers', icon: Icon(Icons.groups_2)),
                  Tab(text: 'Following', icon: Icon(Icons.group_add)),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                FollowersFollowingScreen(
                  userId: user.id,
                  mode: UserListMode.followers,
                  showAppBar: false,
                ),
                FollowersFollowingScreen(
                  userId: user.id,
                  mode: UserListMode.following,
                  showAppBar: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToSearch() {
    print('Navigating to Search');
    _openSearchDrawer();
  }

  void _navigateToNotifications() {
    print('Navigating to Notifications');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  void _navigateToChat() {
    print('Navigating to Chat');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InboxScreen(),
      ),
    );
  }

  void _navigateToLeaderboard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LeaderboardScreen(),
      ),
    );
  }

  void _navigateToCreateEvent() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateEventScreen(),
      ),
    );
  }

  void _navigateToCreateReel() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateReelScreen(),
      ),
    );
  }

  PopupMenuEntry<Object?> _buildEnhancedMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required LinearGradient gradient,
    required String description,
    required String value,
    bool isPremium = false,
  }) {
    return PopupMenuItem<Object?>(
      value: value,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A1A),
              const Color(0xFF0F0F0F),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon with gradient background
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isPremium) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFF59E0B),
                                Color(0xFFEF4444),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: color.withOpacity(0.6),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToEditProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to edit your profile')),
      );
      return;
    }
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (!mounted) return;
      if (profile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load your profile')),
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EditProfileScreen(userProfile: profile),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Try again.')),
      );
    }
  }

  void _navigateToPremium() {
    Navigator.of(context).pushNamed('/premium');
  }

  Widget _buildDesktopFooter(ThemeData theme) {
    // Watch the user profile provider
    final userProfileAsync = ref.watch(userProfileProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          userProfileAsync.when(
            data: (profile) => CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.withOpacity(0.3),
              backgroundImage: profile?.profilePicture != null
                  ? NetworkImage(profile!.profilePicture!)
                  : null,
              child: profile?.profilePicture == null
                  ? Text(
                      profile?.displayName.isNotEmpty == true
                          ? profile!.displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            loading: () => Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
            error: (_, __) => const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.red,
              child: Icon(Icons.error, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userProfileAsync.when(
                    data: (profile) => profile?.displayName ?? 'User Profile',
                    loading: () => 'Loading...',
                    error: (_, __) => 'Error',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  userProfileAsync.when(
                    data: (profile) => 'Level ${profile?.level ?? 1}',
                    loading: () => '',
                    error: (_, __) => '',
                  ),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCta(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366F1).withOpacity(0.12),
            const Color(0xFF22D3EE).withOpacity(0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.workspace_premium, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unlock Premium',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Unlimited clips, pro tools and more',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed('/premium'),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  Widget _buildNeonBrand(ThemeData theme) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: const Text(
            'GAMERFLICK',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 2.0,
            ),
          ),
        ),
        const SizedBox(height: 6),
        _NeonSweepUnderline(),
      ],
    );
  }

  // Painter for subtle retro scanlines overlay on the sidebar
  // and animated sweep underline widget
}

class _SidebarScanlinePainter extends CustomPainter {
  final double spacing;
  final double opacity;

  _SidebarScanlinePainter({this.spacing = 3, this.opacity = 0.04});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final noisePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.white12, Colors.transparent],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), noisePaint);
  }

  @override
  bool shouldRepaint(covariant _SidebarScanlinePainter oldDelegate) {
    return oldDelegate.spacing != spacing || oldDelegate.opacity != opacity;
  }
}

class _NeonSweepUnderline extends StatefulWidget {
  @override
  State<_NeonSweepUnderline> createState() => _NeonSweepUnderlineState();
}

class _NeonSweepUnderlineState extends State<_NeonSweepUnderline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 6,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _SweepPainter(progress: _controller.value),
          );
        },
      ),
    );
  }
}

class _SweepPainter extends CustomPainter {
  final double progress;
  _SweepPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final baseRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(3),
    );
    final basePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRRect(baseRRect, basePaint);

    final sweepWidth = size.width * 0.25;
    final startX = (size.width + sweepWidth) * progress - sweepWidth;
    final sweepRect = Rect.fromLTWH(startX, 0, sweepWidth, size.height);
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.8),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(sweepRect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.clipRRect(baseRRect);
    canvas.drawRect(sweepRect, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _SweepPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
