import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:gamer_flick/services/core/error_reporting_service.dart';
import 'package:gamer_flick/services/core/analytics_service.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final ErrorReportingService _errorReporting = ErrorReportingService();
  final AnalyticsService _analytics = AnalyticsService();

  bool _isInitialized = false;
  final Map<String, Stopwatch> _activeTimers = {};
  final Map<String, List<int>> _performanceMetrics = {};
  Timer? _periodicTimer;
  int _frameCount = 0;
  int _lastFrameTime = 0;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Start frame monitoring
      _startFrameMonitoring();

      // Start periodic performance reporting
      _startPeriodicReporting();

      _isInitialized = true;

      await _analytics.trackEvent('performance_service_initialized');
    } catch (e) {
      await _errorReporting.reportError(
        e,
        null,
        context: 'PerformanceService.initialize',
      );
    }
  }

  void _startFrameMonitoring() {
    SchedulerBinding.instance.addPersistentFrameCallback((timeStamp) {
      _frameCount++;
      _lastFrameTime = timeStamp.inMilliseconds;

      // Monitor frame rate every 60 frames (approximately 1 second at 60fps)
      if (_frameCount % 60 == 0) {
        _checkFrameRate();
      }
    });
  }

  void _checkFrameRate() {
    // Calculate current frame rate
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final frameRate = 60000 /
        (currentTime - _lastFrameTime + 1000); // Prevent division by zero

    if (frameRate < 30) {
      _analytics.trackEvent(
        'low_frame_rate_detected',
        parameters: {'frame_rate': frameRate},
      );
    }
  }

  void _startPeriodicReporting() {
    _periodicTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _reportPerformanceMetrics();
    });
  }

  void startTimer(String timerName) {
    if (!_isInitialized) return;

    _activeTimers[timerName] = Stopwatch()..start();
  }

  void stopTimer(String timerName) {
    if (!_isInitialized) return;

    final stopwatch = _activeTimers.remove(timerName);
    if (stopwatch != null) {
      final duration = stopwatch.elapsedMilliseconds;

      // Store metric for reporting
      _performanceMetrics.putIfAbsent(timerName, () => []);
      _performanceMetrics[timerName]!.add(duration);

      // Track individual timer completion
      _analytics.trackPerformance(timerName, duration);

      if (kDebugMode) {
        print('Timer $timerName: ${duration}ms');
      }
    }
  }

  Future<T> measureOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    if (!_isInitialized) {
      return await operation();
    }

    startTimer(operationName);
    try {
      final result = await operation();
      stopTimer(operationName);
      return result;
    } catch (e) {
      stopTimer(operationName);
      rethrow;
    }
  }

  T measureSyncOperation<T>(
    String operationName,
    T Function() operation,
  ) {
    if (!_isInitialized) {
      return operation();
    }

    startTimer(operationName);
    try {
      final result = operation();
      stopTimer(operationName);
      return result;
    } catch (e) {
      stopTimer(operationName);
      rethrow;
    }
  }

  void trackMemoryUsage() {
    if (!_isInitialized) return;

    try {
      // Get memory info (platform specific)
      final memoryInfo = _getMemoryInfo();

      _analytics.trackEvent(
        'memory_usage',
        parameters: memoryInfo,
      );

      // Check for high memory usage
      if (memoryInfo['usage_percentage'] > 80) {
        _analytics.trackEvent(
          'high_memory_usage',
          parameters: memoryInfo,
        );
      }
    } catch (e) {
      _errorReporting.reportError(
        e,
        null,
        context: 'PerformanceService.trackMemoryUsage',
      );
    }
  }

  Map<String, dynamic> _getMemoryInfo() {
    // This is a simplified implementation
    // In a real app, you'd use platform-specific APIs to get actual memory info
    return {
      'usage_percentage': 50.0, // Placeholder
      'total_memory_mb': 4096, // Placeholder
      'used_memory_mb': 2048, // Placeholder
      'available_memory_mb': 2048, // Placeholder
    };
  }

  void trackNetworkLatency(String endpoint, int latencyMs) {
    if (!_isInitialized) return;

    _analytics.trackEvent(
      'network_latency',
      parameters: {
        'endpoint': endpoint,
        'latency_ms': latencyMs,
      },
    );

    // Track slow network requests
    if (latencyMs > 5000) {
      _analytics.trackEvent(
        'slow_network_request',
        parameters: {
          'endpoint': endpoint,
          'latency_ms': latencyMs,
        },
      );
    }
  }

  void trackAppStartupTime(int startupTimeMs) {
    if (!_isInitialized) return;

    _analytics.trackEvent(
      'app_startup_time',
      parameters: {'startup_time_ms': startupTimeMs},
    );

    // Track slow startup
    if (startupTimeMs > 3000) {
      _analytics.trackEvent(
        'slow_app_startup',
        parameters: {'startup_time_ms': startupTimeMs},
      );
    }
  }

  void trackScreenLoadTime(String screenName, int loadTimeMs) {
    if (!_isInitialized) return;

    _analytics.trackEvent(
      'screen_load_time',
      parameters: {
        'screen_name': screenName,
        'load_time_ms': loadTimeMs,
      },
    );

    // Track slow screen loads
    if (loadTimeMs > 2000) {
      _analytics.trackEvent(
        'slow_screen_load',
        parameters: {
          'screen_name': screenName,
          'load_time_ms': loadTimeMs,
        },
      );
    }
  }

  void trackImageLoadTime(String imageUrl, int loadTimeMs) {
    if (!_isInitialized) return;

    _analytics.trackEvent(
      'image_load_time',
      parameters: {
        'image_url': imageUrl,
        'load_time_ms': loadTimeMs,
      },
    );

    // Track slow image loads
    if (loadTimeMs > 3000) {
      _analytics.trackEvent(
        'slow_image_load',
        parameters: {
          'image_url': imageUrl,
          'load_time_ms': loadTimeMs,
        },
      );
    }
  }

  void trackVideoLoadTime(String videoUrl, int loadTimeMs) {
    if (!_isInitialized) return;

    _analytics.trackEvent(
      'video_load_time',
      parameters: {
        'video_url': videoUrl,
        'load_time_ms': loadTimeMs,
      },
    );

    // Track slow video loads
    if (loadTimeMs > 5000) {
      _analytics.trackEvent(
        'slow_video_load',
        parameters: {
          'video_url': videoUrl,
          'load_time_ms': loadTimeMs,
        },
      );
    }
  }

  void _reportPerformanceMetrics() {
    if (!_isInitialized) return;

    try {
      final report = {
        'timestamp': DateTime.now().toIso8601String(),
        'metrics': _performanceMetrics.map((key, value) => MapEntry(key, {
              'count': value.length,
              'average': value.isEmpty
                  ? 0
                  : value.reduce((a, b) => a + b) / value.length,
              'min': value.isEmpty ? 0 : value.reduce((a, b) => a < b ? a : b),
              'max': value.isEmpty ? 0 : value.reduce((a, b) => a > b ? a : b),
            })),
      };

      _analytics.trackEvent(
        'performance_metrics_report',
        parameters: report,
      );

      // Clear old metrics to prevent memory buildup
      _performanceMetrics.clear();
    } catch (e) {
      _errorReporting.reportError(
        e,
        null,
        context: 'PerformanceService._reportPerformanceMetrics',
      );
    }
  }

  Map<String, dynamic> getPerformanceSummary() {
    final summary = <String, dynamic>{};

    for (final entry in _performanceMetrics.entries) {
      final values = entry.value;
      if (values.isNotEmpty) {
        summary[entry.key] = {
          'count': values.length,
          'average': values.reduce((a, b) => a + b) / values.length,
          'min': values.reduce((a, b) => a < b ? a : b),
          'max': values.reduce((a, b) => a > b ? a : b),
        };
      }
    }

    return summary;
  }

  void dispose() {
    _periodicTimer?.cancel();
    _activeTimers.clear();
    _performanceMetrics.clear();
  }
}
