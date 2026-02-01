import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TournamentBracketTab extends StatefulWidget {
  final Map<String, dynamic> tournament;
  final bool isOwnerOrMod;

  const TournamentBracketTab({
    super.key,
    required this.tournament,
    required this.isOwnerOrMod,
  });

  @override
  _TournamentBracketTabState createState() => _TournamentBracketTabState();
}

class _TournamentBracketTabState extends State<TournamentBracketTab> {
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    try {
      final isSolo = widget.tournament['type'] == 'solo';

      // Use a simpler query first to check if there are any matches
      final countResponse = await Supabase.instance.client
          .from('tournament_matches')
          .select('id')
          .eq('tournament_id', widget.tournament['id']);

      if (countResponse.isEmpty) {
        // No matches exist yet, set empty list
        setState(() {
          _matches = [];
          _isLoading = false;
        });
        return;
      }

      // If matches exist, fetch them with proper joins
      final selectQuery = isSolo
          ? '''
            *,
            participant_a:tournament_participants!tournament_matches_participant_a_id_fkey(
              *,
              profile:profiles(username)
            ),
            participant_b:tournament_participants!tournament_matches_participant_b_id_fkey(
              *,
              profile:profiles(username)
            )
          '''
          : '''
            *,
            team_a:tournament_teams!tournament_matches_team_a_id_fkey(*),
            team_b:tournament_teams!tournament_matches_team_b_id_fkey(*)
          ''';

      final response = await Supabase.instance.client
          .from('tournament_matches')
          .select(selectQuery)
          .eq('tournament_id', widget.tournament['id'])
          .order('round_number', ascending: true)
          .order('match_number', ascending: true);

      setState(() {
        _matches = (response as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching tournament matches: $e');
      setState(() {
        _error = 'Unable to load tournament bracket. Please try again later.';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateBracket() async {
    if (!widget.isOwnerOrMod) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Only tournament owners can generate brackets')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Bracket'),
        content: const Text(
          'This will create a tournament bracket based on current participants. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final participants =
          widget.tournament['participants'] as List<dynamic>? ?? [];
      if (participants.length < 2) {
        throw Exception('Need at least 2 participants to generate bracket');
      }

      // Generate matches based on tournament type and participant count
      final matches = _generateMatches(participants);

      // Insert matches into database
      for (final match in matches) {
        await Supabase.instance.client.from('tournament_matches').insert(match);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bracket generated successfully!')),
        );
        _fetchMatches();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating bracket: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> _generateMatches(List<dynamic> participants) {
    final matches = <Map<String, dynamic>>[];
    final shuffledParticipants = List.from(participants)..shuffle();
    final isSolo = widget.tournament['type'] == 'solo';

    // Ensure even number of participants/teams
    if (shuffledParticipants.length % 2 != 0) {
      // Add a bye participant/team
      shuffledParticipants.add({
        'id': null,
        'profile': {'username': 'BYE'},
        'is_bye': true,
      });
    }

    final rounds = (shuffledParticipants.length / 2).ceil();

    for (int round = 1; round <= rounds; round++) {
      final matchesInRound = shuffledParticipants.length ~/ 2;

      for (int match = 1; match <= matchesInRound; match++) {
        final index1 = (match - 1) * 2;
        final index2 = index1 + 1;

        if (index2 < shuffledParticipants.length) {
          if (isSolo) {
            matches.add({
              'tournament_id': widget.tournament['id'],
              'round_number': round,
              'match_number': match,
              'participant_a_id': shuffledParticipants[index1]['id'],
              'participant_b_id': shuffledParticipants[index2]['id'],
              'status': 'scheduled',
              'created_at': DateTime.now().toIso8601String(),
            });
          } else {
            matches.add({
              'tournament_id': widget.tournament['id'],
              'round_number': round,
              'match_number': match,
              'team1_id': shuffledParticipants[index1]['id'],
              'team2_id': shuffledParticipants[index2]['id'],
              'status': 'scheduled',
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }
      }
      // Prepare for next round (winners advance) - simplified
    }
    return matches;
  }

  Future<void> _updateMatchResult(Map<String, dynamic> match) async {
    final winner = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Match Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Who won this match?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(match['participant_a_id']),
                  child: Text(match['participant_a']?['profile']?['username'] ??
                      'Player A'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.of(context).pop(match['participant_b_id']),
                  child: Text(match['participant_b']?['profile']?['username'] ??
                      'Player B'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (winner == null) return;

    try {
      await Supabase.instance.client.from('tournament_matches').update({
        'winner_id': winner,
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', match['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Match result updated!')),
        );
        _fetchMatches();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating match: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Container(
        color: const Color(0xFFF5F5F5),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Unable to Load Bracket',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'There was an issue loading the tournament bracket. This might be due to database configuration.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade500, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _fetchMatches,
                    icon: const Icon(
                      Icons.refresh,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Generate Bracket button (responsive, avoids overflow)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'Tournament Bracket',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              if (widget.isOwnerOrMod && _matches.isEmpty)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ElevatedButton.icon(
                    onPressed: _generateBracket,
                    icon: const Icon(Icons.account_tree),
                    label: const Text('Generate Bracket'),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Tournament Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tournament Type: ${widget.tournament['type'] == 'solo' ? 'Solo' : 'Team'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Participants: ${(widget.tournament['participants'] as List).length}/${widget.tournament['max_participants']}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Status: ${widget.tournament['status'] ?? 'Unknown'}',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Bracket Display
          if (_matches.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_tree, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No bracket generated yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Generate a bracket to start the tournament!',
                    style: TextStyle(color: Colors.grey),
                  ),
                  if (widget.isOwnerOrMod) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _generateBracket,
                      icon: const Icon(Icons.account_tree),
                      label: const Text('Generate Bracket'),
                    ),
                  ],
                ],
              ),
            )
          else
            _buildBracketView(),
        ],
      ),
    );
  }

  Widget _buildBracketView() {
    // Group matches by round
    final rounds = <int, List<Map<String, dynamic>>>{};
    for (final match in _matches) {
      final round = match['round_number'] as int? ?? 1;
      rounds.putIfAbsent(round, () => []).add(match);
    }

    final sortedRounds = rounds.keys.toList()..sort();

    return Column(
      children: sortedRounds.map((round) {
        final roundMatches = rounds[round]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Round $round',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            ...roundMatches.map((match) => _buildMatchCard(match)),
            const SizedBox(height: 24),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final participantA = match['participant_a'];
    final participantB = match['participant_b'];
    final winner = match['winner'];
    final status = match['status'] as String? ?? 'scheduled';
    final isCompleted = status == 'completed';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildParticipantTile(
                    participantA,
                    isWinner:
                        winner != null && winner['id'] == participantA?['id'],
                    isBye: participantA?['is_bye'] == true,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'vs',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildParticipantTile(
                    participantB,
                    isWinner:
                        winner != null && winner['id'] == participantB?['id'],
                    isBye: participantB?['is_bye'] == true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (widget.isOwnerOrMod && !isCompleted && !_hasBye(match))
                  ElevatedButton(
                    onPressed: () => _updateMatchResult(match),
                    child: const Text('Update Result'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantTile(
    Map<String, dynamic>? participant, {
    required bool isWinner,
    required bool isBye,
  }) {
    final username = participant?['profile']?['username'] ?? 'TBD';
    final isByeMatch = isBye;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isWinner
            ? Colors.green.withOpacity(0.1)
            : isByeMatch
                ? Colors.grey.withOpacity(0.1)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isWinner
            ? Border.all(color: Colors.green)
            : isByeMatch
                ? Border.all(color: Colors.grey)
                : null,
      ),
      child: Row(
        children: [
          if (isWinner)
            const Icon(Icons.emoji_events, color: Colors.green, size: 16),
          if (isByeMatch) const Icon(Icons.block, color: Colors.grey, size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              isByeMatch ? 'BYE' : username,
              style: TextStyle(
                fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                color: isByeMatch ? Colors.grey : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  bool _hasBye(Map<String, dynamic> match) {
    return match['participant_a']?['is_bye'] == true ||
        match['participant_b']?['is_bye'] == true;
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
