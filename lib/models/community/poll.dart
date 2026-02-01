
/// Enhanced Poll model for community posts
/// Supports multiple voting styles, expiration, and analytics
class CommunityPoll {
  final String id;
  final String postId;
  final String question;
  final List<PollOption> options;
  final PollType type;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool allowMultipleVotes;
  final bool showResultsBeforeVoting;
  final bool isAnonymous;
  final int totalVotes;
  final bool isClosed;

  const CommunityPoll({
    required this.id,
    required this.postId,
    required this.question,
    required this.options,
    this.type = PollType.singleChoice,
    required this.createdAt,
    this.expiresAt,
    this.allowMultipleVotes = false,
    this.showResultsBeforeVoting = false,
    this.isAnonymous = false,
    this.totalVotes = 0,
    this.isClosed = false,
  });

  /// Check if poll has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if poll is active (not expired and not closed)
  bool get isActive => !isExpired && !isClosed;

  /// Get time remaining until expiration
  Duration? get timeRemaining {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get winning option(s)
  List<PollOption> get winningOptions {
    if (options.isEmpty) return [];
    final maxVotes = options.map((o) => o.voteCount).reduce((a, b) => a > b ? a : b);
    return options.where((o) => o.voteCount == maxVotes).toList();
  }

  factory CommunityPoll.fromJson(Map<String, dynamic> json) {
    return CommunityPoll(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      question: json['question'] as String,
      options: (json['options'] as List?)
              ?.map((o) => PollOption.fromJson(o as Map<String, dynamic>))
              .toList() ??
          [],
      type: PollType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => PollType.singleChoice,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      allowMultipleVotes: json['allow_multiple_votes'] as bool? ?? false,
      showResultsBeforeVoting: json['show_results_before_voting'] as bool? ?? false,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      totalVotes: json['total_votes'] as int? ?? 0,
      isClosed: json['is_closed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'question': question,
      'options': options.map((o) => o.toJson()).toList(),
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'allow_multiple_votes': allowMultipleVotes,
      'show_results_before_voting': showResultsBeforeVoting,
      'is_anonymous': isAnonymous,
      'total_votes': totalVotes,
      'is_closed': isClosed,
    };
  }

  CommunityPoll copyWith({
    String? id,
    String? postId,
    String? question,
    List<PollOption>? options,
    PollType? type,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? allowMultipleVotes,
    bool? showResultsBeforeVoting,
    bool? isAnonymous,
    int? totalVotes,
    bool? isClosed,
  }) {
    return CommunityPoll(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      question: question ?? this.question,
      options: options ?? this.options,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      allowMultipleVotes: allowMultipleVotes ?? this.allowMultipleVotes,
      showResultsBeforeVoting: showResultsBeforeVoting ?? this.showResultsBeforeVoting,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      totalVotes: totalVotes ?? this.totalVotes,
      isClosed: isClosed ?? this.isClosed,
    );
  }
}

/// Poll option with vote tracking
class PollOption {
  final String id;
  final String text;
  final int voteCount;
  final String? imageUrl;
  final int position;

  const PollOption({
    required this.id,
    required this.text,
    this.voteCount = 0,
    this.imageUrl,
    this.position = 0,
  });

  /// Get percentage of total votes
  double getPercentage(int totalVotes) {
    if (totalVotes == 0) return 0;
    return (voteCount / totalVotes) * 100;
  }

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] as String,
      text: json['text'] as String,
      voteCount: json['vote_count'] as int? ?? 0,
      imageUrl: json['image_url'] as String?,
      position: json['position'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'vote_count': voteCount,
      'image_url': imageUrl,
      'position': position,
    };
  }

  PollOption copyWith({
    String? id,
    String? text,
    int? voteCount,
    String? imageUrl,
    int? position,
  }) {
    return PollOption(
      id: id ?? this.id,
      text: text ?? this.text,
      voteCount: voteCount ?? this.voteCount,
      imageUrl: imageUrl ?? this.imageUrl,
      position: position ?? this.position,
    );
  }
}

/// Poll vote record
class PollVote {
  final String id;
  final String pollId;
  final String optionId;
  final String oderId;
  final DateTime votedAt;

  const PollVote({
    required this.id,
    required this.pollId,
    required this.optionId,
    required this.oderId,
    required this.votedAt,
  });

  // Alias for backward compatibility
  String get userId => oderId;

  factory PollVote.fromJson(Map<String, dynamic> json) {
    return PollVote(
      id: json['id'] as String,
      pollId: json['poll_id'] as String,
      optionId: json['option_id'] as String,
      oderId: json['user_id'] as String,
      votedAt: DateTime.parse(json['voted_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poll_id': pollId,
      'option_id': optionId,
      'user_id': oderId,
      'voted_at': votedAt.toIso8601String(),
    };
  }
}

/// Types of polls
enum PollType {
  singleChoice,    // Select one option
  multipleChoice,  // Select multiple options
  ranked,          // Rank options in order
  prediction,      // Predict outcome (for tournaments/matches)
}

/// Poll duration presets
enum PollDuration {
  oneHour,
  sixHours,
  oneDay,
  threeDays,
  oneWeek,
  custom,
  noExpiration,
}

extension PollDurationExtension on PollDuration {
  Duration? get duration {
    switch (this) {
      case PollDuration.oneHour:
        return const Duration(hours: 1);
      case PollDuration.sixHours:
        return const Duration(hours: 6);
      case PollDuration.oneDay:
        return const Duration(days: 1);
      case PollDuration.threeDays:
        return const Duration(days: 3);
      case PollDuration.oneWeek:
        return const Duration(days: 7);
      case PollDuration.custom:
      case PollDuration.noExpiration:
        return null;
    }
  }

  String get displayName {
    switch (this) {
      case PollDuration.oneHour:
        return '1 hour';
      case PollDuration.sixHours:
        return '6 hours';
      case PollDuration.oneDay:
        return '1 day';
      case PollDuration.threeDays:
        return '3 days';
      case PollDuration.oneWeek:
        return '1 week';
      case PollDuration.custom:
        return 'Custom';
      case PollDuration.noExpiration:
        return 'No expiration';
    }
  }
}
