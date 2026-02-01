import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

abstract class IStorageRepository {
  Future<String> uploadChatImage(XFile image, String userId);
  Future<String> uploadCommunityPostImage(XFile image, String userId, String communityId);
  Future<String?> uploadAvatar(XFile file, String userId);
  Future<String?> uploadBanner(XFile file, String userId);
  Future<List<String>> uploadPostMedia(List<XFile> files, String userId);
  Future<String?> uploadStory(XFile file, String userId);
  Future<String?> uploadReel(XFile file, String userId);
  Future<String?> uploadHighlight(XFile file, String userId);
  Future<String?> uploadCommunityMedia(XFile file, String communityId);
  Future<String?> uploadTournamentMedia(XFile file, String tournamentId);
  Future<String?> uploadStreamThumbnail(XFile file, String userId);
  Future<bool> deleteFile(String bucket, String filePath);
  String getFileUrl(String bucket, String filePath);
  Future<bool> fileExists(String bucket, String filePath);
  Future<void> ensureStorageBucketsExist();
}

class SupabaseStorageRepository implements IStorageRepository {
  final SupabaseClient _client;
  final Uuid _uuid = const Uuid();

  SupabaseStorageRepository(this._client);

  // Storage bucket names
  static const String avatarsBucket = 'avatars';
  static const String bannersBucket = 'banners';
  static const String postsBucket = 'posts';
  static const String storiesBucket = 'stories';
  static const String reelsBucket = 'reels';
  static const String highlightsBucket = 'highlights';
  static const String communitiesBucket = 'communities';
  static const String tournamentsBucket = 'tournaments';
  static const String streamsBucket = 'streams';
  static const String gamesBucket = 'games';

  @override
  Future<String> uploadChatImage(XFile image, String userId) async {
    final bytes = await image.readAsBytes();
    final fileExt = image.name.split('.').last;
    final fileName = '${userId}_${_uuid.v4()}.$fileExt';
    final filePath = 'chat-images/$fileName';
    
    await _client.storage.from(communitiesBucket).uploadBinary(
      filePath, 
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );
    
    return _client.storage.from(communitiesBucket).getPublicUrl(filePath);
  }

  @override
  Future<String> uploadCommunityPostImage(XFile image, String userId, String communityId) async {
    final bytes = await image.readAsBytes();
    final fileExt = image.name.split('.').last;
    final fileName = '${userId}_${_uuid.v4()}.$fileExt';

    final folderPath = communityId == 'new'
        ? 'temp-communities'
        : 'community-posts/$communityId';
    final filePath = '$folderPath/$fileName';

    await _client.storage.from(communitiesBucket).uploadBinary(
      filePath, 
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );
    
    return _client.storage.from(communitiesBucket).getPublicUrl(filePath);
  }

  @override
  Future<String?> uploadAvatar(XFile file, String userId) async {
    try {
      final bytes = await file.readAsBytes();
      final fileExt = file.name.split('.').last;
      final fileName = '${userId}_${_uuid.v4()}.$fileExt';
      final filePath = '$userId/$fileName';

      await _client.storage.from(avatarsBucket).uploadBinary(filePath, bytes);

      return _client.storage.from(avatarsBucket).getPublicUrl(filePath);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> uploadBanner(XFile file, String userId) async {
    try {
      final bytes = await file.readAsBytes();
      final fileExt = file.name.split('.').last;
      final fileName = '${userId}_${_uuid.v4()}.$fileExt';
      final filePath = '$userId/$fileName';

      await _client.storage.from(bannersBucket).uploadBinary(filePath, bytes);

      return _client.storage.from(bannersBucket).getPublicUrl(filePath);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<String>> uploadPostMedia(List<XFile> files, String userId) async {
    final List<String> urls = [];
    try {
      for (final file in files) {
        final bytes = await file.readAsBytes();
        final fileExt = file.name.split('.').last;
        final fileName = '${userId}_${_uuid.v4()}.$fileExt';
        final filePath = '$userId/$fileName';

        await _client.storage.from(postsBucket).uploadBinary(filePath, bytes);
        final url = _client.storage.from(postsBucket).getPublicUrl(filePath);
        urls.add(url);
      }
    } catch (e) {}
    return urls;
  }

  @override
  Future<String?> uploadStory(XFile file, String userId) async {
    try {
      final bytes = await file.readAsBytes();
      final fileExt = file.name.split('.').last;
      final fileName = '${userId}_${_uuid.v4()}.$fileExt';
      final filePath = '$userId/$fileName';

      await _client.storage.from(storiesBucket).uploadBinary(filePath, bytes);

      return _client.storage.from(storiesBucket).getPublicUrl(filePath);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> uploadReel(XFile file, String userId) async {
    try {
      final bytes = await file.readAsBytes();
      final fileExt = file.name.split('.').last;
      final fileName = '${userId}_${_uuid.v4()}.$fileExt';
      final filePath = '$userId/$fileName';

      await _client.storage.from(reelsBucket).uploadBinary(filePath, bytes);

      return _client.storage.from(reelsBucket).getPublicUrl(filePath);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> uploadHighlight(XFile file, String userId) async {
    try {
      final bytes = await file.readAsBytes();
      final fileExt = file.name.split('.').last;
      final fileName = '${userId}_${_uuid.v4()}.$fileExt';
      final filePath = '$userId/$fileName';

      await _client.storage.from(highlightsBucket).uploadBinary(filePath, bytes);

      return _client.storage.from(highlightsBucket).getPublicUrl(filePath);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> uploadCommunityMedia(XFile file, String communityId) async {
    try {
      final bytes = await file.readAsBytes();
      final fileExt = file.name.split('.').last;
      final fileName = '${communityId}_${_uuid.v4()}.$fileExt';
      final filePath = '$communityId/$fileName';

      await _client.storage.from(communitiesBucket).uploadBinary(filePath, bytes);

      return _client.storage.from(communitiesBucket).getPublicUrl(filePath);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> uploadTournamentMedia(XFile file, String tournamentId) async {
    try {
      final bytes = await file.readAsBytes();
      final fileExt = file.name.split('.').last;
      final fileName = '${tournamentId}_${_uuid.v4()}.$fileExt';
      final filePath = '$tournamentId/$fileName';

      await _client.storage.from(tournamentsBucket).uploadBinary(filePath, bytes);

      return _client.storage.from(tournamentsBucket).getPublicUrl(filePath);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<String?> uploadStreamThumbnail(XFile file, String userId) async {
    try {
      final bytes = await file.readAsBytes();
      final fileExt = file.name.split('.').last;
      final fileName = '${userId}_${_uuid.v4()}.$fileExt';
      final filePath = '$userId/$fileName';

      await _client.storage.from(streamsBucket).uploadBinary(filePath, bytes);

      return _client.storage.from(streamsBucket).getPublicUrl(filePath);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> deleteFile(String bucket, String filePath) async {
    try {
      await _client.storage.from(bucket).remove([filePath]);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  String getFileUrl(String bucket, String filePath) {
    return _client.storage.from(bucket).getPublicUrl(filePath);
  }

  @override
  Future<bool> fileExists(String bucket, String filePath) async {
    try {
      final res = await _client.storage.from(bucket).list(path: filePath);
      return res.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> ensureStorageBucketsExist() async {
    final buckets = [
      avatarsBucket,
      bannersBucket,
      postsBucket,
      storiesBucket,
      reelsBucket,
      highlightsBucket,
      communitiesBucket,
      tournamentsBucket,
      streamsBucket,
      gamesBucket,
    ];

    for (final bucket in buckets) {
      try {
        await _client.storage.from(bucket).list(path: '');
      } catch (e) {
        print('Warning: Storage bucket "$bucket" may not exist: $e');
      }
    }
  }
}

final storageRepositoryProvider = Provider<IStorageRepository>((ref) {
  return SupabaseStorageRepository(Supabase.instance.client);
});
