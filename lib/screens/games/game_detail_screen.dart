import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GameDetailScreen extends StatefulWidget {
  final int gameId;
  final String gameName;

  const GameDetailScreen({
    super.key,
    required this.gameId,
    required this.gameName,
  });

  @override
  _GameDetailScreenState createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  late Future<Map<String, dynamic>> _gameDetailFuture;

  @override
  void initState() {
    super.initState();
    _gameDetailFuture = _fetchGameDetails();
  }

  Future<Map<String, dynamic>> _fetchGameDetails() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/games/${widget.gameId}'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load game details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load game details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: _gameDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(color: Colors.red.shade400),
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Game not found.'));
          }

          final game = snapshot.data!;
          final achievements = game['Achievements'] as List<dynamic>? ?? [];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    game['name'],
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: game['image_url'] != null
                      ? Image.network(
                          'http://localhost:3000${game['image_url']}',
                          fit: BoxFit.cover,
                          color: Colors.black.withOpacity(0.5),
                          colorBlendMode: BlendMode.darken,
                        )
                      : Container(color: theme.primaryColor),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  // Game Info Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About ${game['name']}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          game['description'] ?? 'No description available.',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Chip(
                              avatar: Icon(
                                Icons.category,
                                color: theme.primaryColor,
                              ),
                              label: Text(game['genre'] ?? 'N/A'),
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              avatar: Icon(
                                Icons.computer,
                                color: theme.primaryColor,
                              ),
                              label: Text(game['platform'] ?? 'N/A'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Achievements Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Achievements (${achievements.length})',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...achievements
                      .map((ach) => _buildAchievementTile(ach, theme))
                      ,
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAchievementTile(
    Map<String, dynamic> achievement,
    ThemeData theme,
  ) {
    // You can enhance this with rarity colors, icons, etc.
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.primaryColor.withOpacity(0.2),
        child: achievement['icon_url'] != null
            ? Image.network('http://localhost:3000${achievement['icon_url']}')
            : Icon(Icons.emoji_events, color: theme.primaryColor),
      ),
      title: Text(
        achievement['name'],
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(achievement['description'] ?? 'No description.'),
      trailing: Text(
        '${achievement['points'] ?? 0} pts',
        style: TextStyle(
          color: theme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
