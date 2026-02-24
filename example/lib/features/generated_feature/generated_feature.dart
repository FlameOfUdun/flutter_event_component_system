import 'package:flutter_event_component_system/flutter_event_component_system.dart';
import 'package:flutter_event_component_system_annotations/flutter_event_component_system_annotations.dart';

part 'generated_feature.ecs.dart';

@ComponentDefinition()
const int health = 0;

@EventDefinition(
  description: 'Resets health to 0 for testing purposes.',
)
const Object resetHealth = Object();

@DataEventDefinition()
const int addHealth = 10;

@ReactiveSystemDefinition(reactsTo: {addHealth}, interactsWith: {health}, reactsIf: addHealthIf)
void applyAddHealth(SystemReference system) {
  final component = system.getComponent(health);
  final event = system.getDataEvent(addHealth);
  component.value += event.data!;
}

bool addHealthIf(SystemReference system) {
  final component = system.getComponent(health);
  final event = system.getDataEvent(addHealth);
  return component.value + event.data! <= 100;
}

@ReactiveSystemDefinition(reactsTo: {resetHealth}, interactsWith: {health})
void applyResetHealth(SystemReference system) {
  final component = system.getComponent(health);
  component.update(0, force: true);
}

@FeatureDefinition()
void buildGeneratedFeature(
  FeatureReference feature, {
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
