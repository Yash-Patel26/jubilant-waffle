import 'package:flutter/material.dart';

class AICreateScreen extends StatefulWidget {
  const AICreateScreen({super.key});

  @override
  State<AICreateScreen> createState() => _AICreateScreenState();
}

class _AICreateScreenState extends State<AICreateScreen> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _generatedContentController =
      TextEditingController();
  String _selectedContentType = 'Caption';
  bool _isGenerating = false;

  final List<String> _contentTypes = [
    'Caption',
    'Hashtags',
    'Content Ideas',
    'Trending Topics',
    'Engagement Tips',
  ];

  final List<Map<String, dynamic>> _aiFeatures = [
    {
      'icon': Icons.edit,
      'label': 'Smart Captions',
      'description': 'Generate engaging captions for your posts',
      'color': null, // Will be set dynamically in build method
    },
    {
      'icon': Icons.tag,
      'label': 'Hashtag Generator',
      'description': 'Find trending and relevant hashtags',
      'color': null, // Will be set dynamically in build method
    },
    {
      'icon': Icons.lightbulb,
      'label': 'Content Ideas',
      'description': 'Get creative content suggestions',
      'color': null, // Will be set dynamically in build method
    },
    {
      'icon': Icons.trending_up,
      'label': 'Trend Analysis',
      'description': 'Discover what\'s trending in your niche',
      'color': null, // Will be set dynamically in build method
    },
  ];

  Future<void> _generateContent() async {
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a prompt for AI generation')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    // Simulate AI API call
    await Future.delayed(const Duration(seconds: 2));

    // Generate mock content based on type
    String generatedContent = '';
    switch (_selectedContentType) {
      case 'Caption':
        generatedContent = '''🎮 Epic gaming moment! 

Just pulled off the most insane play in my latest match. The adrenaline rush was real! 

What's your most memorable gaming achievement? Drop it in the comments below! 👇

#GamingLife #EpicPlay #GamerCommunity #GamingMoment #GamingAchievement #GamingGoals #GamingPassion #GamingCommunity #GamingLifeStyle #GamingWorld''';
        break;
      case 'Hashtags':
        generatedContent =
            '''#GamingLife #EpicPlay #GamerCommunity #GamingMoment #GamingAchievement #GamingGoals #GamingPassion #GamingCommunity #GamingLifeStyle #GamingWorld #GamingContent #GamingCreator #GamingInfluencer #GamingTrends #GamingCulture #GamingLifestyle #GamingMotivation #GamingInspiration #GamingSuccess #GamingDreams''';
        break;
      case 'Content Ideas':
        generatedContent = '''🎯 Content Ideas for Gaming:

1. "Day in the Life of a Gamer" - Show your daily gaming routine
2. "Gaming Setup Tour" - Showcase your gaming station
3. "Best Gaming Moments" - Compilation of epic plays
4. "Gaming Tips & Tricks" - Showcase your expertise
5. "Gaming Challenges" - Create fun challenges for followers
6. "Gaming Reviews" - Review new games or equipment
7. "Gaming Collaborations" - Team up with other gamers
8. "Gaming Behind the Scenes" - Show the real gaming life''';
        break;
      case 'Trending Topics':
        generatedContent = '''🔥 Trending in Gaming Right Now:

• New Game Releases - Stay updated with latest launches
• Esports Events - Major tournaments and competitions
• Gaming Technology - Latest hardware and software
• Gaming Controversies - Hot topics in the community
• Gaming Memes - Viral content and humor
• Gaming Challenges - Popular challenges and trends
• Gaming Collaborations - Cross-platform partnerships
• Gaming News - Industry updates and announcements''';
        break;
      case 'Engagement Tips':
        generatedContent = '''💡 Boost Your Gaming Content Engagement:

📱 Post Consistently - Create content daily or weekly
🎮 Show Personality - Let your unique style shine
💬 Engage with Comments - Reply to your audience
🎯 Use Trending Hashtags - Stay relevant and discoverable
📸 High-Quality Content - Invest in good visuals
🎥 Go Live - Real-time interaction with followers
🤝 Collaborate - Team up with other creators
📊 Analyze Performance - Track what works best
🎪 Create Challenges - Interactive content for followers
📢 Cross-Promote - Use multiple platforms to reach more gamers''';
        break;
    }

    setState(() {
      _generatedContentController.text = generatedContent;
      _isGenerating = false;
    });
  }

  void _copyToClipboard() {
    if (_generatedContentController.text.isNotEmpty) {
      // In a real app, you'd use Clipboard.setData
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Content copied to clipboard!')),
      );
    }
  }

  void _useInPost() {
    if (_generatedContentController.text.isNotEmpty) {
      Navigator.pop(context, _generatedContentController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Create'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          if (_generatedContentController.text.isNotEmpty)
            TextButton(
              onPressed: _useInPost,
              child: Text(
                'Use in Post',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AI Features Overview
            Text(
              'AI-Powered Content Creation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate engaging content with the help of AI',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),

            // AI Features Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _aiFeatures.length,
              itemBuilder: (context, index) {
                final feature = _aiFeatures[index];
                // Set dynamic colors based on index
                final List<Color> featureColors = [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                  theme.colorScheme.tertiary,
                  theme.colorScheme.primary,
                ];
                final featureColor =
                    featureColors[index % featureColors.length];

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: featureColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          feature['icon'] as IconData,
                          color: featureColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        feature['label'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature['description'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Content Type Selection
            Text(
              'Content Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedContentType,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
              items: _contentTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedContentType = value!;
                });
              },
            ),
            const SizedBox(height: 24),

            // Prompt Input
            Text(
              'Describe what you want to create',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _promptController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'e.g., "Create a gaming caption for my latest victory"',
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
              style: TextStyle(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _generateContent,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label:
                    Text(_isGenerating ? 'Generating...' : 'Generate Content'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Generated Content
            if (_generatedContentController.text.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Generated Content',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _copyToClipboard,
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copy to clipboard',
                      ),
                      IconButton(
                        onPressed: _useInPost,
                        icon: const Icon(Icons.send),
                        tooltip: 'Use in post',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: TextField(
                  controller: _generatedContentController,
                  maxLines: 10,
                  readOnly: true,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Generated content will appear here...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    _generatedContentController.dispose();
    super.dispose();
  }
}
