part of '../ecs_base.dart';

final class ECSManagerData {
  final List<ECSFeatureData> features;
  final List<ECSLogData> logs;

  const ECSManagerData({
    required this.features,
    required this.logs,
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
      features: features,
      logs: logs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'features': features.map((f) => f.toJson()).toList(),
      'logs': logs.map((l) => l.toJson()).toList(),
    };
  }
}
