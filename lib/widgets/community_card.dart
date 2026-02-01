import 'package:flutter/material.dart';
import 'package:gamer_flick/models/community/community.dart';
import '../screens/community/community_detail_screen.dart';

class CommunityCard extends StatelessWidget {
  final Community community;
  final bool showMemberCount;
  final EdgeInsetsGeometry? margin;

  const CommunityCard({
    super.key,
    required this.community,
    this.showMemberCount = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: community.imageUrl != null
            ? CircleAvatar(
                backgroundImage: NetworkImage(community.imageUrl!),
                radius: 24,
              )
            : const CircleAvatar(
                radius: 24,
                child: Icon(Icons.group),
              ),
        title: Text(
          community.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              community.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (community.game != null && community.game!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.sports_esports, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      community.game!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            if (community.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Wrap(
                  spacing: 4,
                  children: community.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
        trailing: showMemberCount
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${community.memberCount}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'members',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CommunityDetailScreen(community: community),
            ),
          );
        },
      ),
    );
  }
}
