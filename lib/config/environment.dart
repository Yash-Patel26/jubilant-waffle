class Environment {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dedknavvqlnqzsadlbfp.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRlZGtuYXZ2cWxucXpzYWRsYmZwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxNTY2NjAsImV4cCI6MjA2OTczMjY2MH0.o1rVTp8NFDFbbYdZHyLQYgLooRLOgN5WbBHHlN1-JHg',
  );

  static const String googleAuthRedirectUrl = String.fromEnvironment(
    'GOOGLE_AUTH_REDIRECT_URL',
    defaultValue: 'io.supabase.flutter://login-callback/',
  );

  static const bool isProduction = bool.fromEnvironment('dart.vm.product');
  static const bool isDevelopment = !isProduction;

  // Custom Backend Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1', // Default for Android Emulator
  );
  static const String apiWebSocketUrl = String.fromEnvironment(
    'API_WS_URL',
    defaultValue: 'ws://10.0.2.2:8080/api/v1/ws', // Default for Android Emulator
  );

  // API Configuration
  static const int apiTimeoutSeconds = 30;
  static const int maxRetries = 3;

  // App Configuration
  static const String appName = 'GamerFlick';
  static const String appVersion = '3.0.0';
  static const int appBuildNumber = 1;

  // Storage Bucket Names (must match exactly with Supabase dashboard)
  static const String avatarsBucket = 'avatars';
  static const String bannersBucket = 'banners';
  static const String postsBucket = 'posts';
  static const String storiesBucket = 'stories';
  static const String reelsBucket = 'reels';
  static const String highlightsBucket = 'highlights';
  static const String communitiesBucket = 'communities';
  static const String tournamentsBucket = 'tournaments';
  static const String streamsBucket = 'streams';
  static const String streamRecordingsBucket = 'stream-recordings';
  static const String gamesBucket = 'games';
}
