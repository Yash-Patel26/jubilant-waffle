import 'package:flutter/material.dart';
import 'package:gamer_flick/models/tournament/tournament.dart';
import 'package:intl/intl.dart';

class TournamentCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback? onTap;

  const TournamentCard({
    super.key,
    required this.tournament,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isFeatured = tournament.status == 'featured' ||
        (tournament.creator?['is_featured'] ?? false);
    final bool isLive = tournament.status == 'ongoing' || tournament.isOngoing;
    final bool isUpcoming =
        tournament.status == 'upcoming' || tournament.isUpcoming;
    final bool isCompleted =
        tournament.status == 'completed' || tournament.isCompleted;
    // final String startsIn = DateFormat.yMMMd().format(tournament.startDate);
    final String type = tournament.type.toUpperCase();
    final Color typeColor =
        type == 'SOLO' ? Colors.purple.shade100 : Colors.orange.shade100;
    final Color typeTextColor = type == 'SOLO' ? Colors.purple : Colors.orange;
    final Color statusDotColor = isLive
        ? Colors.green
        : isUpcoming
            ? Colors.blue
            : isCompleted
                ? Colors.grey
                : Colors.orange;
    final String actionText = isLive
        ? 'View Live'
        : isCompleted
            ? 'View Results'
            : 'Join Tournament';
    final Color prizeColor = Colors.green;
    final String location = tournament.mediaUrl ?? 'Online';
    final String game = tournament.game;
    final String prize = tournament.prizePool ?? '0';
    final int participants = tournament.participantCount ?? 0;
    final int maxParticipants = tournament.maxParticipants;
    final String organizer = tournament.creator?['username'] ?? 'Unknown';
    final String avatarUrl = tournament.creator?['avatar_url'] ?? '';
    final String date = DateFormat.yMd().format(tournament.startDate);

    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      margin: const EdgeInsets.all(6),
      constraints: BoxConstraints(maxHeight: isMobile ? 360 : 320),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top: Featured badge and status dot
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    if (isFeatured)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.star, color: Colors.orange, size: 14),
                            SizedBox(width: 4),
                            Text('Featured',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    const Spacer(),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusDotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
              // Image placeholder
              Container(
                height: isMobile ? 80 : 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.3 : 1.0),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Icon(Icons.image,
                      size: isMobile ? 36 : 36,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tournament.name,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 14 : 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            type,
                            style: TextStyle(
                                color: typeTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 10 : 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game,
                      style: TextStyle(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                          fontSize: isMobile ? 12 : 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.attach_money, size: 16, color: prizeColor),
                        Expanded(
                          child: Text(
                            prize,
                            style: TextStyle(
                                color: prizeColor, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.people,
                            size: 16,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7)),
                        Expanded(
                          child: Text(
                            ' $participants/$maxParticipants',
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                                fontSize: isMobile ? 12 : null),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7)),
                        Expanded(
                          child: Text(
                            ' $date',
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                                fontSize: isMobile ? 12 : null),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.location_on,
                            size: 16,
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7)),
                        Expanded(
                          child: Text(
                            ' $location',
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                                fontSize: isMobile ? 12 : null),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          backgroundColor: Colors.grey.shade200,
                          child: avatarUrl.isEmpty
                              ? const Icon(Icons.person,
                                  size: 16, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'by $organizer',
                            style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                                fontSize: isMobile ? 12 : 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: onTap,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                              backgroundColor: theme.colorScheme.primary,
                            ),
                            child: Text(
                              actionText,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: isMobile ? 12 : null),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.star_border,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7)),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
