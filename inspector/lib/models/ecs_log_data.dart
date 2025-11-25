final class ECSLogData {
  final String level;
  final String message;
  final DateTime time;
  final String? stack;

  const ECSLogData({
    required this.level,
    required this.message,
    required this.time,
    this.stack,
  });

  factory ECSLogData.fromMap(Map<String, dynamic> map) {
    return ECSLogData(
      level: map['level'] as String,
      message: map['message'] as String,
      time: DateTime.parse(map['time'] as String),
      stack: map['stack'] as String?,
    );
  }
}
