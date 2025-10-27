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
  final Set<ReactiveSystem> reactiveSystems = {};

  /// The manager that this feature is associated with.
  @visibleForTesting
  @protected
  ECSManager? manager;

  /// Indicates whether this feature is active.
  @visibleForTesting
  bool isActive = false;

  ECSFeature();

  /// Indicates whether this feature is attached to a manager.
  bool get isAttached => manager != null;

  /// Number of systems in this feature.
  @visibleForTesting
  int get systemsCount {
    return initializeSystems.length + teardownSystems.length + reactiveSystems.length + cleanupSystems.length + executeSystems.length;
  }

  /// Attaches this feature to an ECS manager.
  @visibleForTesting
  void attach(ECSManager manager) {
    this.manager = manager;
  }

  /// Add an entity to this feature.
  ///
  /// This method is protected and should be used by subclasses to add entities.
  ///
  /// If the entity is already added, it will not be added again.
  ///
  /// Throws a [StateError] if the feature is already active.
  @protected
  @visibleForTesting
  void addEntity(ECSEntity entitiy) {
    entities.add(entitiy);
    entitiy.attach(this);
  }

  /// Adds a system to this feature.
  ///
  /// This method is protected and should be used by subclasses to add systems.
  ///
  /// If the system is already added, it will not be added again.
  ///
  /// Throws a [StateError] if the feature is already active.
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
      reactiveSystems.add(system);
    } else {
      throw ArgumentError("System of type ${system.runtimeType} is not supported");
    }
    system.attach(this);
  }

  /// Activates all systems in this feature.
  @visibleForTesting
  void activate() {
    if (isActive) return;
    for (final system in reactiveSystems) {
      system.activate();
    }
    isActive = true;
  }

  /// Deactivates all systems in this feature.
  @visibleForTesting
  void deactivate() {
    if (!isActive) return;
    for (final system in reactiveSystems) {
      system.deactivate();
    }
    isActive = false;
  }

  /// Triggers all the initialize systems in this feature.
  ///
  /// Throws a [StateError] if the feature is not active.
  @visibleForTesting
  void initialize() {
    for (final system in initializeSystems) {
      system.initialize();
    }
  }

  /// Triggers all the teardown systems in this feature.
  @visibleForTesting
  void teardown() {
    for (final system in teardownSystems) {
      system.teardown();
    }
  }

  /// Triggers all the cleanup systems in this feature.
  @visibleForTesting
  void cleanup() {
    for (final system in cleanupSystems) {
      if (system.cleansIf) {
        system.cleanup();
      }
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

  /// Gets an entity of type [TEntity] from this feature if it exists.
  ///
  /// Throws a [StateError] if the entity is not found.
  TEntity getEntity<TEntity extends ECSEntity>() {
    for (final entity in entities) {
      if (entity is TEntity) {
        return entity;
      }
    }
    throw StateError("Entity of type $TEntity not found");
  }

  /// Gets an entity of the specified [type].
  ///
  /// Throws a [StateError] if the entity is not found.
  @visibleForTesting
  ECSEntity getEntityOfType(Type type) {
    for (final entity in entities) {
      if (entity.runtimeType == type) {
        return entity;
      }
    }
    throw StateError("Entity of type $type not found");
  }
}
