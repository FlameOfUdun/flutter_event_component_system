part of '../ecs_base.dart';

/// ECSFeature is a base class for creating features in the ECS system.
final class ECSManager implements ECSEntityListener {
  final Set<ECSFeature> _features = {};

  @visibleForTesting
  ECSManager();

  /// Unmodifiable set of features in the ECS manager.
  Set<ECSFeature> get features {
    return Set.unmodifiable(_features);
  }

  /// Unmodifiable set of all entities across all features.
  Set<ECSEntity> get entities {
    final expanded = features.expand((feature) => feature.entities);
    return Set.unmodifiable(expanded);
  }

  /// Add a feature to the ECS manager.
  @visibleForTesting
  void addFeature(ECSFeature feature) {
    _features.add(feature);

    for (final entity in feature.entities) {
      entity.addListener(this);
    }
  }

  /// Initialize all features in the ECS manager.
  @visibleForTesting
  void initialize() {
    for (final feature in features) {
      feature.initialize();
    }
  }

  /// Teardown all features in the ECS manager.
  @visibleForTesting
  void teardown() {
    for (final feature in features) {
      feature.teardown();
    }
  }

  /// Execute all features in the ECS manager.
  @visibleForTesting
  void execute(Duration duration) {
    for (final feature in features) {
      feature.execute(duration);
    }
  }

  /// Cleanup all features in the ECS manager.
  @visibleForTesting
  void cleanup() {
    for (final feature in features) {
      feature.cleanup();
    }
  }

  @override
  @visibleForTesting
  void onEntityChanged(ECSEntity entity) {
    ECSLogger.logEntityChanged(entity);

    for (final feature in features) {
      feature.react(entity);
    }
  }

  /// Gets an entity of type [TEntity] from all features.
  ///
  /// Throws a [StateError] if the entity is not found.
  TEntity getEntity<TEntity extends ECSEntity>() {
    for (final feature in features) {
      final entity = feature.getEntity<TEntity>();
      if (entity != null) return entity;
    }

    throw StateError("Entity of type $TEntity not found");
  }

  /// Gets an entity of type [TEntity] from a specific feature [TFeature].
  ///
  /// Throws a [StateError] if the feature or entity is not found.
  TEntity getEntityFromFeature<TEntity extends ECSEntity, TFeature extends ECSFeature>() {
    ECSFeature? feature;
    for (final item in features) {
      if (item is TFeature) {
        feature = item;
        break;
      }
    }
    if (feature == null) {
      throw StateError("Feature of type $TFeature not found");
    }

    final entity = feature.getEntity<TEntity>();
    if (entity == null) {
      throw StateError("Entity of type $TEntity not found in feature $TFeature");
    }

    return entity;
  }
}
