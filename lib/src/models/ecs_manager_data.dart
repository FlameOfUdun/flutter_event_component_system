part of '../ecs_base.dart';

final class ECSManagerData {
  final String identifier;
  final List<ECSFeatureData> features;
  final List<ECSLogData> logs;
  final bool isActive;

  const ECSManagerData({
    required this.identifier,
    required this.features,
    required this.logs,
    required this.isActive,
  });

  factory ECSManagerData.fromManager(ECSManager manager) {
    final features = <ECSFeatureData>[];
    for (final feature in manager.features) {
      features.add(ECSFeatureData.fromFeature(feature));
    }

    final logs = <ECSLogData>[];
    for (final log in manager.logs) {
      logs.add(ECSLogData.fromLog(log));
    }

    return ECSManagerData(
      identifier: manager.identifier,
      isActive: manager.isActive,
      features: features,
      logs: logs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'features': features.map((f) => f.toJson()).toList(),
      'logs': logs.map((l) => l.toJson()).toList(),
      'isActive': isActive,
    };
  }
}
