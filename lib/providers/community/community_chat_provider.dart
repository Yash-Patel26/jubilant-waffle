import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/models/community/community_chat_message.dart';
import 'package:gamer_flick/services/community/community_chat_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final communityChatServiceProvider = Provider((ref) => CommunityChatService());

final communityChatProvider = AsyncNotifierProvider.family<CommunityChatNotifier, List<CommunityChatMessage>, String>(() {
  return CommunityChatNotifier();
});

class CommunityChatNotifier extends FamilyAsyncNotifier<List<CommunityChatMessage>, String> {
  late String _communityId;
  RealtimeChannel? _channel;

  @override
  Future<List<CommunityChatMessage>> build(String arg) async {
    _communityId = arg;
    ref.onDispose(() {
      _channel?.unsubscribe();
    });
    return _fetchMessages();
  }

  Future<List<CommunityChatMessage>> _fetchMessages() async {
    return ref.read(communityChatServiceProvider).fetchMessages(_communityId);
  }

  void subscribe() {
    _channel?.unsubscribe();
    _channel = ref.read(communityChatServiceProvider).subscribeToMessages(_communityId, (msg) {
      final currentMessages = state.value ?? [];
      state = AsyncValue.data([...currentMessages, msg]);
    });
  }

  Future<void> sendMessage(String content, {String? imageUrl}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated. Please log in again.');
    }

    if (content.trim().isEmpty && (imageUrl == null || imageUrl.isEmpty)) {
      throw Exception('Message cannot be empty.');
    }

    try {
      final msg = await ref.read(communityChatServiceProvider).sendMessage(
        communityId: _communityId,
        userId: user.id,
        message: content,
      );

      final currentMessages = state.value ?? [];
      state = AsyncValue.data([...currentMessages, msg]);
    } catch (e) {
      rethrow;
    }
  }
}
