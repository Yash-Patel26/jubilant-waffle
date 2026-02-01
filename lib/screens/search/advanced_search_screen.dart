import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/models/ui/search_result.dart';
import '../../widgets/safe_scaffold.dart';
import 'package:gamer_flick/services/search/advanced_search_service.dart';

class AdvancedSearchScreen extends ConsumerStatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  ConsumerState<AdvancedSearchScreen> createState() =>
      _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends ConsumerState<AdvancedSearchScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final AdvancedSearchService _searchService = AdvancedSearchService();

  late TabController _tabController;
  Map<String, List<SearchResult>> _searchResults = {};
  List<String> _searchSuggestions = [];
  List<String> _trendingSearches = [];
  bool _isLoading = false;
  String _currentQuery = '';

  // Filter states
  List<String> _selectedContentTypes = [
    'users',
    'posts',
    'tournaments',
    'communities',
    'games',
    'reels'
  ];
  Map<String, dynamic> _filters = {};
  String _sortBy = 'created_at';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadTrendingSearches();
    _loadSearchSuggestions('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingSearches() async {
    try {
      final trending = await _searchService.getTrendingSearches();
      setState(() {
        _trendingSearches = trending;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadSearchSuggestions(String query) async {
    if (query.length < 2) return;

    try {
      final suggestions = await _searchService.getSearchSuggestions(query);
      setState(() {
        _searchSuggestions = suggestions;
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _performSearch() async {
    if (_currentQuery.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _searchService.advancedSearch(
        query: _currentQuery,
        contentTypes: _selectedContentTypes,
        filters: _filters,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        limit: 20,
        userId: 'current_user_id', // Replace with actual user ID
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: ${e.toString()}')),
        );
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _currentQuery = query;
    });

    if (query.length >= 2) {
      _loadSearchSuggestions(query);
    } else {
      setState(() {
        _searchSuggestions = [];
      });
    }
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      _performSearch();
    }
  }

  void _onFilterChanged() {
    if (_currentQuery.isNotEmpty) {
      _performSearch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      appBar: AppBar(
        title: const Text('Advanced Search'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildSuggestions(),
          _buildTrendingSearches(),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        onSubmitted: _onSearchSubmitted,
        decoration: InputDecoration(
          hintText: 'Search users, posts, tournaments, communities...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _currentQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _currentQuery = '';
                      _searchResults = {};
                      _searchSuggestions = [];
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[800]
              : Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_searchSuggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _searchSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _searchSuggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(suggestion),
              onPressed: () {
                _searchController.text = suggestion;
                _onSearchSubmitted(suggestion);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingSearches() {
    if (_currentQuery.isNotEmpty || _trendingSearches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trending Searches',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _trendingSearches.map((search) {
              return ActionChip(
                label: Text(search),
                onPressed: () {
                  _searchController.text = search;
                  _onSearchSubmitted(search);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty && _currentQuery.isNotEmpty) {
      return const Center(
        child: Text('No results found'),
      );
    }

    if (_searchResults.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildResultTabs(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildResultList('users'),
              _buildResultList('posts'),
              _buildResultList('tournaments'),
              _buildResultList('communities'),
              _buildResultList('games'),
              _buildResultList('reels'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultTabs() {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[900]
          : Colors.grey[100],
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Users'),
          Tab(text: 'Posts'),
          Tab(text: 'Tournaments'),
          Tab(text: 'Communities'),
          Tab(text: 'Games'),
          Tab(text: 'Reels'),
        ],
      ),
    );
  }

  Widget _buildResultList(String contentType) {
    final results = _searchResults[contentType] ?? [];

    if (results.isEmpty) {
      return const Center(
        child: Text('No results found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return _buildResultCard(result);
      },
    );
  }

  Widget _buildResultCard(SearchResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage:
              result.imageUrl != null ? NetworkImage(result.imageUrl!) : null,
          child: result.imageUrl == null
              ? Icon(_getIconForType(result.type))
              : null,
        ),
        title: Text(
          result.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(result.subtitle ?? ''),
        trailing: Icon(_getTrailingIconForType(result.type)),
        onTap: () => _onResultTap(result),
      ),
    );
  }

  IconData _getIconForType(SearchResultType type) {
    switch (type) {
      case SearchResultType.user:
        return Icons.person;
      case SearchResultType.post:
        return Icons.post_add;
      case SearchResultType.game:
        return Icons.games;
      case SearchResultType.community:
        return Icons.group;
      case SearchResultType.tournament:
        return Icons.emoji_events;
      case SearchResultType.reel:
        return Icons.video_library;
    }
  }

  IconData _getTrailingIconForType(SearchResultType type) {
    switch (type) {
      case SearchResultType.user:
        return Icons.person_add;
      case SearchResultType.post:
        return Icons.visibility;
      case SearchResultType.game:
        return Icons.play_arrow;
      case SearchResultType.community:
        return Icons.group_add;
      case SearchResultType.tournament:
        return Icons.sports_esports;
      case SearchResultType.reel:
        return Icons.video_library;
    }
  }

  void _onResultTap(SearchResult result) {
    // Navigate to appropriate screen based on result type
    switch (result.type) {
      case SearchResultType.user:
        // Navigate to user profile
        break;
      case SearchResultType.post:
        // Navigate to post detail
        break;
      case SearchResultType.game:
        // Navigate to game detail
        break;
      case SearchResultType.community:
        // Navigate to community detail
        break;
      case SearchResultType.tournament:
        // Navigate to tournament detail
        break;
      case SearchResultType.reel:
        // Navigate to reel detail
        break;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        selectedContentTypes: _selectedContentTypes,
        filters: _filters,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        onApply: (contentTypes, filters, sortBy, sortOrder) {
          setState(() {
            _selectedContentTypes = contentTypes;
            _filters = filters;
            _sortBy = sortBy;
            _sortOrder = sortOrder;
          });
          _onFilterChanged();
        },
      ),
    );
  }
}

class _FilterDialog extends StatefulWidget {
  final List<String> selectedContentTypes;
  final Map<String, dynamic> filters;
  final String sortBy;
  final String sortOrder;
  final Function(List<String>, Map<String, dynamic>, String, String) onApply;

  const _FilterDialog({
    required this.selectedContentTypes,
    required this.filters,
    required this.sortBy,
    required this.sortOrder,
    required this.onApply,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late List<String> _selectedContentTypes;
  late Map<String, dynamic> _filters;
  late String _sortBy;
  late String _sortOrder;

  @override
  void initState() {
    super.initState();
    _selectedContentTypes = List.from(widget.selectedContentTypes);
    _filters = Map.from(widget.filters);
    _sortBy = widget.sortBy;
    _sortOrder = widget.sortOrder;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search Filters'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Content Types',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildContentTypeCheckboxes(),
            const SizedBox(height: 16),
            const Text('Sort By',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildSortOptions(),
            const SizedBox(height: 16),
            const Text('Filters',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildFilterOptions(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(
                _selectedContentTypes, _filters, _sortBy, _sortOrder);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildContentTypeCheckboxes() {
    final contentTypes = [
      'users',
      'posts',
      'tournaments',
      'communities',
      'games',
      'reels'
    ];

    return Wrap(
      children: contentTypes.map((type) {
        return CheckboxListTile(
          title: Text(type.capitalize()),
          value: _selectedContentTypes.contains(type),
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _selectedContentTypes.add(type);
              } else {
                _selectedContentTypes.remove(type);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSortOptions() {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _sortBy,
          decoration: const InputDecoration(labelText: 'Sort Field'),
          items: const [
            DropdownMenuItem(value: 'created_at', child: Text('Date Created')),
            DropdownMenuItem(value: 'name', child: Text('Name')),
            DropdownMenuItem(value: 'likes_count', child: Text('Likes')),
            DropdownMenuItem(value: 'member_count', child: Text('Members')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _sortBy = value;
              });
            }
          },
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _sortOrder,
          decoration: const InputDecoration(labelText: 'Sort Order'),
          items: const [
            DropdownMenuItem(value: 'asc', child: Text('Ascending')),
            DropdownMenuItem(value: 'desc', child: Text('Descending')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _sortOrder = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildFilterOptions() {
    return Column(
      children: [
        TextField(
          decoration: const InputDecoration(labelText: 'Game Category'),
          onChanged: (value) {
            setState(() {
              _filters['gameCategory'] = value.isNotEmpty ? value : null;
            });
          },
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(labelText: 'Location'),
          onChanged: (value) {
            setState(() {
              _filters['location'] = value.isNotEmpty ? value : null;
            });
          },
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(labelText: 'Min Followers'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _filters['minFollowers'] =
                        value.isNotEmpty ? int.tryParse(value) : null;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(labelText: 'Max Followers'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    _filters['maxFollowers'] =
                        value.isNotEmpty ? int.tryParse(value) : null;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
