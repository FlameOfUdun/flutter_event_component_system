part of '../ecs_base.dart';

/// Base class for ECS systems.
sealed class ECSSystem {
  /// Set of cached entities for this system.
  @visibleForTesting
  Set<ECSEntity> entities = {};

  /// Set of types that this system interacts with.
  ///
  /// This set should be overridden in subclasses to specify the types of
  /// entities that this system can interact with.
  ///
  /// This is used to optimize the system's execution by filtering entities
  /// that are relevant to the system and avoid unnecessary processing.
  ///
  /// This is also used for debugging purposes to understand which entities
  /// are being processed by the system.
  Set<Type> get interactsWith => const {};

  /// The parent feature of this system.
  @visibleForTesting
  @protected
  ECSFeature? feature;

  ECSSystem();

  /// Indicates whether this system is active.
  @visibleForTesting
  @protected
  bool get isAttached => feature != null;

  /// Attaches this system to a feature.
  @visibleForTesting
  void attach(ECSFeature feature) {
    this.feature = feature;
  }

  /// Logs a message to the ECS manager's logger.
  @visibleForTesting
  @protected
  void log(String message, {ECSLogLevel level = ECSLogLevel.info}) {
    feature?.manager?.log(message, level: level);
  }

  /// Gets an entity of type [TEntity] from the ECS system.
  ///
  /// This function will search the internal cahced entities set first. If the entity
  /// is not found, it will be fetched from the parent feature. If the entity is not found
  /// in the parent feature, it will be fetched from the ECS manager and added to the
  /// internal cached entities set.
  ///
  /// Throws a [StateError] if the entity is not found in both the parent feature
  /// and the ECS manager.
  TEntity getEntity<TEntity extends ECSEntity>() {
    for (final entity in entities) {
      if (entity is TEntity) return entity;
    }
    TEntity entity;
    try {
      entity = feature!.getEntity<TEntity>();
    } catch (_) {
      entity = feature!.manager!.getEntity<TEntity>(
        excludeFeatures: {
          feature.runtimeType,
        },
      );
    }
    entities.add(entity);
    return entity;
  }
}

/// Base class for initialize systems.
///
/// Initialize systems are used to perform setup tasks.
///
/// The [initialize] method should be overridden in subclasses to perform
/// the actual initialization logic.
///
/// The [initialize] method is called once after the first frame is rendered and
/// before any other systems are executed.
abstract class InitializeSystem extends ECSSystem {
  InitializeSystem();

  /// Initialize logic for the system.
  @visibleForTesting
  void initialize();
}

/// Base class for cleanup systems.
///
/// Cleanup systems are used to perform cleanup tasks.
///
/// The [cleanup] method should be overridden in subclasses to perform the
/// actual cleanup logic.
///
/// The [cleanup] method is called after all [ExecuteSystem]s have been executed
/// and before the next frame is rendered.
abstract class CleanupSystem extends ECSSystem {
  CleanupSystem();

  /// Whether the system should be executed or not.
  ///
  /// This is used to determine whether the system should be executed on every
  /// frame.
  ///
  /// If this is set to `false`, the system will not be executed on each frame.
  bool get cleansIf => true;

  /// Cleanup logic for the system.
  @visibleForTesting
  void cleanup();
}

/// Base class for teardown systems.
///
/// Teardown systems are used to perform teardown tasks.
///
/// The [teardown] method should be overridden in subclasses to perform the
/// actual teardown logic.
///
/// The [teardown] method is called once after the last frame is rendered and
/// before the application is disposed.
abstract class TeardownSystem extends ECSSystem {
  TeardownSystem();

  /// Teardown logic for the system.
  @visibleForTesting
  void teardown();
}

/// Base class for execute systems.
///
/// Execute systems are used to perform tasks that need to be executed
/// periodically, such as updating the state of entities or processing events.
///
/// The [execute] method should be overridden in subclasses to perform the
/// actual execution logic.
///
/// The [execute] method is called every frame.
abstract class ExecuteSystem extends ECSSystem {
  ExecuteSystem();

  /// Whether the system should be executed or not.
  ///
  /// This is used to determine whether the system should be executed on every
  /// frame.
  ///
  /// If this is set to `false`, the system will not be executed on each frame.
  bool get executesIf => true;

  /// Execute logic for the system.
  @visibleForTesting
  void execute(Duration elapsed);
}

/// Base class for reactive systems.
///
/// Reactive systems are used to react to changes in entities.
///
/// The [react] method should be overridden in subclasses to perform the
/// actual reaction logic.
abstract class ReactiveSystem extends ECSSystem implements ECSEntityListener {
  /// Indicates whether this system is active.
  @visibleForTesting
  bool isActive = false;

  /// The set of entity types that this system reacts to.
  ///
  /// This set should be overridden in subclasses to specify the types of
  /// entities that this system reacts to.
  ///
  /// This is used to optimize the system's reaction by filtering entities
  /// that are relevant to the system and avoid unnecessary processing.
  ///
  /// This is also used for debugging purposes to understand which entities
  /// are being processed by the system.
  Set<Type> get reactsTo;

  /// Whether the system reacts to changes in entities.
  ///
  /// This is used to determine whether the system should be executed
  /// when an entity changes.
  ///
  /// If this is set to `false`, the system will not be executed
  /// when an entity changes, even if it is being watched.
  bool get reactsIf => true;

  /// Activates this system by adding listeners to the entities it reacts to.
  ///
  /// If the system is already active, this method does nothing.
  @visibleForTesting
  void activate() {
    if (isActive) return;
    for (final type in reactsTo) {
      final entity = feature!.manager!.getEntityOfType(type);
      entity.addListener(this);
    }
    isActive = true;
  }

  /// Deactivates this system by removing listeners from the entities it reacts to.
  ///
  /// If the system is not active, this method does nothing.
  @visibleForTesting
  void deactivate() {
    if (!isActive) return;
    for (final type in reactsTo) {
      final entity = feature!.manager!.getEntityOfType(type);
      entity.removeListener(this);
    }
    isActive = false;
  }

  @override
  void onEntityChanged(ECSEntity entity) {
    if (reactsIf) {
      if (entity is ECSComponent) {
        log('${feature.runtimeType}.$runtimeType reacted to changes in ${entity.feature.runtimeType}.${entity.runtimeType}');
      } else {
        log('${feature.runtimeType}.$runtimeType reacted to trigger of ${entity.runtimeType}');
      }
      react();
    }
  }

  @visibleForTesting
  void react();
}
