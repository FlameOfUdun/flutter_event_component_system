part of '../ecs_base.dart';

final class ECSSystemData {
  final String name;
  final String type;
  final String feature;
  final List<String> interactsWith;
  final List<String> reactsTo;

  const ECSSystemData({
    required this.name,
    required this.type,
    required this.feature,
    this.interactsWith = const [],
    this.reactsTo = const [],
  });

  factory ECSSystemData.fromSystem(ECSSystem system) {
    final String type;
    if (system is InitializeSystem) {
      type = 'InitializeSystem';
    } else if (system is ExecuteSystem) {
      type = 'ExecuteSystem';
    } else if (system is CleanupSystem) {
      type = 'CleanupSystem';
    } else if (system is TeardownSystem) {
      type = 'TeardownSystem';
    } else {
      type = 'ReactiveSystem';
    }

    final reactsTo = <String>[];
    if (system is ReactiveSystem) {
      for (final type in system.reactsTo) {
        final entity = system.feature!.manager!.getEntityOfType(type);
        final identifier = '${entity.feature.runtimeType}.${entity.runtimeType}';
        reactsTo.add(identifier);
      }
    }

    final interactsWith = <String>[];
    for (final type in system.interactsWith) {
      final entity = system.feature!.manager!.getEntityOfType(type);
      final identifier = '${entity.feature.runtimeType}.${entity.runtimeType}';
      interactsWith.add(identifier);
    }

    return ECSSystemData(
      name: system.runtimeType.toString(),
      feature: system.feature.runtimeType.toString(),
      type: type,
      interactsWith: interactsWith,
      reactsTo: reactsTo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'feature': feature,
      'interactsWith': interactsWith,
      'reactsTo': reactsTo,
    };
  }
}
