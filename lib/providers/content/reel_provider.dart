import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/models/post/reel.dart';
import 'package:gamer_flick/repositories/reels/reels_repository.dart';

import 'package:gamer_flick/providers/core/supabase_provider.dart';

final reelsRepositoryProvider = Provider<IReelsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseReelsRepository(client: client);
});

final reelProvider = FutureProvider<List<Reel>>((ref) async {
  final repository = ref.watch(reelsRepositoryProvider);
  return await repository.getReelsFeed();
});
