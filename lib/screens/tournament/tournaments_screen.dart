import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tournament_detail_screen.dart';
import 'tournament_creation_screen.dart';
import '../../widgets/home/tournament_card.dart';
import 'package:gamer_flick/models/tournament/tournament.dart';
// import '../../utils/time_utils.dart';

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  _TournamentsScreenState createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _tournaments = [];
  List<Map<String, dynamic>> _filteredTournaments = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'all';
  late TabController _tabController;

  final List<String> _filters = [
    'all',
    'solo',
    'team',
    'ongoing',
    'upcoming',
    'completed'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchTournaments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchTournaments() async {
    try {
      final response =
          await Supabase.instance.client.from('tournaments').select('''
            *,
            creator:profiles!tournaments_created_by_fkey(username, avatar_url),
            participants:tournament_participants(count),
            matches:tournament_matches(count)
          ''').order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _tournaments = (response as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_tournaments);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((tournament) {
        final name = tournament['name']?.toString().toLowerCase() ?? '';
        final game = tournament['game']?.toString().toLowerCase() ?? '';
        final creator =
            tournament['creator']?['username']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();

        return name.contains(query) ||
            game.contains(query) ||
            creator.contains(query);
      }).toList();
    }

    // Apply type/status filter
    switch (_selectedFilter) {
      case 'solo':
        filtered = filtered.where((t) => t['type'] == 'solo').toList();
        break;
      case 'team':
        filtered = filtered.where((t) => t['type'] == 'team').toList();
        break;
      case 'ongoing':
        filtered = filtered.where((t) => _isTournamentOngoing(t)).toList();
        break;
      case 'upcoming':
        filtered = filtered.where((t) => _isTournamentUpcoming(t)).toList();
        break;
      case 'completed':
        filtered = filtered.where((t) => _isTournamentCompleted(t)).toList();
        break;
    }

    setState(() {
      _filteredTournaments = filtered;
    });
  }

  bool _isTournamentOngoing(Map<String, dynamic> tournament) {
    final startDate = DateTime.tryParse(tournament['start_date'] ?? '');
    final endDate = DateTime.tryParse(tournament['end_date'] ?? '');
    final now = DateTime.now();

    if (startDate == null) return false;

    if (endDate != null) {
      return now.isAfter(startDate) && now.isBefore(endDate);
    }

    // If no end date, consider ongoing for 24 hours after start
    return now.isAfter(startDate) &&
        now.isBefore(startDate.add(const Duration(days: 1)));
  }

  bool _isTournamentUpcoming(Map<String, dynamic> tournament) {
    final startDate = DateTime.tryParse(tournament['start_date'] ?? '');
    if (startDate == null) return false;
    return DateTime.now().isBefore(startDate);
  }

  bool _isTournamentCompleted(Map<String, dynamic> tournament) {
    final endDate = DateTime.tryParse(tournament['end_date'] ?? '');
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate);
  }

  // Removed unused status helpers to satisfy linter

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final titleColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
        theme.textTheme.bodyMedium?.color?.withOpacity(0.5);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 139, 139, 139),
        elevation: 0,
        toolbarHeight: isMobile ? 64 : 100,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tournaments',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 20 : 32,
                color: titleColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Discover and join competitive gaming tournaments',
              style:
                  TextStyle(fontSize: isMobile ? 12 : 16, color: subtitleColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 24, top: 16),
            child: isMobile
                ? IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TournamentCreationScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    color: theme.colorScheme.primary,
                    tooltip: 'Create Tournament',
                  )
                : ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => TournamentCreationScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('+ Create Tournament',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimary)),
                  ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Search, filter, sort bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: LayoutBuilder(builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 480;
                  final input = Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                        _applyFilters();
                      },
                      style: TextStyle(fontSize: narrow ? 14 : 16),
                      decoration: InputDecoration(
                        hintText: 'Search tournaments, games, or organizers...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(
                            Theme.of(context).brightness == Brightness.dark
                                ? 0.3
                                : 1.0),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 12),
                      ),
                    ),
                  );

                  final sort = DropdownButton<String>(
                    value: 'Date',
                    items: const [
                      DropdownMenuItem(value: 'Date', child: Text('Date')),
                      DropdownMenuItem(value: 'Prize', child: Text('Prize')),
                      DropdownMenuItem(
                          value: 'Participants', child: Text('Participants')),
                    ],
                    onChanged: (value) {},
                  );

                  final filterBtn = IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () {},
                  );

                  if (narrow) {
                    return Column(
                      children: [
                        Row(children: [input]),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [sort, const SizedBox(width: 4), filterBtn],
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        input,
                        const SizedBox(width: 12),
                        sort,
                        const SizedBox(width: 8),
                        filterBtn
                      ],
                    );
                  }
                }),
              ),
              const SizedBox(height: 16),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(filter.toUpperCase()),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilter = filter;
                          });
                          _applyFilters();
                        },
                        selectedColor: theme.colorScheme.primary,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              // Tournament cards grid
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('Error: $_error'))
                      : _filteredTournaments.isEmpty
                          ? const Center(child: Text('No tournaments found'))
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isMobile ? 2 : 3,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: isMobile ? 0.78 : 0.85,
                              ),
                              itemCount: _filteredTournaments.length,
                              itemBuilder: (context, index) {
                                final tournamentMap =
                                    _filteredTournaments[index];
                                final tournament =
                                    Tournament.fromMap(tournamentMap);
                                return TournamentCard(
                                  tournament: tournament,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TournamentDetailScreen(
                                          tournamentId: tournament.id,
                                        ),
                                      ),
                                    ).then((_) => _fetchTournaments());
                                  },
                                );
                              },
                            ),
            ],
          ),
        ),
      ),
    );
  }

  // Removed unused helpers
}
