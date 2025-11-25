part of '../ecs_base.dart';

/// ECSFeature is a base class for creating features in the ECS system.
final class ECSManager with _ECSLogger {
  /// Static set of all features in every ECS manager.
  static final Set<ECSFeature> _allFeatures = {};

  /// Indicates if the ECS manager is active.
  bool _isActive = false;

  /// Internal set of features in this ECS manager instance.
  final Set<ECSFeature> _features = {};

  /// Indicates if DevTools extensions have been registered.
  static bool _devtoolsRegistered = false;

  @visibleForTesting
  ECSManager() {
    _ensureDevtoolsRegistered(this);
  }

  /// Indicates if the ECS manager is active.
  @visibleForTesting
  bool get isActive => _isActive;

  /// Indicates if any feature has execute or cleanup systems.
  bool get hasExecuteOrCleanupSystems => _features.any((feature) => feature.hasExecuteOrCleanupSystems);

  /// Unmodifiable set of features in the ECS manager.
  @visibleForTesting
  Set<ECSFeature> get features => Set.unmodifiable(_features);

  /// Unmodifiable set of all entities across all features.
  @visibleForTesting
  Set<ECSEntity> get entities => Set.unmodifiable(features.expand((feature) => feature.entities));

  /// Unmodifiable set of all entities across all features.
  void addFeature(ECSFeature feature) {
    feature.attach(this);
    _features.add(feature);
  }

  /// Registers DevTools extensions for ECS inspection.
  void _ensureDevtoolsRegistered(ECSManager manager) {
    if (_devtoolsRegistered) return;
    developer.registerExtension('ext.ecs.requestManagerData', (method, parameters) async {
      final features = <ECSFeatureData>[];
      for (final feature in _allFeatures) {
        features.add(ECSFeatureData.fromFeature(feature));
      }
      final logs = <ECSLogData>[];
      for (final log in manager.logs) {
        logs.add(ECSLogData.fromLog(log));
      }
      final data = ECSManagerData(
        features: features,
        logs: logs,
      );
      final encoded = jsonEncode(data.toJson());
      return developer.ServiceExtensionResponse.result(encoded);
    });
    _devtoolsRegistered = true;
  }

  /// Activates the ECS manager and all its features.
  @visibleForTesting
  void activate() {
    if (_isActive) return;
    for (final feature in _features) {
      _allFeatures.add(feature);
    }
    for (final feature in _features) {
      feature.activate();
    }
    _isActive = true;
  }

  /// Deactivates the ECS manager and all its features.
  @visibleForTesting
  void deactivate() {
    if (!_isActive) return;
    for (final feature in _features) {
      feature.deactivate();
    }
    for (final feature in _features) {
      _allFeatures.remove(feature);
    }
    _isActive = false;
  }

  /// Calls initialize on all features.
  @visibleForTesting
  void initialize() {
    for (final feature in _features) {
      feature.initialize();
    }
  }

  /// Calls teardown on all features.
  @visibleForTesting
  void teardown() {
    for (final feature in _features) {
      feature.teardown();
    }
  }

  /// Calls cleanup on all features.
  @visibleForTesting
  void cleanup() {
    for (final feature in _features) {
      feature.cleanup();
    }
  }

  /// Calls execute on all features with the given [elapsed] duration.
  @visibleForTesting
  void execute(Duration elapsed) {
    for (final feature in _features) {
      feature.execute(elapsed);
    }
  }

  /// Gets an entity of type [TEntity] from all features.
  ///
  /// Throws a [StateError] if the entity is not found.
  ///
  /// Optional [excludeFeatures] can be provided to skip certain feature types during the search.
  ///
  /// Throws a [StateError] if the entity of type [TEntity] is not found.
  TEntity getEntity<TEntity extends ECSEntity>({
    Set<Type>? excludeFeatures,
  }) {
    final filtered = _allFeatures.where((feature) {
      if (excludeFeatures != null) {
        if (excludeFeatures.contains(feature.runtimeType)) {
          return false;
        }
      }
      return true;
    });
    for (final feature in filtered) {
      try {
        return feature.getEntity<TEntity>();
      } catch (_) {
        continue;
      }
    }
    throw StateError("Entity of type $TEntity not found");
  }

  /// Gets an entity of the specified [type] from all features.
  ///
  /// Throws a [StateError] if the entity of the specified [type] is not found.
  @visibleForTesting
  ECSEntity getEntityOfType(Type type) {
    for (final feature in _allFeatures) {
      try {
        return feature.getEntityOfType(type);
      } catch (_) {
        continue;
      }
    }
    throw StateError("Entity of type $type not found");
  }
}
