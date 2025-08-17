part of '../flutter_event_component_system.dart';

/// Interface for listening to changes in entities.
abstract interface class ECSEntityListener {
  /// Called when an entity changes.
  void onEntityChanged(ECSEntity entity) {}
}

/// Represents a base entity in the ECS system.
sealed class ECSEntity {
  final Set<ECSEntityListener> _listeners = {};

  ECSFeature? _parent;

  ECSEntity();

  /// Sets the parent feature of this entity.
  ///
  /// Throws a [StateError] if the parent is already set.
  @visibleForTesting
  void setParent(ECSFeature parent) {
    if (_parent != null) {
      throw StateError('Parent is already set for this entity.');
    }
    _parent = parent;
  }

  /// The parent feature of this entity.
  ECSFeature get parent {
    if (_parent == null) {
      throw StateError('Parent is not set for this entity.');
    }
    return _parent!;
  }

  /// Unmodifiable set of listeners for this entity.
  Set<ECSEntityListener> get listeners {
    return Set.unmodifiable(_listeners);
  }

  /// Adds a listener to this entity.
  void addListener(ECSEntityListener listener) {
    _listeners.add(listener);
  }

  /// Removes a listener from this entity.
  void removeListener(ECSEntityListener listener) {
    _listeners.remove(listener);
  }

  @protected
  void notifyListeners() {
    for (final listener in _listeners) {
      listener.onEntityChanged(this);
    }
  }

  /// Builds a widget that represents this entity in the [ECSInspector].
  Widget buildInspector(BuildContext context) {
    return Text('$runtimeType');
  }
}

abstract class ECSEvent extends ECSEntity {
  ECSEvent();

  /// Triggers the event, notifying all listeners.
  void trigger() {
    notifyListeners();
  }
}

/// Represents a component in the ECS system.
///
/// Components are specialized entities that hold data and can be updated  and
/// will notify listeners when their value changes.
abstract class ECSComponent<TValue> extends ECSEntity {
  TValue _value;
  TValue? _previous;

  ECSComponent(this._value);

  /// The current value of the component.
  TValue get value => _value;

  /// The previous value of the component, or null if never set.
  TValue? get previous => _previous;

  /// Updates the component's value.
  ///
  /// If [notify] is `true`, listeners will be notified of the change. Default is
  /// `true`.
  ///
  /// If the value is the same as the current value, no change will be made.
  void update(
    TValue value, {
    bool notify = true,
  }) {
    _previous = _value;
    _value = value;

    if (!notify) return;
    notifyListeners();
  }

  /// Builds a string descriptor for the component's value.
  String buildDescriptor(TValue? value) {
    return value.toString();
  }

  @override
  Widget buildInspector(BuildContext context) {
    return Text(buildDescriptor(value));
  }
}
