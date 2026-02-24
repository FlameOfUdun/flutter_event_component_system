// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'generated_feature.dart';

// **************************************************************************
// ComponentGenerator
// **************************************************************************

final class HealthComponent extends ECSComponent<int> {
  HealthComponent([super.value = 0]);
}

// **************************************************************************
// EventGenerator
// **************************************************************************

final class ResetHealthEvent extends ECSEvent {}

// **************************************************************************
// DataEventGenerator
// **************************************************************************

final class AddHealthEvent extends ECSDataEvent<int> {
  @override
  void trigger([int data = 10]) => super.trigger(data);
}

// **************************************************************************
// ReactiveSystemGenerator
// **************************************************************************

final class ApplyAddHealthReactiveSystem extends ReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return {AddHealthEvent};
  }

  @override
  bool get reactsIf {
    final component = getEntity<HealthComponent>();
    final event = getEntity<AddHealthEvent>();
    return component.value + event.data! <= 100;
  }

  @override
  Set<Type> get interactsWith {
    return {HealthComponent};
  }

  @override
  void react() {
    final component = getEntity<HealthComponent>();
    final event = getEntity<AddHealthEvent>();
    component.value += event.data!;
  }
}

// **************************************************************************
// FeatureGenerator
// **************************************************************************

final class GeneratedFeature extends ECSFeature {
  GeneratedFeature() {
    addEntity(HealthComponent());
    addEntity(ResetHealthEvent());
    addEntity(AddHealthEvent());
    addSystem(ApplyAddHealthReactiveSystem());
  }
}
