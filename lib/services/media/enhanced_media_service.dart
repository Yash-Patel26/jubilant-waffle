import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';
import 'package:gamer_flick/utils/error_handler.dart';

class EnhancedMediaService {
  static final EnhancedMediaService _instance =
      EnhancedMediaService._internal();
  factory EnhancedMediaService() => _instance;
  EnhancedMediaService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  /// Upload media with advanced options
  Future<String> uploadMedia({
    required dynamic file,
    required String userId,
    required String contentType,
    Map<String, dynamic>? metadata,
    bool compress = true,
    int? maxWidth,
    int? maxHeight,
    double? quality,
  }) async {
    try {
      Uint8List fileBytes;
      String fileName;
      String mimeType;

      if (kIsWeb) {
        if (file is! XFile) {
          throw Exception('For web platform, file must be an XFile');
        }
        fileName = file.name;
        mimeType = file.mimeType ?? 'application/octet-stream';
        fileBytes = await file.readAsBytes();
      } else {
        if (file is File) {
          fileName = p.basename(file.path);
          mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
          fileBytes = await file.readAsBytes();
        } else if (file is XFile) {
          final ioFile = File(file.path);
          fileName = p.basename(file.path);
          mimeType = file.mimeType ??
              lookupMimeType(file.path) ??
              'application/octet-stream';
          fileBytes = await ioFile.readAsBytes();
        } else {
          throw Exception('For mobile platform, file must be a File or XFile');
        }
      }

      // Process image if it's an image file
      if (mimeType.startsWith('image/')) {
        fileBytes = await _processImage(
          fileBytes,
          compress: compress,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          quality: quality,
        );
      }

      final storagePath =
          '$userId/$contentType/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final bucketName = _getBucketName(contentType);
      final storage = _client.storage.from(bucketName);

      final result = await storage.uploadBinary(
        storagePath,
        fileBytes,
        fileOptions: FileOptions(
          contentType: mimeType,
          upsert: true,
          metadata: metadata,
        ),
      );

      if (result.isEmpty) {
        throw Exception('Upload failed: No path returned from Supabase');
      }

      return storage.getPublicUrl(storagePath);
    } catch (e) {
      ErrorHandler.logError('Failed to upload media', e);
      rethrow;
    }
  }

  /// Process image with compression and resizing
  Future<Uint8List> _processImage(
    Uint8List imageBytes, {
    bool compress = true,
    int? maxWidth,
    int? maxHeight,
    double? quality,
  }) async {
    try {
      // For now, return the original image bytes
      // Image processing would require the image package
      return imageBytes;
    } catch (e) {
      ErrorHandler.logError('Failed to process image', e);
      return imageBytes; // Return original if processing fails
    }
  }

  /// Crop image to specified dimensions
  Future<Uint8List> cropImage(
    Uint8List imageBytes, {
    required int x,
    required int y,
    required int width,
    required int height,
  }) async {
    try {
      // For now, return the original image bytes
      // Image cropping would require the image package
      return imageBytes;
    } catch (e) {
      ErrorHandler.logError('Failed to crop image', e);
      rethrow;
    }
  }

  /// Apply filters to image
  Future<Uint8List> applyFilter(
    Uint8List imageBytes, {
    double? brightness,
    double? contrast,
    double? saturation,
    double? hue,
  }) async {
    try {
      // For now, return the original image bytes
      // Image filtering would require the image package
      return imageBytes;
    } catch (e) {
      ErrorHandler.logError('Failed to apply filter', e);
      rethrow;
    }
  }

  /// Pick image from gallery with options
  Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      return await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
    } catch (e) {
      ErrorHandler.logError('Failed to pick image', e);
      return null;
    }
  }

  /// Pick multiple images from gallery
  Future<List<XFile>> pickMultipleImages({
    int maxImages = 10,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      return await _picker.pickMultiImage(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
    } catch (e) {
      ErrorHandler.logError('Failed to pick multiple images', e);
      return [];
    }
  }

  /// Pick video from gallery
  Future<XFile?> pickVideo({
    ImageSource source = ImageSource.gallery,
    Duration? maxDuration,
  }) async {
    try {
      return await _picker.pickVideo(
        source: source,
        maxDuration: maxDuration,
      );
    } catch (e) {
      ErrorHandler.logError('Failed to pick video', e);
      return null;
    }
  }

  /// Get user's media gallery
  Future<List<Map<String, dynamic>>> getUserGallery(
    String userId, {
    String? contentType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from('user_media')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (contentType != null) {
        // Apply content type filter after the select
        final response = await query;
        final allMedia = (response as List).cast<Map<String, dynamic>>();
        return allMedia
            .where((media) => media['content_type'] == contentType)
            .toList();
      }

      final response = await query;
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      ErrorHandler.logError('Failed to get user gallery', e);
      return [];
    }
  }

  /// Save media to user's gallery
  Future<void> saveToGallery({
    required String userId,
    required String mediaUrl,
    required String contentType,
    String? title,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _client.from('user_media').insert({
        'user_id': userId,
        'media_url': mediaUrl,
        'content_type': contentType,
        'title': title,
        'description': description,
        'metadata': metadata,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      ErrorHandler.logError('Failed to save to gallery', e);
      rethrow;
    }
  }

  /// Delete media from gallery
  Future<void> deleteFromGallery(String mediaId, String userId) async {
    try {
      await _client
          .from('user_media')
          .delete()
          .eq('id', mediaId)
          .eq('user_id', userId);
    } catch (e) {
      ErrorHandler.logError('Failed to delete from gallery', e);
      rethrow;
    }
  }

  /// Update media metadata
  Future<void> updateMediaMetadata({
    required String mediaId,
    required String userId,
    String? title,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (metadata != null) updateData['metadata'] = metadata;

      await _client
          .from('user_media')
          .update(updateData)
          .eq('id', mediaId)
          .eq('user_id', userId);
    } catch (e) {
      ErrorHandler.logError('Failed to update media metadata', e);
      rethrow;
    }
  }

  /// Get media statistics
  Future<Map<String, dynamic>> getMediaStats(String userId) async {
    try {
      final response = await _client
          .from('user_media')
          .select('content_type, created_at')
          .eq('user_id', userId);

      final mediaList = response as List;
      final stats = <String, int>{};

      for (final media in mediaList) {
        final type = media['content_type'] as String;
        stats[type] = (stats[type] ?? 0) + 1;
      }

      return {
        'total_media': mediaList.length,
        'by_type': stats,
        'recent_uploads': mediaList
            .where((m) => DateTime.parse(m['created_at'])
                .isAfter(DateTime.now().subtract(const Duration(days: 7))))
            .length,
      };
    } catch (e) {
      ErrorHandler.logError('Failed to get media stats', e);
      return {};
    }
  }

  /// Create media collage
  Future<Uint8List> createCollage(
    List<Uint8List> images, {
    int columns = 2,
    int spacing = 10,
    Color backgroundColor = const Color(0xFF000000),
  }) async {
    try {
      if (images.isEmpty) throw Exception('No images provided');

      // For now, return the first image as placeholder
      // Collage creation would require the image package
      return images.first;
    } catch (e) {
      ErrorHandler.logError('Failed to create collage', e);
      rethrow;
    }
  }

  /// Get bucket name based on content type
  String _getBucketName(String contentType) {
    switch (contentType) {
      case 'posts':
        return 'posts';
      case 'stories':
        return 'stories';
      case 'reels':
        return 'reels';
      case 'audio':
        return 'audio';
      case 'events':
        return 'events';
      case 'profile':
        return 'profiles';
      case 'gallery':
        return 'gallery';
      default:
        return 'posts';
    }
  }

  /// Generate thumbnail for video
  Future<Uint8List?> generateVideoThumbnail(String videoPath) async {
    try {
      // This would typically use a video processing library
      // For now, return null as placeholder
      return null;
    } catch (e) {
      ErrorHandler.logError('Failed to generate video thumbnail', e);
      return null;
    }
  }

  /// Compress video
  Future<File?> compressVideo(
    File videoFile, {
    double? quality,
    int? bitrate,
    int? width,
    int? height,
  }) async {
    try {
      // This would typically use a video processing library
      // For now, return the original file as placeholder
      return videoFile;
    } catch (e) {
      ErrorHandler.logError('Failed to compress video', e);
      return null;
    }
  }
}
