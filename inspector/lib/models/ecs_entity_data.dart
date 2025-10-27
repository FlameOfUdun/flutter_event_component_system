final class ECSEntityData {
  final String feature;
  final String name;
  final String type;
  final String? value;
  final String? previous;

  const ECSEntityData({required this.name, required this.type, required this.feature, this.value, this.previous});

  factory ECSEntityData.fromJson(Map<String, dynamic> json) {
    return ECSEntityData(name: json['name'], type: json['type'], feature: json['feature'], value: json['value'], previous: json['previous']);
  }

  String get id => '$feature.$name';
  bool get isComponent => type == 'Component';
  bool get isEvent => type == 'Event';
}
