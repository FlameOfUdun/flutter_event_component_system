part of '../ecs_base.dart';

/// ECSFeature is a base class for creating features in the ECS system.
final class ECSManager implements ECSEntityListener {
  /// Set of features in the ECS manager.
  @visibleForTesting
  final Set<ECSFeature> features = {};

  ECSManager();

  /// Unmodifiable set of all entities across all features.
  Set<ECSEntity> get entities {
    final expanded = features.expand((feature) => feature.entities);
    return Set.unmodifiable(expanded);
  }

  /// Add a feature to the ECS manager.
  @visibleForTesting
  void addFeature(ECSFeature feature) {
    feature.setManager(this);
    features.add(feature);

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
      try {
        return feature.getEntity<TEntity>();
      } catch (_) {
        continue;
      }
    }

    throw StateError("Entity of type $TEntity not found");
  }
}
