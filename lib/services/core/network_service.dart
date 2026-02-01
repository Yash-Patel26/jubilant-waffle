import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:gamer_flick/config/environment.dart';
import 'package:gamer_flick/services/core/error_reporting_service.dart';
import 'package:gamer_flick/services/core/analytics_service.dart';

class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  final ErrorReportingService _errorReporting = ErrorReportingService();
  final AnalyticsService _analytics = AnalyticsService();

  bool _isInitialized = false;
  bool _isConnected = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // Stream controller for connectivity status
  final _connectivityStreamController = StreamController<bool>.broadcast();
  
  /// Stream of connectivity status (true = online, false = offline)
  Stream<bool> get connectivityStream => _connectivityStreamController.stream;
  
  /// Stream of connectivity changes from the system
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Check initial connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      _isConnected = connectivityResult.isNotEmpty &&
          !connectivityResult.contains(ConnectivityResult.none);

      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          _errorReporting.reportError(
            error,
            null,
            context: 'NetworkService.connectivityListener',
          );
        },
      );

      _isInitialized = true;

      await _analytics.trackEvent(
        'network_service_initialized',
        parameters: {'is_connected': _isConnected},
      );
    } catch (e) {
      await _errorReporting.reportError(
        e,
        null,
        context: 'NetworkService.initialize',
      );
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);

    if (wasConnected != _isConnected) {
      // Emit connectivity change to stream
      _connectivityStreamController.add(_isConnected);
      
      _analytics.trackEvent(
        'connectivity_changed',
        parameters: {
          'was_connected': wasConnected,
          'is_connected': _isConnected,
          'connection_type': results.toString(),
        },
      );

      if (kDebugMode) {
        print('Network connectivity changed: ${results.toString()}');
      }
    }
  }

  bool get isConnected => _isConnected;
  bool get isDisconnected => !_isConnected;

  Future<bool> checkConnectivity() async {
    if (!_isInitialized) {
      await initialize();
    }
    try {
      final result = await _connectivity.checkConnectivity();
      _isConnected =
          result.isNotEmpty && !result.contains(ConnectivityResult.none);
      return _isConnected;
    } catch (e) {
      await _errorReporting.reportError(
        e,
        null,
        context: 'NetworkService.checkConnectivity',
      );
      return false;
    }
  }

  Future<T> executeWithRetry<T>({
    required Future<T> Function() operation,
    int maxRetries = Environment.maxRetries,
    Duration? retryDelay,
    String? operationName,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isConnected) {
      throw NetworkException('No internet connection available');
    }

    int attempts = 0;
    Duration delay = retryDelay ?? const Duration(seconds: 1);

    while (attempts < maxRetries) {
      try {
        attempts++;

        await _analytics.trackEvent(
          'network_operation_attempt',
          parameters: {
            'operation_name': operationName,
            'attempt': attempts,
            'max_retries': maxRetries,
          },
        );

        final result = await operation();

        await _analytics.trackEvent(
          'network_operation_success',
          parameters: {
            'operation_name': operationName,
            'attempts': attempts,
          },
        );

        return result;
      } catch (e) {
        await _errorReporting.reportError(
          e,
          null,
          context: 'NetworkService.executeWithRetry',
          additionalData: {
            'operation_name': operationName,
            'attempt': attempts,
            'max_retries': maxRetries,
          },
        );

        if (attempts >= maxRetries) {
          await _analytics.trackEvent(
            'network_operation_failed',
            parameters: {
              'operation_name': operationName,
              'attempts': attempts,
              'error': e.toString(),
            },
          );
          rethrow;
        }

        // Wait before retrying
        await Future.delayed(delay);

        // Exponential backoff
        delay = Duration(milliseconds: delay.inMilliseconds * 2);
      }
    }

    throw NetworkException('Operation failed after $maxRetries attempts');
  }

  Future<T> executeWithTimeout<T>({
    required Future<T> Function() operation,
    Duration? timeout,
    String? operationName,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isConnected) {
      throw NetworkException('No internet connection available');
    }

    final timeoutDuration =
        timeout ?? Duration(seconds: Environment.apiTimeoutSeconds);

    try {
      await _analytics.trackEvent(
        'network_operation_started',
        parameters: {
          'operation_name': operationName,
          'timeout_seconds': timeoutDuration.inSeconds,
        },
      );

      final result = await operation().timeout(timeoutDuration);

      await _analytics.trackEvent(
        'network_operation_completed',
        parameters: {
          'operation_name': operationName,
        },
      );

      return result;
    } on TimeoutException {
      await _analytics.trackEvent(
        'network_operation_timeout',
        parameters: {
          'operation_name': operationName,
          'timeout_seconds': timeoutDuration.inSeconds,
        },
      );

      await _errorReporting.reportError(
        'Operation timed out',
        null,
        context: 'NetworkService.executeWithTimeout',
        additionalData: {
          'operation_name': operationName,
          'timeout_seconds': timeoutDuration.inSeconds,
        },
      );

      throw NetworkException(
          'Operation timed out after ${timeoutDuration.inSeconds} seconds');
    } catch (e) {
      await _analytics.trackEvent(
        'network_operation_error',
        parameters: {
          'operation_name': operationName,
          'error': e.toString(),
        },
      );

      await _errorReporting.reportError(
        e,
        null,
        context: 'NetworkService.executeWithTimeout',
        additionalData: {
          'operation_name': operationName,
        },
      );

      rethrow;
    }
  }

  Future<bool> pingServer(String url) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      client.close();

      return response.statusCode == 200;
    } catch (e) {
      await _errorReporting.reportError(
        e,
        null,
        context: 'NetworkService.pingServer',
        additionalData: {'url': url},
      );
      return false;
    }
  }

  Future<Map<String, dynamic>> getNetworkInfo() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();

      return {
        'connectivity_type': connectivityResult.toString(),
        'wifi_name': null, // Not available in newer versions
        'mobile_network': null, // Not available in newer versions
        'is_connected': _isConnected,
      };
    } catch (e) {
      await _errorReporting.reportError(
        e,
        null,
        context: 'NetworkService.getNetworkInfo',
      );
      return {
        'connectivity_type': 'unknown',
        'is_connected': _isConnected,
      };
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityStreamController.close();
  }
  
  /// Execute with offline fallback
  /// Attempts online action first, falls back to offline action if not connected
  Future<T> executeWithOfflineFallback<T>({
    required Future<T> Function() onlineAction,
    required Future<T> Function() offlineAction,
  }) async {
    if (await checkConnectivity()) {
      try {
        return await onlineAction();
      } catch (e) {
        // Network error occurred, fall back to offline
        return await offlineAction();
      }
    }
    return await offlineAction();
  }
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}
