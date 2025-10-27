import 'ecs_entity_data.dart';
import 'ecs_feature_data.dart';
import 'ecs_log_data.dart';

final class ECSManagerData {
  final List<ECSFeatureData> features;
  final List<ECSLogData> logs;

  const ECSManagerData({required this.features, this.logs = const []});

  factory ECSManagerData.fromJson(Map<String, dynamic> json) {
    return ECSManagerData(
      features: (json['features'] as List).map((f) => ECSFeatureData.fromJson(f)).toList(),
      logs: (json['logs'] as List).map((l) => ECSLogData.fromMap(l)).toList(),
    );
  }

  List<ECSEntityData> get entities {
    final allEntities = <ECSEntityData>[];
    for (final feature in features) {
      allEntities.addAll(feature.entities);
    }
    return allEntities;
  }

  ECSEntityData getEntity(String id) {
    for (final feature in features) {
      try {
        return feature.getEntity(id);
      } catch (_) {
        // Ignore
      }
    }
    throw Exception('Not found');
  }
}
