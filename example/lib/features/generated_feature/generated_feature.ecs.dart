// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'generated_feature.dart';

// **************************************************************************
// ECSComponentGenerator
// **************************************************************************

final class HealthComponent extends ECSComponent<int> {
  HealthComponent([super.value = 0]);
}

// **************************************************************************
// ECSEventGenerator
// **************************************************************************

/// Resets health to 0 for testing purposes.
final class ResetHealthEvent extends ECSEvent {}

// **************************************************************************
// ECSDataEventGenerator
// **************************************************************************

final class AddHealthEvent extends ECSDataEvent<int> {
  @override
  void trigger([int data = 10]) => super.trigger(data);
}

// **************************************************************************
// ECSReactiveSystemGenerator
// **************************************************************************

final class ApplyAddHealthReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {AddHealthEvent};
  }

  @override
  bool get reactsIf {
    final component = getEntity<HealthComponent>();
    final event = getEntity<AddHealthEvent>();
    return component.value + event.data <= 100;
  }

  @override
  Set<Type> get interactsWith {
    return const {HealthComponent};
  }

  @override
  void react() {
    final component = getEntity<HealthComponent>();
    final event = getEntity<AddHealthEvent>();
    component.value += event.data;
  }
}

final class ApplyResetHealthReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {ResetHealthEvent};
  }

  @override
  Set<Type> get interactsWith {
    return const {HealthComponent};
  }

  @override
  void react() {
    final component = getEntity<HealthComponent>();
    component.update(0, force: true);
  }
}

// **************************************************************************
// ECSFeatureGenerator
// **************************************************************************

final class GeneratedFeature extends ECSFeature {
  GeneratedFeature({
    bool mock = false,
  }) {
    if (mock) {
      addEntity(ResetHealthEvent());
    }
    addEntity(HealthComponent());
    addEntity(AddHealthEvent());
    addSystem(ApplyAddHealthReactiveSystem());
    addSystem(ApplyResetHealthReactiveSystem());
  }
}
