class AppSettings {
  final String appVersion;
  final bool maintenanceMode;
  final String defaultLanguage;

  AppSettings({
    required this.appVersion,
    required this.maintenanceMode,
    required this.defaultLanguage,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      appVersion: json['appVersion'] as String,
      maintenanceMode: json['maintenanceMode'] as bool,
      defaultLanguage: json['defaultLanguage'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appVersion': appVersion,
      'maintenanceMode': maintenanceMode,
      'defaultLanguage': defaultLanguage,
    };
  }
}
