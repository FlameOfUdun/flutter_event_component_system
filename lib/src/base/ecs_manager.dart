part of 'ecs_base.dart';

/// ECSManager is a base class for managing features in the ECS system.
final class ECSManager with ECSLogger {
  /// An optional name for this ECS manager.
  final String? name;

  /// The unique index for this ECS manager.
  late final int index;

  /// Static set of all ECS managers.
  static final Set<ECSManager> _managers = {};

  /// Internal set of features in this ECS manager instance.
  final Set<ECSFeature> _features = {};

  /// Static flag that indicates if DevTools extensions have been registered.
  static bool _devtoolsRegistered = false;

  /// Static counter for generating unique manager indexes.
  static int _nextManagerIndex = 0;

  /// Indicates if the ECS manager is active.
  bool _isActive = false;

  ECSManager({
    this.name,
    Set<ECSFeature>? features,
  }) {
    _ensureDevtoolsRegistered();
    index = _nextManagerIndex++;
    if (features != null) {
      addFeatures(features);
    }
    activate();
  }

  /// Indicates if the ECS manager is active.
  bool get isActive => _isActive;

  /// Indicates if any feature has execute or cleanup systems.
  bool get hasExecuteOrCleanupSystems => _features.any((feature) => feature.hasExecuteOrCleanupSystems);

  /// Unmodifiable set of features in the ECS manager.
  Set<ECSFeature> get features => Set.unmodifiable(_features);

  /// Unmodifiable set of all entities across all features.
  Set<ECSEntity> get entities => Set.unmodifiable(features.expand((feature) => feature.entities.values));

  /// Unique identifier for this ECS manager.
  String get identifier => name ?? 'ECSManager_$index';

  /// Adds a feature to the ECS manager.
  void addFeature(ECSFeature feature) {
    feature.attach(this);
    _features.add(feature);
  }

  /// Adds multiple features to the ECS manager.
  void addFeatures(Set<ECSFeature> features) {
    for (final feature in features) {
      feature.attach(this);
      _features.add(feature);
    }
  }

  /// Registers DevTools extensions for ECS inspection.
  void _ensureDevtoolsRegistered() {
    if (_devtoolsRegistered) {
      return;
    }

    developer.registerExtension('ext.ecs.requestInspectorData', (method, parameters) async {
      final managers = _managers.map(ECSManagerData.fromManager).toList();
      final data = ECSInspectorData(managers: managers);
      final encoded = jsonEncode(data.toJson());
      return developer.ServiceExtensionResponse.result(encoded);
    });

    _devtoolsRegistered = true;
  }

  /// Activates the ECS manager and all its features.
  void activate() {
    if (_isActive) return;
    _managers.add(this);
    for (final feature in _features) {
      feature.activate();
    }
    _isActive = true;
  }

  /// Deactivates the ECS manager and all its features.
  void deactivate() {
    if (!_isActive) return;
    for (final feature in _features) {
      feature.deactivate();
    }
    _managers.remove(this);
    _isActive = false;
  }

  /// Calls initialize on all features.
  void initialize() {
    for (final feature in _features) {
      feature.initialize();
    }
  }

  /// Calls teardown on all features.
  void teardown() {
    for (final feature in _features) {
      feature.teardown();
    }
  }

  /// Calls cleanup on all features.
  void cleanup() {
    for (final feature in _features) {
      feature.cleanup();
    }
  }

  /// Calls execute on all features with the given [elapsed] duration.
  void execute(Duration elapsed) {
    for (final feature in _features) {
      feature.execute(elapsed);
    }
  }

  /// Gets an entity of type [TEntity] from all features.
  ///
  /// Throws a [StateError] if the entity is not found.
  ///
  /// Throws a [StateError] if the entity of type [TEntity] is not found.
  TEntity getEntity<TEntity extends ECSEntity>() {
    final current = _getEntityFromManager<TEntity>(this);
    if (current != null) {
      return current;
    }

    for (final manager in _managers) {
      if (manager == this) {
        continue;
      }

      final entity = _getEntityFromManager<TEntity>(manager);
      if (entity != null) {
        return entity;
      }
    }

    throw StateError("Entity of type $TEntity not found");
  }

  /// Helper function to get an entity of type [TEntity] from a specific [manager].
  TEntity? _getEntityFromManager<TEntity extends ECSEntity>(ECSManager manager) {
    for (final feature in manager._features) {
      final entity = feature.entities[TEntity];
      if (entity != null) {
        return entity as TEntity;
      }
    }
    return null;
  }

  /// Gets an entity of the specified [type] from all features.
  ///
  /// Throws a [StateError] if the entity of the specified [type] is not found.
  ECSEntity getEntityOfType(Type type) {
    final current = _getEntityOfTypeFromManager(this, type);
    if (current != null) {
      return current;
    }

    for (final manager in _managers) {
      if (manager == this) {
        continue;
      }

      final entity = _getEntityOfTypeFromManager(manager, type);
      if (entity != null) {
        return entity;
      }
    }

    throw StateError("Entity of type $type not found");
  }

  /// Helper function to get an entity of the specified [type] from a specific [manager].
  ECSEntity? _getEntityOfTypeFromManager(ECSManager manager, Type type) {
    for (final feature in manager._features) {
      final entity = feature.entities[type];
      if (entity != null) {
        return entity;
      }
    }
    return null;
  }
}
