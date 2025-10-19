part of '../ecs_base.dart';

/// Interface for listening to changes in entities.
abstract interface class ECSEntityListener {
  /// Called when an entity changes.
  void onEntityChanged(ECSEntity entity) {}
}

/// Represents a base entity in the ECS system.
sealed class ECSEntity {
  /// Set of listeners for this entity.
  @visibleForTesting
  final Set<ECSEntityListener> listeners = {};

  /// The parent feature of this entity.
  @visibleForTesting
  late ECSFeature feature;

  ECSEntity();

  /// Sets the parent feature of this entity.
  ///
  /// Throws a [StateError] if the parent is already set.
  @visibleForTesting
  void setFeature(ECSFeature feature) {
    this.feature = feature;
  }

  /// Adds a listener to this entity.
  @visibleForTesting
  void addListener(ECSEntityListener listener) {
    listeners.add(listener);
  }

  /// Removes a listener from this entity.
  @visibleForTesting
  void removeListener(ECSEntityListener listener) {
    listeners.remove(listener);
  }

  @protected
  void notifyListeners() {
    for (final listener in listeners) {
      listener.onEntityChanged(this);
    }
  }
}

/// Represents an event in the ECS system.
///
/// Events are specialized entities that can be triggered to notify listeners.
abstract class ECSEvent extends ECSEntity {
  ECSEvent();

  /// Triggers the event, notifying all listeners.
  void trigger() {
    notifyListeners();
  }

  /// Builds a widget that represents this entity in the [ECSInspector].
  ///
  /// [context] is the build context in which the widget is built.
  Widget buildInspector(BuildContext context) {
    return ElevatedButton(
      onPressed: trigger,
      child: const Text('Trigger Event'),
    );
  }
}

/// Represents a component in the ECS system.
///
/// Components are specialized entities that hold data and can be updated  and
/// will notify listeners when their value changes.
abstract class ECSComponent<TValue> extends ECSEntity {
  /// The current value of the component.
  TValue _value;

  /// The previous value of the component.
  TValue? _previous;

  ECSComponent(this._value);

  /// The current value of the component.
  TValue get value => _value;

  /// The previous value of the component, or null if never set.
  TValue? get previous => _previous;

  /// Updates the component's value.
  ///
  /// If [notify] is `true`, listeners will be notified of the change. Default
  /// is `true`.
  ///
  /// If the [value] is equal to the current value, no change will be made
  /// unless [force] is `true`, then update will be applied anyways. Defaults is
  /// `false`.
  void update(
    TValue value, {
    bool notify = true,
    bool force = false,
  }) {
    if (force == false) {
      if (_value == value) {
        return;
      }
    }

    _previous = _value;
    _value = value;

    if (notify) {
      notifyListeners();
    }
  }

  /// Fast setter for updating the component's value.
  ///
  /// This is equivalent to calling [update] with default parameters.
  set value(TValue value) {
    update(value);
  }

  /// Builds a string descriptor for the component's value in [ECSInspector].
  ///
  /// If the [value] is null, "null" will be returned.
  String buildDescriptor(TValue? value) {
    return value.toString();
  }

  /// Builds a widget that represents this entity in the [ECSInspector].
  ///
  /// [context] is the build context in which the widget is built.
  Widget buildInspector(BuildContext context, TValue? value) {
    return Text(buildDescriptor(value));
  }
}
