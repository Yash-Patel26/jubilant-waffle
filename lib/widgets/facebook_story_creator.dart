import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class FacebookStoryCreator extends StatefulWidget {
  final Function(Map<String, dynamic>) onStoryCreated;
  final VoidCallback? onClose;

  const FacebookStoryCreator({
    super.key,
    required this.onStoryCreated,
    this.onClose,
  });

  @override
  State<FacebookStoryCreator> createState() => _FacebookStoryCreatorState();
}

class _FacebookStoryCreatorState extends State<FacebookStoryCreator>
    with TickerProviderStateMixin {
  final List<dynamic> _selectedMedia = [];
  String _selectedStoryType = 'Photo';
  bool _isLoading = false;
  final TextEditingController _textController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _storyTypes = [
    {'icon': Icons.photo_library, 'label': 'Photo', 'color': Colors.green},
    {'icon': Icons.videocam, 'label': 'Video', 'color': Colors.purple},
    {'icon': Icons.text_fields, 'label': 'Text', 'color': Colors.blue},
    {'icon': Icons.brush, 'label': 'Drawing', 'color': Colors.orange},
  ];

  final List<Map<String, dynamic>> _storyEffects = [
    {'icon': Icons.filter, 'label': 'Filters', 'color': Colors.pink},
    {'icon': Icons.emoji_emotions, 'label': 'Stickers', 'color': Colors.yellow},
    {'icon': Icons.text_fields, 'label': 'Text', 'color': Colors.cyan},
    {'icon': Icons.music_note, 'label': 'Music', 'color': Colors.indigo},
  ];

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
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add to your story',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMediaOption(
                  Icons.photo_library,
                  'Photo',
                  () => _handlePhotoSelection(picker, ImageSource.gallery),
                ),
                _buildMediaOption(
                  Icons.camera_alt,
                  'Camera',
                  () => _handlePhotoSelection(picker, ImageSource.camera),
                ),
                _buildMediaOption(
                  Icons.videocam,
                  'Video',
                  () => _handleVideoSelection(picker),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _handlePhotoSelection(
      ImagePicker picker, ImageSource source) async {
    Navigator.pop(context);
    try {
      final image = await picker.pickImage(source: source);
      if (image != null && mounted) {
        setState(() {
          _selectedMedia.clear();
          _selectedMedia.add(image);
          _selectedStoryType = 'Photo';
        });
      }
    } catch (e) {
      _showErrorMessage('Error picking photo: $e');
    }
  }

  Future<void> _handleVideoSelection(ImagePicker picker) async {
    Navigator.pop(context);
    try {
      final video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null && mounted) {
        setState(() {
          _selectedMedia.clear();
          _selectedMedia.add(video);
          _selectedStoryType = 'Video';
        });
      }
    } catch (e) {
      _showErrorMessage('Error picking video: $e');
    }
  }

  Widget _buildMediaOption(IconData icon, String label, VoidCallback onTap) {
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
            child: Icon(icon, size: 32, color: Colors.blue.shade600),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<Widget> _buildMediaWidget(dynamic media) async {
    try {
      if (kIsWeb) {
        if (media is XFile) {
          final bytes = await media.readAsBytes();
          return Image.memory(
            bytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.image, size: 48),
              );
            },
          );
        }
      } else {
        if (media is XFile) {
          return Image.file(
            File(media.path),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey.shade300,
                child: const Icon(Icons.image, size: 48),
              );
            },
          );
        }
      }

      return Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.image, size: 48),
      );
    } catch (e) {
      return Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.image, size: 48),
      );
    }
  }

  Future<void> _createStory() async {
    if (_selectedMedia.isEmpty && _textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please add some content to your story (text or media)')),
      );
      return;
    }

    // Allow text-only stories
    if (_textController.text.trim().isNotEmpty && _selectedMedia.isEmpty) {
      debugPrint('Creating text-only story: ${_textController.text.trim()}');
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate story creation delay
      await Future.delayed(const Duration(seconds: 1));

      final storyData = {
        'media': _selectedMedia,
        'type': _selectedStoryType,
        'text': _textController.text.trim(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      widget.onStoryCreated(storyData);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating story: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          height: size.height * 0.9,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Create story',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed:
                            widget.onClose ?? () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          shape: const CircleBorder(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Story Type Selection
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Story Type',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: _storyTypes.map((type) {
                          final isSelected =
                              _selectedStoryType == type['label'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedStoryType = type['label'] as String;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (type['color'] as Color)
                                        .withValues(alpha: 0.2)
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? type['color'] as Color
                                      : theme.dividerColor,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    type['icon'] as IconData,
                                    color: type['color'] as Color,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    type['label'] as String,
                                    style: TextStyle(
                                      color: isSelected
                                          ? type['color'] as Color
                                          : theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Text Input
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Text (Optional)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _textController,
                        maxLines: 3,
                        maxLength: 200,
                        decoration: InputDecoration(
                          hintText: 'Add text to your story...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                          counterText:
                              '${_textController.text.length}/200 characters',
                        ),
                      ),
                    ],
                  ),
                ),

                // Media Preview Area
                Container(
                  height: 300, // Fixed height instead of Expanded
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: _selectedMedia.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Add to your story',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the button below to add photos or videos',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              // Media Display
                              SizedBox(
                                width: double.infinity,
                                height: double.infinity,
                                child: FutureBuilder<Widget>(
                                  future:
                                      _buildMediaWidget(_selectedMedia.first),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Container(
                                        color: Colors.grey.shade300,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                    return snapshot.data ??
                                        Container(
                                          color: Colors.grey.shade300,
                                          child:
                                              const Icon(Icons.image, size: 48),
                                        );
                                  },
                                ),
                              ),
                              // Remove Button
                              Positioned(
                                top: 16,
                                right: 16,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedMedia.clear();
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              // Story Type Badge
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _storyTypes.firstWhere(
                                      (type) =>
                                          type['label'] == _selectedStoryType,
                                      orElse: () => {'color': Colors.grey},
                                    )['color'] as Color,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _selectedStoryType,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                // Story Effects
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Story Effects',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: _storyEffects.map((effect) {
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // Handle effect selection
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          '${effect['label']} coming soon!')),
                                );
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Column(
                                  children: [
                                    Icon(
                                      effect['icon'] as IconData,
                                      color: effect['color'] as Color,
                                      size: 24,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      effect['label'] as String,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickMedia,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Add Media'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _createStory,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.send),
                          label:
                              Text(_isLoading ? 'Creating...' : 'Share Story'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
