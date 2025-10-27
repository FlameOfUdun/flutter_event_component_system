part of '../ecs_base.dart';

/// ECSFeature is a base class for creating features in the ECS system.
final class ECSManager with ECSLogger {
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

  /// Whether any feature has execute or cleanup systems.
  bool get hasExecuteOrCleanup {
    for (final feature in features) {
      if (feature.executeSystems.isNotEmpty) {
        return true;
      }
      if (feature.cleanupSystems.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  /// Add a feature to the ECS manager.
  @visibleForTesting
  void addFeature(ECSFeature feature) {
    feature.attach(this);
    features.add(feature);
  }

  /// Remove a feature from the ECS manager.
  /// 
  /// Removed feature will be deactivated.
  @visibleForTesting
  void removeFeature(ECSFeature feature) {
    features.remove(feature);
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
    final filtered = features.where((feature) {
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
    for (final feature in features) {
      try {
        return feature.getEntityOfType(type);
      } catch (_) {
        continue;
      }
    }

    throw StateError("Entity of type $type not found");
  }
}
