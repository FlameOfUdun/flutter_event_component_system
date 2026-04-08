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
    final String type;
    if (entity is ECSComponent) {
      type = 'Component';
    } else if (entity is ECSDataEvent) {
      type = 'DataEvent';
    } else if (entity is ECSEvent) {
      type = 'Event';
    } else {
      type = 'Dependency';
    }

    return ECSEntityData(
      identifier: entity.identifier,
      type: type,
      value: switch (entity) {
        ECSComponent<dynamic> e => e.describe(e.value),
        ECSDataEvent<dynamic> e when e.dataOrNull != null =>
          e.describe(e.dataOrNull),
        _ => null,
      },
      previous: switch (entity) {
        ECSComponent<dynamic> e => e.describe(e.previous),
        _ => null,
      },
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
