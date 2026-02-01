import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show File; // Only used on mobile
// import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart'; // Temporarily commented out

class PostMediaUploader extends StatefulWidget {
  final String userId;
  final void Function(String url)? onUploaded;
  final String? initialUrl;

  const PostMediaUploader({
    super.key,
    required this.userId,
    this.onUploaded,
    this.initialUrl,
  });

  @override
  State<PostMediaUploader> createState() => _PostMediaUploaderState();
}

class _PostMediaUploaderState extends State<PostMediaUploader> {
  Uint8List? _webMediaBytes;
  File? _mediaFile;
  String? _mediaUrl;
  bool _isUploading = false;
  bool _isVideo = false;

  Future<void> _pickMedia({required bool video}) async {
    final picker = ImagePicker();
    final picked = video
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webMediaBytes = bytes;
          _mediaFile = null;
          _isVideo = video;
        });
        await _uploadMediaWeb(picked);
      } else {
        setState(() {
          _mediaFile = File(picked.path);
          _webMediaBytes = null;
          _isVideo = video;
        });
        await _uploadMediaMobile(picked);
      }
    }
  }

  Future<void> _uploadMediaWeb(XFile picked) async {
    setState(() => _isUploading = true);
    final supabase = Supabase.instance.client;

    // Handle file extension properly for web
    String fileExt;
    final mimeType = picked.mimeType ?? 'image/jpeg';
    if (mimeType.startsWith('image/')) {
      fileExt = mimeType.split('/')[1];
    } else if (mimeType.startsWith('video/')) {
      fileExt = mimeType.split('/')[1];
    } else {
      fileExt = 'jpg'; // fallback
    }

    final fileName =
        '${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = 'posts/$fileName';
    final bytes = await picked.readAsBytes();
    await supabase.storage.from('posts').uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(contentType: picked.mimeType),
        );
    final publicUrl = supabase.storage.from('posts').getPublicUrl(filePath);
    setState(() {
      _mediaUrl = publicUrl;
      _isUploading = false;
    });
    if (widget.onUploaded != null) {
      widget.onUploaded!(publicUrl);
    }
  }

  Future<String?> _transcodeVideo(String inputPath) async {
    // Temporarily disabled due to ffmpeg compatibility issues
    // final tempDir = await getTemporaryDirectory();
    // final outputPath =
    //     '${tempDir.path}/transcoded_${DateTime.now().millisecondsSinceEpoch}.mp4';
    // final session = await FFmpegKit.execute(
    //     '-i "$inputPath" -c:v libx264 -c:a aac -movflags +faststart -preset veryfast -crf 23 "$outputPath"');
    // final returnCode = await session.getReturnCode();
    // if (returnCode?.isValueSuccess() ?? false) {
    //   return outputPath;
    // }
    return null; // Return null for now
  }

  Future<void> _uploadMediaMobile(XFile picked) async {
    setState(() => _isUploading = true);
    final supabase = Supabase.instance.client;
    final fileExt = picked.path.split('.').last;
    final fileName =
        '${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = 'posts/$fileName';
    String uploadPath = picked.path;
    if (_isVideo && !kIsWeb) {
      // Transcode video before upload (mobile only)
      final transcodedPath = await _transcodeVideo(picked.path);
      if (transcodedPath != null) {
        uploadPath = transcodedPath;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to transcode video. Please try again.')),
        );
        setState(() => _isUploading = false);
        return;
      }
    }
    final file = File(uploadPath);
    await supabase.storage.from('posts').upload(
          filePath,
          file,
          fileOptions: FileOptions(contentType: picked.mimeType),
        );
    final publicUrl = supabase.storage.from('posts').getPublicUrl(filePath);
    setState(() {
      _mediaUrl = publicUrl;
      _isUploading = false;
    });
    if (widget.onUploaded != null) {
      widget.onUploaded!(publicUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewUrl = _mediaUrl ?? widget.initialUrl;
    Widget previewWidget = const SizedBox.shrink();
    if (_isUploading) {
      previewWidget = const Center(child: CircularProgressIndicator());
    } else if (_isVideo) {
      if (kIsWeb && _webMediaBytes != null) {
        // No native video preview in Flutter web, show a placeholder
        previewWidget = const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text('Video selected (preview not supported on web)'),
        );
      } else if (_mediaFile != null) {
        previewWidget = Text(
          'Video selected: \\${_mediaFile!.path.split('/').last}',
        );
      } else if (previewUrl != null) {
        previewWidget = Text('Video uploaded: $previewUrl');
      }
    } else {
      if (kIsWeb && _webMediaBytes != null) {
        previewWidget = Image.memory(_webMediaBytes!, height: 180);
      } else if (_mediaFile != null) {
        previewWidget = Image.file(_mediaFile!, height: 180);
      } else if (previewUrl != null) {
        previewWidget = Image.network(previewUrl, height: 180);
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.image),
              label: const Text('Pick Image'),
              onPressed: _isUploading ? null : () => _pickMedia(video: false),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.videocam),
              label: const Text('Pick Video'),
              onPressed: _isUploading ? null : () => _pickMedia(video: true),
            ),
          ],
        ),
        const SizedBox(height: 16),
        previewWidget,
      ],
    );
  }
}
