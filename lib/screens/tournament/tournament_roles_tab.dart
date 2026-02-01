import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:gamer_flick/services/tournament/tournament_service.dart';

class TournamentRolesTab extends StatefulWidget {
  final String tournamentId;
  final bool isOwner;
  final Map<String, dynamic> tournament;

  const TournamentRolesTab({
    super.key,
    required this.tournamentId,
    required this.isOwner,
    required this.tournament,
  });

  @override
  State<TournamentRolesTab> createState() => _TournamentRolesTabState();
}

class _TournamentRolesTabState extends State<TournamentRolesTab> {
  List<Map<String, dynamic>> _staffMembers = [];
  List<Map<String, dynamic>> _participants = [];
  bool _isLoading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final supabase = Supabase.instance.client;

      // Fetch staff members (admins and moderators)
      final staffData = await supabase
          .from('tournament_roles')
          .select('*, profile:profiles!tournament_roles_user_id_fkey(*)')
          .eq('tournament_id', widget.tournamentId)
          .inFilter('role', ['admin', 'moderator']);

      // Fetch all participants
      final participantsData = await supabase
          .from('tournament_participants')
          .select('*, profile:profiles!tournament_participants_user_id_fkey(*)')
          .eq('tournament_id', widget.tournamentId);

      setState(() {
        _staffMembers = (staffData as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _participants = (participantsData as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _loadError = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _insertStaffRole({
    required String userId,
    required String role,
  }) async {
    final supabase = Supabase.instance.client;
    await supabase.from('tournament_roles').upsert({
      'tournament_id': widget.tournamentId,
      'user_id': userId,
      'role': role,
    });
  }

  Future<void> _removeStaffRole({
    required String userId,
  }) async {
    final supabase = Supabase.instance.client;
    await supabase
        .from('tournament_roles')
        .delete()
        .eq('tournament_id', widget.tournamentId)
        .eq('user_id', userId);
  }

  Future<void> _openAddStaffMemberDialog() async {
    // Build candidates list from participants not already staff
    final Set<String> staffUserIds = _staffMembers
        .map((m) => (m['user_id'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final List<Map<String, dynamic>> candidates = _participants
        .where(
            (p) => p['user_id'] != null && !staffUserIds.contains(p['user_id']))
        .toList();

    String? selectedUserId =
        candidates.isNotEmpty ? (candidates.first['user_id'] as String?) : null;
    String selectedRole = 'moderator';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Staff Member'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedUserId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Select Participant',
                    border: OutlineInputBorder(),
                  ),
                  items: candidates
                      .map((c) => DropdownMenuItem<String>(
                            value: c['user_id'] as String,
                            child: Text(
                              (c['profile']?['username'] ?? 'Unknown')
                                  as String,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (val) => selectedUserId = val,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(
                        value: 'moderator', child: Text('Moderator')),
                  ],
                  onChanged: (val) => selectedRole = val ?? 'moderator',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedUserId == null
                  ? null
                  : () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && selectedUserId != null) {
      try {
        await _insertStaffRole(userId: selectedUserId!, role: selectedRole);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff member added')),
          );
          await _fetchData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add staff: $e')),
          );
        }
      }
    }
  }

  Future<void> _promoteParticipant({
    required String userId,
    required String role,
  }) async {
    try {
      await _insertStaffRole(userId: userId, role: role);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Promoted to ${role[0].toUpperCase()}${role.substring(1)}')),
        );
        await _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to promote: $e')),
        );
      }
    }
  }

  Future<void> _removeParticipant(int participantId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Participant'),
        content: Text(
            'Are you sure you want to remove $username from the tournament?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await TournamentService()
          .removeParticipant(widget.tournamentId, participantId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Participant removed')),
        );
        await _fetchData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove participant: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're on mobile
    final isMobile = MediaQuery.of(context).size.width < 600;
    final cardPadding = isMobile ? 16.0 : 20.0;
    final horizontalPadding = isMobile ? 12.0 : 16.0;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Tournament Roles & Permissions Header
            Container(
              padding: EdgeInsets.all(cardPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.shield,
                      color: Colors.green.shade700,
                      size: isMobile ? 20 : 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tournament Roles & Permissions',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Manage tournament staff and participant permissions',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withOpacity(0.7) ??
                                Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Role Type Cards
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                children: [
                  _buildRoleTypeCard(
                    icon: Icons.admin_panel_settings,
                    title: 'Tournament Admin',
                    subtitle: 'Full control',
                    permissions: [
                      'Manage tournament settings',
                      'Control brackets & matches',
                      'Moderate chat & media',
                      'Assign roles'
                    ],
                    count:
                        _staffMembers.where((s) => s['role'] == 'admin').length,
                    color: Colors.red,
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 12),
                  _buildRoleTypeCard(
                    icon: Icons.settings,
                    title: 'Moderator',
                    subtitle: 'Limited control',
                    permissions: [
                      'Moderate chat messages',
                      'Review media uploads',
                      'Assist participants',
                      'Report issues'
                    ],
                    count: _staffMembers
                        .where((s) => s['role'] == 'moderator')
                        .length,
                    color: Colors.blue,
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 12),
                  _buildRoleTypeCard(
                    icon: Icons.person,
                    title: 'Participant',
                    subtitle: 'Player access',
                    permissions: [
                      'Join tournament matches',
                      'Chat with other players',
                      'Upload media content',
                      'View bracket & results'
                    ],
                    count: _participants.length,
                    color: Colors.green,
                    isMobile: isMobile,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tournament Staff Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Container(
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.05),
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
                        Text(
                          'Tournament Staff',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        if (widget.isOwner)
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade500,
                                  Colors.blue.shade600
                                ],
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
                              onPressed: _openAddStaffMemberDialog,
                              icon: Icon(
                                Icons.person_add,
                                size: isMobile ? 16 : 18,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Add Staff Member',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isMobile ? 12 : 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 12 : 16,
                                  vertical: isMobile ? 8 : 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_staffMembers.isNotEmpty) ...[
                      ..._staffMembers.map((staff) => _buildStaffMemberCard(
                            staff: staff,
                            isMobile: isMobile,
                            onRemove: widget.isOwner
                                ? () async {
                                    try {
                                      await _removeStaffRole(
                                          userId: staff['user_id'] as String);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content:
                                                  Text('Staff member removed')),
                                        );
                                        await _fetchData();
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content:
                                                  Text('Failed to remove: $e')),
                                        );
                                      }
                                    }
                                  }
                                : null,
                          )),
                    ] else ...[
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.settings,
                              size: isMobile ? 48 : 64,
                              color: Theme.of(context).dividerColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No additional staff members',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.7) ??
                                    Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add moderators to help manage the tournament',
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withOpacity(0.8) ??
                                    Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Registered Participants Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Container(
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registered Participants',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_participants.isNotEmpty) ...[
                      ..._participants
                          .map((participant) => _buildParticipantCard(
                                participant: participant,
                                isMobile: isMobile,
                              )),
                    ] else ...[
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: isMobile ? 48 : 64,
                              color: Theme.of(context).dividerColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No participants yet',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withOpacity(0.7) ??
                                    Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Participants will appear here once they join',
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color
                                        ?.withOpacity(0.8) ??
                                    Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: horizontalPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<String> permissions,
    required int count,
    required MaterialColor color,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
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
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: color.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color.shade700,
                  size: isMobile ? 20 : 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: color.shade800,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        color: color.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count ${title == 'Tournament Admin' ? 'Admin' : title == 'Moderator' ? 'Moderators' : 'Participants'}',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.bold,
                    color: color.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...permissions.map((permission) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: isMobile ? 14 : 16,
                      color: color.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        permission,
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          color: color.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildStaffMemberCard({
    required Map<String, dynamic> staff,
    required bool isMobile,
    VoidCallback? onRemove,
  }) {
    final profile = staff['profile'] ?? {};
    final role = staff['role'] ?? 'unknown';
    final roleColor = role == 'admin' ? Colors.red : Colors.blue;
    final roleLabel = role == 'admin' ? 'Admin' : 'Moderator';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isMobile ? 20 : 24,
            backgroundColor: roleColor.shade100,
            backgroundImage: profile['avatar_url'] != null
                ? NetworkImage(profile['avatar_url'])
                : null,
            child: profile['avatar_url'] == null
                ? Text(
                    (profile['username']?[0] ?? 'A').toUpperCase(),
                    style: TextStyle(
                      color: roleColor.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 16 : 18,
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
                  profile['username'] ?? 'Unknown User',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  profile['email'] ?? 'No email',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: Theme.of(context).textTheme.bodySmall?.color ??
                        Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: roleColor.shade200),
            ),
            child: Text(
              roleLabel,
              style: TextStyle(
                fontSize: isMobile ? 10 : 11,
                fontWeight: FontWeight.w500,
                color: roleColor.shade700,
              ),
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Remove Staff',
              onPressed: onRemove,
              icon:
                  Icon(Icons.remove_circle_outline, color: Colors.red.shade400),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParticipantCard({
    required Map<String, dynamic> participant,
    required bool isMobile,
  }) {
    final profile = participant['profile'] ?? {};
    final region = participant['region'] ?? 'Unknown Region';
    final joinedAt = participant['created_at'] != null
        ? DateFormat('MMM dd, HH:mm')
            .format(DateTime.parse(participant['created_at']))
        : 'Unknown';
    final String? userId = participant['user_id'] as String?;
    final String username = (profile['username'] ?? 'Unknown') as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isMobile ? 20 : 24,
            backgroundColor: Colors.green.shade100,
            backgroundImage: profile['avatar_url'] != null
                ? NetworkImage(profile['avatar_url'])
                : null,
            child: profile['avatar_url'] == null
                ? Text(
                    (profile['username']?[0] ?? 'P').toUpperCase(),
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 16 : 18,
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
                  profile['username'] ?? 'Unknown User',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  '$region • Registered $joinedAt',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: Theme.of(context).textTheme.bodySmall?.color ??
                        Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              'Participant',
              style: TextStyle(
                fontSize: isMobile ? 10 : 11,
                fontWeight: FontWeight.w500,
                color: Colors.green.shade700,
              ),
            ),
          ),
          if (widget.isOwner && userId != null) ...[
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              tooltip: 'Manage',
              onSelected: (value) async {
                if (value == 'promote_moderator') {
                  await _promoteParticipant(userId: userId, role: 'moderator');
                } else if (value == 'promote_admin') {
                  await _promoteParticipant(userId: userId, role: 'admin');
                } else if (value == 'remove') {
                  final dynamic idRaw = participant['id'];
                  final int? participantId = idRaw is int
                      ? idRaw
                      : int.tryParse(idRaw?.toString() ?? '');
                  if (participantId != null) {
                    await _removeParticipant(participantId, username);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Invalid participant identifier')),
                      );
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'promote_moderator',
                  child: Text('Promote to Moderator'),
                ),
                const PopupMenuItem(
                  value: 'promote_admin',
                  child: Text('Promote to Admin'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Remove from Tournament'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
