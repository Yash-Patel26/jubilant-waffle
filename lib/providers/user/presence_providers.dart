import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/services/user/presence_service.dart';

final presenceServiceProvider =
    Provider<PresenceService>((ref) => PresenceService());

// StreamProvider for online status of a user
final onlineStatusProvider = StreamProvider.family<bool, String>((ref, userId) {
  final service = ref.watch(presenceServiceProvider);
  return service.onlineStatus(userId);
});

// StreamProvider for typing status in a conversation (requires conversationId and current userId)
final typingStatusProvider = StreamProvider.family
    .autoDispose<bool, ({String conversationId, String userId})>((ref, params) {
  final service = ref.watch(presenceServiceProvider);
  return service.typingStatus(params.conversationId, params.userId);
});
