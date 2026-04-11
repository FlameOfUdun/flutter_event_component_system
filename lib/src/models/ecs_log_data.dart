part of 'ecs_models.dart';

final class ECSLogData {
  final String time;
  final String level;
  final String message;
  final String? stack;
  final String? featureName;
  final String? systemName;

  const ECSLogData({
    required this.time,
    required this.level,
    required this.message,
    this.stack,
    this.featureName,
    this.systemName,
  });

  factory ECSLogData.fromLog(ECSLog log) {
    return ECSLogData(
      time: log.time.toIso8601String(),
      level: log.level.name,
      message: log.message,
      stack: log.stack.toString(),
      featureName: log.featureName,
      systemName: log.systemName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'level': level,
      'message': message,
      'stack': stack,
      if (featureName != null) 'featureName': featureName,
      if (systemName != null) 'systemName': systemName,
    };
  }
}
