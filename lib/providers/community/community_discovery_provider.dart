import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/models/community/community.dart';
import 'package:gamer_flick/providers/community/community_notifier.dart';
import 'package:gamer_flick/providers/user/user_notifier.dart';

final trendingCommunitiesProvider = FutureProvider<List<Community>>((ref) async {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.fetchTrendingCommunities();
});

final popularCommunitiesProvider = FutureProvider<List<Community>>((ref) async {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.fetchPopularCommunities();
});

final newestCommunitiesProvider = FutureProvider<List<Community>>((ref) async {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.fetchNewestCommunities();
});

final recommendedCommunitiesProvider = FutureProvider<List<Community>>((ref) async {
  final repository = ref.watch(communityRepositoryProvider);
  final user = ref.watch(userProvider).value;
  if (user == null) return [];
  return repository.getRecommendedCommunities(user.id);
});

final communitiesByCategoryProvider = FutureProvider.family<List<Community>, String>((ref, category) async {
  final repository = ref.watch(communityRepositoryProvider);
  return repository.getCommunitiesByCategory(category);
});
