import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/providers/content/stick_cam_provider.dart';
import 'package:gamer_flick/models/ui/stick_cam_session.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/webrtc_video_widget.dart';

class StickCamScreen extends StatelessWidget {
  const StickCamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StickCamProvider(),
      child: const _StickCamView(),
    );
  }
}

class _StickCamView extends StatefulWidget {
  const _StickCamView();
  @override
  State<_StickCamView> createState() => _StickCamViewState();
}

class _StickCamViewState extends State<_StickCamView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  bool _isFullScreen = false;
  bool _isMuted = false;
  bool _isVideoOff = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveUtils.isMobile(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Consumer<StickCamProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  _buildHeader(theme, provider),
                  Expanded(
                    child: _buildMainContent(theme, provider, isMobile),
                  ),
                  if (provider.session?.status == 'connected')
                    _buildChatInput(theme, provider),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, StickCamProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stick Cam',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  _getStatusText(provider),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (provider.session?.status == 'connected') ...[
            IconButton(
              onPressed: () {
                setState(() {
                  _isMuted = !_isMuted;
                });
                provider.toggleMute(_isMuted);
              },
              icon: Icon(
                _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                color: _isMuted ? Colors.red : theme.colorScheme.onSurface,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _isVideoOff = !_isVideoOff;
                });
                provider.toggleVideo(_isVideoOff);
              },
              icon: Icon(
                _isVideoOff
                    ? Icons.videocam_off_rounded
                    : Icons.videocam_rounded,
                color: _isVideoOff ? Colors.red : theme.colorScheme.onSurface,
              ),
            ),
            IconButton(
              onPressed: () => provider.next(),
              icon: Icon(
                Icons.skip_next_rounded,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusText(StickCamProvider provider) {
    if (provider.isMatching) {
      return 'Finding a gamer...';
    } else if (provider.session?.status == 'connected') {
      return 'Connected with a fellow gamer';
    } else if (provider.session?.status == 'ended') {
      return 'Connection ended';
    } else {
      return 'Ready to connect';
    }
  }

  Widget _buildMainContent(
      ThemeData theme, StickCamProvider provider, bool isMobile) {
    if (provider.session == null) {
      return _buildLobbyView(theme, provider);
    } else if (provider.session?.status == 'connected') {
      return _buildVideoCallView(theme, provider, isMobile);
    } else {
      return _buildMatchingView(theme, provider);
    }
  }

  Widget _buildLobbyView(ThemeData theme, StickCamProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gaming-themed icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.sports_esports_rounded,
              size: 60,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),

          Text(
            'Connect with Fellow Gamers',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          Text(
            'Join random video calls with gamers from around the world. Share your gaming experiences, discuss strategies, or just hang out!',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Gaming interests selection
          _buildGamingInterests(theme, provider),
          const SizedBox(height: 24),

          // Start button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => provider.startMatching(),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.videocam_rounded),
                  const SizedBox(width: 8),
                  Text(
                    'Start Gaming Call',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamingInterests(ThemeData theme, StickCamProvider provider) {
    final interests = [
      'FPS Games',
      'MOBA',
      'Battle Royale',
      'RPG',
      'Strategy',
      'Racing',
      'Fighting',
      'Sports',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gaming Interests (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: interests.map((interest) {
            final isSelected = provider.interests.contains(interest);
            return FilterChip(
              label: Text(interest),
              selected: isSelected,
              onSelected: (selected) {
                final newInterests = List<String>.from(provider.interests);
                if (selected) {
                  newInterests.add(interest);
                } else {
                  newInterests.remove(interest);
                }
                provider.setInterests(newInterests);
              },
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              selectedColor: theme.colorScheme.primary.withOpacity(0.2),
              checkmarkColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMatchingView(ThemeData theme, StickCamProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Icon(
                    Icons.search_rounded,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Finding a Gamer...',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Looking for someone with similar gaming interests',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => provider.cancelMatching(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCallView(
      ThemeData theme, StickCamProvider provider, bool isMobile) {
    return Stack(
      children: [
        // Main video area
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black,
          child: _isFullScreen
              ? _buildFullScreenVideo(theme, provider)
              : _buildSplitVideoView(theme, provider, isMobile),
        ),

        // Chat overlay
        if (!_isFullScreen) _buildChatOverlay(theme, provider),

        // Controls overlay
        _buildVideoControls(theme, provider),
      ],
    );
  }

  Widget _buildFullScreenVideo(ThemeData theme, StickCamProvider provider) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Stack(
        children: [
          // Remote video (full screen)
          WebRTCVideoWidget(
            stream: provider.remoteStream,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // Local video (picture-in-picture)
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: WebRTCVideoWidget(
                stream: provider.localStream,
                fit: BoxFit.cover,
                width: 120,
                height: 160,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitVideoView(
      ThemeData theme, StickCamProvider provider, bool isMobile) {
    return Column(
      children: [
        // Remote video (top)
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: WebRTCVideoWidget(
              stream: provider.remoteStream,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Local video (bottom)
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: WebRTCVideoWidget(
              stream: provider.localStream,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatOverlay(ThemeData theme, StickCamProvider provider) {
    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Chat header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chat_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Chat',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isFullScreen = !_isFullScreen;
                      });
                    },
                    icon: Icon(
                      _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.white,
                      size: 16,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _chatScrollController,
                padding: const EdgeInsets.all(8),
                itemCount: provider.messages.length,
                itemBuilder: (context, index) {
                  final message = provider.messages[index];
                  final isMe = message.senderId ==
                      Supabase.instance.client.auth.currentUser?.id;

                  return _buildChatMessage(message, isMe, theme);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessage(
      StickCamMessage message, bool isMe, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isMe
                  ? theme.colorScheme.primary.withOpacity(0.8)
                  : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoControls(ThemeData theme, StickCamProvider provider) {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute button
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            color: _isMuted ? Colors.red : Colors.white,
            onPressed: () {
              setState(() {
                _isMuted = !_isMuted;
              });
              provider.toggleMute(_isMuted);
            },
          ),

          // Video button
          _buildControlButton(
            icon: _isVideoOff
                ? Icons.videocam_off_rounded
                : Icons.videocam_rounded,
            color: _isVideoOff ? Colors.red : Colors.white,
            onPressed: () {
              setState(() {
                _isVideoOff = !_isVideoOff;
              });
              provider.toggleVideo(_isVideoOff);
            },
          ),

          // Next button
          _buildControlButton(
            icon: Icons.skip_next_rounded,
            color: Colors.white,
            onPressed: () => provider.next(),
          ),

          // End call button
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              onPressed: () => provider.endCall(),
              icon: const Icon(
                Icons.call_end_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color),
      ),
    );
  }

  Widget _buildChatInput(ThemeData theme, StickCamProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  provider.sendMessage(text.trim());
                  _messageController.clear();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              if (_messageController.text.trim().isNotEmpty) {
                provider.sendMessage(_messageController.text.trim());
                _messageController.clear();
              }
            },
            icon: Icon(
              Icons.send_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
