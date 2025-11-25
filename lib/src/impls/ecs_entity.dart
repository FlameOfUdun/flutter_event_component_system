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
  ECSFeature? feature;

  ECSEntity();

  /// Indicates whether this entity is active (i.e., has a parent feature).
  @visibleForTesting
  @protected
  bool get isAttached => feature != null;

  /// Attaches this entity to a feature.
  @visibleForTesting
  void attach(ECSFeature feature) {
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

  /// Logs a message to the ECS manager's logging system.
  @protected
  @visibleForTesting
  void log(String message, {ECSLogLevel level = ECSLogLevel.info}) {
    feature?.manager?.log(message, level: level);
  }
}

/// Represents an event in the ECS system.
///
/// Events are specialized entities that can be triggered to notify listeners.
abstract class ECSEvent extends ECSEntity {
  /// The last triggered timestamp of the event.
  DateTime? _triggeredAt;

  ECSEvent();

  /// The last triggered timestamp of the event, or null if never triggered.
  DateTime? get triggeredAt => _triggeredAt;

  /// Triggers the event, notifying all listeners.
  void trigger() {
    _triggeredAt = DateTime.now();
    notifyListeners();
  }

  @override
  void notifyListeners() {
    log('$runtimeType triggered');
    super.notifyListeners();
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

  /// The last updated timestamp of the component.
  DateTime? _updatedAt;

  ECSComponent(this._value);

  /// The current value of the component.
  TValue get value => _value;

  /// The previous value of the component, or null if never set.
  TValue? get previous => _previous;

  /// The last updated timestamp of the component, or null if never updated.
  DateTime? get updatedAt => _updatedAt;

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
    _updatedAt = DateTime.now();
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
  String describe(TValue? value) {
    return value.toString();
  }

  @override
  void notifyListeners() {
    log('${feature.runtimeType}.$runtimeType updated from ${describe(_previous)} to ${describe(_value)}');
    super.notifyListeners();
  }
}
