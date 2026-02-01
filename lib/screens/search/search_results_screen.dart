import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../profile/profile_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late Future<List<Map<String, dynamic>>> _searchFuture;

  @override
  void initState() {
    super.initState();
    _searchFuture = _performSearch();
  }

  Future<List<Map<String, dynamic>>> _performSearch() async {
    final supabase = Supabase.instance.client;
    final query = widget.query.toLowerCase();

    List<Map<String, dynamic>> users = [];

    try {
      // Search users
      final userResults = await supabase
          .from('profiles')
          .select()
          .ilike('username', '%$query%')
          .limit(10);
      users = (userResults as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      // Handle error silently
    }

    return users;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Users: ${widget.query}'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _searchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text('No users found.')),
            );
          }

          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Users',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              ...users.map((user) => ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(user['username'] ?? 'Unknown'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(
                            userId: user['user_id'],
                          ),
                        ),
                      );
                    },
                  )),
            ],
          );
        },
      ),
    );
  }
}
