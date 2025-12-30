final class ECSEntityData {
  final String identifier;
  final String type;
  final String? value;
  final String? previous;

  const ECSEntityData({
    required this.identifier,
    required this.type,
    this.value,
    this.previous,
  });

  factory ECSEntityData.fromJson(Map<String, dynamic> json) {
    return ECSEntityData(
      identifier: json['identifier'],
      type: json['type'],
      value: json['value'],
      previous: json['previous'],
    );
  }

  String get id => identifier;
  bool get isComponent => type == 'Component';
  bool get isEvent => type == 'Event';
}
