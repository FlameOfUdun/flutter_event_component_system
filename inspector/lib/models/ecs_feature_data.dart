import 'ecs_entity_data.dart';
import 'ecs_system_data.dart';

final class ECSFeatureData {
  final String name;
  final List<ECSSystemData> systems;
  final List<ECSEntityData> entities;

  const ECSFeatureData({required this.name, required this.systems, required this.entities});

  factory ECSFeatureData.fromJson(Map<String, dynamic> json) {
    return ECSFeatureData(
      name: json['name'],
      systems: (json['systems'] as List).map((s) => ECSSystemData.fromJson(s)).toList(),
      entities: (json['entities'] as List).map((e) => ECSEntityData.fromJson(e)).toList(),
    );
  }

  String get id {
    return name;
  }

  ECSEntityData getEntity(String id) {
    for (final entity in entities) {
      if (entity.feature == id) {
        return entity;
      }
    }
    throw Exception('Not found');
  }
}
