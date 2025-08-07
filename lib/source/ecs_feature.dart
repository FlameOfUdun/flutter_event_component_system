part of '../flutter_event_component_system.dart';

/// ECSFeature is a base class for creating features in the ECS system.
///
/// Features can contain entities and systems, and they provide a way to organize
/// and manage different parts of the ECS architecture.
abstract class ECSFeature {
  final Set<ECSEntity> _entities = {};
  final Set<InitializeSystem> _initializeSystems = {};
  final Set<TeardownSystem> _teardownSystems = {};
  final Set<CleanupSystem> _cleanupSystems = {};
  final Set<ExecuteSystem> _executeSystems = {};
  final Map<Type, Set<ReactiveSystem>> _reactiveSystems = {};

  ECSFeature();

  /// Unmodifiable set of entities in this feature.
  Set<ECSEntity> get entities {
    return Set.unmodifiable(_entities);
  }

  /// Unmodifiable sets of initialize systems in this feature.
  Set<InitializeSystem> get initializeSystems {
    return Set.unmodifiable(_initializeSystems);
  }

  /// Unmodifiable sets of teardown systems in this feature.
  Set<TeardownSystem> get teardownSystems {
    return Set.unmodifiable(_teardownSystems);
  }

  /// Unmodifiable sets of reactive systems in this feature.
  Set<CleanupSystem> get cleanupSystems {
    return Set.unmodifiable(_cleanupSystems);
  }

  /// Unmodifiable sets of execute systems in this feature.
  Set<ExecuteSystem> get executeSystems {
    return Set.unmodifiable(_executeSystems);
  }

  /// Unmodifiable map of reactive systems by entity type.
  Map<Type, Set<ReactiveSystem>> get reactiveSystems {
    return Map.unmodifiable(_reactiveSystems);
  }

  /// Number of systems in this feature.
  int get systemsCount {
    return initializeSystems.length + teardownSystems.length + reactiveSystems.length + cleanupSystems.length + executeSystems.length;
  }

  /// Add an entity to this feature.
  ///
  /// This method is protected and should be used by subclasses to add entities.
  ///
  /// If the entity is already added, it will not be added again.
  @protected
  @visibleForTesting
  void addEntity(ECSEntity entitiy) {
    entitiy.setParent(this);
    _entities.add(entitiy);
  }

  /// Adds a system to this feature.
  ///
  /// This method is protected and should be used by subclasses to add systems.
  ///
  /// If the system is already added, it will not be added again.
  @protected
  @visibleForTesting
  void addSystem(ECSSystem system) {
    if (system is InitializeSystem) {
      _initializeSystems.add(system);
    } else if (system is TeardownSystem) {
      _teardownSystems.add(system);
    } else if (system is CleanupSystem) {
      _cleanupSystems.add(system);
    } else if (system is ExecuteSystem) {
      _executeSystems.add(system);
    } else if (system is ReactiveSystem) {
      for (final entity in system.reactsTo) {
        _reactiveSystems.putIfAbsent(entity, () => {}).add(system);
      }
    } else {
      throw ArgumentError('Unsupported system type: ${system.runtimeType}');
    }
    system.setParent(this);
  }

  /// Initializes the features.
  @visibleForTesting
  void initialize() {
    for (final system in _initializeSystems) {
      system.initialize();
    }
  }

  /// Tears down the features.
  @visibleForTesting
  void teardown() {
    for (final system in _teardownSystems) {
      system.teardown();
    }
  }

  /// Cleans up the features.
  @visibleForTesting
  void cleanup() {
    for (final system in _cleanupSystems) {
      system.cleanup();
    }
  }

  /// Executes the features.
  @visibleForTesting
  void execute(Duration elapsed) {
    for (final system in _executeSystems) {
      if (system.executesIf) {
        system.execute(elapsed);
      }
    }
  }

  /// Reacts to an entity change.
  @visibleForTesting
  void react(ECSEntity entity) {
    final systems = reactiveSystems[entity.runtimeType];
    if (systems == null || systems.isEmpty) return;

    for (final system in systems) {
      if (system.reactsIf) {
        ECSLogger.logSystemReacted(system, entity);
        system.react();
      }
    }
  }

  /// Gets an entity of type [TEntity] from this feature if it exists.
  @visibleForTesting
  TEntity? getEntity<TEntity extends ECSEntity>() {
    for (final item in _entities) {
      if (item is TEntity) return item;
    }
    return null;
  }
}
