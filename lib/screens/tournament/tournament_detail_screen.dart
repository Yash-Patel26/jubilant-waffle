import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tournament_info_tab.dart';
import 'tournament_participate_tab.dart';
import 'tournament_chat_tab.dart';
import 'tournament_media_tab.dart';
import 'tournament_bracket_tab.dart';
import 'tournament_edit_screen.dart';
import 'tournament_roles_tab.dart';
import 'package:gamer_flick/services/tournament/tournament_service.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;

  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  _TournamentDetailScreenState createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _tournament;
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  Map<String, dynamic>? _currentUserRole;

  @override
  void initState() {
    super.initState();
    // Initialize with a safe default; we'll adjust after fetching details
    _tabController = TabController(length: 5, vsync: this);
    _fetchTournamentDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTournamentDetails() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final data = await Supabase.instance.client.from('tournaments').select('''
            *,
            creator:profiles!tournaments_created_by_fkey(username, avatar_url),
            participants:tournament_participants(
              *,
              profile:profiles(*)
            ),
            roles:tournament_roles(*)
          ''').eq('id', widget.tournamentId).single();

      // Find current user's role
      final roles = data['roles'] as List<dynamic>? ?? [];
      final currentUserRole = roles.firstWhere(
        (r) => r['user_id'] == user.id,
        orElse: () => null,
      );

      if (currentUserRole != null) {
        _currentUserRole = currentUserRole;
      }

      // Adjust TabController length based on ownership (Roles tab only for owner)
      final bool isOwnerLocal = (_currentUserRole != null &&
          (_currentUserRole!['role'] as String?) == 'owner');
      final int newLength = isOwnerLocal ? 6 : 5;
      if (_tabController.length != newLength) {
        final int currentIndex = _tabController.index;
        _tabController.dispose();
        _tabController = TabController(
          length: newLength,
          vsync: this,
          initialIndex: currentIndex.clamp(0, newLength - 1),
        );
      }

      setState(() {
        _tournament = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  bool get _isOwnerOrModerator {
    if (_currentUserRole == null) return false;
    final roleName = _currentUserRole!['role'] as String?;
    return roleName == 'owner' || roleName == 'moderator';
  }

  bool get _isOwner {
    if (_currentUserRole == null) return false;
    final roleName = _currentUserRole!['role'] as String?;
    return roleName == 'owner';
  }

  Future<void> _deleteTournament() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tournament'),
        content: const Text(
          'Are you sure you want to delete this tournament? This action cannot be undone and will permanently remove all tournament data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      await TournamentService().deleteTournament(widget.tournamentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tournament deleted successfully'),
            backgroundColor: theme.colorScheme.secondary,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate deletion
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Center(
              child: Column(
                children: [
                  Icon(Icons.error_outline,
                      color: theme.colorScheme.error, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Cannot Delete Tournament',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            content: Text(
              e.toString().replaceFirst('Exception:', '').trim(),
              style: TextStyle(color: theme.colorScheme.error, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Tournament'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Tournament Link'),
              subtitle: const Text('Copy link to clipboard'),
              onTap: () {
                Navigator.pop(context);
                _copyTournamentLink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share via Other Apps'),
              subtitle: const Text('Share using system share'),
              onTap: () {
                Navigator.pop(context);
                _shareTournament();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() {
    if (!_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only tournament owners can edit tournaments'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentEditScreen(
          tournament: _tournament!,
          onUpdated: _fetchTournamentDetails,
        ),
      ),
    );
  }

  void _copyTournamentLink() {
    final tournamentUrl =
        'https://gamerflick.app/tournaments/${widget.tournamentId}';
    Clipboard.setData(ClipboardData(text: tournamentUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tournament link copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareTournament() {
    final tournamentName = _tournament?['name'] ?? 'Tournament';
    final game = _tournament?['game'] ?? 'Game';
    final shareText =
        'Check out this $game tournament: $tournamentName\n\nJoin now at: https://gamerflick.app/tournaments/${widget.tournamentId}';

    // Copy to clipboard instead of sharing
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tournament details copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error: $_error',
                style: TextStyle(color: theme.colorScheme.error)),
          ),
        ),
      );
    }

    if (_tournament == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
            child: Text('Tournament not found.',
                style: TextStyle(color: theme.textTheme.bodyLarge?.color))),
      );
    }

    return DefaultTabController(
      length: _isOwner ? 6 : 5,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(
              220), // Increased height for better mobile visibility
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8), // Reduced vertical padding
                  color: Theme.of(context).cardColor,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tournament!['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 26),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _tournament!['type'] == 'solo'
                                            ? theme.colorScheme.primary
                                                .withOpacity(0.1)
                                            : theme.colorScheme.secondary
                                                .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        (_tournament!['type'] ?? '')
                                            .toString()
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color: _tournament!['type'] == 'solo'
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.secondary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Game: ${_tournament!['game'] ?? 'Unknown'}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.black54),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!isMobile) ...[
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.share),
                              tooltip: 'Share',
                              onPressed: _showShareDialog,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Edit',
                              onPressed: _showEditDialog,
                            ),
                            if (_isOwner)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.error,
                                  foregroundColor: theme.colorScheme.onError,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.delete),
                                label: const Text('Delete Tournament'),
                                onPressed:
                                    _isLoading ? null : _deleteTournament,
                              ),
                          ],
                        ],
                      ),
                      if (isMobile)
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.share),
                              tooltip: 'Share',
                              onPressed: _showShareDialog,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Edit',
                              onPressed: _showEditDialog,
                            ),
                            if (_isOwner)
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.colorScheme.error,
                                  foregroundColor: theme.colorScheme.onError,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.delete),
                                label: const Text('Delete'),
                                onPressed:
                                    _isLoading ? null : _deleteTournament,
                              ),
                          ],
                        ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            labelStyle: TextStyle(
                              fontSize: isMobile ? 15 : 12,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                            unselectedLabelStyle: TextStyle(
                              fontSize: isMobile ? 15 : 12,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 8 : 8,
                              vertical: isMobile ? 6 : 0,
                            ),
                            indicatorColor: theme.colorScheme.primary,
                            tabs: [
                              Tab(
                                icon:
                                    Icon(Icons.info, size: isMobile ? 20 : 18),
                                text: 'Info',
                              ),
                              Tab(
                                icon: Icon(Icons.person_add,
                                    size: isMobile ? 20 : 18),
                                text: 'Participate',
                              ),
                              Tab(
                                icon:
                                    Icon(Icons.chat, size: isMobile ? 20 : 18),
                                text: 'Chat',
                              ),
                              Tab(
                                icon: Icon(Icons.photo_library,
                                    size: isMobile ? 20 : 18),
                                text: 'Media',
                              ),
                              Tab(
                                icon: Icon(Icons.account_tree,
                                    size: isMobile ? 20 : 18),
                                text: 'Bracket',
                              ),
                              if (_isOwner)
                                Tab(
                                  icon: Icon(Icons.admin_panel_settings,
                                      size: isMobile ? 20 : 18),
                                  text: 'Roles',
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            TournamentInfoTab(
              tournament: _tournament!,
              isOwnerOrMod: _isOwnerOrModerator,
              onUpdated: _fetchTournamentDetails,
            ),
            TournamentParticipateTab(
              tournament: _tournament!,
              onUpdated: _fetchTournamentDetails,
            ),
            TournamentChatTab(
              tournamentId: widget.tournamentId,
              currentUserRole: _currentUserRole,
            ),
            TournamentMediaTab(
              tournamentId: widget.tournamentId,
              currentUserRole: _currentUserRole,
            ),
            TournamentBracketTab(
              tournament: _tournament!,
              isOwnerOrMod: _isOwnerOrModerator,
            ),
            if (_isOwner)
              TournamentRolesTab(
                tournamentId: widget.tournamentId,
                isOwner: _isOwner,
                tournament: _tournament!,
              ),
          ],
        ),
      ),
    );
  }
}
