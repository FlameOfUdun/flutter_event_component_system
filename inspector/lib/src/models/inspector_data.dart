/// Data models for the ECS Inspector.
/// These models represent the serialized state from the ECS library.
library;

enum EntityType { component, event }

enum LogLevel { verbose, debug, info, warning, error, fatal }

/// Represents a single entity (Component or Event) in the ECS system.
class EntityData {
  final String identifier;
  final EntityType type;
  final String? value;
  final String? previous;
  final String featureName;
  final String managerName;

  const EntityData({
    required this.identifier,
    required this.type,
    this.value,
    this.previous,
    required this.featureName,
    required this.managerName,
  });

  /// Extract the name from the identifier (last part after the last dot).
  String get name {
    final parts = identifier.split('.');
    return parts.isNotEmpty ? parts.last : identifier;
  }

  bool get isComponent => type == EntityType.component;
  bool get isEvent => type == EntityType.event;

  factory EntityData.fromJson(Map<String, dynamic> json, String featureName, String managerName) {
    return EntityData(
      identifier: json['identifier'] as String,
      type: json['type'] == 'Component' ? EntityType.component : EntityType.event,
      value: json['value'] as String?,
      previous: json['previous'] as String?,
      featureName: featureName,
      managerName: managerName,
    );
  }

  Map<String, dynamic> toJson() => {
    'identifier': identifier,
    'type': type == EntityType.component ? 'Component' : 'Event',
    if (value != null) 'value': value,
    if (previous != null) 'previous': previous,
  };
}

/// Represents a system in the ECS framework.
class SystemData {
  final String identifier;
  final String type;
  final List<String> reactsTo;
  final List<String> interactsWith;
  final String featureName;
  final String managerName;

  const SystemData({
    required this.identifier,
    required this.type,
    required this.reactsTo,
    required this.interactsWith,
    required this.featureName,
    required this.managerName,
  });

  /// Extract the name from the identifier (last part after the last dot).
  String get name {
    final parts = identifier.split('.');
    return parts.isNotEmpty ? parts.last : identifier;
  }

  factory SystemData.fromJson(Map<String, dynamic> json, String featureName, String managerName) {
    return SystemData(
      identifier: json['identifier'] as String,
      type: json['type'] as String,
      reactsTo: (json['reactsTo'] as List<dynamic>?)?.cast<String>() ?? [],
      interactsWith: (json['interactsWith'] as List<dynamic>?)?.cast<String>() ?? [],
      featureName: featureName,
      managerName: managerName,
    );
  }

  Map<String, dynamic> toJson() => {
    'identifier': identifier,
    'type': type,
    'reactsTo': reactsTo,
    'interactsWith': interactsWith,
  };
}

/// Represents a feature (module) in the ECS framework.
class FeatureData {
  final String identifier;
  final List<EntityData> entities;
  final List<SystemData> systems;
  final String managerName;

  const FeatureData({
    required this.identifier,
    required this.entities,
    required this.systems,
    required this.managerName,
  });

  /// Extract the name from the identifier (last part after the last dot).
  String get name {
    final parts = identifier.split('.');
    return parts.isNotEmpty ? parts.last : identifier;
  }

  factory FeatureData.fromJson(Map<String, dynamic> json, String managerName) {
    final identifier = json['identifier'] as String;
    // Extract feature name from identifier for child entities/systems
    final featureName = identifier.split('.').last;
    return FeatureData(
      identifier: identifier,
      entities: (json['entities'] as List<dynamic>?)
          ?.map((e) => EntityData.fromJson(e as Map<String, dynamic>, featureName, managerName))
          .toList() ?? [],
      systems: (json['systems'] as List<dynamic>?)
          ?.map((s) => SystemData.fromJson(s as Map<String, dynamic>, featureName, managerName))
          .toList() ?? [],
      managerName: managerName,
    );
  }

  EntityData? getEntity(String identifier) {
    try {
      return entities.firstWhere((e) => e.identifier == identifier);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'identifier': identifier,
    'entities': entities.map((e) => e.toJson()).toList(),
    'systems': systems.map((s) => s.toJson()).toList(),
  };
}

/// Represents a log entry from the ECS system.
class LogData {
  final String message;
  final LogLevel level;
  final DateTime timestamp;
  final String? stack;
  final String? featureName;
  final String? systemName;

  const LogData({
    required this.message,
    required this.level,
    required this.timestamp,
    this.stack,
    this.featureName,
    this.systemName,
  });

  /// Get call stack as a list of frames.
  List<String> get callStack {
    if (stack == null || stack!.isEmpty) return [];
    return stack!.split('\n').where((line) => line.trim().isNotEmpty).toList();
  }

  factory LogData.fromJson(Map<String, dynamic> json) {
    return LogData(
      message: json['message'] as String? ?? '',
      level: _parseLogLevel(json['level'] as String?),
      timestamp: DateTime.tryParse(json['time'] as String? ?? '') ?? DateTime.now(),
      stack: json['stack'] as String?,
      featureName: json['featureName'] as String?,
      systemName: json['systemName'] as String?,
    );
  }

  static LogLevel _parseLogLevel(String? level) {
    return switch (level?.toLowerCase()) {
      'verbose' => LogLevel.verbose,
      'debug' => LogLevel.debug,
      'info' => LogLevel.info,
      'warning' => LogLevel.warning,
      'error' => LogLevel.error,
      'fatal' => LogLevel.fatal,
      _ => LogLevel.info,
    };
  }

  Map<String, dynamic> toJson() => {
    'message': message,
    'level': level.name,
    'time': timestamp.toIso8601String(),
    'stack': stack,
    'featureName': featureName,
    'systemName': systemName,
  };
}

/// Represents an ECS Manager instance.
class ManagerData {
  final String identifier;
  final List<FeatureData> features;
  final List<LogData> logs;
  final bool isActive;

  const ManagerData({
    required this.identifier,
    required this.features,
    required this.logs,
    this.isActive = false,
  });

  /// Extract the name from the identifier (last part after the last dot).
  String get name {
    final parts = identifier.split('.');
    return parts.isNotEmpty ? parts.last : identifier;
  }

  factory ManagerData.fromJson(Map<String, dynamic> json) {
    final identifier = json['identifier'] as String;
    // Extract manager name from identifier for child features
    final managerName = identifier.split('.').last;
    return ManagerData(
      identifier: identifier,
      features: (json['features'] as List<dynamic>?)
          ?.map((f) => FeatureData.fromJson(f as Map<String, dynamic>, managerName))
          .toList() ?? [],
      logs: (json['logs'] as List<dynamic>?)
          ?.map((l) => LogData.fromJson(l as Map<String, dynamic>))
          .toList() ?? [],
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  /// Get all entities across all features.
  List<EntityData> get allEntities {
    return features.expand((f) => f.entities).toList();
  }

  /// Get all systems across all features.
  List<SystemData> get allSystems {
    return features.expand((f) => f.systems).toList();
  }

  Map<String, dynamic> toJson() => {
    'identifier': identifier,
    'features': features.map((f) => f.toJson()).toList(),
    'logs': logs.map((l) => l.toJson()).toList(),
    'isActive': isActive,
  };
}

/// Root data structure for the inspector.
class InspectorData {
  final List<ManagerData> managers;
  final DateTime fetchedAt;

  InspectorData({
    required this.managers,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  factory InspectorData.fromJson(Map<String, dynamic> json) {
    return InspectorData(
      managers: (json['managers'] as List<dynamic>?)
          ?.map((m) => ManagerData.fromJson(m as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  /// Get all entities across all managers and features.
  List<EntityData> get allEntities {
    return managers.expand((m) => m.allEntities).toList();
  }

  /// Get all systems across all managers and features.
  List<SystemData> get allSystems {
    return managers.expand((m) => m.allSystems).toList();
  }

  /// Get all logs across all managers.
  List<LogData> get allLogs {
    return managers.expand((m) => m.logs).toList();
  }

  /// Get all feature names.
  Set<String> get featureNames {
    return managers.expand((m) => m.features.map((f) => f.name)).toSet();
  }

  /// Get all manager names.
  Set<String> get managerNames {
    return managers.map((m) => m.name).toSet();
  }

  /// Empty inspector data.
  static final empty = InspectorData(managers: []);

  bool get isEmpty => managers.isEmpty;
  bool get isNotEmpty => managers.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'managers': managers.map((m) => m.toJson()).toList(),
  };
}
