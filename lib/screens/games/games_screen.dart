import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  _GamesScreenState createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  late Future<List<Map<String, dynamic>>> _gamesFuture;

  @override
  void initState() {
    super.initState();
    _gamesFuture = _loadPlayGamaGames();
  }

  /// Load games from PlayGama data in games.json asset.
  /// Parses segments and flattens hits into a single list.
  Future<List<Map<String, dynamic>>> _loadPlayGamaGames() async {
    try {
      final jsonString = await rootBundle.loadString('games.json');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final segments = data['segments'] as List<dynamic>? ?? [];
      final List<Map<String, dynamic>> allGames = [];
      for (final segment in segments) {
        final hits = (segment as Map<String, dynamic>)['hits'] as List<dynamic>? ?? [];
        for (final hit in hits) {
          allGames.add(hit as Map<String, dynamic>);
        }
      }
      return allGames;
    } catch (e) {
      return [];
    }
  }

  Future<void> _openPlayGama(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade800, width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.sports_esports, color: theme.primaryColor, size: 32),
                const SizedBox(width: 12),
                Text(
                  'Browse Games',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Games Grid (PlayGama from games.json)
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _gamesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: TextStyle(color: Colors.red.shade400),
                      ),
                    ),
                  );
                }
                final games = snapshot.data ?? [];
                if (games.isEmpty) {
                  return const Center(child: Text('No games found.'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    final title = game['title'] as String? ?? 'Game';
                    final playgamaUrl = game['playgamaGameUrl'] as String? ?? game['gameURL'] as String? ?? '';
                    final images = game['images'] as List<dynamic>? ?? [];
                    final imageUrl = images.isNotEmpty ? images[0] as String? : null;

                    return InkWell(
                      onTap: () {
                        if (playgamaUrl.isNotEmpty) {
                          _openPlayGama(playgamaUrl);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: imageUrl != null && imageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (_, __) => Container(
                                        color: Colors.grey.shade800,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      ),
                                      errorWidget: (_, __, ___) => Container(
                                        color: Colors.grey.shade800,
                                        child: const Icon(
                                          Icons.sports_esports,
                                          size: 50,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey.shade800,
                                      child: const Icon(
                                        Icons.sports_esports,
                                        size: 50,
                                      ),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                              child: Text(
                                title,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                              child: FilledButton.icon(
                                onPressed: playgamaUrl.isNotEmpty
                                    ? () => _openPlayGama(playgamaUrl)
                                    : null,
                                icon: const Icon(Icons.play_arrow, size: 18),
                                label: const Text('Play'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
