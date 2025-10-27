part of '../ecs_base.dart';

final class ECSEntityData {
  final String name;
  final String type;
  final String feature;
  final String? value;
  final String? previous;

  const ECSEntityData({
    required this.name,
    required this.type,
    required this.feature,
    this.value,
    this.previous,
  });

  factory ECSEntityData.fromEntity(ECSEntity entity) {
    final type = entity is ECSEvent ? 'Event' : 'Component';

    return ECSEntityData(
      name: entity.runtimeType.toString(),
      feature: entity.feature.runtimeType.toString(),
      type: type,
      value: entity is ECSComponent ? entity.describe(entity.value) : null,
      previous: entity is ECSComponent ? entity.describe(entity.previous) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'feature': feature,
      if (value != null) 'value': value,
      if (previous != null) 'previous': previous,
    };
  }
}
