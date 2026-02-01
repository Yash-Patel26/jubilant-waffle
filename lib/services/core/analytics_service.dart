import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gamer_flick/config/environment.dart';
import 'package:gamer_flick/services/core/error_reporting_service.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final ErrorReportingService _errorReporting = ErrorReportingService();
  bool _isInitialized = false;
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;

      await _errorReporting.reportInfo(
        'Analytics service initialized',
        context: 'AnalyticsService.initialize',
      );
    } catch (e) {
      await _errorReporting.reportError(
        e,
        null,
        context: 'AnalyticsService.initialize',
      );
    }
  }

  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
    String? userId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final eventData = {
        'event_name': eventName,
        'parameters': parameters ?? {},
        'user_id': userId,
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': await _getSessionId(),
        'app_version': Environment.appVersion,
        'environment': Environment.isProduction ? 'production' : 'development',
      };

      if (Environment.isProduction) {
        await _logProductionEvent(eventData);
      } else {
        await _logDevelopmentEvent(eventData);
      }

      // TODO: Send to external analytics service (e.g., Firebase Analytics, Mixpanel)
      // await _sendToAnalyticsService(eventData);
    } catch (e) {
      await _errorReporting.reportError(
        e,
        null,
        context: 'AnalyticsService.trackEvent',
        additionalData: {
          'event_name': eventName,
          'parameters': parameters,
        },
      );
    }
  }

  Future<void> trackScreenView(
    String screenName, {
    String? screenClass,
    Map<String, dynamic>? parameters,
    String? userId,
  }) async {
    await trackEvent(
      'screen_view',
      parameters: {
        'screen_name': screenName,
        'screen_class': screenClass,
        ...?parameters,
      },
      userId: userId,
    );
  }

  Future<void> trackUserAction(
    String action, {
    String? category,
    String? label,
    int? value,
    Map<String, dynamic>? parameters,
    String? userId,
  }) async {
    await trackEvent(
      'user_action',
      parameters: {
        'action': action,
        'category': category,
        'label': label,
        'value': value,
        ...?parameters,
      },
      userId: userId,
    );
  }

  Future<void> trackError(
    String errorType,
    String errorMessage, {
    String? errorCode,
    Map<String, dynamic>? parameters,
    String? userId,
  }) async {
    await trackEvent(
      'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        'error_code': errorCode,
        ...?parameters,
      },
      userId: userId,
    );
  }

  Future<void> trackPerformance(
    String metricName,
    int duration, {
    String? category,
    Map<String, dynamic>? parameters,
    String? userId,
  }) async {
    await trackEvent(
      'performance',
      parameters: {
        'metric_name': metricName,
        'duration_ms': duration,
        'category': category,
        ...?parameters,
      },
      userId: userId,
    );
  }

  Future<void> trackUserEngagement(
    String engagementType, {
    int? duration,
    String? contentId,
    String? contentType,
    Map<String, dynamic>? parameters,
    String? userId,
  }) async {
    await trackEvent(
      'user_engagement',
      parameters: {
        'engagement_type': engagementType,
        'duration_seconds': duration,
        'content_id': contentId,
        'content_type': contentType,
        ...?parameters,
      },
      userId: userId,
    );
  }

  Future<void> trackFeatureUsage(
    String featureName, {
    String? featureCategory,
    Map<String, dynamic>? parameters,
    String? userId,
  }) async {
    await trackEvent(
      'feature_usage',
      parameters: {
        'feature_name': featureName,
        'feature_category': featureCategory,
        ...?parameters,
      },
      userId: userId,
    );
  }

  Future<void> trackConversion(
    String conversionType, {
    double? value,
    String? currency,
    Map<String, dynamic>? parameters,
    String? userId,
  }) async {
    await trackEvent(
      'conversion',
      parameters: {
        'conversion_type': conversionType,
        'value': value,
        'currency': currency,
        ...?parameters,
      },
      userId: userId,
    );
  }

  Future<String> _getSessionId() async {
    if (_prefs == null) return 'unknown';

    String? sessionId = _prefs!.getString('analytics_session_id');
    if (sessionId == null) {
      sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      await _prefs!.setString('analytics_session_id', sessionId);
    }
    return sessionId;
  }

  Future<void> _logProductionEvent(Map<String, dynamic> eventData) async {
    // In production, log events to a file or external service
    developer.log(
      'ANALYTICS: ${eventData['event_name']}',
      name: 'GamerFlick',
    );
  }

  Future<void> _logDevelopmentEvent(Map<String, dynamic> eventData) async {
    // In development, provide detailed logging
    developer.log(
      'ANALYTICS: ${eventData['event_name']}',
      name: 'GamerFlick',
    );

    if (kDebugMode) {
      print('=== ANALYTICS EVENT ===');
      print('Event: ${eventData['event_name']}');
      print('Parameters: ${eventData['parameters']}');
      print('User ID: ${eventData['user_id']}');
      print('Session ID: ${eventData['session_id']}');
      print('Timestamp: ${eventData['timestamp']}');
      print('======================');
    }
  }

  // Convenience methods for common events
  Future<void> trackAppOpen({String? userId}) async {
    await trackEvent('app_open', userId: userId);
  }

  Future<void> trackAppClose({String? userId}) async {
    await trackEvent('app_close', userId: userId);
  }

  Future<void> trackLogin({String? method, String? userId}) async {
    await trackEvent(
      'login',
      parameters: {'method': method},
      userId: userId,
    );
  }

  Future<void> trackLogout({String? userId}) async {
    await trackEvent('logout', userId: userId);
  }

  Future<void> trackSignUp({String? method, String? userId}) async {
    await trackEvent(
      'sign_up',
      parameters: {'method': method},
      userId: userId,
    );
  }

  Future<void> trackPostCreated({String? postType, String? userId}) async {
    await trackEvent(
      'post_created',
      parameters: {'post_type': postType},
      userId: userId,
    );
  }

  Future<void> trackReelCreated({String? userId}) async {
    await trackEvent('reel_created', userId: userId);
  }

  Future<void> trackReelViewed({
    String? reelId,
    String? userId,
    int? watchTime,
    bool? completed,
  }) async {
    await trackEvent(
      'reel_viewed',
      parameters: {
        'reel_id': reelId,
        'user_id': userId,
        'watch_time': watchTime,
        'completed': completed,
      },
      userId: userId,
    );
  }

  Future<void> trackReelLiked({String? reelId, String? userId}) async {
    await trackEvent(
      'reel_liked',
      parameters: {'reel_id': reelId},
      userId: userId,
    );
  }

  Future<void> trackTournamentJoined(
      {String? tournamentId, String? userId}) async {
    await trackEvent(
      'tournament_joined',
      parameters: {'tournament_id': tournamentId},
      userId: userId,
    );
  }

  Future<void> trackCommunityJoined(
      {String? communityId, String? userId}) async {
    await trackEvent(
      'community_joined',
      parameters: {'community_id': communityId},
      userId: userId,
    );
  }

  // Future<void> _sendToAnalyticsService(Map<String, dynamic> eventData) async {
  //   // TODO: Implement integration with external analytics services
  //   // Examples: Firebase Analytics, Mixpanel, Amplitude, etc.
  // }
}
