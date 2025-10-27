final class ECSSystemData {
  final String feature;
  final String name;
  final String type;
  final List<String> interactsWith;
  final List<String> reactsTo;

  const ECSSystemData({required this.name, required this.feature, required this.type, this.interactsWith = const [], this.reactsTo = const []});

  factory ECSSystemData.fromJson(Map<String, dynamic> json) {
    return ECSSystemData(
      feature: json['feature'],
      name: json['name'],
      type: json['type'],
      interactsWith: List<String>.from(json['interactsWith'] ?? []),
      reactsTo: List<String>.from(json['reactsTo'] ?? []),
    );
  }

  String get id => '$feature.$name';
}
