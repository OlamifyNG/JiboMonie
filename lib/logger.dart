import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum LogLevel { info, warning, error }

class ReleaseLogger {
  static const _channel = MethodChannel('com.jibomonie.logger');

  static Future<void> log(String message,
      {LogLevel level = LogLevel.info}) async {
    final fullMessage = "JiboMonieApp: $message";

    // Customize the log based on the level
    String logMessage;
    switch (level) {
      case LogLevel.error:
        logMessage = "ERROR: $fullMessage";
        break;
      case LogLevel.warning:
        logMessage = "WARNING: $fullMessage";
        break;
      case LogLevel.info:
      default:
        logMessage = "INFO: $fullMessage";
        break;
    }

    if (kReleaseMode || kProfileMode) {
      try {
        await _channel.invokeMethod('log', {
          'message': logMessage,
          'level': level.name, // Send level as string
          'timestamp': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Fallback to debugPrint if native logging fails
        debugPrint('Native logging failed: $e');
        debugPrint(logMessage);
      }
    } else {
      debugPrint(logMessage); // Visible in debug mode
    }
  }
}
