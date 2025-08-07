part of '../flutter_event_component_system.dart';

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

  @visibleForTesting
  ECSContext(this.manager, this.callback);

  /// Unmodifiable set of features in the ECS context.
  Set<ECSEntity> get entities {
    return manager.entities;
  }

  /// Gets an entity of type [TEntity] from the ECS manager.
  TEntity get<TEntity extends ECSEntity>() {
    return manager.getEntity<TEntity>();
  }

  /// Watches an entity of type [TEntity] for changes.
  TEntity watch<TEntity extends ECSEntity>() {
    final entity = manager.getEntity<TEntity>();
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
    final entity = manager.getEntity<TEntity>();
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
