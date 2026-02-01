import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TournamentParticipateTab extends StatefulWidget {
  final Map<String, dynamic> tournament;
  final VoidCallback? onUpdated;

  const TournamentParticipateTab({
    super.key,
    required this.tournament,
    this.onUpdated,
  });

  @override
  _TournamentParticipateTabState createState() =>
      _TournamentParticipateTabState();
}

class _TournamentParticipateTabState extends State<TournamentParticipateTab> {
  bool _isLoading = false;
  bool _isJoined = false;
  Map<String, dynamic>? _userParticipation;

  @override
  void initState() {
    super.initState();
    _checkParticipationStatus();
  }

  Future<void> _checkParticipationStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final participants =
        widget.tournament['participants'] as List<dynamic>? ?? [];
    final userParticipant = participants.firstWhere(
      (p) => p['user_id'] == user.id,
      orElse: () => null,
    );

    setState(() {
      _isJoined = userParticipant != null;
      _userParticipation = userParticipant;
    });
  }

  Future<void> _joinTournament() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to join the tournament')),
      );
      return;
    }

    if (widget.tournament['type'] == 'solo') {
      _showSoloJoinDialog();
    } else {
      _showTeamJoinDialog();
    }
  }

  void _showSoloJoinDialog() {
    final formKey = GlobalKey<FormState>();
    String inGameName = '';
    String inGameId = '';
    String teamName = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Solo Tournament'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'In-game Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your in-game name';
                  }
                  return null;
                },
                onSaved: (value) => inGameName = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'In-game ID',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your in-game ID';
                  }
                  return null;
                },
                onSaved: (value) => inGameId = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Team Name (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Leave empty for auto-generated name',
                ),
                onSaved: (value) => teamName = value ?? '',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.of(context).pop();
                await _processSoloJoin(inGameName, inGameId, teamName);
              }
            },
            child: const Text('Join Tournament'),
          ),
        ],
      ),
    );
  }

  void _showTeamJoinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Team Tournament'),
        content: const Text(
          'Team tournaments require you to be part of a team. '
          'You can either create a new team or join an existing one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showCreateTeamDialog();
            },
            child: const Text('Create Team'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showJoinTeamDialog();
            },
            child: const Text('Join Team'),
          ),
        ],
      ),
    );
  }

  void _showCreateTeamDialog() {
    final formKey = GlobalKey<FormState>();
    String teamName = '';
    String teamImageUrl = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Team'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a team name';
                  }
                  return null;
                },
                onSaved: (value) => teamName = value ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Team Image URL (Optional)',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => teamImageUrl = value ?? '',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                Navigator.of(context).pop();
                await _createTeamAndJoin(teamName, teamImageUrl);
              }
            },
            child: const Text('Create & Join'),
          ),
        ],
      ),
    );
  }

  void _showJoinTeamDialog() {
    // This would show a list of available teams
    // For now, show a placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Existing Team'),
        content: const Text('Team selection feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _processSoloJoin(
      String inGameName, String inGameId, String teamName) async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get member role
      final roles = widget.tournament['roles'] as List<dynamic>? ?? [];
      final memberRole = roles.firstWhere(
        (r) => r['name'] == 'Member',
        orElse: () => null,
      );

      if (memberRole == null) {
        throw Exception('Member role not found');
      }

      // Join tournament
      await Supabase.instance.client.from('tournament_participants').insert({
        'tournament_id': widget.tournament['id'],
        'user_id': user.id,
        'role_id': memberRole['id'],
        'in_game_name': inGameName,
        'in_game_id': inGameId,
        'team_name':
            teamName.isNotEmpty ? teamName : 'Team_${user.id.substring(0, 8)}',
        'joined_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined tournament!')),
        );
        await _checkParticipationStatus();
        widget.onUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining tournament: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createTeamAndJoin(String teamName, String teamImageUrl) async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create team
      final teamResult = await Supabase.instance.client
          .from('teams')
          .insert({
            'name': teamName,
            'image_url': teamImageUrl.isNotEmpty ? teamImageUrl : null,
            'created_by': user.id,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Add user as team leader
      await Supabase.instance.client.from('team_members').insert({
        'team_id': teamResult['id'],
        'user_id': user.id,
        'role': 'leader',
        'joined_at': DateTime.now().toIso8601String(),
      });

      // Get member role
      final roles = widget.tournament['roles'] as List<dynamic>? ?? [];
      final memberRole = roles.firstWhere(
        (r) => r['name'] == 'Member',
        orElse: () => null,
      );

      if (memberRole == null) {
        throw Exception('Member role not found');
      }

      // Join tournament with team
      await Supabase.instance.client.from('tournament_participants').insert({
        'tournament_id': widget.tournament['id'],
        'user_id': user.id,
        'role_id': memberRole['id'],
        'team_id': teamResult['id'],
        'team_name': teamName,
        'joined_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team created and joined tournament!')),
        );
        await _checkParticipationStatus();
        widget.onUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating team: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _leaveTournament() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Tournament'),
        content: const Text('Are you sure you want to leave this tournament?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await Supabase.instance.client
          .from('tournament_participants')
          .delete()
          .eq('tournament_id', widget.tournament['id'])
          .eq('user_id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left tournament successfully')),
        );
        await _checkParticipationStatus();
        widget.onUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error leaving tournament: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final participants =
        widget.tournament['participants'] as List<dynamic>? ?? [];
    final maxParticipants = widget.tournament['max_participants'] as int? ?? 0;
    final isFull = participants.length >= maxParticipants;
    final remainingSpots = maxParticipants - participants.length;

    // Check if we're on mobile
    final isMobile = MediaQuery.of(context).size.width < 600;
    final cardPadding = isMobile ? 16.0 : 20.0;
    final horizontalPadding = isMobile ? 12.0 : 16.0;

    // Safety check for valid data
    if (widget.tournament.isEmpty) {
      return const Center(
        child: Text('Tournament data not available'),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tournament Registration Status Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(cardPadding),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.person_add,
                        color: Colors.blue,
                        size: isMobile ? 18 : 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tournament Registration',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isMobile ? 16 : 20),

                // Status Cards - Stack vertically on mobile
                if (isMobile)
                  Column(
                    children: [
                      _buildStatusCard(
                        icon: Icons.people,
                        value:
                            '${participants.length}/${maxParticipants > 0 ? maxParticipants : 0}',
                        label: 'Registered',
                        color: Colors.blue,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 12),
                      _buildStatusCard(
                        icon: Icons.access_time,
                        value: '3d 12h',
                        label: 'Time Left',
                        color: Colors.orange,
                        isMobile: isMobile,
                      ),
                      const SizedBox(height: 12),
                      _buildStatusCard(
                        icon: Icons.emoji_events,
                        value: '₹24',
                        label: 'Prize Pool',
                        color: Colors.amber,
                        isMobile: isMobile,
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      // Registration Status Card
                      Expanded(
                        child: _buildStatusCard(
                          icon: Icons.people,
                          value:
                              '${participants.length}/${maxParticipants > 0 ? maxParticipants : 0}',
                          label: 'Registered',
                          color: Colors.blue,
                          isMobile: isMobile,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Time Remaining Card
                      Expanded(
                        child: _buildStatusCard(
                          icon: Icons.access_time,
                          value: '3d 12h',
                          label: 'Time Left',
                          color: Colors.orange,
                          isMobile: isMobile,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Prize Pool Card
                      Expanded(
                        child: _buildStatusCard(
                          icon: Icons.emoji_events,
                          value: '₹24',
                          label: 'Prize Pool',
                          color: Colors.amber,
                          isMobile: isMobile,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 16 : 20),

          // Join Tournament Form Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(cardPadding),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_note,
                        color: Colors.green,
                        size: isMobile ? 18 : 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Join Tournament',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Fill out the form below to register for ${widget.tournament['name']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 20),

                // Join/Leave Button
                Center(
                  child: _isJoined
                      ? Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    'You are registered!',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.shade400,
                                    Colors.red.shade600
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _leaveTournament,
                                icon: const Icon(Icons.exit_to_app),
                                label: const Text('Leave Tournament'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: isFull
                                  ? [Colors.grey.shade400, Colors.grey.shade600]
                                  : [
                                      Colors.blue.shade400,
                                      Colors.blue.shade600
                                    ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isFull
                                    ? Colors.grey.withOpacity(0.3)
                                    : Colors.blue.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed:
                                _isLoading || isFull ? null : _joinTournament,
                            icon: const Icon(Icons.person_add),
                            label: Text(isFull
                                ? 'Tournament Full'
                                : 'Register for Tournament'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                ),

                if (!_isJoined && !isFull) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Click the button above to join this tournament. You\'ll need to provide your in-game details.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: isMobile ? 16 : 20),

          // Registered Participants Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(cardPadding),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.people,
                        color: Colors.purple,
                        size: isMobile ? 18 : 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Registered Participants',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (participants.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No participants yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be among the first to register!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      ...participants.take(3).map((participant) {
                        final profile = participant['profile'];
                        final role = participant['role'];
                        final joinedAt = participant['joined_at'] != null
                            ? DateTime.parse(participant['joined_at'])
                            : null;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: profile?['avatar_url'] != null
                                    ? NetworkImage(profile['avatar_url'])
                                    : null,
                                backgroundColor: Colors.blue.shade100,
                                child: profile?['avatar_url'] == null
                                    ? Text(
                                        profile?['username']?[0]
                                                .toUpperCase() ??
                                            'U',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile?['username'] ?? 'Unknown User',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (joinedAt != null)
                                      Text(
                                        '${_getRegionText()} • Registered ${_getTimeAgo(joinedAt)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (role != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getRoleColor(role['name'])
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _getRoleColor(role['name'])
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    role['name'],
                                    style: TextStyle(
                                      color: _getRoleColor(role['name']),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Text(
                                    'Confirmed',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                      if (participants.length > 3)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.people,
                                color: Colors.blue.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '$remainingSpots more spots available',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                              Text(
                                'Be among the first to register!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String value,
    required String label,
    required MaterialColor color,
    required bool isMobile,
  }) {
    // Safety check for valid parameters
    final safeValue = value.isNotEmpty ? value : '0';
    final safeLabel = label.isNotEmpty ? label : 'Unknown';
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.shade50,
            color.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color.shade700,
                size: isMobile ? 18 : 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  safeValue,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: color.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            safeLabel,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: color.shade600,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
          if (label == 'Registered') ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                2,
                (index) => Container(
                  width: isMobile ? 6 : 8,
                  height: isMobile ? 6 : 8,
                  margin: EdgeInsets.symmetric(horizontal: isMobile ? 1 : 2),
                  decoration: BoxDecoration(
                    color: color.shade400,
                    borderRadius: BorderRadius.circular(isMobile ? 3 : 4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getRegionText() {
    // This could be dynamic based on user location
    return 'North India';
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Color _getRoleColor(String roleName) {
    switch (roleName.toLowerCase()) {
      case 'owner':
        return Colors.red;
      case 'moderator':
        return Colors.orange;
      case 'member':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
