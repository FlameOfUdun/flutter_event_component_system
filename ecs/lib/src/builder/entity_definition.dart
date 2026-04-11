part of 'ecs_builder.dart';

sealed class EntityDefinition {}

sealed class ListenableEntityDefinition extends EntityDefinition {}

final class ComponentDefinition<T> extends ListenableEntityDefinition {
  ComponentDefinition._(T value);

  DateTime? get updatedAt => throw UnimplementedError();

  T? get previous => throw UnimplementedError();

  T get value => throw UnimplementedError();

  set value(T value) => throw UnimplementedError();

  void update(T value, {bool notify = true, bool force = false}) => throw UnimplementedError();
}

final class EventDefinition extends ListenableEntityDefinition {
  EventDefinition._();

  DateTime? get triggeredAt => throw UnimplementedError();

  void trigger() => throw UnimplementedError();
}

final class DataEventDefinition<T> extends ListenableEntityDefinition {
  DataEventDefinition._();

  T get data => throw UnimplementedError();

  T? get dataOrNull => throw UnimplementedError();

  DateTime? get triggeredAt => throw UnimplementedError();

  void trigger(T data) => throw UnimplementedError();
}

final class DependencyDefinition<T> {
  final T value;

  DependencyDefinition._(this.value);
}
