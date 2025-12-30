import 'ecs_manager_data.dart';

final class ECSInspectorData {
  final List<ECSManagerData> managers;

  const ECSInspectorData({required this.managers});

  factory ECSInspectorData.fromJson(Map<String, dynamic> json) {
    return ECSInspectorData(
      managers: (json['managers'] as List)
          .map((m) => ECSManagerData.fromJson(m))
          .toList(),
    );
  }
}
