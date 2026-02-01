class UserSettings {
  final String userId;
  final bool notificationsEnabled;
  final String theme; // e.g., 'light', 'dark'
  final bool isPrivateAccount;
  final bool showOnlineStatus;

  UserSettings({
    required this.userId,
    required this.notificationsEnabled,
    required this.theme,
    required this.isPrivateAccount,
    required this.showOnlineStatus,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      userId: json['userId'] as String,
      notificationsEnabled: json['notificationsEnabled'] as bool,
      theme: json['theme'] as String,
      isPrivateAccount: json['isPrivateAccount'] as bool,
      showOnlineStatus: json['showOnlineStatus'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'notificationsEnabled': notificationsEnabled,
      'theme': theme,
      'isPrivateAccount': isPrivateAccount,
      'showOnlineStatus': showOnlineStatus,
    };
  }
}
