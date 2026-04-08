import 'package:flutter_event_component_system/flutter_event_component_system.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';

part 'generated_feature.ecs.dart';

@ECSComponentDefinition()
const int health = 0;

@ECSEventDefinition(
  description: 'Resets health to 0 for testing purposes.',
)
const Object resetHealth = Object();

@ECSDataEventDefinition()
const int addHealth = 10;

@ECSReactiveSystemDefinition(reactsTo: {addHealth}, interactsWith: {health}, reactsIf: addHealthIf)
void applyAddHealth(ECSSystemReference system) {
  final component = system.getComponent(health);
  final event = system.getDataEvent(addHealth);
  component.value += event.data;
}

bool addHealthIf(ECSSystemReference system) {
  final component = system.getComponent(health);
  final event = system.getDataEvent(addHealth);
  return component.value + event.data <= 100;
}

@ECSReactiveSystemDefinition(reactsTo: {resetHealth}, interactsWith: {health})
void applyResetHealth(ECSSystemReference system) {
  final component = system.getComponent(health);
  component.update(0, force: true);
}

@ECSFeatureDefinition()
void buildGeneratedFeature(
  ECSFeatureReference feature, {
  bool mock = false,
}) {
  if (mock) {
    feature.addEvent(resetHealth);
  }
  feature.addComponent(health);
  feature.addDataEvent(addHealth);
  feature.addReactiveSystem(applyAddHealth);
  feature.addReactiveSystem(applyResetHealth);
}
