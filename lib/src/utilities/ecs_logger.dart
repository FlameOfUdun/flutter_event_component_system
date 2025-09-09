part of '../ecs_base.dart';

final class ECSLogger {
  static final List<ECSLog> _entries = [];

  /// Maximum number of log entries to keep.
  /// 
  /// This can be adjusted based on the application's needs.
  /// 
  /// Default is set to 1000 entries.
  /// 
  /// if the number of entries exceeds this limit, the oldest entries will be 
  /// removed.
  static var maxEntries = 1000;

  ECSLogger._();

  /// Unmodifiable list of log entries.
  static List<ECSLog> get entries => List.unmodifiable(_entries);

  /// Logs an entity change event.
  @visibleForTesting
  static void logEntityChanged(ECSEntity entity) {
    log(_EntityChanged(
      time: DateTime.now(),
      level: ECSLogLevel.info,
      entity: entity,
      stack: StackTrace.current,
    ));
  }

  /// Logs a system reaction to an entity change.
  @visibleForTesting
  static void logSystemReacted(ReactiveSystem system, ECSEntity event) {
    log(_SystemReacted(
      time: DateTime.now(),
      level: ECSLogLevel.info,
      system: system,
      entity: event,
      stack: StackTrace.current,
    ));
  }

  /// Logs a custom log entry.
  static void log(ECSLog log) {
    while (_entries.length >= maxEntries) {
      _entries.removeAt(0);
    }
    _entries.add(log);
  }

  /// Clears all log entries.
  static void clear() {
    _entries.clear();
  }
}

/// Base class for ECS log entries.
abstract class ECSLog {
  /// The time when the log entry was created.
  final DateTime time;

  /// The log level of the entry.
  final ECSLogLevel level;

  /// The stack trace at the time of logging.
  final StackTrace stack;

  const ECSLog({
    required this.time,
    required this.level,
    required this.stack,
  });

  /// Human-readable description of the log entry.
  String get description;
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

/// Represents an entity change event in the ECS system.
final class _EntityChanged<TEntity extends ECSEntity> extends ECSLog {
  /// The entity that changed.
  final TEntity entity;

  const _EntityChanged({
    required super.time,
    required super.level,
    required this.entity,
    required super.stack,
  });

  @override
  String get description {
    final buffer = StringBuffer("[${entity.parent.runtimeType}.${entity.runtimeType}] ");
    if (entity is ECSComponent) {
      final component = entity as ECSComponent;
      final previous = component.buildDescriptor(component.previous);
      final current = component.buildDescriptor(component.value);
      buffer.write('updated ');
      buffer.write('from $previous ');
      buffer.write('to $current');
    } else {
      buffer.write('triggered');
    }
    return buffer.toString();
  }
}

/// Represents a system reacting to an entity change.
final class _SystemReacted<TSystem extends ReactiveSystem, TEvent extends ECSEntity> extends ECSLog {
  /// The system that reacted to the entity change.
  final TSystem system;

  /// The entity that triggered the reaction.
  final TEvent entity;

  const _SystemReacted({
    required super.time,
    required super.level,
    required this.system,
    required this.entity,
    required super.stack,
  });

  @override
  String get description {
    final buffer = StringBuffer('[${system.parent.runtimeType}.${system.runtimeType}] reacted to [${entity.parent.runtimeType}.${entity.runtimeType}] ');
    if (entity is ECSComponent) {
      final component = entity as ECSComponent;
      final previous = component.buildDescriptor(component.previous);
      final current = component.buildDescriptor(component.value);
      buffer.write('update ');
      buffer.write('from $previous ');
      buffer.write('to $current');
    } else {
      buffer.write('trigger');
    }
    return buffer.toString();
  }
}
