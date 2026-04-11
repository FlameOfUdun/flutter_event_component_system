part of 'ecs_base.dart';

/// Interface for listening to changes in entities.
abstract interface class ECSEntityListener {
  /// Called when an entity changes.
  void onEntityChanged(ECSEntity entity);
}

/// Represents a base entity in the ECS system.
sealed class ECSEntity {
  /// The parent feature of this entity.
  @visibleForTesting
  ECSFeature? feature;

  /// Indicates whether this entity is active (i.e., has a parent feature).
  @visibleForTesting
  @protected
  bool get isAttached => feature != null;

  /// Unique identifier for this entity.
  String get identifier => '${feature?.identifier}.$runtimeType';

  /// Attaches this entity to a feature.
  void attach(ECSFeature feature) {
    this.feature = feature;
  }

  /// Logs a message to the ECS manager's logging system.
  @protected
  @visibleForTesting
  void log(String message, {ECSLogLevel level = ECSLogLevel.info}) {
    // systemName is intentionally omitted: an entity may be observed by multiple systems.
    feature?.manager?.log(
      message,
      level: level,
      featureName: feature?.runtimeType.toString(),
    );
  }

  @protected
  @visibleForTesting

  /// Builds a string descriptor for this entity in inspector.
  String describe() {
    return identifier;
  }
}

/// Represents a listenable entity in the ECS system.
sealed class ECSListenableEntity extends ECSEntity {
  /// Set of listeners for this entity.
  @visibleForTesting
  final Set<ECSEntityListener> listeners = {};

  /// Adds a listener to this entity.
  void addListener(ECSEntityListener listener) {
    listeners.add(listener);
  }

  /// Removes a listener from this entity.
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
abstract class ECSEvent extends ECSListenableEntity {
  /// The last triggered timestamp of the event.
  DateTime? _triggeredAt;

  /// The last triggered timestamp of the event, or null if never triggered.
  DateTime? get triggeredAt => _triggeredAt;

  /// Triggers the event, notifying all listeners.
  void trigger() {
    _triggeredAt = DateTime.now();
    log('$identifier triggered');
    notifyListeners();
  }
}

/// Data events are specialized entities that can be triggered with associated
/// data to notify listeners.
///
/// When triggered, the event holds the data temporarily during notification,
/// after which the data is cleared.
///
/// Noice that you should not use the [data] property asynchronously after triggering.
abstract class ECSDataEvent<TData> extends ECSListenableEntity {
  /// The current data of the event.
  TData? _data;

  /// The last triggered timestamp of the event.
  DateTime? _triggeredAt;

  /// The current data of the event, or null if none.
  TData get data {
    if (_data == null) {
      throw StateError(
          'No data available. This may be because the event has not been triggered, or the data has already been cleared after notification.');
    }
    return _data!;
  }

  TData? get dataOrNull => _data;

  /// The last triggered timestamp of the event, or null if never triggered.
  DateTime? get triggeredAt => _triggeredAt;

  /// Triggers the event with associated [data], notifying all listeners.
  void trigger(TData data) {
    _data = data;
    _triggeredAt = DateTime.now();
    log('$identifier triggered with data: ${describe(_data)}');
    notifyListeners();
  }

  @override
  String describe([TData? data]) {
    return data.toString();
  }
}

/// Represents a component in the ECS system.
///
/// Components are specialized entities that hold data and can be updated  and
/// will notify listeners when their value changes.
abstract class ECSComponent<TValue> extends ECSListenableEntity {
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
      log('$identifier updated from ${describe(_previous)} to ${describe(_value)}');
      notifyListeners();
    }
  }

  /// Fast setter for updating the component's value.
  ///
  /// This is equivalent to calling [update] with default parameters.
  set value(TValue value) {
    update(value);
  }

  @override
  String describe([TValue? value]) {
    return value.toString();
  }
}

/// Represents a dependency in the ECS system.
abstract class ECSDependency<TValue> extends ECSEntity {
  final TValue value;

  ECSDependency(this.value);
}
