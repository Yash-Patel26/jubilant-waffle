/// Achievement model for gamification system
class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int points;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final Map<String, dynamic>? requirements;
  final bool isSecret;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.points,
    required this.category,
    required this.rarity,
    this.requirements,
    this.isSecret = false,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      points: json['points'] as int,
      category: AchievementCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AchievementCategory.general,
      ),
      rarity: AchievementRarity.values.firstWhere(
        (e) => e.name == json['rarity'],
        orElse: () => AchievementRarity.common,
      ),
      requirements: json['requirements'] as Map<String, dynamic>?,
      isSecret: json['is_secret'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'points': points,
      'category': category.name,
      'rarity': rarity.name,
      'requirements': requirements,
      'is_secret': isSecret,
    };
  }
}

/// User's unlocked achievement
class UserAchievement {
  final String id;
  final String oderId;
  final String achievementId;
  final DateTime unlockedAt;
  final int progress;
  final bool isComplete;
  final Achievement? achievement;

  const UserAchievement({
    required this.id,
    required this.oderId,
    required this.achievementId,
    required this.unlockedAt,
    this.progress = 100,
    this.isComplete = true,
    this.achievement,
  });

  // Alias for userId
  String get userId => oderId;

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'] as String,
      oderId: json['user_id'] as String,
      achievementId: json['achievement_id'] as String,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
      progress: json['progress'] as int? ?? 100,
      isComplete: json['is_complete'] as bool? ?? true,
      achievement: json['achievements'] != null
          ? Achievement.fromJson(json['achievements'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': oderId,
      'achievement_id': achievementId,
      'unlocked_at': unlockedAt.toIso8601String(),
      'progress': progress,
      'is_complete': isComplete,
    };
  }
}

/// Achievement progress tracking
class AchievementProgress {
  final String oderId;
  final String achievementId;
  final int currentValue;
  final int targetValue;
  final DateTime lastUpdated;

  const AchievementProgress({
    required this.oderId,
    required this.achievementId,
    required this.currentValue,
    required this.targetValue,
    required this.lastUpdated,
  });

  // Alias for userId
  String get userId => oderId;

  double get progressPercentage => 
      targetValue > 0 ? (currentValue / targetValue * 100).clamp(0, 100) : 0;

  bool get isComplete => currentValue >= targetValue;

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return AchievementProgress(
      oderId: json['user_id'] as String,
      achievementId: json['achievement_id'] as String,
      currentValue: json['current_value'] as int,
      targetValue: json['target_value'] as int,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': oderId,
      'achievement_id': achievementId,
      'current_value': currentValue,
      'target_value': targetValue,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

enum AchievementCategory {
  general,
  content,
  community,
  tournament,
  social,
  gaming,
  streak,
  milestone,
}

enum AchievementRarity {
  common,      // 10 points
  uncommon,    // 25 points
  rare,        // 50 points
  epic,        // 100 points
  legendary,   // 250 points
}

extension AchievementRarityExtension on AchievementRarity {
  int get defaultPoints {
    switch (this) {
      case AchievementRarity.common:
        return 10;
      case AchievementRarity.uncommon:
        return 25;
      case AchievementRarity.rare:
        return 50;
      case AchievementRarity.epic:
        return 100;
      case AchievementRarity.legendary:
        return 250;
    }
  }

  String get displayName {
    switch (this) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  String get colorHex {
    switch (this) {
      case AchievementRarity.common:
        return '#9E9E9E'; // Gray
      case AchievementRarity.uncommon:
        return '#4CAF50'; // Green
      case AchievementRarity.rare:
        return '#2196F3'; // Blue
      case AchievementRarity.epic:
        return '#9C27B0'; // Purple
      case AchievementRarity.legendary:
        return '#FF9800'; // Orange/Gold
    }
  }
}
