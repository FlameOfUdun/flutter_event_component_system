final class FeatureDefinition {
  final String? description;

  const FeatureDefinition({this.description});
}

final class FeatureReference {
  void addComponent(dynamic component) {}
  void addEvent(dynamic event) {}
  void addDataEvent(dynamic dataEvent) {}
  void addReactiveSystem(dynamic system) {}
}
