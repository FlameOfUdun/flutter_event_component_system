part of 'ecs_base.dart';

/// ECSFeature is a base class for creating features in the ECS system.
///
/// Features can contain entities and systems, and they provide a way to organize
/// and manage different parts of the ECS architecture.
abstract class ECSFeature {
  /// Map of entities in this feature, keyed by their type.
  final Map<Type, ECSEntity> entities = {};

  /// Set of initialize systems in this feature.
  final Set<ECSInitializeSystem> initializeSystems = {};

  /// Set of teardown systems in this feature.
  final Set<ECSTeardownSystem> teardownSystems = {};

  /// Set of cleanup systems in this feature.
  final Set<ECSCleanupSystem> cleanupSystems = {};

  /// Set of execute systems in this feature.
  final Set<ECSExecuteSystem> executeSystems = {};

  /// Map of reactive systems by entity type.
  final Set<ECSReactiveSystem> reactiveSystems = {};

  /// The manager that this feature is associated with.
  ECSManager? manager;

  /// Indicates whether this feature is active.
  @visibleForTesting
  bool isActive = false;

  ECSFeature();

  /// Indicates whether this feature is attached to a manager.
  bool get isAttached => manager != null;

  /// Unique identifier for this feature.
  String get identifier => manager != null ? "${manager!.identifier}.$runtimeType" : "$runtimeType";


  /// Number of systems in this feature.
  int get systemsCount {
    return initializeSystems.length + teardownSystems.length + reactiveSystems.length + cleanupSystems.length + executeSystems.length;
  }

  /// Indicates whether this feature has execute or cleanup systems.
  bool get hasExecuteOrCleanupSystems {
    return executeSystems.isNotEmpty || cleanupSystems.isNotEmpty;
  }

  /// Attaches this feature to an ECS manager.
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
  void addEntity(ECSEntity entity) {
    final existing = entities[entity.runtimeType];
    if (existing != null) {
      throw StateError("Entity of type ${entity.runtimeType} already exists in this feature");
    }
    entities[entity.runtimeType] = entity;
    entity.attach(this);
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
    bool registered = false;
    if (system is ECSInitializeSystem) {
      if (!initializeSystems.add(system)) {
        throw StateError("System of type ${system.runtimeType} is already added to this feature");
      }
      registered = true;
    }
    if (system is ECSTeardownSystem) {
      if (!teardownSystems.add(system)) {
        throw StateError("System of type ${system.runtimeType} is already added to this feature");
      }
      registered = true;
    }
    if (system is ECSCleanupSystem) {
      if (!cleanupSystems.add(system)) {
        throw StateError("System of type ${system.runtimeType} is already added to this feature");
      }
      registered = true;
    }
    if (system is ECSExecuteSystem) {
      if (!executeSystems.add(system)) {
        throw StateError("System of type ${system.runtimeType} is already added to this feature");
      }
      registered = true;
    }
    if (system is ECSReactiveSystem) {
      if (!reactiveSystems.add(system)) {
        throw StateError("System of type ${system.runtimeType} is already added to this feature");
      }
      registered = true;
    }
    if (!registered) {
      throw ArgumentError("System of type ${system.runtimeType} is not supported");
    }
    system.attach(this);
  }

  /// Activates all systems in this feature.
  void activate() {
    if (isActive) return;
    for (final system in reactiveSystems) {
      system.activate();
    }
    isActive = true;
  }

  /// Deactivates all systems in this feature.
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
  void initialize() {
    for (final system in initializeSystems) {
      system.initialize();
    }
  }

  /// Triggers all the teardown systems in this feature.
  void teardown() {
    for (final system in teardownSystems) {
      system.teardown();
    }
  }

  /// Triggers all the cleanup systems in this feature.
  void cleanup() {
    for (final system in cleanupSystems) {
      if (system.cleansIf) {
        system.cleanup();
      }
    }
  }

  /// Executes the features.
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
    final entity = entities[TEntity];
    if (entity == null) {
      throw StateError("Entity of type $TEntity not found");
    }
    return entity as TEntity;
  }

  /// Gets an entity of the specified [type].
  ///
  /// Throws a [StateError] if the entity is not found.
  @visibleForTesting
  ECSEntity getEntityOfType(Type type) {
    final entity = entities[type];
    if (entity == null) {
      throw StateError("Entity of type $type not found");
    }
    return entity;
  }
}
