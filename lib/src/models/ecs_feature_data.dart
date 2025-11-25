part of '../ecs_base.dart';

final class ECSFeatureData {
  final String name;
  final List<ECSSystemData> systems;
  final List<ECSEntityData> entities;

  const ECSFeatureData({
    required this.name,
    required this.systems,
    required this.entities,
  });

  factory ECSFeatureData.fromFeature(ECSFeature feature) {
    final systems = <ECSSystemData>[];
    for (final system in feature.initializeSystems) {
      systems.add(ECSSystemData.fromSystem(system));
    }
    for (final system in feature.executeSystems) {
      systems.add(ECSSystemData.fromSystem(system));
    }
    for (final system in feature.cleanupSystems) {
      systems.add(ECSSystemData.fromSystem(system));
    }
    for (final system in feature.teardownSystems) {
      systems.add(ECSSystemData.fromSystem(system));
    }
    for (final system in feature.reactiveSystems) {
      systems.add(ECSSystemData.fromSystem(system));
    }

    final entities = <ECSEntityData>[];
    for (final entity in feature.entities) {
      entities.add(ECSEntityData.fromEntity(entity));
    }

    return ECSFeatureData(
      name: feature.runtimeType.toString(),
      systems: systems,
      entities: entities,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'systems': systems.map((s) => s.toJson()).toList(),
      'entities': entities.map((e) => e.toJson()).toList(),
    };
  }
}
