import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:gamer_flick/providers/app/premium_provider.dart';
import 'package:gamer_flick/services/media/supabase_upload_service.dart';
import 'package:gamer_flick/services/post/post_service.dart';

// Simple in-screen overlay model for authoring
class _OverlayDraft {
  _OverlayDraft({
    required this.text,
    required this.top,
    required this.left,
    this.style = 'white',
  });
  String text;
  double top;
  double left;
  String style; // 'pink' | 'watermark' | 'white'
}

class CreateReelScreen extends rp.ConsumerStatefulWidget {
  const CreateReelScreen({super.key});

  @override
  rp.ConsumerState<CreateReelScreen> createState() => _CreateReelScreenState();
}

class _CreateReelScreenState extends rp.ConsumerState<CreateReelScreen> {
  final TextEditingController _captionController = TextEditingController();
  dynamic _selectedVideo; // XFile for web, File for mobile
  String _selectedMusic = 'None';
  String _selectedEffect = 'None';
  String _selectedTemplate = 'None';
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _showDebugInfo = false;

  final List<_OverlayDraft> _overlays = <_OverlayDraft>[];
  double _previewWidth = 0;
  double _previewHeight = 0;

  final List<String> _musicOptions = [
    'None',
    'Trending',
    'Pop',
    'Hip Hop',
    'Rock',
    'Jazz'
  ];
  final List<String> _effectOptions = [
    'None',
    'Blur',
    'Vintage',
    'Bright',
    'Contrast',
    'Sepia'
  ];
  final List<String> _templateOptions = [
    'None',
    'Story',
    'Square',
    'Portrait',
    'Landscape'
  ];

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideo = video; // Use XFile directly for both web and mobile
      });

      // Video selected successfully
    } else {
      // No video selected
    }
  }

  Future<void> _takeVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      setState(() {
        _selectedVideo = video; // Use XFile directly for both web and mobile
      });
    } else {
      // No video captured
    }
  }

  TextStyle _getTextStyle(String style) {
    final theme = Theme.of(context);

    switch (style) {
      case 'pink':
        return TextStyle(
          color: theme.colorScheme.secondary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(blurRadius: 2, color: theme.shadowColor)],
        );
      case 'watermark':
        return TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          shadows: [Shadow(blurRadius: 1, color: theme.shadowColor)],
        );
      default:
        return TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          shadows: [Shadow(blurRadius: 2, color: theme.shadowColor)],
        );
    }
  }

  Future<void> _addOverlayDialog() async {
    final textCtrl = TextEditingController();
    String style = 'white';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Text Overlay'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textCtrl,
                decoration: const InputDecoration(
                  labelText: 'Text',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: style,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'white', child: Text('White')),
                  DropdownMenuItem(value: 'pink', child: Text('Pink')),
                  DropdownMenuItem(
                      value: 'watermark', child: Text('Watermark')),
                ],
                onChanged: (v) => style = v ?? 'white',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (result == true && textCtrl.text.trim().isNotEmpty) {
      setState(() {
        _overlays.add(_OverlayDraft(
          text: textCtrl.text.trim(),
          // Place near center initially
          top: (_previewHeight > 0 ? _previewHeight / 2 : 100) - 20,
          left: (_previewWidth > 0 ? _previewWidth / 2 : 100) - 60,
          style: style,
        ));
      });
    }
  }

  void _showVideoPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Video',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(Icons.camera_alt, 'Camera', _takeVideo),
                _buildPickerOption(Icons.photo_library, 'Gallery', _pickVideo),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: Colors.pink),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<String?> _uploadVideo() async {
    if (_selectedVideo == null) return null;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final url = await SupabaseUploadService.uploadFile(
        file: _selectedVideo!,
        userId: userId,
        contentType: 'reels',
      );

      return url;
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }

  Future<void> _publishReel() async {
    if (_selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video for your reel')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Upload video
      final videoUrl = await _uploadVideo();

      if (videoUrl == null) {
        throw Exception('Failed to upload video');
      }

      setState(() {
        _isUploading = false;
        _uploadProgress = 1.0;
      });

      // Save reel to database
      final postService = PostService();
      final reel = await postService.createReel(
        videoUrl: videoUrl,
        thumbnailUrl: videoUrl, // Using video URL as thumbnail for now
        caption: _captionController.text.trim().isEmpty
            ? null
            : _captionController.text.trim(),
        gameTag: null, // Can be added later
        duration: null, // Can be added later
        metadata: {
          'music': _selectedMusic,
          'effect': _selectedEffect,
          'template': _selectedTemplate,
          'text_overlays': _overlays
              .map((o) => {
                    'text': o.text,
                    'top': o.top,
                    'left': o.left,
                    'style': o.style,
                  })
              .toList(),
        },
      );

      if (reel == null) {
        throw Exception('Failed to save reel to database');
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reel published successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Reel'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.titleTextStyle?.color,
        elevation: 0,
        actions: [
          // Debug toggle button
          IconButton(
            icon: Icon(
                _showDebugInfo ? Icons.bug_report : Icons.bug_report_outlined),
            onPressed: () {
              setState(() {
                _showDebugInfo = !_showDebugInfo;
              });
            },
            tooltip: 'Toggle Debug Info',
          ),
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '${(_uploadProgress * 100).toInt()}%',
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ),
            )
          else
            TextButton(
              onPressed: _isLoading ? null : _publishReel,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Publish',
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          rp.Consumer(builder: (context, ref, _) {
            final isPremium = ref.watch(premiumProvider).asData?.value == true;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: theme.dividerColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.movie_filter,
                      color: isPremium ? Colors.green : Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isPremium
                          ? 'Unlimited clips enabled'
                          : 'Upgrade to Premium for unlimited clips',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (!isPremium)
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/premium'),
                      child: const Text('Upgrade'),
                    ),
                ],
              ),
            );
          }),
          // Debug Info Panel
          if (_showDebugInfo) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: theme.dividerColor.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bug_report, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Debug Info',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Debug summary printed to console')),
                          );
                        },
                        child: const Text('Export'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selected Video: ${_selectedVideo?.name ?? 'None'}',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'Caption: ${_captionController.text.isEmpty ? 'None' : _captionController.text}',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'Music: $_selectedMusic | Effect: $_selectedEffect | Template: $_selectedTemplate',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Video Selection + overlay authoring preview
                  LayoutBuilder(builder: (context, constraints) {
                    _previewWidth = constraints.maxWidth;
                    _previewHeight = 380;

                    return Container(
                      width: double.infinity,
                      height: _previewHeight,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          if (_selectedVideo != null)
                            FittedBox(
                              fit: BoxFit.cover,
                              child: kIsWeb
                                  ? Image.network(
                                      _selectedVideo!.path,
                                      errorBuilder: (c, e, s) =>
                                          const SizedBox.shrink(),
                                    )
                                  : Image.file(_selectedVideo!),
                            )
                          else
                            GestureDetector(
                              onTap: _showVideoPicker,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo,
                                        size: 48,
                                        color: theme.textTheme.bodyMedium?.color
                                            ?.withOpacity(0.5)),
                                    const SizedBox(height: 8),
                                    Text('Add Video',
                                        style: theme.textTheme.bodyMedium),
                                  ],
                                ),
                              ),
                            ),
                          ..._overlays.asMap().entries.map((entry) {
                            final int i = entry.key;
                            final _OverlayDraft o = entry.value;
                            return Positioned(
                              top: o.top,
                              left: o.left,
                              child: GestureDetector(
                                onPanUpdate: (d) {
                                  setState(() {
                                    o.top = (o.top + d.delta.dy)
                                        .clamp(0, _previewHeight - 30);
                                    o.left = (o.left + d.delta.dx)
                                        .clamp(0, _previewWidth - 60);
                                  });
                                },
                                onLongPress: () async {
                                  final remove = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Overlay options'),
                                      content: const Text(
                                          'Do you want to delete this overlay?'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Cancel')),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Delete')),
                                      ],
                                    ),
                                  );
                                  if (remove == true) {
                                    setState(() => _overlays.removeAt(i));
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    o.text,
                                    style: _getTextStyle(o.style),
                                  ),
                                ),
                              ),
                            );
                          }),
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pink,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _selectedVideo == null
                                  ? null
                                  : _addOverlayDialog,
                              icon: const Icon(Icons.text_fields),
                              label: const Text('Add Text'),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Caption
                  TextField(
                    controller: _captionController,
                    decoration: const InputDecoration(
                      hintText: 'Write a caption...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Options
                  _buildOptionSection('Music', _selectedMusic, _musicOptions,
                      (value) {
                    setState(() => _selectedMusic = value ?? 'None');
                  }),
                  const SizedBox(height: 16),

                  _buildOptionSection('Effect', _selectedEffect, _effectOptions,
                      (value) {
                    setState(() => _selectedEffect = value ?? 'None');
                  }),
                  const SizedBox(height: 16),

                  _buildOptionSection(
                      'Template', _selectedTemplate, _templateOptions, (value) {
                    setState(() => _selectedTemplate = value ?? 'None');
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionSection(String title, String selectedValue,
      List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selectedValue,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }
}
