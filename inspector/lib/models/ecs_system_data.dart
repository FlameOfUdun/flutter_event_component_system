final class ECSSystemData {
  final String identifier;
  final String type;
  final List<String> interactsWith;
  final List<String> reactsTo;

  const ECSSystemData({
    required this.identifier,
    required this.type,
    this.interactsWith = const [],
    this.reactsTo = const [],
  });

  factory ECSSystemData.fromJson(Map<String, dynamic> json) {
    return ECSSystemData(
      identifier: json['identifier'],
      type: json['type'],
      interactsWith: List<String>.from(json['interactsWith'] ?? []),
      reactsTo: List<String>.from(json['reactsTo'] ?? []),
    );
  }

  String get id => identifier;
}
