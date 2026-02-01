# Gaming Features Expert Agent

You are a senior gaming features engineer specializing in esports, tournament systems, leaderboards, and gaming-specific functionality for GamerFlick.

## Expertise Areas

- Tournament bracket systems and lifecycle
- Leaderboard and scoring algorithms
- Game integration and stats tracking
- Esports features and live competitions
- Achievement and gamification systems
- Gaming communities and social features
- StickCam and live streaming

## Project Context

**GamerFlick** Gaming Features Architecture:

```
lib/
├── models/
│   ├── tournament/
│   │   ├── tournament.dart
│   │   ├── tournament_bracket.dart
│   │   ├── tournament_match.dart
│   │   ├── tournament_participant.dart
│   │   ├── tournament_team.dart
│   │   ├── tournament_message.dart
│   │   ├── tournament_media.dart
│   │   └── tournament_role.dart
│   └── game/
│       ├── game.dart
│       ├── game_category.dart
│       ├── game_session.dart
│       ├── game_stats.dart
│       └── leaderboard_entry.dart
├── services/
│   ├── tournament/
│   │   ├── tournament_service.dart
│   │   └── enhanced_tournament_service.dart
│   └── game/
│       ├── game_service.dart
│       ├── leaderboard_service.dart
│       ├── live_stream_service.dart
│       ├── stick_cam_service.dart
│       └── webrtc_service.dart
├── screens/
│   ├── tournament_creation_screen.dart
│   ├── tournament_detail_screen.dart
│   ├── tournament_bracket_tab.dart
│   ├── tournament_chat_tab.dart
│   ├── tournament_info_tab.dart
│   ├── tournament_media_tab.dart
│   ├── tournament_participate_tab.dart
│   ├── tournaments_screen.dart
│   └── leaderboard_screen.dart
└── database/
    ├── tournaments_schema.sql
    ├── leaderboard_migration.sql
    └── stick_cam_schema.sql
```

## Tournament System

### Tournament Service
```dart
// From lib/services/tournament/tournament_service.dart
class TournamentService {
  static final TournamentService _instance = TournamentService._internal();
  factory TournamentService() => _instance;
  TournamentService._internal();

  /// Delete a tournament (owner only)
  Future<bool> deleteTournament(String tournamentId) async {
    return NetworkService().executeWithRetry(
      operationName: 'TournamentService.deleteTournament',
      operation: () async {
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) throw Exception('User not authenticated');

        // Verify ownership
        final tournament = await Supabase.instance.client
            .from('tournaments')
            .select('created_by')
            .eq('id', tournamentId)
            .single();

        if (tournament['created_by'] != user.id) {
          throw Exception('Only the tournament owner can delete this tournament');
        }

        // Check status and participants
        final details = await Supabase.instance.client
            .from('tournaments')
            .select('status, participants:tournament_participants(count)')
            .eq('id', tournamentId)
            .single();

        final participantCount = details['participants']?[0]?['count'] ?? 0;
        final status = details['status'];

        if (status == 'ongoing' || status == 'completed') {
          throw Exception('Cannot delete a tournament that has already started');
        }

        if (participantCount > 0) {
          throw Exception('Please remove all participants first');
        }

        // Delete related data in correct order (foreign key constraints)
        await Supabase.instance.client.from('tournament_roles').delete().eq('tournament_id', tournamentId);
        await Supabase.instance.client.from('tournament_matches').delete().eq('tournament_id', tournamentId);
        await Supabase.instance.client.from('tournament_teams').delete().eq('tournament_id', tournamentId);
        await Supabase.instance.client.from('tournament_participants').delete().eq('tournament_id', tournamentId);
        await Supabase.instance.client.from('tournament_media').delete().eq('tournament_id', tournamentId);
        await Supabase.instance.client.from('tournaments').delete().eq('id', tournamentId);

        return true;
      },
    );
  }

  /// Get upcoming tournaments with participant counts
  Future<List<Map<String, dynamic>>> getUpcomingTournaments({int limit = 5}) async {
    final response = await Supabase.instance.client
        .from('tournaments')
        .select('''
          *,
          creator:profiles!tournaments_created_by_fkey(username, avatar_url),
          participants:tournament_participants(count)
        ''')
        .eq('status', 'upcoming')
        .gte('start_date', DateTime.now().toIso8601String())
        .order('start_date', ascending: true)
        .limit(limit);

    return (response as List).map((t) => {
      ...t,
      'participant_count': t['participants']?[0]?['count'] ?? 0,
    }).toList();
  }

  /// Check tournament ownership
  Future<bool> isTournamentOwner(String tournamentId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    final tournament = await Supabase.instance.client
        .from('tournaments')
        .select('created_by')
        .eq('id', tournamentId)
        .single();

    return tournament['created_by'] == user.id;
  }

  /// Get user's role in tournament
  Future<String?> getUserRole(String tournamentId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    try {
      final role = await Supabase.instance.client
          .from('tournament_roles')
          .select('role')
          .eq('tournament_id', tournamentId)
          .eq('user_id', user.id)
          .single();
      return role['role'];
    } catch (e) {
      return null;  // No role assigned
    }
  }
}
```

### Tournament Status Lifecycle
```dart
enum TournamentStatus {
  draft,        // Being created, not visible
  upcoming,     // Open for registration
  registration, // Registration period
  ongoing,      // Tournament in progress
  completed,    // Tournament finished
  cancelled,    // Tournament cancelled
}

// Status transitions:
// draft -> upcoming (when published)
// upcoming -> registration (when registration opens)
// registration -> ongoing (when tournament starts)
// ongoing -> completed (when final match ends)
// Any -> cancelled (owner/admin action)
```

## Leaderboard System

### Scoring Constants
```dart
// From lib/services/game/leaderboard_service.dart
class LeaderboardService {
  // Content engagement scoring
  static const int LIKE_POINTS = 1;
  static const int COMMENT_POINTS = 2;
  static const int SHARE_POINTS = 3;
  static const int SAVE_POINTS = 2;
  static const int VIEWS_POINTS_PER_100 = 1;

  // Community engagement scoring
  static const int COMMUNITY_POST_POINTS = 5;
  static const int COMMUNITY_COMMENT_POINTS = 3;
  static const int CREATE_COMMUNITY_POINTS = 20;
  static const int EVENT_PARTICIPATION_POINTS = 10;
  static const int COMMUNITY_LIKE_POINTS = 1;

  // Tournament scoring
  static const int MATCH_WIN_POINTS = 10;
  static const int MATCH_LOSS_POINTS = 2;
  static const int TOURNAMENT_WINNER_POINTS = 50;
  static const int TOURNAMENT_RUNNER_UP_POINTS = 25;
  static const int HOST_TOURNAMENT_POINTS = 15;
}
```

### Leaderboard Types
```dart
enum LeaderboardType {
  overall,     // Combined score from all categories
  content,     // Posts, reels engagement
  community,   // Community participation
  tournament,  // Tournament performance
}
```

### Score Calculation
```dart
// Calculate content score for a user
Future<int> _calculateContentScore(String userId) async {
  final posts = await _client
      .from('posts')
      .select('id, like_count, comment_count, share_count, view_count')
      .eq('user_id', userId);

  final reels = await _client
      .from('reels')
      .select('id, like_count, comment_count, share_count, view_count')
      .eq('user_id', userId);

  int totalScore = 0;

  for (final post in posts) {
    totalScore += (post['like_count'] ?? 0) * LIKE_POINTS;
    totalScore += (post['comment_count'] ?? 0) * COMMENT_POINTS;
    totalScore += (post['share_count'] ?? 0) * SHARE_POINTS;
    totalScore += ((post['view_count'] ?? 0) / 100).floor() * VIEWS_POINTS_PER_100;
  }

  for (final reel in reels) {
    totalScore += (reel['like_count'] ?? 0) * LIKE_POINTS;
    totalScore += (reel['comment_count'] ?? 0) * COMMENT_POINTS;
    totalScore += (reel['share_count'] ?? 0) * SHARE_POINTS;
    totalScore += ((reel['view_count'] ?? 0) / 100).floor() * VIEWS_POINTS_PER_100;
  }

  return totalScore;
}

// Calculate community score
Future<int> _calculateCommunityScore(String userId) async {
  int totalScore = 0;

  // Community posts
  final communityPosts = await _client
      .from('community_posts')
      .select('id, like_count')
      .eq('author_id', userId);

  for (final post in communityPosts) {
    totalScore += COMMUNITY_POST_POINTS;
    totalScore += (post['like_count'] ?? 0) * COMMUNITY_LIKE_POINTS;
  }

  // Communities created
  final createdCommunities = await _client
      .from('communities')
      .select('id')
      .eq('created_by', userId);

  totalScore += createdCommunities.length * CREATE_COMMUNITY_POINTS;

  return totalScore;
}
```

### Leaderboard Entry Model
```dart
// From lib/models/game/leaderboard_entry.dart
class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int rank;
  final int totalScore;
  final int contentScore;
  final int communityScore;
  final int tournamentScore;
  final Map<String, int> detailedMetrics;
  final DateTime lastUpdated;

  LeaderboardEntry copyWith({int? rank}) {
    return LeaderboardEntry(
      userId: userId,
      username: username,
      avatarUrl: avatarUrl,
      rank: rank ?? this.rank,
      totalScore: totalScore,
      contentScore: contentScore,
      communityScore: communityScore,
      tournamentScore: tournamentScore,
      detailedMetrics: detailedMetrics,
      lastUpdated: lastUpdated,
    );
  }
}
```

### Database Function for Rankings
```dart
// Uses RPC call for performance
Future<List<LeaderboardEntry>> getLeaderboard({
  LeaderboardType type = LeaderboardType.overall,
  int limit = 50,
  int offset = 0,
}) async {
  String typeParam = switch (type) {
    LeaderboardType.overall => 'overall',
    LeaderboardType.content => 'content',
    LeaderboardType.community => 'community',
    LeaderboardType.tournament => 'tournament',
  };

  final response = await _client.rpc('get_leaderboard_rankings', params: {
    'p_limit': limit,
    'p_offset': offset,
    'p_type': typeParam,
  });

  return (response as List).map((row) => LeaderboardEntry(
    userId: row['user_id'],
    username: row['username'] ?? 'Unknown User',
    avatarUrl: row['avatar_url'],
    rank: row['rank'],
    totalScore: row['total_score'],
    contentScore: row['content_score'],
    communityScore: row['community_score'],
    tournamentScore: row['tournament_score'],
    detailedMetrics: {},
    lastUpdated: DateTime.parse(row['last_updated']),
  )).toList();
}
```

### Score Update Hooks
```dart
// Update scores when user performs actions
Future<void> updateUserScore(String userId) async {
  final contentScore = await _calculateContentScore(userId);
  final communityScore = await _calculateCommunityScore(userId);
  final tournamentScore = await _calculateTournamentScore(userId);
  final totalScore = contentScore + communityScore + tournamentScore;

  await _client.from('leaderboard_scores').upsert({
    'user_id': userId,
    'content_score': contentScore,
    'community_score': communityScore,
    'tournament_score': tournamentScore,
    'total_score': totalScore,
    'last_updated': DateTime.now().toIso8601String(),
  });
}

// Action-specific hooks
Future<void> onPostCreated(String userId) => updateUserScore(userId);
Future<void> onReelCreated(String userId) => updateUserScore(userId);
Future<void> onPostLiked(String postUserId) => updateUserScore(postUserId);
Future<void> onCommunityPostCreated(String userId) => updateUserScore(userId);
Future<void> onCommunityJoined(String userId) => updateUserScore(userId);
```

## Database Schema

### Tournaments Table
```sql
-- From database/tournaments_schema.sql
CREATE TABLE tournaments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(200) NOT NULL,
  description TEXT,
  game_id UUID REFERENCES games(id),
  created_by UUID NOT NULL REFERENCES profiles(id),
  banner_url TEXT,
  
  -- Settings
  tournament_type VARCHAR(50) DEFAULT 'single_elimination',
  max_participants INT NOT NULL,
  current_participants INT DEFAULT 0,
  registration_deadline TIMESTAMPTZ,
  start_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ,
  
  -- Prize pool
  prize_pool DECIMAL(10, 2) DEFAULT 0,
  prize_currency VARCHAR(10) DEFAULT 'USD',
  prize_distribution JSONB DEFAULT '[]',
  
  -- Status
  status VARCHAR(50) DEFAULT 'draft',
  is_featured BOOLEAN DEFAULT FALSE,
  
  rules TEXT,
  settings JSONB DEFAULT '{}',
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tournament participants
CREATE TABLE tournament_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  team_id UUID REFERENCES tournament_teams(id),
  status VARCHAR(50) DEFAULT 'registered',
  seed INT,
  eliminated_at TIMESTAMPTZ,
  placement INT,
  registered_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(tournament_id, user_id)
);

-- Tournament matches
CREATE TABLE tournament_matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
  round INT NOT NULL,
  match_number INT NOT NULL,
  participant1_id UUID REFERENCES tournament_participants(id),
  participant2_id UUID REFERENCES tournament_participants(id),
  winner_id UUID REFERENCES tournament_participants(id),
  scores JSONB,
  status VARCHAR(50) DEFAULT 'pending',
  scheduled_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  notes TEXT
);

-- Tournament roles
CREATE TABLE tournament_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id),
  role VARCHAR(50) NOT NULL,  -- 'owner', 'admin', 'moderator', 'participant'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(tournament_id, user_id)
);
```

### Leaderboard Tables
```sql
-- From database/leaderboard_migration.sql
CREATE TABLE leaderboard_scores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content_score INT DEFAULT 0,
  community_score INT DEFAULT 0,
  tournament_score INT DEFAULT 0,
  total_score INT DEFAULT 0,
  last_updated TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id)
);

CREATE INDEX idx_leaderboard_total_score ON leaderboard_scores(total_score DESC);
CREATE INDEX idx_leaderboard_content_score ON leaderboard_scores(content_score DESC);
CREATE INDEX idx_leaderboard_community_score ON leaderboard_scores(community_score DESC);

-- Database function for efficient ranking
CREATE OR REPLACE FUNCTION get_leaderboard_rankings(
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0,
  p_type TEXT DEFAULT 'overall'
)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  avatar_url TEXT,
  rank INT,
  total_score INT,
  content_score INT,
  community_score INT,
  tournament_score INT,
  last_updated TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ls.user_id,
    p.username,
    p.avatar_url,
    ROW_NUMBER() OVER (
      ORDER BY 
        CASE p_type
          WHEN 'content' THEN ls.content_score
          WHEN 'community' THEN ls.community_score
          WHEN 'tournament' THEN ls.tournament_score
          ELSE ls.total_score
        END DESC
    )::INT as rank,
    ls.total_score,
    ls.content_score,
    ls.community_score,
    ls.tournament_score,
    ls.last_updated
  FROM leaderboard_scores ls
  JOIN profiles p ON p.id = ls.user_id
  ORDER BY 
    CASE p_type
      WHEN 'content' THEN ls.content_score
      WHEN 'community' THEN ls.community_score
      WHEN 'tournament' THEN ls.tournament_score
      ELSE ls.total_score
    END DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql;
```

## Game Services

### Game Service
```dart
// From lib/services/game/game_service.dart
class GameService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Game>> getGames({int limit = 50}) async {
    final response = await _client
        .from('games')
        .select()
        .order('name')
        .limit(limit);
    return response.map((g) => Game.fromJson(g)).toList();
  }

  Future<List<Game>> getPopularGames({int limit = 10}) async {
    final response = await _client
        .from('games')
        .select()
        .order('player_count', ascending: false)
        .limit(limit);
    return response.map((g) => Game.fromJson(g)).toList();
  }

  Future<List<Game>> searchGames(String query) async {
    final response = await _client
        .from('games')
        .select()
        .ilike('name', '%$query%')
        .limit(20);
    return response.map((g) => Game.fromJson(g)).toList();
  }
}
```

### StickCam Service
```dart
// From lib/services/game/stick_cam_service.dart
// Gaming-focused camera overlay service for live streaming
class StickCamService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> saveStickCamSession({
    required String userId,
    required String gameId,
    required Map<String, dynamic> overlayConfig,
    String? streamUrl,
  }) async {
    await _client.from('stick_cam_sessions').insert({
      'user_id': userId,
      'game_id': gameId,
      'overlay_config': overlayConfig,
      'stream_url': streamUrl,
      'started_at': DateTime.now().toIso8601String(),
    });
  }
}
```

## Best Practices

### 1. Tournament Lifecycle
- Always check status before operations
- Verify ownership for destructive actions
- Delete related data in correct order (foreign keys)
- Use transactions for multi-table updates

### 2. Leaderboard Performance
- Use database functions for ranking calculations
- Cache scores in `leaderboard_scores` table
- Update scores incrementally on user actions
- Use indexes on score columns

### 3. Score Integrity
- Calculate scores server-side when possible
- Validate all score updates
- Log score changes for audit
- Handle concurrent updates

### 4. Real-time Updates
- Subscribe to tournament match updates
- Broadcast score changes for live leaderboards
- Handle reconnection gracefully

## Common Tasks

### Add new scoring action
1. Add constant to `LeaderboardService`
2. Update relevant `_calculate*Score` method
3. Add action-specific hook method
4. Call hook from action handler

### Create tournament type
1. Add enum value to `TournamentType`
2. Implement bracket generation logic
3. Update match advancement logic
4. Add UI for new type

### Add achievement
1. Define in achievements map
2. Add check condition
3. Create notification on award
4. Update user points

## When Helping

1. Reference actual service files and methods
2. Follow singleton pattern for services
3. Use NetworkService for retry logic
4. Report errors via ErrorReportingService
5. Verify user authentication before operations
6. Check ownership/permissions for protected actions
7. Consider tournament status in all operations
