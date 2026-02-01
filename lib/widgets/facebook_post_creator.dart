import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class FacebookPostCreator extends StatefulWidget {
  final Function(Map<String, dynamic>) onPostCreated;
  final VoidCallback? onClose;

  const FacebookPostCreator({
    super.key,
    required this.onPostCreated,
    this.onClose,
  });

  @override
  State<FacebookPostCreator> createState() => _FacebookPostCreatorState();
}

class _FacebookPostCreatorState extends State<FacebookPostCreator>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final List<dynamic> _selectedMedia = [];
  String _selectedPrivacy = 'Public';
  bool _isLoading = false;
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _privacyOptions = [
    {'icon': Icons.public, 'label': 'Public', 'color': Colors.green},
    {'icon': Icons.people, 'label': 'Friends', 'color': Colors.blue},
    {'icon': Icons.lock, 'label': 'Only me', 'color': Colors.grey},
  ];

  final List<Map<String, dynamic>> _mediaOptions = [
    {
      'icon': Icons.photo_library,
      'label': 'Photo/Video',
      'color': Colors.green
    },
    {'icon': Icons.tag, 'label': 'Tag People', 'color': Colors.blue},
    {'icon': Icons.location_on, 'label': 'Check in', 'color': Colors.red},
    {
      'icon': Icons.emoji_emotions,
      'label': 'Feeling/Activity',
      'color': Colors.orange
    },
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
    final result = await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add to your post',
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
                  'Photo/Video',
                  () async {
                    Navigator.pop(context);
                    try {
                      final images = await picker.pickMultiImage();
                      if (images.isNotEmpty) {
                        setState(() {
                          _selectedMedia.addAll(images);
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error picking images: $e')),
                        );
                      }
                    }
                  },
                ),
                _buildMediaOption(
                  Icons.camera_alt,
                  'Camera',
                  () async {
                    Navigator.pop(context);
                    try {
                      final image =
                          await picker.pickImage(source: ImageSource.camera);
                      if (image != null) {
                        setState(() {
                          _selectedMedia.add(image);
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error taking photo: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  void _removeMedia(int index) {
    setState(() {
      _selectedMedia.removeAt(index);
    });
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
        } else if (media is Uint8List) {
          return Image.memory(
            media,
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
        } else if (media is File) {
          return Image.file(
            media,
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

      // Fallback for unsupported media types
      return Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.image, size: 48),
      );
    } catch (e) {
      // Return fallback widget on error
      return Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.image, size: 48),
      );
    }
  }

  Future<void> _createPost() async {
    if (_textController.text.trim().isEmpty && _selectedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content to your post')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate post creation delay
      await Future.delayed(const Duration(seconds: 1));

      final postData = {
        'text': _textController.text.trim(),
        'media': _selectedMedia,
        'privacy': _selectedPrivacy,
        'timestamp': DateTime.now().toIso8601String(),
      };

      widget.onPostCreated(postData);

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating post: $e')),
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
          height: size.height * 0.8,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
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
                      'Create post',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: widget.onClose ?? () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
              ),

              // User Info
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primary,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Name',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPrivacy = _selectedPrivacy == 'Public'
                                    ? 'Friends'
                                    : _selectedPrivacy == 'Friends'
                                        ? 'Only me'
                                        : 'Public';
                              });
                            },
                            child: Row(
                              children: [
                                Icon(
                                  _privacyOptions.firstWhere(
                                    (option) =>
                                        option['label'] == _selectedPrivacy,
                                  )['icon'] as IconData,
                                  size: 16,
                                  color: _privacyOptions.firstWhere(
                                    (option) =>
                                        option['label'] == _selectedPrivacy,
                                  )['color'] as Color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _selectedPrivacy,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Icon(Icons.arrow_drop_down, size: 16),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Text Input
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _textController,
                        maxLines: null,
                        maxLength: 5000,
                        decoration: InputDecoration(
                          hintText: "What's on your mind?",
                          border: InputBorder.none,
                          counterText: '',
                        ),
                        style: theme.textTheme.bodyLarge,
                        onChanged: (value) {
                          setState(() {
                            _isExpanded = value.isNotEmpty;
                          });
                        },
                      ),

                      // Media Preview
                      if (_selectedMedia.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedMedia.length,
                            itemBuilder: (context, index) {
                              final media = _selectedMedia[index];
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 150,
                                        height: 200,
                                        child: FutureBuilder<Widget>(
                                          future: _buildMediaWidget(media),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return Container(
                                                color: Colors.grey.shade300,
                                                child: const Center(
                                                  child:
                                                      CircularProgressIndicator(),
                                                ),
                                              );
                                            }
                                            return snapshot.data ??
                                                Container(
                                                  color: Colors.grey.shade300,
                                                  child: const Icon(Icons.image,
                                                      size: 48),
                                                );
                                          },
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: () => _removeMedia(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.7),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Bottom Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: theme.dividerColor),
                  ),
                ),
                child: Column(
                  children: [
                    // Media Options
                    Row(
                      children: [
                        Text(
                          'Add to your post',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: _mediaOptions.map((option) {
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (option['label'] == 'Photo/Video') {
                                _pickMedia();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    option['icon'] as IconData,
                                    color: option['color'] as Color,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    option['label'] as String,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Post Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Post',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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
    );
  }
}
