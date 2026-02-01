import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:mime/mime.dart';
import 'package:image_picker/image_picker.dart';

// Import dart:io for mobile platforms
import 'dart:io' as io;

class SupabaseUploadService {
  static final _client = Supabase.instance.client;

  /// Uploads a file to Supabase Storage under the user's folder and returns the public URL.
  /// [file] is the file to upload (XFile for web, File for mobile).
  /// [userId] is the current user's ID.
  /// [contentType] is one of 'posts', 'reels', 'stories', 'audio', 'events'.
  /// Throws an error if upload fails.
  static Future<String> uploadFile({
    required dynamic file,
    required String userId,
    required String contentType,
  }) async {
    String fileName;
    String mimeType;
    Uint8List fileBytes;

    if (kIsWeb) {
      // Handle web platform
      if (file is! XFile) {
        throw Exception('For web platform, file must be an XFile');
      }
      fileName = file.name;
      mimeType = file.mimeType ?? 'application/octet-stream';
      fileBytes = await file.readAsBytes();
    } else {
      // Handle mobile platform
      if (file is io.File) {
        fileName = p.basename(file.path);
        mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
        fileBytes = await file.readAsBytes();
      } else if (file is XFile) {
        // Convert XFile to File for mobile platform
        final ioFile = io.File(file.path);
        fileName = p.basename(file.path);
        mimeType = file.mimeType ??
            lookupMimeType(file.path) ??
            'application/octet-stream';
        fileBytes = await ioFile.readAsBytes();
      } else {
        throw Exception('For mobile platform, file must be a File or XFile');
      }
    }

    final storagePath = '$userId/$contentType/$fileName';

    // Map content type to the correct bucket
    String bucketName;
    switch (contentType) {
      case 'posts':
        bucketName = 'posts';
        break;
      case 'stories':
        bucketName = 'stories';
        break;
      case 'reels':
        bucketName = 'reels';
        break;
      case 'audio':
        bucketName = 'audio';
        break;
      case 'events':
        bucketName = 'events';
        break;
      default:
        bucketName = 'posts'; // Default fallback
    }

    final storage = _client.storage.from(bucketName);

    final result = await storage.uploadBinary(
      storagePath,
      fileBytes,
      fileOptions: FileOptions(contentType: mimeType, upsert: true),
    );

    if (result.isEmpty) {
      throw Exception('Upload failed: No path returned from Supabase');
    }

    // Get the public URL
    final publicUrl = storage.getPublicUrl(storagePath);
    return publicUrl;
  }
}
