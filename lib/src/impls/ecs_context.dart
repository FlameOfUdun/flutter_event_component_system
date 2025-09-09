part of '../ecs_base.dart';

/// Context for accessing ECS system from widgets.
final class ECSContext implements ECSEntityListener {
  /// The ECS manager instance.
  @visibleForTesting
  final ECSManager manager;

  /// Callback for notifying changes in the ECS context.
  @visibleForTesting
  final void Function() callback;

  /// Map of entity listeners.
  @visibleForTesting
  final Map<ECSEntity, void Function()> listeners = {};

  /// Set of entities being watched.
  @visibleForTesting
  final Set<ECSEntity> watchers = {};

  /// Optional listeners for enter event.
  @visibleForTesting
  void Function()? onEnterListener;

  /// Optional listeners for exit event.
  @visibleForTesting
  void Function()? onExitListener;

  /// Indicates if the context has been disposed.
  @visibleForTesting
  var disposed = false;

  /// Indicates if the context is currently locked for rebuilding.
  @visibleForTesting
  var locked = false;

  /// Set of commonly accessed entities by the ECS context.
  @visibleForTesting
  Set<ECSEntity> entities = {};

  @visibleForTesting
  ECSContext(this.manager, this.callback);

  /// Retrieves an entity of type [TEntity] from the ECS context.
  /// 
  /// This function will search the entities set first.
  /// If the entity is not found, it will be fetched from the ECS manager and added
  /// to the entities set. Otherwise, it will return the existing entity from the set.
  TEntity _getEntity<TEntity extends ECSEntity>() {
    for (final entity in entities) {
      if (entity is TEntity) return entity;
    }
    final entity = manager.getEntity<TEntity>();
    entities.add(entity);
    return entity;
  }

  /// Gets an entity of type [TEntity] from the ECS manager.
  TEntity get<TEntity extends ECSEntity>() {
    return _getEntity<TEntity>();
  }

  /// Watches an entity of type [TEntity] for changes.
  TEntity watch<TEntity extends ECSEntity>() {
    final entity = _getEntity<TEntity>();
    if (watchers.add(entity)) entity.addListener(this);
    return entity;
  }

  /// Listens to changes in an entity of type [TEntity].
  /// 
  /// The listener will be called whenever the entity changes.
  /// 
  /// If the entity is already being watched, it will be overridden.
  /// 
  /// Callbacks are executed asynchronously and safe to use in the widget tree.
  void listen<TEntity extends ECSEntity>(void Function(TEntity entity) listener) {
    final entity = _getEntity<TEntity>();
    if (!listeners.containsKey(entity)) entity.addListener(this);
    listeners[entity] = () => listener(entity);
  }

  /// Initializes the ECS context.
  @visibleForTesting
  void initialize() {
    Future.microtask(() {
      onEnterListener?.call();
      onEnterListener = null;
    });
  }

  /// Disposes the ECS context.
  @visibleForTesting
  void dispose() {
    disposed = true;

    entities.clear();

    for (final entity in watchers) {
      entity.removeListener(this);
    }
    watchers.clear();

    for (final entity in listeners.keys) {
      entity.removeListener(this);
    }
    listeners.clear();

    Future.microtask(() {
      onExitListener?.call();
      onExitListener = null;
    });
  }

  /// Rebuilds the ECS context.
  /// 
  /// This method is used to trigger a rebuild of the context.
  /// 
  /// If the context is locked, it will not rebuild until the lock is released.
  @visibleForTesting
  void rebuild() {
    if (locked) return;
    locked = true;

    callback();

    Future.microtask(() {
      locked = false;
    });
  }

  /// Callback for when entring the ECS context.
  void onEnter(void Function() function) {
    if (onEnterListener != null) return;
    onEnterListener = function;
  }

  /// Callback for when exiting the ECS context.
  void onExit(void Function() function) {
    if (onExitListener != null) return;
    onExitListener = function;
  }

  @override
  @visibleForTesting
  void onEntityChanged(ECSEntity entity) {
    if (watchers.contains(entity)) rebuild();

    final listener = listeners[entity];
    if (listener != null) Future.microtask(listener);
  }
}
