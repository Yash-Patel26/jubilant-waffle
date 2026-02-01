import 'package:flutter/material.dart';
import 'package:gamer_flick/models/chat/message.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import '../../utils/time_utils.dart';

class MediaGalleryScreen extends StatelessWidget {
  final List<Message> images;
  final Map<String, String>? userMap; // userId -> userName
  const MediaGalleryScreen({super.key, required this.images, this.userMap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Media Gallery')),
      body: GridView.builder(
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final message = images[index];
          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => _FullScreenGallery(
                  images: images,
                  initialIndex: index,
                  userMap: userMap,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: isVideoUrl(message.imageUrl ?? '')
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          color: Colors.black12,
                          child: Icon(Icons.videocam,
                              size: 40, color: Colors.grey[700]),
                        ),
                        const Positioned(
                          bottom: 8,
                          right: 8,
                          child: Icon(Icons.play_circle_fill,
                              color: Colors.white, size: 28),
                        ),
                      ],
                    )
                  : Image.network(message.imageUrl!, fit: BoxFit.cover),
            ),
          );
        },
      ),
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  final List<Message> images;
  final int initialIndex;
  final Map<String, String>? userMap;
  const _FullScreenGallery(
      {required this.images, required this.initialIndex, this.userMap});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late int currentIndex;
  late PageController _controller;
  bool _downloading = false;
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _downloadImage(String url) async {
    setState(() => _downloading = true);
    try {
      final response = await http.get(Uri.parse(url));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${url.split('/').last}');
      await file.writeAsBytes(response.bodyBytes);
      // TODO: On mobile, move to gallery and request permissions if needed
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image downloaded to temp directory')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Download failed: $e')));
    } finally {
      setState(() => _downloading = false);
    }
  }

  Future<void> _shareImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${url.split('/').last}');
      await file.writeAsBytes(response.bodyBytes);
      await Share.shareXFiles([XFile(file.path)],
          text: 'Check out this image!');
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Share failed: $e')));
    }
  }

  void _initVideo(String url) async {
    _videoController?.dispose();
    _videoController = VideoPlayerController.network(url);
    await _videoController!.initialize();
    setState(() {
      _videoInitialized = true;
    });
    _videoController!.play();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final userMap = widget.userMap ?? {};
    final message = images[currentIndex];
    final senderName = userMap[message.senderId] ?? message.senderId;
    final isVideo = isVideoUrl(message.imageUrl ?? '');
    if (isVideo &&
        (_videoController == null ||
            _videoController!.dataSource != message.imageUrl)) {
      _videoInitialized = false;
      _initVideo(message.imageUrl!);
    }
    return Dialog(
      backgroundColor: Colors.black,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => currentIndex = i),
            itemBuilder: (context, index) {
              final message = images[index];
              final isVideo = isVideoUrl(message.imageUrl ?? '');
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: isVideo
                          ? (_videoController != null &&
                                  _videoInitialized &&
                                  _videoController!.dataSource ==
                                      message.imageUrl
                              ? AspectRatio(
                                  aspectRatio:
                                      _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                )
                              : const CircularProgressIndicator())
                          : InteractiveViewer(
                              minScale: 1,
                              maxScale: 4,
                              child: Image.network(message.imageUrl!,
                                  fit: BoxFit.contain),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
                    child: Column(
                      children: [
                        Text(
                          'Sent: ${TimeUtils.formatDateTimeIST(message.createdAt)}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                        Text(
                          'Sender: ${userMap[message.senderId] ?? message.senderId}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_downloading)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white)),
                  ),
                IconButton(
                  icon:
                      const Icon(Icons.download, color: Colors.white, size: 28),
                  onPressed: _downloading
                      ? null
                      : () => _downloadImage(message.imageUrl!),
                  tooltip: 'Download',
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.white, size: 28),
                  onPressed: () => _shareImage(message.imageUrl!),
                  tooltip: 'Share',
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

bool isVideoUrl(String url) {
  return url.endsWith('.mp4') || url.endsWith('.mov') || url.endsWith('.webm');
}
