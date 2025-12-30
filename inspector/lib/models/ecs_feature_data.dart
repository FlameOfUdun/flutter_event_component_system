import 'ecs_entity_data.dart';
import 'ecs_system_data.dart';

final class ECSFeatureData {
  final String identifier;
  final List<ECSSystemData> systems;
  final List<ECSEntityData> entities;

  const ECSFeatureData({
    required this.identifier,
    required this.systems,
    required this.entities,
  });

  factory ECSFeatureData.fromJson(Map<String, dynamic> json) {
    return ECSFeatureData(
      identifier: json['identifier'],
      systems: (json['systems'] as List)
          .map((s) => ECSSystemData.fromJson(s))
          .toList(),
      entities: (json['entities'] as List)
          .map((e) => ECSEntityData.fromJson(e))
          .toList(),
    );
  }

  String get id => identifier;

  ECSEntityData getEntity(String identifier) {
    for (final entity in entities) {
      if (entity.identifier == identifier) {
        return entity;
      }
    }
    throw Exception('Not found');
  }
}
