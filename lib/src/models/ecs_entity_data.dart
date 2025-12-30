part of '../ecs_base.dart';

final class ECSEntityData {
  final String identifier;
  final String type;
  final String? value;
  final String? previous;

  const ECSEntityData({
    required this.identifier,
    required this.type,
    this.value,
    this.previous,
  });

  factory ECSEntityData.fromEntity(ECSEntity entity) {
    final type = entity is ECSEvent ? 'Event' : 'Component';

    return ECSEntityData(
      identifier: entity.identifier,
      type: type,
      value: entity is ECSComponent ? entity.describe(entity.value) : null,
      previous:
          entity is ECSComponent ? entity.describe(entity.previous) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'type': type,
      if (value != null) 'value': value,
      if (previous != null) 'previous': previous,
    };
  }
}
