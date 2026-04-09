/// Marks a top-level variable as an ECS component.
final class Component {
  final String? description;
  const Component({this.description});
}

/// Marks a top-level variable as an ECS dependency.
final class Dependency {
  final String? description;
  const Dependency({this.description});
}

/// Marks a top-level void function as an ECS event.
/// - Zero parameters → no-data event (ECSEvent)
/// - One parameter → data event (ECSDataEvent&lt;T&gt;) where T is the parameter type
final class Event {
  final String? description;
  const Event({this.description});
}
