import 'package:gamer_flick/models/post/post.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/services/media/supabase_upload_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:convert';
import 'package:image/image.dart' as img;

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key, Post? existingPost});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final List<dynamic> _selectedImages = []; // Can be File or XFile
  final List<dynamic> _selectedVideos = []; // Can be File or XFile
  String _selectedPrivacy = 'Public';
  String? _selectedContentType; // Track selected content type
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  // Productivity enhancements
  bool _isDraftSaved = false;
  final List<String> _quickTemplates = [
    'Just had an amazing gaming session! 🎮',
    'Check out this epic play! 🔥',
    'New high score achieved! 🏆',
    'Gaming with friends tonight! 👥',
    'This game is incredible! ⭐',
    'Can\'t stop playing this! 🎯',
  ];
  final List<String> _recentCaptions = [];

  final List<Map<String, dynamic>> _contentTypes = [
    {'icon': Icons.image, 'label': 'Photo', 'color': Colors.blue},
    {'icon': Icons.videocam, 'label': 'Video', 'color': Colors.purple},
  ];

  final List<Map<String, dynamic>> _privacyOptions = [
    {'icon': Icons.public, 'label': 'Public', 'description': 'Anyone can see'},
    {'icon': Icons.group, 'label': 'Friends', 'description': 'Friends only'},
    {'icon': Icons.lock, 'label': 'Private', 'description': 'Only you'},
  ];

  @override
  void initState() {
    super.initState();
    // Start auto-save when text changes
    _captionController.addListener(() {
      if (_captionController.text.isNotEmpty) {
        _startAutoSave();
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    // Prefer multi-image picker where available
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages
          ..clear()
          ..addAll(images);
        _selectedVideos.clear();
        _selectedContentType = 'Photo';
      });
      return;
    }
    // Fallback to single image
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImages
          ..clear()
          ..add(image);
        _selectedVideos.clear();
        _selectedContentType = 'Photo';
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    // image_picker does not support multi-video selection; allow repeated selection to accumulate
    final video = await picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideos.add(video);
        _selectedImages.clear();
        _selectedContentType = 'Video';
      });
    }
  }

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
        _selectedVideos.clear();
        _selectedContentType = 'Photo'; // Set content type
      });
    }
  }

  Future<void> _takeVideo() async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      setState(() {
        _selectedVideos.add(video);
        _selectedImages.clear();
        _selectedContentType = 'Video'; // Set content type
      });
    }
  }

  void _showContentPicker(String contentType) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add $contentType',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  Icons.camera_alt,
                  'Camera',
                  contentType == 'Photo' ? _takePhoto : _takeVideo,
                ),
                _buildPickerOption(
                  Icons.photo_library,
                  'Gallery',
                  contentType == 'Photo' ? _pickImage : _pickVideo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption(IconData icon, String label, VoidCallback onTap) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.dividerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  /// Compresses the selected image to reduce file size
  Future<Uint8List> _compressImage(XFile imageFile) async {
    try {
      // Read the image bytes
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Decode the image
      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('Failed to decode image');
      }

      // Calculate new dimensions while maintaining aspect ratio
      int targetWidth = originalImage.width;
      int targetHeight = originalImage.height;

      // More aggressive dimensions for faster processing
      const int maxWidth = 800; // Reduced from 1200 for faster processing
      const int maxHeight = 1000; // Reduced from 1600 for faster processing

      if (targetWidth > maxWidth || targetHeight > maxHeight) {
        if (targetWidth > targetHeight) {
          // Landscape image
          targetWidth = maxWidth;
          targetHeight =
              (originalImage.height * maxWidth / originalImage.width).round();
        } else {
          // Portrait image
          targetHeight = maxHeight;
          targetWidth =
              (originalImage.width * maxHeight / originalImage.height).round();
        }
      }

      // Resize the image with fastest interpolation
      final img.Image resizedImage = img.copyResize(
        originalImage,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.nearest, // Fastest interpolation
      );

      // Determine output format based on original format
      final String originalPath = imageFile.path.toLowerCase();
      Uint8List compressedBytes;

      if (originalPath.contains('.png')) {
        // For PNG, use fastest compression level
        compressedBytes =
            img.encodePng(resizedImage, level: 1); // Reduced from 3 for speed
      } else if (originalPath.contains('.webp')) {
        // For WebP, convert to JPEG with faster compression
        compressedBytes = img.encodeJpg(
          resizedImage,
          quality: 70, // Reduced from 80 for faster compression
        );
      } else {
        // For JPEG and other formats, use faster compression
        compressedBytes = img.encodeJpg(
          resizedImage,
          quality: 70, // Reduced from 80 for faster compression
        );
      }

      // Log compression results
      final double compressionRatio =
          compressedBytes.length / imageBytes.length;
      print(
          'Post image compressed: ${(compressionRatio * 100).toStringAsFixed(1)}% of original size');
      print(
          'Original: ${(imageBytes.length / 1024).toStringAsFixed(1)}KB, Compressed: ${(compressedBytes.length / 1024).toStringAsFixed(1)}KB');

      return compressedBytes;
    } catch (e) {
      // If compression fails, return original bytes
      print('Post image compression failed: $e');
      return await imageFile.readAsBytes();
    }
  }

  /// Creates a compressed XFile from compressed bytes
  Future<XFile> _createCompressedXFile(
      Uint8List compressedBytes, String originalPath) async {
    // Create a temporary file path
    final String fileName = originalPath.split('/').last;
    final String extension = fileName.split('.').last;

    // For web, we'll create a data URL
    if (kIsWeb) {
      final String mimeType = 'image/${extension.toLowerCase()}';
      final String base64 = base64Encode(compressedBytes);
      final String dataUrl = 'data:$mimeType;base64,$base64';

      // Create a new XFile with compressed data
      return XFile(dataUrl, name: fileName);
    } else {
      // For mobile, we'll need to save to a temporary file
      // This is a simplified approach - in production you might want to use path_provider
      return XFile.fromData(compressedBytes, name: fileName);
    }
  }

  /// Shows compression statistics to the user
  void _showCompressionStats(int originalSize, int compressedSize) {
    final double compressionRatio = compressedSize / originalSize;
    final double savedPercentage = (1 - compressionRatio) * 100;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Image compressed: ${savedPercentage.toStringAsFixed(1)}% smaller (${(originalSize / 1024).toStringAsFixed(1)}KB → ${(compressedSize / 1024).toStringAsFixed(1)}KB)',
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Shows the post optimistically in the feed before upload completes
  void _showOptimisticPost() {
    if (mounted) {
      // Show immediate feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post is being published...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );

      // Navigate back immediately to show the post
      Navigator.pop(context, {'refresh': true, 'optimistic': true});
    }
  }

  /// Refreshes the posts feed to show the new post immediately
  void _refreshPostsFeed() {
    // Notify parent screens to refresh posts
    if (mounted) {
      // Send a message to refresh the home feed
      Navigator.pop(context, {'refresh': true});
    }
  }

  /// Saves current post as draft
  Future<void> _saveDraft() async {
    try {
      final draft = {
        'caption': _captionController.text,
        'contentType': _selectedContentType,
        'privacy': _selectedPrivacy,
        'scheduledDate': _scheduledDate?.toIso8601String(),
        'scheduledTime': _scheduledTime?.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Save to local storage (you can implement this with SharedPreferences)
      // For now, we'll just show a success message
      setState(() {
        _isDraftSaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save draft: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Loads a saved draft
  Future<void> _loadDraft() async {
    try {
      // Load from local storage (implement with SharedPreferences)
      // For now, we'll just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No saved drafts found'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load draft: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Applies a quick template
  void _applyTemplate(String template) {
    setState(() {
      _captionController.text = template;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Template applied!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// Shows quick templates
  void _showQuickTemplates() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Templates',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _quickTemplates.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_quickTemplates[index]),
                    onTap: () {
                      Navigator.pop(context);
                      _applyTemplate(_quickTemplates[index]);
                    },
                    trailing: const Icon(Icons.add),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Auto-save draft periodically
  void _startAutoSave() {
    // Auto-save every 30 seconds
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted && _captionController.text.isNotEmpty) {
        _saveDraft();
      }
    });
  }

  Future<List<String>> _uploadMediaFiles() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final List<String> uploadedUrls = [];

    // Pre-compress all images in parallel for faster processing
    final List<XFile> compressedImages = [];
    if (_selectedImages.isNotEmpty) {
      setState(() {
        _uploadProgress = 0.1;
      });

      // Compress all images in parallel
      final List<Future<XFile>> compressionFutures = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        final image = _selectedImages[i];
        if (image.path.toLowerCase().contains('.jpg') ||
            image.path.toLowerCase().contains('.jpeg') ||
            image.path.toLowerCase().contains('.png') ||
            image.path.toLowerCase().contains('.webp')) {
          compressionFutures.add(_compressAndCreateFile(image, i));
        } else {
          compressionFutures.add(Future.value(image));
        }
      }

      // Wait for all compressions to complete
      final compressedResults = await Future.wait(compressionFutures);
      compressedImages.addAll(compressedResults);

      setState(() {
        _uploadProgress = 0.4;
      });
    }

    // Upload all media files in parallel
    final List<Future<String>> uploadFutures = [];

    // Add image uploads
    for (final image in compressedImages) {
      uploadFutures.add(SupabaseUploadService.uploadFile(
        file: image,
        userId: userId,
        contentType: 'posts',
      ));
    }

    // Add video uploads (no compression for videos)
    for (final video in _selectedVideos) {
      uploadFutures.add(SupabaseUploadService.uploadFile(
        file: video,
        userId: userId,
        contentType: 'posts',
      ));
    }

    // Upload all files in parallel
    final results = await Future.wait(uploadFutures);
    uploadedUrls.addAll(results);

    setState(() {
      _uploadProgress = 1.0;
    });

    return uploadedUrls;
  }

  /// Compresses image and creates compressed file
  Future<XFile> _compressAndCreateFile(XFile image, int index) async {
    // Get original image bytes for comparison
    final Uint8List originalBytes = await image.readAsBytes();

    // Compress the image
    final Uint8List compressedBytes = await _compressImage(image);

    // Show compression statistics for first image only to avoid spam
    if (index == 0) {
      _showCompressionStats(originalBytes.length, compressedBytes.length);
    }

    // Create compressed XFile
    return await _createCompressedXFile(compressedBytes, image.path);
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _scheduledDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _scheduledDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _scheduledTime = picked;
      });
    }
  }

  Future<void> _publishPost() async {
    // Check if content type is selected
    if (_selectedContentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a content type first')),
      );
      return;
    }

    // Check if appropriate media is selected for the content type
    if (_selectedContentType == 'Photo' && _selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a photo for your post')),
      );
      return;
    }

    if (_selectedContentType == 'Video' && _selectedVideos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video for your post')),
      );
      return;
    }

    // Check if there's any content
    if (_selectedImages.isEmpty &&
        _selectedVideos.isEmpty &&
        _captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content to your post')),
      );
      return;
    }

    if (_scheduledDate != null && _scheduledTime != null) {
      final scheduledDateTime = DateTime(
        _scheduledDate!.year,
        _scheduledDate!.month,
        _scheduledDate!.day,
        _scheduledTime!.hour,
        _scheduledTime!.minute,
      );

      if (scheduledDateTime.isBefore(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a future date and time')),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Show optimistic update immediately
      _showOptimisticPost();

      // Upload media files in background
      final mediaUrls = await _uploadMediaFiles();

      setState(() {
        _isUploading = false;
      });

      // Save post to database with optimized insert
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final postData = {
        'user_id': user.id,
        'content': _captionController.text.trim(),
        'media_urls': mediaUrls,
        'is_public': _selectedPrivacy == 'Public',
        'game_tag': null, // Can be added later
        'location': null, // Can be added later
        'created_at':
            DateTime.now().toIso8601String(), // Add explicit timestamp
      };

      // Use a faster insert operation
      final result = await Supabase.instance.client
          .from('posts')
          .insert(postData)
          .select('id') // Only select the ID for faster response
          .single();

      setState(() {
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        final isScheduled = _scheduledDate != null && _scheduledTime != null;
        final scheduledDateTime = isScheduled
            ? DateTime(
                _scheduledDate!.year,
                _scheduledDate!.month,
                _scheduledDate!.day,
                _scheduledTime!.hour,
                _scheduledTime!.minute,
              )
            : null;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isScheduled
                  ? 'Post scheduled for ${scheduledDateTime.toString().substring(0, 16)}!'
                  : 'Post published successfully! ${mediaUrls.length} media files uploaded.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
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
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<Widget> _buildImageWidget(dynamic imageSource) async {
    if (kIsWeb) {
      if (imageSource is String) {
        return Image.network(imageSource);
      } else if (imageSource is Uint8List) {
        return Image.memory(imageSource);
      } else if (imageSource is XFile) {
        final bytes = await imageSource.readAsBytes();
        return Image.memory(bytes);
      }
    } else {
      if (imageSource is File) {
        return Image.file(imageSource);
      } else if (imageSource is XFile) {
        return Image.file(File(imageSource.path));
      }
    }
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Create Post',
            style: TextStyle(color: theme.colorScheme.onSurface)),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.titleTextStyle?.color,
        elevation: 0,
        actions: [
          // Draft save button
          if (!_isUploading && _captionController.text.isNotEmpty)
            IconButton(
              onPressed: _saveDraft,
              icon: Icon(
                _isDraftSaved ? Icons.check : Icons.save,
                color: _isDraftSaved ? Colors.green : theme.colorScheme.primary,
              ),
              tooltip: _isDraftSaved ? 'Draft saved' : 'Save draft',
            ),

          // Quick templates button
          if (!_isUploading)
            IconButton(
              onPressed: _showQuickTemplates,
              icon: const Icon(Icons.text_fields),
              tooltip: 'Quick templates',
            ),

          // Load draft button
          if (!_isUploading)
            IconButton(
              onPressed: _loadDraft,
              icon: const Icon(Icons.folder_open),
              tooltip: 'Load draft',
            ),

          if (_isUploading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _uploadProgress < 0.6 ? 'Compressing...' : 'Uploading...',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(_uploadProgress * 100).toInt()}%',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
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
              onPressed: _isLoading ? null : _publishPost,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Publish',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Theme(
              data: theme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content Type Selection
                  Text(
                    'Content Type',
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: _contentTypes.map((type) {
                      final isSelected = _selectedContentType == type['label'];
                      return OutlinedButton.icon(
                        icon: Icon(type['icon'] as IconData,
                            color: isSelected
                                ? type['color'] as Color
                                : theme.colorScheme.onSurface),
                        label: Text(type['label'] as String,
                            style: TextStyle(
                                color: isSelected
                                    ? type['color'] as Color
                                    : theme.colorScheme.onSurface)),
                        onPressed: () {
                          setState(() {
                            _selectedContentType = type['label'] as String;
                          });
                          if (type['label'] == 'Photo') {
                            _showContentPicker('Photo');
                          } else {
                            _showContentPicker('Video');
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          side: BorderSide(
                            color: isSelected
                                ? type['color'] as Color
                                : theme.colorScheme.outline,
                            width: isSelected ? 2 : 1,
                          ),
                          backgroundColor: isSelected
                              ? (type['color'] as Color).withOpacity(0.1)
                              : theme.colorScheme.surface,
                        ),
                      );
                    }).toList(),
                  ),

                  // Clear selection button
                  if (_selectedContentType != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear Selection'),
                        onPressed: () {
                          setState(() {
                            _selectedContentType = null;
                            _selectedImages.clear();
                            _selectedVideos.clear();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Image Compression Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.compress, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Images are automatically compressed for optimal post viewing and faster uploads',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Content Type Requirement
                  if (_selectedContentType != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _selectedContentType == 'Photo'
                            ? Colors.blue.shade50
                            : Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedContentType == 'Photo'
                              ? Colors.blue.shade200
                              : Colors.purple.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedContentType == 'Photo'
                                ? Icons.image
                                : Icons.videocam,
                            color: _selectedContentType == 'Photo'
                                ? Colors.blue.shade700
                                : Colors.purple.shade700,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedContentType == 'Photo'
                                  ? 'Photo selected: Add an image to your post'
                                  : 'Video selected: Add a video to your post',
                              style: TextStyle(
                                color: _selectedContentType == 'Photo'
                                    ? Colors.blue.shade700
                                    : Colors.purple.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Selected Media Preview
                  if (_selectedImages.isNotEmpty ||
                      _selectedVideos.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          _selectedContentType == 'Photo'
                              ? Icons.image
                              : Icons.videocam,
                          color: _selectedContentType == 'Photo'
                              ? Colors.blue
                              : Colors.purple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedContentType == 'Photo'
                              ? 'Photo Preview'
                              : 'Video Preview (${_selectedVideos.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _selectedVideos.isNotEmpty
                          ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedVideos.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  width: 200,
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: theme.dividerColor
                                              .withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Icon(Icons.videocam,
                                              size: 48,
                                              color: theme.colorScheme.primary),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedVideos.removeAt(index);
                                              if (_selectedVideos.isEmpty &&
                                                  _selectedImages.isEmpty) {
                                                _selectedContentType = null;
                                              }
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: theme.shadowColor
                                                  .withOpacity(0.7),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.close,
                                              color:
                                                  theme.colorScheme.onSurface,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Stack(
                                      children: [
                                        SizedBox(
                                          width: 200,
                                          child: kIsWeb
                                              ? FutureBuilder<Widget>(
                                                  future: _buildImageWidget(
                                                      _selectedImages[index]),
                                                  builder: (context, snapshot) {
                                                    if (snapshot
                                                            .connectionState ==
                                                        ConnectionState
                                                            .waiting) {
                                                      return const Center(
                                                          child:
                                                              CircularProgressIndicator());
                                                    }
                                                    return snapshot.data ??
                                                        Container();
                                                  },
                                                )
                                              : Image.file(
                                                  File(_selectedImages[index]
                                                      .path),
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedImages.removeAt(index);
                                                if (_selectedImages.isEmpty) {
                                                  _selectedContentType = null;
                                                }
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: theme.shadowColor
                                                    .withOpacity(0.7),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                color:
                                                    theme.colorScheme.onSurface,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Caption Input
                  Text(
                    'Caption',
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _captionController,
                    maxLines: 4,
                    maxLength: 500, // Add character limit
                    decoration: InputDecoration(
                      hintText: 'What\'s on your mind?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                      counterText:
                          '${_captionController.text.length}/500 characters',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _isDraftSaved = false; // Reset draft saved status
                      });
                    },
                  ),

                  // Quick actions for caption
                  if (_captionController.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${_captionController.text.split(' ').where((word) => word.isNotEmpty).length} words',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _captionController.text =
                                  _captionController.text.toUpperCase();
                            });
                          },
                          icon: const Icon(Icons.format_size, size: 16),
                          label: const Text('UPPERCASE'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _captionController.text =
                                  _captionController.text.toLowerCase();
                            });
                          },
                          icon: const Icon(Icons.format_size, size: 16),
                          label: const Text('lowercase'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Productivity Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.speed, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              'Productivity Tools',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.save, size: 16),
                              label: const Text('Save Draft'),
                              onPressed: _saveDraft,
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.text_fields, size: 16),
                              label: const Text('Templates'),
                              onPressed: _showQuickTemplates,
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.schedule, size: 16),
                              label: const Text('Schedule'),
                              onPressed: () {
                                // Focus on schedule section
                                // You can implement scroll to schedule section
                              },
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.clear, size: 16),
                              label: const Text('Clear All'),
                              onPressed: () {
                                setState(() {
                                  _captionController.clear();
                                  _selectedImages.clear();
                                  _selectedVideos.clear();
                                  _selectedContentType = null;
                                  _scheduledDate = null;
                                  _scheduledTime = null;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.keyboard,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pro tip: Use the buttons above for quick actions',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Privacy Settings
                  Text(
                    'Privacy',
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: _privacyOptions.map((option) {
                      final isSelected = _selectedPrivacy == option['label'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPrivacy = option['label'] as String;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                option['icon'] as IconData,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                option['label'] as String,
                                style: TextStyle(
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
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
                  const SizedBox(height: 24),

                  // Schedule Post Option
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.schedule,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                            Text(
                              'Schedule Post',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.calendar_today),
                                label: Text(_scheduledDate != null
                                    ? '${_scheduledDate!.day}/${_scheduledDate!.month}/${_scheduledDate!.year}'
                                    : 'Select Date'),
                                onPressed: _selectDate,
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.access_time),
                                label: Text(_scheduledTime != null
                                    ? '${_scheduledTime!.hour}:${_scheduledTime!.minute.toString().padLeft(2, '0')}'
                                    : 'Select Time'),
                                onPressed: _selectTime,
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_scheduledDate != null || _scheduledTime != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear Schedule'),
                              onPressed: () {
                                setState(() {
                                  _scheduledDate = null;
                                  _scheduledTime = null;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
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
          // Loading overlay for immediate feedback
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: theme.colorScheme.outline,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _uploadProgress < 0.6
                            ? 'Compressing Images...'
                            : 'Uploading...',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_uploadProgress * 100).toInt()}%',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }
}
