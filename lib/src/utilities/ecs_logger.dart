part of '../ecs_base.dart';

mixin ECSLogger {
  final List<ECSLog> _logs = [];

  /// Maximum number of log entries to keep.
  ///
  /// This can be adjusted based on the application's needs.
  ///
  /// Default is set to 1000 entries.
  ///
  /// if the number of entries exceeds this limit, the oldest entries will be
  /// removed.
  final maxEntries = 100;

  /// Unmodifiable list of log entries.
  List<ECSLog> get logs => List.unmodifiable(_logs);

  /// Logs a custom log entry.
  void log(
    String message, {
    ECSLogLevel level = ECSLogLevel.info,
  }) {
    while (_logs.length >= maxEntries) {
      _logs.removeAt(0);
    }
    _logs.add(ECSLog(
      time: DateTime.now(),
      level: level,
      message: message,
      stack: StackTrace.current,
    ));
  }

  /// Clears all log entries.
  void clear() {
    _logs.clear();
  }
}

/// Base class for ECS log entries.
final class ECSLog {
  /// The time when the log entry was created.
  final DateTime time;

  /// The log level of the entry.
  final ECSLogLevel level;

  /// The stack trace at the time of logging.
  final StackTrace stack;

  /// The log message.
  final String message;

  const ECSLog({
    required this.time,
    required this.level,
    required this.stack,
    required this.message,
  });
}

/// Represents the log levels for ECS logging.
enum ECSLogLevel {
  /// Informational log level.
  info,

  /// Warning log level.
  warning,

  /// Error log level.
  error,

  /// Debug log level.
  debug,

  /// Verbose log level.
  verbose,

  /// Fatal log level.
  fatal,
}
