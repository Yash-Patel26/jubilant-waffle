import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gamer_flick/config/environment.dart';
import 'package:gamer_flick/services/core/error_reporting_service.dart';
import 'package:gamer_flick/services/core/analytics_service.dart';
import 'package:gamer_flick/services/core/network_service.dart';

class AppInitializationService {
  static final AppInitializationService _instance =
      AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  final ErrorReportingService _errorReporting = ErrorReportingService();
  final AnalyticsService _analytics = AnalyticsService();
  final NetworkService _networkService = NetworkService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isInitialized = false;
  bool _isInitializing = false;
  final List<String> _initializationSteps = [];
  final List<String> _failedSteps = [];

  // Progress tracking
  final ValueNotifier<double> progress = ValueNotifier<double>(0.0);
  final ValueNotifier<String> statusMessage = ValueNotifier<String>('Starting...');

  // Total estimated steps for progress calculation
  static const int _totalEstimatedSteps = 6;
  int _currentStepCount = 0;

  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;

    _isInitializing = true;
    final stopwatch = Stopwatch()..start();

    try {
      await _analytics.trackEvent('app_initialization_started');

      // Step 1: Initialize core services
      statusMessage.value = 'Initializing core services...';
      await _initializeCoreServices();
      _updateProgress();

      // Step 2: Initialize platform-specific configurations
      statusMessage.value = 'Configuring platform...';
      await _initializePlatformConfigurations();
      _updateProgress();

      // Step 3: Initialize data services
      statusMessage.value = 'Loading data services...';
      await _initializeDataServices();
      _updateProgress();

      // Step 4: Initialize user session
      statusMessage.value = 'Checking user session...';
      await _initializeUserSession();
      _updateProgress();

      // Step 5: Perform health checks
      statusMessage.value = 'Running health checks...';
      await _performHealthChecks();
      _updateProgress();

      // Step 6: Finalize initialization
      statusMessage.value = 'Finalizing...';
      await _finalizeInitialization();
      _updateProgress();

      _isInitialized = true;
      _isInitializing = false;

      final initializationTime = stopwatch.elapsedMilliseconds;

      await _analytics.trackEvent(
        'app_initialization_completed',
        parameters: {
          'initialization_time_ms': initializationTime,
          'steps_completed': _initializationSteps.length,
          'failed_steps': _failedSteps.length,
        },
      );

      if (kDebugMode) {
        print('=== APP INITIALIZATION COMPLETED ===');
        print('Time: ${initializationTime}ms');
        print('Steps: ${_initializationSteps.join(', ')}');
        if (_failedSteps.isNotEmpty) {
          print('Failed: ${_failedSteps.join(', ')}');
        }
        print('===================================');
      }
    } catch (e, stackTrace) {
      _isInitializing = false;

      await _errorReporting.reportError(
        e,
        stackTrace,
        context: 'AppInitializationService.initialize',
        additionalData: {
          'completed_steps': _initializationSteps,
          'failed_steps': _failedSteps,
        },
      );

      await _analytics.trackEvent(
        'app_initialization_failed',
        parameters: {
          'error': e.toString(),
          'completed_steps': _initializationSteps.length,
          'failed_steps': _failedSteps.length,
        },
      );

      rethrow;
    }
  }

  Future<void> _initializeCoreServices() async {
    await _executeStep('Initialize Error Reporting', () async {
      await _errorReporting.initialize();
    });

    await _executeStep('Initialize Analytics', () async {
      await _analytics.initialize();
    });

    await _executeStep('Initialize Network Service', () async {
      await _networkService.initialize();
    });
  }

  Future<void> _initializePlatformConfigurations() async {
    await _executeStep('Set Platform Configurations', () async {
      // Set preferred orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      // Set system UI overlay style
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );

      // Enable system UI
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
      );
    });
  }

  Future<void> _initializeDataServices() async {
    await _executeStep('Initialize Shared Preferences', () async {
      await SharedPreferences.getInstance();
    });

    await _executeStep('Initialize Secure Storage', () async {
      // Test secure storage access
      await _secureStorage.write(key: 'test_key', value: 'test_value');
      await _secureStorage.delete(key: 'test_key');
    });

    await _executeStep('Verify Storage Buckets', () async {
      // Import and call the storage service method
      // This will be done after Supabase is initialized in main.dart
    });
  }

  Future<void> _initializeUserSession() async {
    await _executeStep('Check User Session', () async {
      // Check if user is already logged in
      final sessionToken = await _secureStorage.read(key: 'session_token');
      if (sessionToken != null) {
        await _analytics.trackEvent('user_session_restored');
      } else {
        await _analytics.trackEvent('user_session_not_found');
      }
    });
  }

  Future<void> _performHealthChecks() async {
    await _executeStep('Network Connectivity Check', () async {
      final isConnected = await _networkService.checkConnectivity();
      if (!isConnected) {
        await _analytics.trackEvent('network_connectivity_failed');
      }
    });

    await _executeStep('Server Health Check', () async {
      final isServerHealthy =
          await _networkService.pingServer(Environment.supabaseUrl);
      if (!isServerHealthy) {
        await _analytics.trackEvent('server_health_check_failed');
      }
    });
  }

  Future<void> _finalizeInitialization() async {
    await _executeStep('Finalize Initialization', () async {
      // Perform any final setup tasks
      await _analytics.trackEvent('app_ready');
    });
  }

  void _updateProgress() {
    _currentStepCount++;
    progress.value = _currentStepCount / _totalEstimatedSteps;
  }

  Future<void> _executeStep(
      String stepName, Future<void> Function() step) async {
    try {
      await step();
      _initializationSteps.add(stepName);

      await _analytics.trackEvent(
        'initialization_step_completed',
        parameters: {'step_name': stepName},
      );
    } catch (e) {
      _failedSteps.add(stepName);

      await _errorReporting.reportError(
        e,
        null,
        context: 'AppInitializationService.$stepName',
        additionalData: {'step_name': stepName},
      );

      await _analytics.trackEvent(
        'initialization_step_failed',
        parameters: {
          'step_name': stepName,
          'error': e.toString(),
        },
      );

      // In production, we might want to continue with other steps
      // In development, we might want to fail fast
      if (Environment.isDevelopment) {
        rethrow;
      }
    }
  }

  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  List<String> get completedSteps => List.unmodifiable(_initializationSteps);
  List<String> get failedSteps => List.unmodifiable(_failedSteps);

  Future<void> reset() async {
    _isInitialized = false;
    _isInitializing = false;
    _initializationSteps.clear();
    _failedSteps.clear();
  }

  Future<Map<String, dynamic>> getInitializationStatus() async {
    return {
      'is_initialized': _isInitialized,
      'is_initializing': _isInitializing,
      'completed_steps': _initializationSteps,
      'failed_steps': _failedSteps,
      'total_steps': _initializationSteps.length + _failedSteps.length,
      'success_rate': _initializationSteps.length /
          (_initializationSteps.length + _failedSteps.length),
    };
  }
}
