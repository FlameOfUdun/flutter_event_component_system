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
  bool disposed = false;

  /// Indicates if the context is currently locked for rebuilding.
  @visibleForTesting
  bool locked = false;

  /// Set of commonly accessed entities by the ECS context.
  @visibleForTesting
  Set<ECSEntity> entities = {};

  /// Queue of callbacks to be executed.
  @visibleForTesting
  List<void Function()> queue = [];

  /// Indicates if a queue is currently running.
  @visibleForTesting
  bool isRunning = false;

  /// Indicates if onEnter has been set.
  @visibleForTesting
  bool onEnterSet = false;

  /// Indicates if onExit has been set.
  @visibleForTesting
  bool onExitSet = false;

  @visibleForTesting
  ECSContext(this.manager, this.callback);

  /// Retrieves an entity of type [TEntity] from the ECS context.
  ///
  /// This function will search the cached entities set first.
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
  ///
  /// If a [condition] is provided, the context will only rebuild when the condition is met.
  TEntity watch<TEntity extends ECSEntity>([bool Function(TEntity entity)? condition]) {
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
    if (onEnterListener != null) {
      enqueue(onEnterListener!);
    }
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

    if (onExitListener != null) {
      enqueue(onExitListener!);
    }
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
    guard(
      callback,
      description: 'ECSContext rebuild callback',
    );
    scheduleMicrotask(() {
      locked = false;
    });
  }

  /// Callback for when entring the ECS context.
  void onEnter(void Function() function) {
    if (onEnterSet) return;
    onEnterSet = true;
    onEnterListener = function;
  }

  /// Callback for when exiting the ECS context.
  void onExit(void Function() function) {
    if (onExitSet) return;
    onExitSet = true;
    onExitListener = function;
  }

  @override
  @visibleForTesting
  void onEntityChanged(ECSEntity entity) {
    if (watchers.contains(entity)) {
      rebuild();
    }

    if (listeners.containsKey(entity)) {
      enqueue(listeners[entity]!);
    }
  }

  /// Enqueues a function to be executed asynchronously.
  @visibleForTesting
  void enqueue(void Function() function) {
    queue.add(function);

    if (isRunning) return;
    isRunning = true;

    scheduleMicrotask(() async {
      while (queue.isNotEmpty) {
        final callbacks = List<void Function()>.from(queue);
        queue.clear();

        for (final callback in callbacks) {
          guard(
            callback,
            description: 'ECSContext queued callback',
          );
        }
      }

      isRunning = false;
    });
  }

  /// Runs a function safely, catching and reporting any errors.
  @visibleForTesting
  void guard(
    void Function() function, {
    required String description,
  }) {
    try {
      function();
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'ECSContext',
        context: ErrorDescription(description),
      ));
    }
  }
}
