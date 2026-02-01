import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:gamer_flick/config/environment.dart';

class ErrorReportingService {
  static final ErrorReportingService _instance =
      ErrorReportingService._internal();
  factory ErrorReportingService() => _instance;
  ErrorReportingService._internal();

  bool _isInitialized = false;
  PackageInfo? _packageInfo;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _packageInfo = await PackageInfo.fromPlatform();
      _isInitialized = true;
    } catch (e) {
      developer.log('Failed to initialize ErrorReportingService: $e');
    }
  }

  Future<void> reportError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Get device information
      final deviceInfo = await _getDeviceInfo();

      // Create error report
      final errorReport = {
        'timestamp': DateTime.now().toIso8601String(),
        'error': error.toString(),
        'stackTrace': stackTrace?.toString(),
        'context': context,
        'additionalData': additionalData,
        'appVersion': _packageInfo?.version ?? 'Unknown',
        'buildNumber': _packageInfo?.buildNumber ?? 'Unknown',
        'packageName': _packageInfo?.packageName ?? 'Unknown',
        'deviceInfo': deviceInfo,
        'environment': Environment.isProduction ? 'production' : 'development',
      };

      // Log error based on environment
      if (Environment.isProduction) {
        _logProductionError(errorReport);
      } else {
        _logDevelopmentError(errorReport);
      }

      // TODO: Send to external error reporting service (e.g., Sentry, Crashlytics)
      // await _sendToErrorReportingService(errorReport);
    } catch (e) {
      developer.log('Failed to report error: $e');
    }
  }

  Future<void> reportWarning(
    String message, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final warningReport = {
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'warning',
        'message': message,
        'context': context,
        'additionalData': additionalData,
        'appVersion': _packageInfo?.version ?? 'Unknown',
        'environment': Environment.isProduction ? 'production' : 'development',
      };

      if (Environment.isProduction) {
        _logProductionWarning(warningReport);
      } else {
        _logDevelopmentWarning(warningReport);
      }
    } catch (e) {
      developer.log('Failed to report warning: $e');
    }
  }

  Future<void> reportInfo(
    String message, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final infoReport = {
        'timestamp': DateTime.now().toIso8601String(),
        'type': 'info',
        'message': message,
        'context': context,
        'additionalData': additionalData,
        'appVersion': _packageInfo?.version ?? 'Unknown',
        'environment': Environment.isProduction ? 'production' : 'development',
      };

      if (Environment.isProduction) {
        _logProductionInfo(infoReport);
      } else {
        _logDevelopmentInfo(infoReport);
      }
    } catch (e) {
      developer.log('Failed to report info: $e');
    }
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'platform': 'android',
          'version': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'brand': androidInfo.brand,
          'model': androidInfo.model,
          'manufacturer': androidInfo.manufacturer,
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'platform': 'ios',
          'name': iosInfo.name,
          'systemName': iosInfo.systemName,
          'systemVersion': iosInfo.systemVersion,
          'model': iosInfo.model,
          'localizedModel': iosInfo.localizedModel,
        };
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        return {
          'platform': 'windows',
          'computerName': windowsInfo.computerName,
          'majorVersion': windowsInfo.majorVersion,
          'minorVersion': windowsInfo.minorVersion,
          'buildNumber': windowsInfo.buildNumber,
        };
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        final macOsInfo = await _deviceInfo.macOsInfo;
        return {
          'platform': 'macos',
          'computerName': macOsInfo.computerName,
          'hostName': macOsInfo.hostName,
          'arch': macOsInfo.arch,
          'model': macOsInfo.model,
          'kernelVersion': macOsInfo.kernelVersion,
          'osRelease': macOsInfo.osRelease,
        };
      } else if (defaultTargetPlatform == TargetPlatform.linux) {
        final linuxInfo = await _deviceInfo.linuxInfo;
        return {
          'platform': 'linux',
          'name': linuxInfo.name,
          'version': linuxInfo.version,
          'id': linuxInfo.id,
          'idLike': linuxInfo.idLike,
          'versionCodename': linuxInfo.versionCodename,
          'versionId': linuxInfo.versionId,
          'prettyName': linuxInfo.prettyName,
          'buildId': linuxInfo.buildId,
          'variant': linuxInfo.variant,
          'variantId': linuxInfo.variantId,
          'machineId': linuxInfo.machineId,
        };
      } else {
        return {
          'platform': 'unknown',
          'targetPlatform': defaultTargetPlatform.toString(),
        };
      }
    } catch (e) {
      return {
        'platform': 'unknown',
        'error': e.toString(),
      };
    }
  }

  void _logProductionError(Map<String, dynamic> errorReport) {
    // In production, log errors to a file or external service
    developer.log(
      'ERROR: ${errorReport['error']}',
      name: 'GamerFlick',
      error: errorReport['stackTrace'],
    );
  }

  void _logDevelopmentError(Map<String, dynamic> errorReport) {
    // In development, provide detailed logging
    developer.log(
      'ERROR: ${errorReport['error']}',
      name: 'GamerFlick',
      error: errorReport['stackTrace'],
    );

    if (kDebugMode) {
      print('=== ERROR REPORT ===');
      print('Context: ${errorReport['context']}');
      print('Additional Data: ${errorReport['additionalData']}');
      print('App Version: ${errorReport['appVersion']}');
      print('Device Info: ${errorReport['deviceInfo']}');
      print('===================');
    }
  }

  void _logProductionWarning(Map<String, dynamic> warningReport) {
    developer.log(
      'WARNING: ${warningReport['message']}',
      name: 'GamerFlick',
    );
  }

  void _logDevelopmentWarning(Map<String, dynamic> warningReport) {
    developer.log(
      'WARNING: ${warningReport['message']}',
      name: 'GamerFlick',
    );

    if (kDebugMode) {
      print('=== WARNING ===');
      print('Message: ${warningReport['message']}');
      print('Context: ${warningReport['context']}');
      print('===============');
    }
  }

  void _logProductionInfo(Map<String, dynamic> infoReport) {
    developer.log(
      'INFO: ${infoReport['message']}',
      name: 'GamerFlick',
    );
  }

  void _logDevelopmentInfo(Map<String, dynamic> infoReport) {
    developer.log(
      'INFO: ${infoReport['message']}',
      name: 'GamerFlick',
    );

    if (kDebugMode) {
      print('=== INFO ===');
      print('Message: ${infoReport['message']}');
      print('Context: ${infoReport['context']}');
      print('============');
    }
  }

  // Future<void> _sendToErrorReportingService(Map<String, dynamic> errorReport) async {
  //   // TODO: Implement integration with external error reporting services
  //   // Examples: Sentry, Crashlytics, Bugsnag, etc.
  // }
}
