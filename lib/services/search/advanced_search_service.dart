import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/utils/error_handler.dart';
import 'package:gamer_flick/models/ui/search_result.dart';

class AdvancedSearchService {
  static final AdvancedSearchService _instance =
      AdvancedSearchService._internal();
  factory AdvancedSearchService() => _instance;
  AdvancedSearchService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// Advanced search with comprehensive filtering
  Future<Map<String, List<SearchResult>>> advancedSearch({
    required String query,
    List<String>? contentTypes,
    Map<String, dynamic>? filters,
    String? sortBy,
    String? sortOrder,
    int limit = 20,
    int offset = 0,
    String? userId,
  }) async {
    try {
      final results = <String, List<SearchResult>>{};
      final types = contentTypes ??
          ['users', 'posts', 'tournaments', 'communities', 'games', 'reels'];

      for (final type in types) {
        switch (type) {
          case 'users':
            results['users'] = await _searchUsers(
              query,
              filters: filters?['users'],
              sortBy: sortBy,
              sortOrder: sortOrder,
              limit: limit,
              offset: offset,
            );
            break;
          case 'posts':
            results['posts'] = await _searchPosts(
              query,
              filters: filters?['posts'],
              sortBy: sortBy,
              sortOrder: sortOrder,
              limit: limit,
              offset: offset,
              userId: userId,
            );
            break;
          case 'tournaments':
            results['tournaments'] = await _searchTournaments(
              query,
              filters: filters?['tournaments'],
              sortBy: sortBy,
              sortOrder: sortOrder,
              limit: limit,
              offset: offset,
            );
            break;
          case 'communities':
            results['communities'] = await _searchCommunities(
              query,
              filters: filters?['communities'],
              sortBy: sortBy,
              sortOrder: sortOrder,
              limit: limit,
              offset: offset,
            );
            break;
          case 'games':
            results['games'] = await _searchGames(
              query,
              filters: filters?['games'],
              sortBy: sortBy,
              sortOrder: sortOrder,
              limit: limit,
              offset: offset,
            );
            break;
          case 'reels':
            results['reels'] = await _searchReels(
              query,
              filters: filters?['reels'],
              sortBy: sortBy,
              sortOrder: sortOrder,
              limit: limit,
              offset: offset,
              userId: userId,
            );
            break;
        }
      }

      return results;
    } catch (e) {
      ErrorHandler.logError('Failed to perform advanced search', e);
      return {};
    }
  }

  /// Search users with advanced filters
  Future<List<SearchResult>> _searchUsers(
    String query, {
    Map<String, dynamic>? filters,
    String? sortBy,
    String? sortOrder,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      dynamic request = _client.from('profiles').select('''
            id,
            username,
            display_name,
            bio,
            avatar_url,
            location,
            favorite_games,
            followers_count,
            following_count,
            created_at
          ''');

      // Apply search query
      if (query.isNotEmpty) {
        request = request.or(
            'username.ilike.%$query%,display_name.ilike.%$query%,bio.ilike.%$query%');
      }

      // Apply filters
      if (filters != null) {
        if (filters['location'] != null) {
          request = request.ilike('location', '%${filters['location']}%');
        }
        if (filters['game'] != null) {
          request = request.contains('favorite_games', [filters['game']]);
        }
        if (filters['minFollowers'] != null) {
          request = request.gte('followers_count', filters['minFollowers']);
        }
        if (filters['maxFollowers'] != null) {
          request = request.lte('followers_count', filters['maxFollowers']);
        }
        if (filters['isVerified'] != null) {
          request = request.eq('is_verified', filters['isVerified']);
        }
      }

      // Apply sorting
      if (sortBy != null) {
        final order = sortOrder == 'desc' ? false : true;
        request = request.order(sortBy, ascending: order);
      } else {
        request = request.order('created_at', ascending: false);
      }

      final response = await request.range(offset, offset + limit - 1);

      return (response as List)
          .map((user) => SearchResult(
                id: user['id'],
                type: SearchResultType.user,
                title: user['display_name'] ?? user['username'],
                subtitle: user['bio'] ?? '',
                imageUrl: user['avatar_url'],
                originalObject: user,
              ))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search users', e);
      return [];
    }
  }

  /// Search posts with advanced filters
  Future<List<SearchResult>> _searchPosts(
    String query, {
    Map<String, dynamic>? filters,
    String? sortBy,
    String? sortOrder,
    int limit = 20,
    int offset = 0,
    String? userId,
  }) async {
    try {
      dynamic request = _client.from('posts').select('''
            id,
            content,
            media_urls,
            created_at,
            likes_count,
            comments_count,
            game_category,
            tags,
            profiles!posts_user_id_fkey(username, display_name, avatar_url)
          ''');

      // Apply search query
      if (query.isNotEmpty) {
        request = request
            .or('content.ilike.%$query%,tags.cs.{${query.toLowerCase()}}');
      }

      // Apply filters
      if (filters != null) {
        if (filters['gameCategory'] != null) {
          request = request.eq('game_category', filters['gameCategory']);
        }
        if (filters['hasMedia'] != null) {
          // Apply media filter after the select
          final response = await request;
          final allPosts = (response as List).cast<Map<String, dynamic>>();
          final filteredPosts = allPosts.where((post) {
            if (filters['hasMedia']) {
              return post['media_urls'] != null &&
                  (post['media_urls'] as List).isNotEmpty;
            } else {
              return post['media_urls'] == null ||
                  (post['media_urls'] as List).isEmpty;
            }
          }).toList();

          return filteredPosts
              .map((post) => SearchResult(
                    id: post['id'],
                    type: SearchResultType.post,
                    title: post['profiles']['display_name'] ??
                        post['profiles']['username'],
                    subtitle: post['content'] ?? '',
                    imageUrl: post['media_urls']?.isNotEmpty == true
                        ? post['media_urls'][0]
                        : null,
                    originalObject: post,
                  ))
              .toList();
        }
        if (filters['minLikes'] != null) {
          request = request.gte('likes_count', filters['minLikes']);
        }
        if (filters['dateRange'] != null) {
          final startDate = filters['dateRange']['start'];
          final endDate = filters['dateRange']['end'];
          if (startDate != null) {
            request = request.gte('created_at', startDate);
          }
          if (endDate != null) {
            request = request.lte('created_at', endDate);
          }
        }
        if (filters['tags'] != null) {
          request = request.contains('tags', filters['tags']);
        }
      }

      // Apply sorting
      if (sortBy != null) {
        final order = sortOrder == 'desc' ? false : true;
        request = request.order(sortBy, ascending: order);
      } else {
        request = request.order('created_at', ascending: false);
      }

      final response = await request.range(offset, offset + limit - 1);

      return (response as List)
          .map((post) => SearchResult(
                id: post['id'],
                type: SearchResultType.post,
                title: post['profiles']['display_name'] ??
                    post['profiles']['username'],
                subtitle: post['content'] ?? '',
                imageUrl: post['media_urls']?.isNotEmpty == true
                    ? post['media_urls'][0]
                    : null,
                originalObject: post,
              ))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search posts', e);
      return [];
    }
  }

  /// Search tournaments with advanced filters
  Future<List<SearchResult>> _searchTournaments(
    String query, {
    Map<String, dynamic>? filters,
    String? sortBy,
    String? sortOrder,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      dynamic request = _client.from('tournaments').select('''
            id,
            name,
            description,
            game_category,
            status,
            prize_pool,
            max_participants,
            current_participants,
            start_date,
            end_date,
            entry_fee,
            created_at
          ''');

      // Apply search query
      if (query.isNotEmpty) {
        request = request.or(
            'name.ilike.%$query%,description.ilike.%$query%,game_category.ilike.%$query%');
      }

      // Apply filters
      if (filters != null) {
        if (filters['status'] != null) {
          request = request.eq('status', filters['status']);
        }
        if (filters['gameCategory'] != null) {
          request = request.eq('game_category', filters['gameCategory']);
        }
        if (filters['minPrizePool'] != null) {
          request = request.gte('prize_pool', filters['minPrizePool']);
        }
        if (filters['maxPrizePool'] != null) {
          request = request.lte('prize_pool', filters['maxPrizePool']);
        }
        if (filters['entryFee'] != null) {
          request = request.eq('entry_fee', filters['entryFee']);
        }
        if (filters['dateRange'] != null) {
          final startDate = filters['dateRange']['start'];
          final endDate = filters['dateRange']['end'];
          if (startDate != null) {
            request = request.gte('start_date', startDate);
          }
          if (endDate != null) {
            request = request.lte('end_date', endDate);
          }
        }
      }

      // Apply sorting
      if (sortBy != null) {
        final order = sortOrder == 'desc' ? false : true;
        request = request.order(sortBy, ascending: order);
      } else {
        request = request.order('created_at', ascending: false);
      }

      final response = await request.range(offset, offset + limit - 1);

      return (response as List)
          .map((tournament) => SearchResult(
                id: tournament['id'],
                type: SearchResultType.tournament,
                title: tournament['name'],
                subtitle: tournament['description'] ?? '',
                imageUrl: null, // Tournaments don't have images in this model
                originalObject: tournament,
              ))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search tournaments', e);
      return [];
    }
  }

  /// Search communities with advanced filters
  Future<List<SearchResult>> _searchCommunities(
    String query, {
    Map<String, dynamic>? filters,
    String? sortBy,
    String? sortOrder,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      dynamic request = _client.from('communities').select('''
            id,
            name,
            description,
            game_category,
            member_count,
            is_private,
            tags,
            created_at
          ''');

      // Apply search query
      if (query.isNotEmpty) {
        request = request.or(
            'name.ilike.%$query%,description.ilike.%$query%,game_category.ilike.%$query%');
      }

      // Apply filters
      if (filters != null) {
        if (filters['gameCategory'] != null) {
          request = request.eq('game_category', filters['gameCategory']);
        }
        if (filters['isPrivate'] != null) {
          request = request.eq('is_private', filters['isPrivate']);
        }
        if (filters['minMembers'] != null) {
          request = request.gte('member_count', filters['minMembers']);
        }
        if (filters['maxMembers'] != null) {
          request = request.lte('member_count', filters['maxMembers']);
        }
        if (filters['tags'] != null) {
          request = request.contains('tags', filters['tags']);
        }
      }

      // Apply sorting
      if (sortBy != null) {
        final order = sortOrder == 'desc' ? false : true;
        request = request.order(sortBy, ascending: order);
      } else {
        request = request.order('member_count', ascending: false);
      }

      final response = await request.range(offset, offset + limit - 1);

      return (response as List)
          .map((community) => SearchResult(
                id: community['id'],
                type: SearchResultType.community,
                title: community['name'],
                subtitle: community['description'] ?? '',
                imageUrl: null, // Communities don't have images in this model
                originalObject: community,
              ))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search communities', e);
      return [];
    }
  }

  /// Search games with advanced filters
  Future<List<SearchResult>> _searchGames(
    String query, {
    Map<String, dynamic>? filters,
    String? sortBy,
    String? sortOrder,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      dynamic request = _client.from('games').select('''
            id,
            name,
            description,
            category,
            platform,
            release_date,
            rating,
            player_count,
            created_at
          ''');

      // Apply search query
      if (query.isNotEmpty) {
        request = request.or(
            'name.ilike.%$query%,description.ilike.%$query%,category.ilike.%$query%');
      }

      // Apply filters
      if (filters != null) {
        if (filters['category'] != null) {
          request = request.eq('category', filters['category']);
        }
        if (filters['platform'] != null) {
          request = request.eq('platform', filters['platform']);
        }
        if (filters['minRating'] != null) {
          request = request.gte('rating', filters['minRating']);
        }
        if (filters['maxRating'] != null) {
          request = request.lte('rating', filters['maxRating']);
        }
        if (filters['playerCount'] != null) {
          request = request.eq('player_count', filters['playerCount']);
        }
      }

      // Apply sorting
      if (sortBy != null) {
        final order = sortOrder == 'desc' ? false : true;
        request = request.order(sortBy, ascending: order);
      } else {
        request = request.order('rating', ascending: false);
      }

      final response = await request.range(offset, offset + limit - 1);

      return (response as List)
          .map((game) => SearchResult(
                id: game['id'],
                type: SearchResultType.game,
                title: game['name'],
                subtitle: game['description'] ?? '',
                imageUrl: null, // Games don't have images in this model
                originalObject: game,
              ))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search games', e);
      return [];
    }
  }

  /// Search reels with advanced filters
  Future<List<SearchResult>> _searchReels(
    String query, {
    Map<String, dynamic>? filters,
    String? sortBy,
    String? sortOrder,
    int limit = 20,
    int offset = 0,
    String? userId,
  }) async {
    try {
      dynamic request = _client.from('reels').select('''
            id,
            title,
            description,
            media_url,
            duration,
            likes_count,
            comments_count,
            game_category,
            tags,
            created_at,
            profiles!reels_user_id_fkey(username, display_name, avatar_url)
          ''');

      // Apply search query
      if (query.isNotEmpty) {
        request = request.or(
            'title.ilike.%$query%,description.ilike.%$query%,tags.cs.{${query.toLowerCase()}}');
      }

      // Apply filters
      if (filters != null) {
        if (filters['gameCategory'] != null) {
          request = request.eq('game_category', filters['gameCategory']);
        }
        if (filters['minDuration'] != null) {
          request = request.gte('duration', filters['minDuration']);
        }
        if (filters['maxDuration'] != null) {
          request = request.lte('duration', filters['maxDuration']);
        }
        if (filters['minLikes'] != null) {
          request = request.gte('likes_count', filters['minLikes']);
        }
        if (filters['tags'] != null) {
          request = request.contains('tags', filters['tags']);
        }
      }

      // Apply sorting
      if (sortBy != null) {
        final order = sortOrder == 'desc' ? false : true;
        request = request.order(sortBy, ascending: order);
      } else {
        request = request.order('created_at', ascending: false);
      }

      final response = await request.range(offset, offset + limit - 1);

      return (response as List)
          .map((reel) => SearchResult(
                id: reel['id'],
                type: SearchResultType.reel,
                title: reel['title'] ??
                    reel['profiles']['display_name'] ??
                    reel['profiles']['username'],
                subtitle: reel['description'] ?? '',
                imageUrl: reel['media_url'],
                originalObject: reel,
              ))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search reels', e);
      return [];
    }
  }

  /// Get search suggestions based on query
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final suggestions = <String>{};

      // Get user suggestions
      final userResponse = await _client
          .from('profiles')
          .select('username, display_name')
          .or('username.ilike.%$query%,display_name.ilike.%$query%')
          .limit(5);

      for (final user in userResponse) {
        suggestions.add(user['username']);
        if (user['display_name'] != null) {
          suggestions.add(user['display_name']);
        }
      }

      // Get game suggestions
      final gameResponse = await _client
          .from('games')
          .select('name')
          .ilike('name', '%$query%')
          .limit(5);

      for (final game in gameResponse) {
        suggestions.add(game['name']);
      }

      // Get tournament suggestions
      final tournamentResponse = await _client
          .from('tournaments')
          .select('name')
          .ilike('name', '%$query%')
          .limit(5);

      for (final tournament in tournamentResponse) {
        suggestions.add(tournament['name']);
      }

      return suggestions.toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get search suggestions', e);
      return [];
    }
  }

  /// Get trending search terms
  Future<List<String>> getTrendingSearches() async {
    try {
      // This would typically come from analytics data
      // For now, return some common gaming terms
      return [
        'Fortnite',
        'Call of Duty',
        'League of Legends',
        'Valorant',
        'Minecraft',
        'PUBG',
        'Apex Legends',
        'CS:GO',
        'Dota 2',
        'Overwatch',
      ];
    } catch (e) {
      ErrorHandler.logError('Failed to get trending searches', e);
      return [];
    }
  }
}
