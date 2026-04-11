library;

import 'package:flutter_event_component_system/flutter_event_component_system.dart';

part 'test_feature.ecs.g.dart';

final testFeature = ECS.createFeature();

final testComponent = testFeature.addComponent(0);

final testEvent = testFeature.addEvent();

final testDataEvent = testFeature.addDataEvent<String>();

final testReactiveSystem = testFeature.addReactiveSystem(
  reactsTo: {testDataEvent},
  reactsIf: () {
    return testComponent.value > 0;
  },
  react: () {
    testComponent.update(10, notify: true, force: true);
    final previous = testComponent.previous;
    final current = testComponent.value;
    final updatedAt = testComponent.updatedAt;
    testComponent.value++;
    final triggeredAt = testEvent.triggeredAt;
    testEvent.trigger();
    testDataEvent.trigger('Hello');
    _react(testDataEvent.data);
  },
);

void _react(String data) {
  testComponent.value++;
}

final testExecuteSystem = testFeature.addExecuteSystem(
  executesIf: () {
    return _executesIf();
  },
  execute: (Duration elapsed) {
    _execute();
  },
);

bool _executesIf() {
  return _executesIf2();
}

bool _executesIf2() {
  return testComponent.value > 0;
}

void _execute() {
  _execute2();
}

void _execute2() {
  testEvent.trigger();
}

final testCleanupSystem = testFeature.addCleanupSystem(
  cleansIf: () {
    return _cleansIf();
  },
  cleanup: () {
    _cleanup();
  },
);

bool _cleansIf() {
  return testComponent.value > 20;
}

void _cleanup() {
  _cleanup2();
}

void _cleanup2() {
  testComponent.value = 0;
}

final testTeardownSystem = testFeature.addTeardownSystem(
  teardown: () {
    _teardown();
  },
);

void _teardown() {
  _teardown2();
}

void _teardown2() {
  testComponent.value = 1;
}

final testInitializeSystem = testFeature.addInitializeSystem(initialize: () {
  _initialize();
});

void _initialize() {
  _initialize2();
}

void _initialize2() {
  testComponent.value = 1;
}
