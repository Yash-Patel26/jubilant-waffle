import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../profile/profile_screen.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // Import for kIsWeb and defaultTargetPlatform

class SearchScreen extends StatefulWidget {
  final String? initialQuery;

  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _userResults = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _search(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        setState(() {
          _error = "Authentication error: Please log in again.";
          _isLoading = false;
        });
        return;
      }

      final userRes = await Supabase.instance.client
          .from('profiles')
          .select('id, username, bio, avatar_url, profile_picture_url')
          .ilike('username', '%$query%')
          .not('id', 'eq', currentUserId);

      setState(() {
        _userResults = userRes;
      });
    } catch (e) {
      setState(() {
        _error = 'An error occurred during search: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine if it's a desktop/web platform
    final isDesktopOrWeb = kIsWeb ||
        Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.linux;

    return Scaffold(
      backgroundColor:
          theme.colorScheme.surface, // Use theme background color
      appBar: AppBar(
        elevation: 0, // Remove elevation for flat, modern look
        backgroundColor:
            theme.colorScheme.surface, // Use surface color for AppBar
        foregroundColor:
            theme.colorScheme.onSurface, // Ensure title and icons are visible
        title: Text(
          'Search Users',
          style: theme.appBarTheme.titleTextStyle?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: 22, // Adjusted font size
              ) ??
              const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.white), // Fallback
        ),
        iconTheme: IconThemeData(
          color: theme
              .colorScheme.onSurface, // Ensure back button color is consistent
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0), // Increased padding
            child: TextField(
              controller: _searchController,
              style:
                  TextStyle(color: theme.colorScheme.onSurface), // Text color
              decoration: InputDecoration(
                hintText: 'Search for users...',
                hintStyle: TextStyle(
                    color: theme.colorScheme.onSurface
                        .withOpacity(0.6)), // Hint text color
                prefixIcon: Icon(Icons.search,
                    color: theme.colorScheme.primary), // Accent color for icon
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.6)), // Clear icon
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _userResults = []; // Clear results on clear
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                  borderSide: BorderSide(
                      color: theme.colorScheme.outline
                          .withOpacity(0.3)), // Subtle border
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.colorScheme.outline.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: theme.colorScheme.primary,
                      width: 2), // Accent border on focus
                ),
                filled: true,
                fillColor: theme.colorScheme
                    .surfaceContainerHighest, // Input background color
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 16), // Adjust padding
              ),
              onChanged: (value) {
                if (value.trim().isNotEmpty) {
                  _search(value.trim());
                } else {
                  setState(() {
                    _userResults = []; // Clear results when search is empty
                  });
                }
              },
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _search(value.trim());
                }
              },
            ),
          ),
          if (_isLoading)
            LinearProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary)), // Accent color for progress
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_error!,
                  style: TextStyle(color: theme.colorScheme.error)),
            ),
          Expanded(
            child: _buildUserResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserResults() {
    final theme = Theme.of(context);

    if (_userResults.isEmpty &&
        !_isLoading &&
        _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search_rounded, // Search icon
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'No users found.',
              style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ) ??
                  TextStyle(color: theme.colorScheme.onSurface),
            ),
          ],
        ),
      );
    } else if (_userResults.isEmpty &&
        !_isLoading &&
        _searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded, // Initial search icon
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Start typing to search for users.',
              style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ) ??
                  TextStyle(color: theme.colorScheme.onSurface),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _userResults.length,
      itemBuilder: (context, index) {
        final user = _userResults[index];
        return Container(
          margin: const EdgeInsets.symmetric(
              vertical: 4, horizontal: 16), // Margin for the card-like effect
          decoration: BoxDecoration(
            color: theme
                .colorScheme.surfaceContainerHighest, // Card background color
            borderRadius: BorderRadius.circular(12), // Rounded corners
            border: Border.all(
              color:
                  theme.colorScheme.outline.withOpacity(0.2), // Subtle border
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05), // Subtle shadow
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                vertical: 8, horizontal: 16), // Adjusted padding
            leading: CircleAvatar(
              radius: 24, // Slightly smaller avatar
              backgroundColor: theme.colorScheme.primary
                  .withOpacity(0.2), // Accent color background
              backgroundImage:
                  (user['avatar_url'] != null && user['avatar_url'].isNotEmpty)
                      ? NetworkImage(user['avatar_url'])
                      : (user['profile_picture_url'] != null &&
                              user['profile_picture_url'].isNotEmpty)
                          ? NetworkImage(user['profile_picture_url'])
                          : null,
              child: (user['avatar_url'] == null ||
                          user['avatar_url'].isEmpty) &&
                      (user['profile_picture_url'] == null ||
                          user['profile_picture_url'].isEmpty)
                  ? Text(
                      user['username']?[0]?.toUpperCase() ?? 'U',
                      style: TextStyle(
                        color:
                            theme.colorScheme.onPrimary, // Text color on accent
                        fontWeight: FontWeight.bold,
                        fontSize: 16, // Adjusted font size
                      ),
                    )
                  : null,
            ),
            title: Text(
              user['username'] ?? 'No name',
              style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ) ??
                  TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600),
            ),
            subtitle: Text(user['bio'] ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                    ) ??
                    TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.7))),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(userId: user['id']),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
