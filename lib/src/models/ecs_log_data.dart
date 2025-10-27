part of '../ecs_base.dart';

final class ECSLogData {
  final String time;
  final String level;
  final String message;
  final String? stack;

  const ECSLogData({
    required this.time,
    required this.level,
    required this.message,
    this.stack,
  });

  factory ECSLogData.fromLog(ECSLog log) {
    return ECSLogData(
      time: log.time.toIso8601String(),
      level: log.level.name,
      message: log.message,
      stack: log.stack.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'level': level,
      'message': message,
      'stack': stack,
    };
  }
}
