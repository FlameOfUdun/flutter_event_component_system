part of '../ecs_base.dart';

final class ECSInspectorData {
  final List<ECSManagerData> managers;

  const ECSInspectorData({
    required this.managers,
  });

  Map<String, dynamic> toJson() {
    return {
      'managers': managers.map((m) => m.toJson()).toList(),
    };
  }
}
