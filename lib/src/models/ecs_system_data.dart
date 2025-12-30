part of '../ecs_base.dart';

final class ECSSystemData {
  final String identifier;
  final String type;
  final List<String> interactsWith;
  final List<String> reactsTo;

  const ECSSystemData({
    required this.identifier,
    required this.type,
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
        reactsTo.add(entity.identifier);
      }
    }

    final interactsWith = <String>[];
    for (final type in system.interactsWith) {
      final entity = system.feature!.manager!.getEntityOfType(type);
      interactsWith.add(entity.identifier);
    }

    return ECSSystemData(
      identifier: system.identifier,
      type: type,
      interactsWith: interactsWith,
      reactsTo: reactsTo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'type': type,
      'interactsWith': interactsWith,
      'reactsTo': reactsTo,
    };
  }
}
