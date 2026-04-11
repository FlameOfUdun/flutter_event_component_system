// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'test_feature.dart';

final class TestComponent extends ECSComponent<int> {
  TestComponent() : super(0);
}

final class TestEvent extends ECSEvent {}

final class TestDataEvent extends ECSDataEvent<String> {}

final class TestReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get reactsTo {
    return const {TestDataEvent};
  }

  @override
  bool get reactsIf {
    return getEntity<TestComponent>().value > 0;
  }

  @override
  void react() {
    getEntity<TestComponent>().update(10, notify: true, force: true);
    final previous = getEntity<TestComponent>().previous;
    final current = getEntity<TestComponent>().value;
    final updatedAt = getEntity<TestComponent>().updatedAt;
    getEntity<TestComponent>().value++;
    final triggeredAt = getEntity<TestEvent>().triggeredAt;
    getEntity<TestEvent>().trigger();
    getEntity<TestDataEvent>().trigger('Hello');
    _react(testDataEvent.data);
  }

  void _react(String data) {
    getEntity<TestComponent>().value++;
  }
}

final class TestExecuteSystem extends ECSExecuteSystem {
  @override
  bool get executesIf {
    return _executesIf();
  }

  @override
  void execute(Duration elapsed) {
    _execute();
  }

  void _execute() {
    _execute2();
  }

  void _execute2() {
    getEntity<TestEvent>().trigger();
  }

  bool _executesIf() {
    return _executesIf2();
  }

  bool _executesIf2() {
    return getEntity<TestComponent>().value > 0;
  }
}

final class TestCleanupSystem extends ECSCleanupSystem {
  @override
  bool get cleansIf {
    return _cleansIf();
  }

  @override
  void cleanup() {
    _cleanup();
  }

  void _cleanup() {
    _cleanup2();
  }

  void _cleanup2() {
    getEntity<TestComponent>().value = 0;
  }

  bool _cleansIf() {
    return getEntity<TestComponent>().value > 20;
  }
}

final class TestTeardownSystem extends ECSTeardownSystem {
  @override
  void teardown() {
    _teardown();
  }

  void _teardown() {
    _teardown2();
  }

  void _teardown2() {
    getEntity<TestComponent>().value = 1;
  }
}

final class TestInitializeSystem extends ECSInitializeSystem {
  @override
  void initialize() {
    _initialize();
  }

  void _initialize() {
    _initialize2();
  }

  void _initialize2() {
    getEntity<TestComponent>().value = 1;
  }
}

final class TestFeature extends ECSFeature {
  TestFeature() {
    addEntity(TestComponent());
    addEntity(TestEvent());
    addEntity(TestDataEvent());
    addSystem(TestReactiveSystem());
    addSystem(TestExecuteSystem());
    addSystem(TestCleanupSystem());
    addSystem(TestTeardownSystem());
    addSystem(TestInitializeSystem());
  }
}

