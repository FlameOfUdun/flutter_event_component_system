final class ReactiveSystemDefinition {
  final String? name;
  final String? description;
  final Set<Object> reactsTo;
  final Set<Object> interactsWith;
  final bool Function(SystemReference system)? reactsIf;

  const ReactiveSystemDefinition({
    this.name,
    this.description,
    required this.reactsTo,
    this.interactsWith = const {},
    this.reactsIf,
  });
}

sealed class EntityReference<T> {
  T get value;
}

final class ComponentReference<T> {
  const ComponentReference(T referece);

  void update(T value) {}
  set value(T value) => update(value);
  T get value => Object() as T;
  T? get previousValue => null;
}

final class DataEventReference<T> {
  const DataEventReference(T referece);

  T? get data => Object() as T?;
  void trigger(T data) {}
}

final class EventReference {
  const EventReference(Object referece);

  void trigger() {}
}

final class SystemReference {
  ComponentReference<T> getComponent<T>(T component) {
    return ComponentReference<T>(component);
  }

  DataEventReference<T> getDataEvent<T>(T event) {
    return DataEventReference<T>(event);
  }

  EventReference getEvent(Object event) {
    return EventReference(event);
  }
}
