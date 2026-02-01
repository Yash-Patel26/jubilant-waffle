class Community {
  final String id;
  final String name;
  final String displayName;
  final String description;
  final String? imageUrl;
  final String? bannerUrl;
  final bool isPublic;
  final bool isVerified;
  final int memberCount;
  final int onlineCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? game;
  final List<String> tags;
  final String? rules;
  final bool? isVipOnly;
  final bool isNsfw;
  final bool allowImages;
  final bool allowVideos;
  final bool allowLinks;
  final bool allowPolls;
  final String contentFilter; // 'low', 'medium', 'high'
  final String language;
  final String? sidebar;
  final String? wiki;
  final Map<String, dynamic>? settings;
  final int karmaRequirement;
  final int accountAgeRequirement;
  final bool requireFlair;
  final List<String> allowedFlairs;
  final bool enableModLog;
  final bool enableWiki;
  final bool enableContestMode;
  final bool enableSpoilers;
  final String sortType; // 'hot', 'new', 'top', 'rising', 'controversial'
  final String defaultSort; // 'hot', 'new', 'top', 'rising', 'controversial'

  Community({
    required this.id,
    required this.name,
    required this.displayName,
    required this.description,
    this.imageUrl,
    this.bannerUrl,
    required this.isPublic,
    required this.isVerified,
    required this.memberCount,
    this.onlineCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.game,
    this.tags = const [],
    this.rules,
    this.isVipOnly,
    this.isNsfw = false,
    this.allowImages = true,
    this.allowVideos = true,
    this.allowLinks = true,
    this.allowPolls = true,
    this.contentFilter = 'medium',
    this.language = 'en',
    this.sidebar,
    this.wiki,
    this.settings,
    this.karmaRequirement = 0,
    this.accountAgeRequirement = 0,
    this.requireFlair = false,
    this.allowedFlairs = const [],
    this.enableModLog = true,
    this.enableWiki = false,
    this.enableContestMode = false,
    this.enableSpoilers = true,
    this.sortType = 'hot',
    this.defaultSort = 'hot',
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['display_name'] as String? ?? json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      isPublic: json['is_public'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      memberCount: json['member_count'] as int? ?? 0,
      onlineCount: json['online_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String?,
      game: json['game'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      rules: json['rules'] as String?,
      isVipOnly: json['is_vip_only'] as bool?,
      isNsfw: json['is_nsfw'] as bool? ?? false,
      allowImages: json['allow_images'] as bool? ?? true,
      allowVideos: json['allow_videos'] as bool? ?? true,
      allowLinks: json['allow_links'] as bool? ?? true,
      allowPolls: json['allow_polls'] as bool? ?? true,
      contentFilter: json['content_filter'] as String? ?? 'medium',
      language: json['language'] as String? ?? 'en',
      sidebar: json['sidebar'] as String?,
      wiki: json['wiki'] as String?,
      settings: json['settings'] as Map<String, dynamic>?,
      karmaRequirement: json['karma_requirement'] as int? ?? 0,
      accountAgeRequirement: json['account_age_requirement'] as int? ?? 0,
      requireFlair: json['require_flair'] as bool? ?? false,
      allowedFlairs: json['allowed_flairs'] != null
          ? List<String>.from(json['allowed_flairs'])
          : [],
      enableModLog: json['enable_mod_log'] as bool? ?? true,
      enableWiki: json['enable_wiki'] as bool? ?? false,
      enableContestMode: json['enable_contest_mode'] as bool? ?? false,
      enableSpoilers: json['enable_spoilers'] as bool? ?? true,
      sortType: json['sort_type'] as String? ?? 'hot',
      defaultSort: json['default_sort'] as String? ?? 'hot',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'description': description,
      'image_url': imageUrl,
      'banner_url': bannerUrl,
      'is_public': isPublic,
      'is_verified': isVerified,
      'member_count': memberCount,
      'online_count': onlineCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'game': game,
      'tags': tags,
      'rules': rules,
      'is_vip_only': isVipOnly,
      'is_nsfw': isNsfw,
      'allow_images': allowImages,
      'allow_videos': allowVideos,
      'allow_links': allowLinks,
      'allow_polls': allowPolls,
      'content_filter': contentFilter,
      'language': language,
      'sidebar': sidebar,
      'wiki': wiki,
      'settings': settings,
      'karma_requirement': karmaRequirement,
      'account_age_requirement': accountAgeRequirement,
      'require_flair': requireFlair,
      'allowed_flairs': allowedFlairs,
      'enable_mod_log': enableModLog,
      'enable_wiki': enableWiki,
      'enable_contest_mode': enableContestMode,
      'enable_spoilers': enableSpoilers,
      'sort_type': sortType,
      'default_sort': defaultSort,
    };
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'name': name,
      'display_name': displayName,
      'description': description,
      'image_url': imageUrl,
      'banner_url': bannerUrl,
      'is_public': isPublic,
      'is_verified': isVerified,
      'member_count': memberCount,
      'online_count': onlineCount,
      'created_by': createdBy,
      'game': game,
      'tags': tags,
      'rules': rules,
      'is_vip_only': isVipOnly,
      'is_nsfw': isNsfw,
      'allow_images': allowImages,
      'allow_videos': allowVideos,
      'allow_links': allowLinks,
      'allow_polls': allowPolls,
      'content_filter': contentFilter,
      'language': language,
      'sidebar': sidebar,
      'wiki': wiki,
      'settings': settings,
      'karma_requirement': karmaRequirement,
      'account_age_requirement': accountAgeRequirement,
      'require_flair': requireFlair,
      'allowed_flairs': allowedFlairs,
      'enable_mod_log': enableModLog,
      'enable_wiki': enableWiki,
      'enable_contest_mode': enableContestMode,
      'enable_spoilers': enableSpoilers,
      'sort_type': sortType,
      'default_sort': defaultSort,
    };
  }

  Community copyWith({
    String? id,
    String? name,
    String? displayName,
    String? description,
    String? imageUrl,
    String? bannerUrl,
    bool? isPublic,
    bool? isVerified,
    int? memberCount,
    int? onlineCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? game,
    List<String>? tags,
    String? rules,
    bool? isVipOnly,
    bool? isNsfw,
    bool? allowImages,
    bool? allowVideos,
    bool? allowLinks,
    bool? allowPolls,
    String? contentFilter,
    String? language,
    String? sidebar,
    String? wiki,
    Map<String, dynamic>? settings,
    int? karmaRequirement,
    int? accountAgeRequirement,
    bool? requireFlair,
    List<String>? allowedFlairs,
    bool? enableModLog,
    bool? enableWiki,
    bool? enableContestMode,
    bool? enableSpoilers,
    String? sortType,
    String? defaultSort,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      isPublic: isPublic ?? this.isPublic,
      isVerified: isVerified ?? this.isVerified,
      memberCount: memberCount ?? this.memberCount,
      onlineCount: onlineCount ?? this.onlineCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      game: game ?? this.game,
      tags: tags ?? this.tags,
      rules: rules ?? this.rules,
      isVipOnly: isVipOnly ?? this.isVipOnly,
      isNsfw: isNsfw ?? this.isNsfw,
      allowImages: allowImages ?? this.allowImages,
      allowVideos: allowVideos ?? this.allowVideos,
      allowLinks: allowLinks ?? this.allowLinks,
      allowPolls: allowPolls ?? this.allowPolls,
      contentFilter: contentFilter ?? this.contentFilter,
      language: language ?? this.language,
      sidebar: sidebar ?? this.sidebar,
      wiki: wiki ?? this.wiki,
      settings: settings ?? this.settings,
      karmaRequirement: karmaRequirement ?? this.karmaRequirement,
      accountAgeRequirement:
          accountAgeRequirement ?? this.accountAgeRequirement,
      requireFlair: requireFlair ?? this.requireFlair,
      allowedFlairs: allowedFlairs ?? this.allowedFlairs,
      enableModLog: enableModLog ?? this.enableModLog,
      enableWiki: enableWiki ?? this.enableWiki,
      enableContestMode: enableContestMode ?? this.enableContestMode,
      enableSpoilers: enableSpoilers ?? this.enableSpoilers,
      sortType: sortType ?? this.sortType,
      defaultSort: defaultSort ?? this.defaultSort,
    );
  }
}
