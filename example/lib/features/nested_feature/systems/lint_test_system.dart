part of '../nested_feature.dart';

final class LintTestSystem extends ReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return {
      DataEvent,
    };
  }

  @override
  Set<Type> get interactsWith {
    return {
      DataEvent,
    };
  }

  @override
  void react() async {
    final event = getEntity<DataEvent>();
    await Future.delayed(const Duration(seconds: 1));
    event.data; // Triggers lint error for accessing event data after an async gap.
    _outOfReact();
   
  }

  void _outOfReact() {
    final event = getEntity<DataEvent>();
    event.data; // Triggers lint error for accessing event data outside of react method.
    event.trigger(null); // Triggers lint error for event not added to interactsWith.
  }
}
