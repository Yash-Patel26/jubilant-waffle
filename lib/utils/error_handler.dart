import 'package:gamer_flick/config/environment.dart';
import 'package:gamer_flick/services/core/error_reporting_service.dart';
import 'package:flutter/material.dart';

class ErrorHandler {
  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) {
      if (Environment.isProduction) {
        // In production, log to a service like Crashlytics
        logError('Flutter Error', details.exception, details.stack);
      } else {
        // In development, use Flutter's default error handling
        FlutterError.dumpErrorToConsole(details);
      }
    };
  }

  static void logError(String message, dynamic error, [StackTrace? stackTrace]) {
    final reportingService = ErrorReportingService();
    reportingService.reportError(
      error,
      stackTrace,
      context: message,
    );
  }

  static void logInfo(String message) {
    final reportingService = ErrorReportingService();
    reportingService.reportInfo(message);
  }

  static void logWarning(String message) {
    final reportingService = ErrorReportingService();
    reportingService.reportWarning(message);
  }

  static String getFriendlyMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('network') || errorString.contains('internet')) {
      return 'Please check your internet connection and try again.';
    }
    if (errorString.contains('timeout')) {
      return 'The connection timed out. Please try again.';
    }
    if (errorString.contains('invalid login')) {
      return 'Invalid email or password.';
    }
    if (errorString.contains('already exists')) {
      return 'This already exists. Please try a different value.';
    }
    if (errorString.contains('unauthorized') || errorString.contains('401')) {
      return 'Your session has expired. Please login again.';
    }
    
    return 'Something went well wrong. Please try again later.';
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
