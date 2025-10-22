part of '../ecs_base.dart';

/// ECSFeature is a base class for creating features in the ECS system.
final class ECSManager implements ECSEntityListener {
  /// Set of features in the ECS manager.
  @visibleForTesting
  final Set<ECSFeature> features = {};

  @visibleForTesting
  ECSManager();

  /// Unmodifiable set of all entities across all features.
  @visibleForTesting
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

  /// Remove a feature from the ECS manager.
  @visibleForTesting
  void removeFeature(ECSFeature feature) {
    for (final entity in feature.entities) {
      entity.removeListener(this);
    }

    features.remove(feature);
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
    ECSLogger.log(_EntityChanged(
      time: DateTime.now(),
      level: ECSLogLevel.info,
      entity: entity,
      stack: StackTrace.current,
    ));

    for (final feature in features) {
      feature.react(entity);
    }
  }

  /// Gets an entity of type [TEntity] from all features.
  ///
  /// Throws a [StateError] if the entity is not found.
  /// 
  /// Optional [excludeFeatures] can be provided to skip certain feature types during the search.
  TEntity getEntity<TEntity extends ECSEntity>({
    Set<Type>? excludeFeatures,
  }) {
    final filtered = features.where((feature) {
      if (excludeFeatures != null ) {
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
}
