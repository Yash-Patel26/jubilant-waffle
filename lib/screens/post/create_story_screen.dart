import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/services/media/supabase_upload_service.dart';

// Import dart:io for mobile platforms

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final TextEditingController _captionController = TextEditingController();
  dynamic _selectedMedia; // XFile for web, File for mobile
  final String _selectedPrivacy = 'Public';
  bool _isLoading = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  final List<Map<String, dynamic>> _storyTypes = [
    {'icon': Icons.image, 'label': 'Photo', 'color': Colors.blue},
    {'icon': Icons.videocam, 'label': 'Video', 'color': Colors.purple},
  ];

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final media = await picker.pickImage(source: ImageSource.gallery);
    if (media != null) {
      setState(() {
        _selectedMedia = media; // Use XFile directly for both web and mobile
      });
    }
  }

  Future<void> _takeMedia() async {
    final picker = ImagePicker();
    final media = await picker.pickImage(source: ImageSource.camera);
    if (media != null) {
      setState(() {
        _selectedMedia = media; // Use XFile directly for both web and mobile
      });
    }
  }

  void _showMediaPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add to Story',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPickerOption(
                  Icons.camera_alt,
                  'Camera',
                  _takeMedia,
                ),
                _buildPickerOption(
                  Icons.photo_library,
                  'Gallery',
                  _pickMedia,
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
      onTap: onTap,
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
      const int maxWidth = 600; // Reduced from 720 for faster processing
      const int maxHeight = 1000; // Reduced from 1280 for faster processing

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
          quality: 65, // Reduced from 75 for faster compression
        );
      } else {
        // For JPEG and other formats, use faster compression
        compressedBytes = img.encodeJpg(
          resizedImage,
          quality: 65, // Reduced from 75 for faster compression
        );
      }

      // Log compression results
      final double compressionRatio =
          compressedBytes.length / imageBytes.length;
      print(
          'Story image compressed: ${(compressionRatio * 100).toStringAsFixed(1)}% of original size');
      print(
          'Original: ${(imageBytes.length / 1024).toStringAsFixed(1)}KB, Compressed: ${(compressedBytes.length / 1024).toStringAsFixed(1)}KB');

      return compressedBytes;
    } catch (e) {
      // If compression fails, return original bytes
      print('Story image compression failed: $e');
      return await imageFile.readAsBytes();
    }
  }

  /// Shows the story optimistically in the feed before upload completes
  void _showOptimisticStory() {
    if (mounted) {
      // Show immediate feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Story is being published...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );

      // Navigate back immediately to show the story
      Navigator.pop(context, {'refresh': true, 'optimistic': true});
    }
  }

  /// Refreshes the stories feed to show the new story immediately
  void _refreshStoriesFeed() {
    // Notify parent screens to refresh stories
    if (mounted) {
      // Send a message to refresh the home feed
      Navigator.pop(context, {'refresh': true});
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

  Future<String?> _uploadMedia() async {
    if (_selectedMedia == null) return null;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Show compression progress
      setState(() {
        _uploadProgress = 0.1;
      });

      // Compress image if it's an image file
      XFile mediaToUpload = _selectedMedia!;
      if (_selectedMedia!.path.toLowerCase().contains('.jpg') ||
          _selectedMedia!.path.toLowerCase().contains('.jpeg') ||
          _selectedMedia!.path.toLowerCase().contains('.png') ||
          _selectedMedia!.path.toLowerCase().contains('.webp')) {
        setState(() {
          _uploadProgress = 0.2;
        });

        // Get original image bytes for comparison
        final Uint8List originalBytes = await _selectedMedia!.readAsBytes();

        // Compress the image with faster settings
        final Uint8List compressedBytes = await _compressImage(_selectedMedia!);

        setState(() {
          _uploadProgress = 0.5; // Increased progress for compression
        });

        // Show compression statistics
        _showCompressionStats(originalBytes.length, compressedBytes.length);

        // Create compressed XFile
        mediaToUpload =
            await _createCompressedXFile(compressedBytes, _selectedMedia!.path);

        setState(() {
          _uploadProgress = 0.7; // Increased progress for file creation
        });
      }

      // Upload the compressed media
      final url = await SupabaseUploadService.uploadFile(
        file: mediaToUpload,
        userId: userId,
        contentType: 'stories',
      );

      setState(() {
        _uploadProgress = 1.0; // Complete
      });

      return url;
    } catch (e) {
      throw Exception('Failed to upload media: $e');
    }
  }

  Future<void> _publishStory() async {
    if (_selectedMedia == null && _captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add some content to your story')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Show optimistic update immediately
      _showOptimisticStory();

      // Upload media if selected
      String? mediaUrl;
      if (_selectedMedia != null) {
        mediaUrl = await _uploadMedia();
        setState(() {
          _uploadProgress = 1.0;
        });
      }

      setState(() {
        _isUploading = false;
      });

      // Save story to database with optimized insert
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final storyData = {
        'user_id': user.id,
        'content': _captionController.text.trim(),
        'media_url': mediaUrl,
        'expires_at':
            DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
        'created_at':
            DateTime.now().toIso8601String(), // Add explicit timestamp
      };

      // Use a faster insert operation
      final result = await Supabase.instance.client
          .from('stories')
          .insert(storyData)
          .select('id') // Only select the ID for faster response
          .single();

      setState(() {
        _isLoading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story published successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
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
        title: const Text('Add to Story'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.titleTextStyle?.color,
        elevation: 0,
        actions: [
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _uploadProgress < 0.6 ? 'Compressing...' : 'Uploading...',
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
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
              onPressed: _isLoading ? null : _publishStory,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Upload',
                      style: TextStyle(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Story Type Selection
            Text(
              'Add to Story',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: _storyTypes.map((type) {
                return OutlinedButton.icon(
                  icon: Icon(type['icon'] as IconData,
                      color: type['color'] as Color),
                  label: Text(type['label'] as String),
                  onPressed: _showMediaPicker,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                );
              }).toList(),
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
                      'Images are automatically compressed for optimal story viewing and faster uploads',
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

            // Selected Media Preview
            if (_selectedMedia != null) ...[
              Text(
                'Story Preview',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // Use platform-aware image loading
                      if (kIsWeb)
                        FutureBuilder<String>(
                          future: _getImageUrlForWeb(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Image.network(
                                snapshot.data!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: theme.dividerColor.withOpacity(0.3),
                                    child: Icon(
                                      Icons.image,
                                      size: 50,
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.5),
                                    ),
                                  );
                                },
                              );
                            } else {
                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: theme.dividerColor.withOpacity(0.3),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                          },
                        )
                      else
                        FutureBuilder<Uint8List>(
                          future: _selectedMedia!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError || !snapshot.hasData) {
                              return const Center(child: Icon(Icons.error));
                            }
                            return Image.memory(
                              snapshot.data!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMedia = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.shadowColor.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: theme.colorScheme.onSurface,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Caption Input
            Text(
              'Add to Story',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _captionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Add text to your story...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surface,
              ),
            ),
            const SizedBox(height: 24),

            // Story Duration Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.purple.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your story will be visible for 24 hours',
                      style: TextStyle(
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _getImageUrlForWeb() async {
    if (_selectedMedia == null) return '';

    // For web, we can use the path directly if it's a network URL
    // Otherwise, we'll need to convert the file to a data URL
    if (_selectedMedia!.path.startsWith('http')) {
      return _selectedMedia!.path;
    } else {
      // Convert file to data URL for web
      final bytes = await _selectedMedia!.readAsBytes();
      final base64 = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64';
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }
}
