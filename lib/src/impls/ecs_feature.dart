part of '../ecs_base.dart';

/// ECSFeature is a base class for creating features in the ECS system.
///
/// Features can contain entities and systems, and they provide a way to organize
/// and manage different parts of the ECS architecture.
abstract class ECSFeature {
  /// Set of entities in this feature.
  @visibleForTesting
  final Set<ECSEntity> entities = {};

  /// Set of initialize systems in this feature.
  @visibleForTesting
  final Set<InitializeSystem> initializeSystems = {};

  /// Set of teardown systems in this feature.
  @visibleForTesting
  final Set<TeardownSystem> teardownSystems = {};

  /// Set of cleanup systems in this feature.
  @visibleForTesting
  final Set<CleanupSystem> cleanupSystems = {};

  /// Set of execute systems in this feature.
  @visibleForTesting
  final Set<ExecuteSystem> executeSystems = {};

  /// Map of reactive systems by entity type.
  @visibleForTesting
  final Map<Type, Set<ReactiveSystem>> reactiveSystems = {};

  /// The manager that this feature is associated with.
  @visibleForTesting
  @protected
  late ECSManager manager;

  ECSFeature();

  /// Number of systems in this feature.
  @visibleForTesting
  int get systemsCount {
    return initializeSystems.length + teardownSystems.length + reactiveSystems.length + cleanupSystems.length + executeSystems.length;
  }

  /// Sets the manager for this feature.
  @visibleForTesting
  void setManager(ECSManager manager) {
    this.manager = manager;
  }

  /// Add an entity to this feature.
  ///
  /// This method is protected and should be used by subclasses to add entities.
  ///
  /// If the entity is already added, it will not be added again.
  @protected
  @visibleForTesting
  void addEntity(ECSEntity entitiy) {
    entitiy.setFeature(this);
    entities.add(entitiy);
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
      initializeSystems.add(system);
    } else if (system is TeardownSystem) {
      teardownSystems.add(system);
    } else if (system is CleanupSystem) {
      cleanupSystems.add(system);
    } else if (system is ExecuteSystem) {
      executeSystems.add(system);
    } else if (system is ReactiveSystem) {
      for (final entity in system.reactsTo) {
        reactiveSystems.putIfAbsent(entity, () => {}).add(system);
      }
    } else {
      throw ArgumentError('Unsupported system type: ${system.runtimeType}');
    }
    system.setFeature(this);
  }

  /// Initializes the features.
  @visibleForTesting
  void initialize() {
    for (final system in initializeSystems) {
      system.initialize();
    }
  }

  /// Tears down the features.
  @visibleForTesting
  void teardown() {
    for (final system in teardownSystems) {
      system.teardown();
    }
  }

  /// Cleans up the features.
  @visibleForTesting
  void cleanup() {
    for (final system in cleanupSystems) {
      system.cleanup();
    }
  }

  /// Executes the features.
  @visibleForTesting
  void execute(Duration elapsed) {
    for (final system in executeSystems) {
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
  TEntity getEntity<TEntity extends ECSEntity>() {
    for (final entity in entities) {
      if (entity is TEntity) {
        return entity;
      }
    }

    throw StateError("Entity of type $TEntity not found");
  }
}
