import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/services/game/live_stream_service.dart';

class LiveStreamViewerScreen extends StatefulWidget {
  final Map<String, dynamic> stream;
  const LiveStreamViewerScreen({super.key, required this.stream});

  @override
  State<LiveStreamViewerScreen> createState() => _LiveStreamViewerScreenState();
}

class _LiveStreamViewerScreenState extends State<LiveStreamViewerScreen> {
  final LiveStreamService _service = LiveStreamService();
  VideoPlayerController? _controller;
  YoutubePlayerController? _ytController;
  bool _isInitializing = true;
  int _viewerCount = 0;
  RealtimeChannel? _viewersChannel;

  String get _streamId => widget.stream['id'] as String;
  String get _title => (widget.stream['title'] ?? 'Live Stream') as String;
  String? get _streamUrl => widget.stream['stream_url'] as String?;
  Map<String, dynamic>? get _streamer =>
      widget.stream['profiles'] as Map<String, dynamic>?;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _service.joinStream(_streamId);
      final count = await _service.getViewerCount(_streamId);
      if (mounted) setState(() => _viewerCount = count);

      _viewersChannel = _service.subscribeToViewerChanges(
        streamId: _streamId,
        onChanged: () async {
          final c = await _service.getViewerCount(_streamId);
          if (mounted) setState(() => _viewerCount = c);
        },
      );

      final url = _streamUrl;
      if (url != null && !_isYouTubeUrl(url)) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(url));
        await _controller!.initialize();
        await _controller!.setLooping(true);
        await _controller!.play();
      } else if (url != null && _isYouTubeUrl(url)) {
        final videoId = _extractYouTubeVideoId(url);
        if (videoId != null) {
          _ytController = YoutubePlayerController(
            params: const YoutubePlayerParams(
              showControls: true,
              showFullscreenButton: true,
              strictRelatedVideos: true,
              enableCaption: false,
            ),
          );
          _ytController!.loadVideoById(videoId: videoId);
        }
      }
    } catch (_) {
      // Swallow init errors to avoid blocking UI
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  bool _isYouTubeUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('youtube.com') || lower.contains('youtu.be');
  }

  @override
  void dispose() {
    _viewersChannel?.unsubscribe();
    _service.leaveStream(_streamId);
    _controller?.dispose();
    _ytController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final username =
        _streamer != null ? (_streamer!['username'] ?? 'Streamer') : 'Streamer';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: _isInitializing
          ? Center(
              child:
                  CircularProgressIndicator(color: theme.colorScheme.primary))
          : Column(
              children: [
                Expanded(
                  child: _buildPlayerArea(),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(top: BorderSide(color: theme.dividerColor)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.dividerColor,
                        backgroundImage: _streamer != null &&
                                _streamer!['avatar_url'] != null &&
                                (_streamer!['avatar_url'] as String).isNotEmpty
                            ? NetworkImage(_streamer!['avatar_url'] as String)
                            : null,
                        child: (_streamer == null ||
                                _streamer!['avatar_url'] == null ||
                                (_streamer!['avatar_url'] as String).isEmpty)
                            ? Text(
                                username
                                    .toString()
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: TextStyle(
                                    color: theme.colorScheme.onSurface),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username.toString(),
                              style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$_viewerCount watching',
                              style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.6),
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.live_tv, color: theme.colorScheme.error),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPlayerArea() {
    final theme = Theme.of(context);
    final url = _streamUrl;
    if (url == null || url.isEmpty) {
      return Center(
        child: Text('No stream URL provided',
            style: TextStyle(color: theme.colorScheme.onSurface)),
      );
    }

    if (_isYouTubeUrl(url)) {
      if (_ytController == null) {
        return Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary));
      }
      return YoutubePlayerScaffold(
        controller: _ytController!,
        builder: (context, player) {
          return Container(
              color: theme.colorScheme.surface, child: Center(child: player));
        },
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  if (_controller!.value.isPlaying) {
                    _controller!.pause();
                  } else {
                    _controller!.play();
                  }
                  setState(() {});
                },
                icon: Icon(
                  _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _extractYouTubeVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      }
      if (uri.host.contains('youtube.com')) {
        if (uri.path.contains('/watch')) {
          return uri.queryParameters['v'];
        }
        final segments = uri.pathSegments;
        final liveIndex = segments.indexOf('live');
        if (liveIndex != -1 && liveIndex + 1 < segments.length) {
          return segments[liveIndex + 1];
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
