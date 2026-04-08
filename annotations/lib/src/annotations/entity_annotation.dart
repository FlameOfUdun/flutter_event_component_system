/// Marks a top-level variable as an ECS component.
/// The variable's type is the component's value type.
/// The variable's initializer is the default value.
final class Component {
  final String? description;
  const Component({this.description});
}

/// Marks a top-level variable as an ECS dependency.
/// The variable's type is the dependency's value type.
/// The variable's initializer is the default value.
final class Dependency {
  final String? description;
  const Dependency({this.description});
}

/// Marks a top-level void function as an ECS event.
/// - Zero parameters → no-data event (ECSEvent)
/// - One parameter → data event (ECSDataEvent<T>) where T is the parameter type
/// The function body lists the systems that react to this event (declaration only).
final class Event {
  final String? description;
  const Event({this.description});
}
