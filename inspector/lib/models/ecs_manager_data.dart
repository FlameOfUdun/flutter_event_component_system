import 'ecs_entity_data.dart';
import 'ecs_feature_data.dart';
import 'ecs_log_data.dart';

final class ECSManagerData {
  final String identifier;
  final List<ECSFeatureData> features;
  final List<ECSLogData> logs;
  final bool isActive;

  const ECSManagerData({
    required this.identifier,
    required this.features,
    this.logs = const [],
    this.isActive = false,
  });

  factory ECSManagerData.fromJson(Map<String, dynamic> json) {
    return ECSManagerData(
      identifier: json['identifier'],
      features: (json['features'] as List)
          .map((f) => ECSFeatureData.fromJson(f))
          .toList(),
      logs: (json['logs'] as List).map((l) => ECSLogData.fromMap(l)).toList(),
      isActive: json['isActive'] ?? false,
    );
  }

  List<ECSEntityData> get entities {
    final allEntities = <ECSEntityData>[];
    for (final feature in features) {
      allEntities.addAll(feature.entities);
    }
    return allEntities;
  }

  ECSEntityData getEntity(String identifier) {
    for (final feature in features) {
      try {
        return feature.getEntity(identifier);
      } catch (_) {
        // Ignore
      }
    }
    throw Exception('Not found');
  }
}
