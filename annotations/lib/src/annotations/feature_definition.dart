final class FeatureDefinition {
  final String? name;
  final String? description;
  final void Function<TArgs>(TArgs args)? builder;

  const FeatureDefinition({this.name, this.description, this.builder});
}

final class FeatureReference {
  void addComponent(Object component) {}
  void addEvent(Object event) {}
  void addDataEvent(Object dataEvent) {}
  void addReactiveSystem(Object system) {}
}
