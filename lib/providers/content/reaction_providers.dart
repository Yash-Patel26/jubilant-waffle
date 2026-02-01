import 'package:flutter_riverpod/flutter_riverpod.dart';

// StateProvider for reactions on a message (local state)
final messageReactionsProvider =
    StateProvider.family<List<String>, String>((ref, messageId) => []);

// Optionally, you can add helpers for updating reactions, or use MessagingService for backend sync.
