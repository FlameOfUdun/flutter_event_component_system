part of 'ecs_base.dart';

/// Base class for ECS systems.
sealed class ECSSystem {
  /// Cached entities that this system interacts with.
  Map<Type, ECSEntity> entities = {};

  /// The parent feature of this system.
  ECSFeature? feature;

  ECSSystem();

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

  /// Unique identifier for this system.
  String get identifier => '${feature?.identifier}.$runtimeType';

  /// Indicates whether this system is active.
  @visibleForTesting
  @protected
  bool get isAttached => feature != null;

  /// Attaches this system to a feature.
  void attach(ECSFeature feature) {
    this.feature = feature;
  }

  /// Logs a message to the ECS manager's logger.
  @visibleForTesting
  @protected
  void log(String message, {ECSLogLevel level = ECSLogLevel.info}) {
    feature?.manager?.log(
      message,
      level: level,
      featureName: feature?.runtimeType.toString(),
      systemName: runtimeType.toString(),
    );
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
  @visibleForTesting
  @protected
  TEntity getEntity<TEntity extends ECSEntity>() {
    final cached = entities[TEntity];
    if (cached != null) {
      return cached as TEntity;
    }
    TEntity entity;
    try {
      entity = feature!.getEntity<TEntity>();
    } catch (_) {
      entity = feature!.manager!.getEntity<TEntity>();
    }
    entities[TEntity] = entity;
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
abstract class ECSInitializeSystem extends ECSSystem {
  /// Initialize logic for the system.
  void initialize();
}

/// Base class for cleanup systems.
///
/// Cleanup systems are used to perform cleanup tasks.
///
/// The [cleanup] method should be overridden in subclasses to perform the
/// actual cleanup logic.
///
/// The [cleanup] method is called after all [ECSExecuteSystem]s have been executed
/// and before the next frame is rendered.
abstract class ECSCleanupSystem extends ECSSystem {
  /// Whether the system should be executed or not.
  ///
  /// This is used to determine whether the system should be executed on every
  /// frame.
  ///
  /// If this is set to `false`, the system will not be executed on each frame.
  bool get cleansIf => true;

  /// Cleanup logic for the system.
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
abstract class ECSTeardownSystem extends ECSSystem {
  /// Teardown logic for the system.
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
abstract class ECSExecuteSystem extends ECSSystem {
  /// Whether the system should be executed or not.
  ///
  /// This is used to determine whether the system should be executed on every
  /// frame.
  ///
  /// If this is set to `false`, the system will not be executed on each frame.
  bool get executesIf => true;

  /// Execute logic for the system.
  void execute(Duration elapsed);
}

/// Base class for reactive systems.
///
/// Reactive systems are used to react to changes in entities.
///
/// The [react] method should be overridden in subclasses to perform the
/// actual reaction logic.
abstract class ECSReactiveSystem extends ECSSystem implements ECSEntityListener {
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
      if (entity is ECSListenableEntity) {
        entity.addListener(this);
      } else {
        log('Entity of type $type is not listenable and cannot be reacted to', level: ECSLogLevel.warning);
      }
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
      if (entity is ECSListenableEntity) {
        entity.removeListener(this);
      } else {
        log('Entity of type $type is not listenable and cannot be reacted to', level: ECSLogLevel.warning);
      }
    }
    isActive = false;
  }

  @override
  @visibleForTesting
  void onEntityChanged(ECSEntity entity) {
    if (reactsIf) {
      if (entity is ECSComponent) {
        log('$identifier reacted to changes in ${entity.identifier}');
      } else if (entity is ECSDataEvent) {
        log('$identifier reacted to trigger of ${entity.identifier}');
      } else if (entity is ECSEvent) {
        log('$identifier reacted to trigger of ${entity.identifier}');
      }
      react();
    }
  }

  @visibleForTesting
  void react();
}
