import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/utils/error_handler.dart';

class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // =====================================================
  // GLOBAL SEARCH
  // =====================================================

  /// Perform global search across all content types
  Future<Map<String, dynamic>> globalSearch(String query,
      {int limit = 20}) async {
    try {
      final results = <String, dynamic>{};

      // Search users
      results['users'] = await searchUsers(query, limit: (limit / 4).round());

      // Search posts
      results['posts'] = await searchPosts(query, limit: (limit / 4).round());

      // Search tournaments
      results['tournaments'] =
          await searchTournaments(query, limit: (limit / 4).round());

      // Search games
      results['games'] = await searchGames(query, limit: (limit / 4).round());

      return results;
    } catch (e) {
      ErrorHandler.logError('Failed to perform global search', e);
      return {};
    }
  }

  /// Search with filters
  Future<Map<String, dynamic>> filteredSearch({
    required String query,
    List<String>?
        contentTypes, // ['users', 'posts', 'tournaments', 'communities', 'games']
    Map<String, dynamic>? filters,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final results = <String, dynamic>{};
      final types = contentTypes ?? ['users', 'posts', 'tournaments', 'games'];

      for (final type in types) {
        switch (type) {
          case 'users':
            results['users'] =
                await searchUsers(query, limit: limit, offset: offset);
            break;
          case 'posts':
            results['posts'] =
                await searchPosts(query, limit: limit, offset: offset);
            break;
          case 'tournaments':
            results['tournaments'] =
                await searchTournaments(query, limit: limit, offset: offset);
            break;

          case 'games':
            results['games'] =
                await searchGames(query, limit: limit, offset: offset);
            break;
        }
      }

      return results;
    } catch (e) {
      ErrorHandler.logError('Failed to perform filtered search', e);
      return {};
    }
  }

  // =====================================================
  // USER SEARCH
  // =====================================================

  /// Search users by username, display name, or bio
  Future<List<Map<String, dynamic>>> searchUsers(String query,
      {int limit = 20, int offset = 0}) async {
    try {
      final response = await _client
          .from('profiles')
          .select('''
            id,
            username,
            display_name,
            bio,
            avatar_url,
            location,
            favorite_games,
            is_public
          ''')
          .or('username.ilike.%$query%,display_name.ilike.%$query%,bio.ilike.%$query%')
          .eq('is_public', true)
          .order('username')
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((user) => {
                'id': user['id'],
                'username': user['username'],
                'display_name': user['display_name'],
                'bio': user['bio'],
                'avatar_url': user['avatar_url'],
                'location': user['location'],
                'favorite_games': user['favorite_games'] ?? [],
                'type': 'user',
              })
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search users', e);
      return [];
    }
  }

  /// Search users by game preference
  Future<List<Map<String, dynamic>>> searchUsersByGame(String game,
      {int limit = 20}) async {
    try {
      final response = await _client
          .from('profiles')
          .select('''
            id,
            username,
            display_name,
            bio,
            avatar_url,
            location,
            favorite_games,
            is_public
          ''')
          .contains('favorite_games', [game])
          .eq('is_public', true)
          .order('username')
          .limit(limit);

      return (response as List)
          .map((user) => {
                'id': user['id'],
                'username': user['username'],
                'display_name': user['display_name'],
                'bio': user['bio'],
                'avatar_url': user['avatar_url'],
                'location': user['location'],
                'favorite_games': user['favorite_games'] ?? [],
                'type': 'user',
              })
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search users by game', e);
      return [];
    }
  }

  /// Search users by location
  Future<List<Map<String, dynamic>>> searchUsersByLocation(String location,
      {int limit = 20}) async {
    try {
      final response = await _client
          .from('profiles')
          .select('''
            id,
            username,
            display_name,
            bio,
            avatar_url,
            location,
            favorite_games,
            is_public
          ''')
          .ilike('location', '%$location%')
          .eq('is_public', true)
          .order('username')
          .limit(limit);

      return (response as List)
          .map((user) => {
                'id': user['id'],
                'username': user['username'],
                'display_name': user['display_name'],
                'bio': user['bio'],
                'avatar_url': user['avatar_url'],
                'location': user['location'],
                'favorite_games': user['favorite_games'] ?? [],
                'type': 'user',
              })
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search users by location', e);
      return [];
    }
  }

  // =====================================================
  // POST SEARCH
  // =====================================================

  /// Search posts by content, game tag, or location
  Future<List<Map<String, dynamic>>> searchPosts(String query,
      {int limit = 20, int offset = 0}) async {
    try {
      final response = await _client
          .from('posts')
          .select('''
            *,
            likes:post_likes(count),
            comments:comments(count)
          ''')
          .or('content.ilike.%$query%,game_tag.ilike.%$query%,location.ilike.%$query%')
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((post) => {
                'id': post['id'],
                'content': post['content'],
                'media_urls': post['media_urls'] ?? [],
                'game_tag': post['game_tag'],
                'location': post['location'],
                'created_at': post['created_at'],
                'likes_count': post['likes'][0]['count'] ?? 0,
                'comments_count': post['comments'][0]['count'] ?? 0,
                'type': 'post',
              })
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search posts', e);
      return [];
    }
  }

  /// Search posts by game tag
  Future<List<Map<String, dynamic>>> searchPostsByGame(String game,
      {int limit = 20}) async {
    try {
      final response = await _client
          .from('posts')
          .select('''
            *,
            likes:post_likes(count),
            comments:comments(count)
          ''')
          .eq('game_tag', game)
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((post) => {
                'id': post['id'],
                'content': post['content'],
                'media_urls': post['media_urls'] ?? [],
                'game_tag': post['game_tag'],
                'location': post['location'],
                'created_at': post['created_at'],
                'likes_count': post['likes'][0]['count'] ?? 0,
                'comments_count': post['comments'][0]['count'] ?? 0,
                'type': 'post',
              })
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search posts by game', e);
      return [];
    }
  }

  /// Search posts by location
  Future<List<Map<String, dynamic>>> searchPostsByLocation(String location,
      {int limit = 20}) async {
    try {
      final response = await _client
          .from('posts')
          .select('''
            *,
            likes:post_likes(count),
            comments:comments(count)
          ''')
          .ilike('location', '%$location%')
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((post) => {
                'id': post['id'],
                'content': post['content'],
                'media_urls': post['media_urls'] ?? [],
                'game_tag': post['game_tag'],
                'location': post['location'],
                'created_at': post['created_at'],
                'likes_count': post['likes'][0]['count'] ?? 0,
                'comments_count': post['comments'][0]['count'] ?? 0,
                'type': 'post',
              })
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search posts by location', e);
      return [];
    }
  }

  // =====================================================
  // TOURNAMENT SEARCH
  // =====================================================

  /// Search tournaments by name, game, or description
  Future<List<Map<String, dynamic>>> searchTournaments(String query,
      {int limit = 20, int offset = 0}) async {
    try {
      final response = await _client
          .from('tournaments')
          .select('''
            *,
            participants:tournament_participants(count)
          ''')
          .or('name.ilike.%$query%,game.ilike.%$query%,description.ilike.%$query%')
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((tournament) => {
                'id': tournament['id'],
                'name': tournament['name'],
                'game': tournament['game'],
                'description': tournament['description'],
                'start_date': tournament['start_date'],
                'end_date': tournament['end_date'],
                'status': tournament['status'],
                'prize_pool': tournament['prize_pool'],
                'max_participants': tournament['max_participants'],
                'participants_count':
                    tournament['participants'][0]['count'] ?? 0,
                'type': 'tournament',
              })
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search tournaments', e);
      return [];
    }
  }

  /// Search tournaments by game
  Future<List<Map<String, dynamic>>> searchTournamentsByGame(String game,
      {int limit = 20}) async {
    try {
      final response = await _client
          .from('tournaments')
          .select('''
            *,
            participants:tournament_participants(count)
          ''')
          .eq('game', game)
          .eq('is_public', true)
          .order('start_date', ascending: true)
          .limit(limit);

      return (response as List)
          .map((tournament) => {
                'id': tournament['id'],
                'name': tournament['name'],
                'game': tournament['game'],
                'description': tournament['description'],
                'start_date': tournament['start_date'],
                'end_date': tournament['end_date'],
                'status': tournament['status'],
                'prize_pool': tournament['prize_pool'],
                'max_participants': tournament['max_participants'],
                'participants_count':
                    tournament['participants'][0]['count'] ?? 0,
                'type': 'tournament',
              })
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search tournaments by game', e);
      return [];
    }
  }

  /// Search tournaments by status
  Future<List<Map<String, dynamic>>> searchTournamentsByStatus(String status,
      {int limit = 20}) async {
    try {
      final response = await _client
          .from('tournaments')
          .select('''
            *,
            participants:tournament_participants(count)
          ''')
          .eq('status', status)
          .eq('is_public', true)
          .order('start_date', ascending: true)
          .limit(limit);

      return (response as List)
          .map((tournament) => {
                'id': tournament['id'],
                'name': tournament['name'],
                'game': tournament['game'],
                'description': tournament['description'],
                'start_date': tournament['start_date'],
                'end_date': tournament['end_date'],
                'status': tournament['status'],
                'prize_pool': tournament['prize_pool'],
                'max_participants': tournament['max_participants'],
                'participants_count':
                    tournament['participants'][0]['count'] ?? 0,
                'type': 'tournament',
              })
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search tournaments by status', e);
      return [];
    }
  }

  // =====================================================
  // GAME SEARCH
  // =====================================================

  /// Search games by name, genre, or platform
  Future<List<Map<String, dynamic>>> searchGames(String query,
      {int limit = 20, int offset = 0}) async {
    try {
      final response = await _client
          .from('games')
          .select('*')
          .or('name.ilike.%$query%,genre.ilike.%$query%,platform.ilike.%$query%')
          .order('popularity_score', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((game) => {
                'id': game['id'],
                'name': game['name'],
                'genre': game['genre'],
                'platforms': game['platforms'] ?? [],
                'description': game['description'],
                'release_date': game['release_date'],
                'popularity_score': game['popularity_score'],
                'type': 'game',
              })
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search games', e);
      return [];
    }
  }

  /// Search games by genre
  Future<List<Map<String, dynamic>>> searchGamesByGenre(String genre,
      {int limit = 20}) async {
    try {
      final response = await _client
          .from('games')
          .select('*')
          .eq('genre', genre)
          .order('popularity_score', ascending: false)
          .limit(limit);

      return (response as List)
          .map((game) => {
                'id': game['id'],
                'name': game['name'],
                'genre': game['genre'],
                'platforms': game['platforms'] ?? [],
                'description': game['description'],
                'release_date': game['release_date'],
                'popularity_score': game['popularity_score'],
                'type': 'game',
              })
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search games by genre', e);
      return [];
    }
  }

  /// Search games by platform
  Future<List<Map<String, dynamic>>> searchGamesByPlatform(String platform,
      {int limit = 20}) async {
    try {
      final response = await _client
          .from('games')
          .select('*')
          .contains('platforms', [platform])
          .order('popularity_score', ascending: false)
          .limit(limit);

      return (response as List)
          .map((game) => {
                'id': game['id'],
                'name': game['name'],
                'genre': game['genre'],
                'platforms': game['platforms'] ?? [],
                'description': game['description'],
                'release_date': game['release_date'],
                'popularity_score': game['popularity_score'],
                'type': 'game',
              })
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search games by platform', e);
      return [];
    }
  }

  // =====================================================
  // SEARCH SUGGESTIONS
  // =====================================================

  /// Get search suggestions based on query
  Future<List<String>> getSearchSuggestions(String query,
      {int limit = 10}) async {
    try {
      final suggestions = <String>{};

      // Get user suggestions
      final userSuggestions = await _client
          .from('profiles')
          .select('username, display_name')
          .or('username.ilike.$query%,display_name.ilike.$query%')
          .eq('is_public', true)
          .limit(limit);

      for (final user in userSuggestions) {
        suggestions.add(user['username']);
        if (user['display_name'] != null) {
          suggestions.add(user['display_name']);
        }
      }

      // Get game suggestions
      final gameSuggestions = await _client
          .from('games')
          .select('name')
          .ilike('name', '$query%')
          .limit(limit);

      for (final game in gameSuggestions) {
        suggestions.add(game['name']);
      }

      // Get tournament suggestions
      final tournamentSuggestions = await _client
          .from('tournaments')
          .select('name')
          .ilike('name', '$query%')
          .eq('is_public', true)
          .limit(limit);

      for (final tournament in tournamentSuggestions) {
        suggestions.add(tournament['name']);
      }

      return suggestions.take(limit).toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get search suggestions', e);
      return [];
    }
  }

  // =====================================================
  // SEARCH HISTORY
  // =====================================================

  /// Save search query to history
  Future<bool> saveSearchQuery(String query) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      await _client.from('search_history').insert({
        'user_id': currentUser.id,
        'query': query,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to save search query', e);
      return false;
    }
  }

  /// Get user's search history
  Future<List<String>> getSearchHistory({int limit = 20}) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return [];

      final response = await _client
          .from('search_history')
          .select('query')
          .eq('user_id', currentUser.id)
          .order('timestamp', ascending: false)
          .limit(limit);

      return (response as List).map((item) => item['query'] as String).toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get search history', e);
      return [];
    }
  }

  /// Clear search history
  Future<bool> clearSearchHistory() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      await _client
          .from('search_history')
          .delete()
          .eq('user_id', currentUser.id);

      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to clear search history', e);
      return false;
    }
  }

  // =====================================================
  // TRENDING SEARCHES
  // =====================================================

  /// Get trending search terms
  Future<List<Map<String, dynamic>>> getTrendingSearches(
      {int limit = 10}) async {
    try {
      final response = await _client
          .rpc('get_trending_searches', params: {'limit_param': limit});

      return (response as List)
          .map((item) => {
                'query': item['query'],
                'count': item['count'],
                'trend': item['trend'],
              })
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get trending searches', e);
      return [];
    }
  }

  /// Get popular searches by category
  Future<Map<String, List<String>>> getPopularSearchesByCategory() async {
    try {
      final results = <String, List<String>>{};

      // Popular games
      final popularGames = await _client
          .from('games')
          .select('name')
          .order('popularity_score', ascending: false)
          .limit(10);

      results['games'] =
          (popularGames as List).map((game) => game['name'] as String).toList();

      // Popular tournaments
      final popularTournaments = await _client
          .from('tournaments')
          .select('name')
          .eq('is_public', true)
          .order('participants', ascending: false)
          .limit(10);

      results['tournaments'] = (popularTournaments as List)
          .map((tournament) => tournament['name'] as String)
          .toList();

      return results;
    } catch (e) {
      ErrorHandler.logError('Failed to get popular searches by category', e);
      return {};
    }
  }
}
