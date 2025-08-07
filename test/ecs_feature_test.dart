import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_event_component_system/flutter_event_component_system.dart';

class DummyComponent extends ECSComponent<int> {
  DummyComponent([super.value = 0]);
}

class DummyEvent extends ECSEvent {}

class DummyInitSystem extends InitializeSystem {
  bool initialized = false;
  @override
  Set<Type> get interactsWith => {};
  @override
  void initialize() => initialized = true;
}

class DummyTeardownSystem extends TeardownSystem {
  bool tornDown = false;
  @override
  Set<Type> get interactsWith => {};
  @override
  void teardown() => tornDown = true;
}

class DummyCleanupSystem extends CleanupSystem {
  bool cleaned = false;
  @override
  Set<Type> get interactsWith => {};
  @override
  void cleanup() => cleaned = true;
}

class DummyExecuteSystem extends ExecuteSystem {
  Duration? lastElapsed;
  @override
  Set<Type> get interactsWith => {};
  @override
  void execute(Duration elapsed) => lastElapsed = elapsed;
}

class DummyReactiveSystem extends ReactiveSystem {
  bool reacted = false;
  @override
  Set<Type> get interactsWith => {};
  @override
  Set<Type> get reactsTo => {DummyEvent};
  @override
  void react() => reacted = true;
}

class TestFeature extends ECSFeature {
  TestFeature();
}

class MultiReactiveSystem extends ReactiveSystem {
  bool reacted = false;
  @override
  Set<Type> get interactsWith => {};
  @override
  Set<Type> get reactsTo => {DummyEvent, DummyComponent};
  @override
  void react() => reacted = true;
}

void main() {
  group('ECSFeature', () {
    test('addEntity and getEntity', () {
      final feature = TestFeature();
      feature.addEntity(DummyComponent());
      feature.addEntity(DummyEvent());
      expect(feature.getEntity<DummyComponent>(), isA<DummyComponent>());
      expect(feature.getEntity<DummyEvent>(), isA<DummyEvent>());
    });

    test('addSystem registers all system types', () {
      final feature = TestFeature();
      final init = DummyInitSystem();
      final teardown = DummyTeardownSystem();
      final cleanup = DummyCleanupSystem();
      final execute = DummyExecuteSystem();
      final reactive = DummyReactiveSystem();
      feature.addSystem(init);
      feature.addSystem(teardown);
      feature.addSystem(cleanup);
      feature.addSystem(execute);
      feature.addSystem(reactive);
      expect(feature.initializeSystems, contains(init));
      expect(feature.teardownSystems, contains(teardown));
      expect(feature.cleanupSystems, contains(cleanup));
      expect(feature.executeSystems, contains(execute));
      expect(feature.reactiveSystems[DummyEvent], contains(reactive));
    });

    test('initialize calls all InitializeSystems', () {
      final feature = TestFeature();
      final init = DummyInitSystem();
      feature.addSystem(init);
      feature.initialize();
      expect(init.initialized, isTrue);
    });

    test('teardown calls all TeardownSystems', () {
      final feature = TestFeature();
      final teardown = DummyTeardownSystem();
      feature.addSystem(teardown);
      feature.teardown();
      expect(teardown.tornDown, isTrue);
    });

    test('cleanup calls all CleanupSystems', () {
      final feature = TestFeature();
      final cleanup = DummyCleanupSystem();
      feature.addSystem(cleanup);
      feature.cleanup();
      expect(cleanup.cleaned, isTrue);
    });

    test('execute calls all ExecuteSystems', () {
      final feature = TestFeature();
      final execute = DummyExecuteSystem();
      feature.addSystem(execute);
      final duration = Duration(milliseconds: 123);
      feature.execute(duration);
      expect(execute.lastElapsed, duration);
    });

    test('reactiveSystems map is correct', () {
      final feature = TestFeature();
      final reactive = DummyReactiveSystem();
      feature.addSystem(reactive);
      expect(feature.reactiveSystems[DummyEvent], contains(reactive));
    });

    test('systemsCount returns correct total', () {
      final feature = TestFeature();
      feature.addSystem(DummyInitSystem());
      feature.addSystem(DummyTeardownSystem());
      feature.addSystem(DummyCleanupSystem());
      feature.addSystem(DummyExecuteSystem());
      feature.addSystem(DummyReactiveSystem());
      expect(feature.systemsCount, 5);
    });

    test('getEntity returns null for non-existent entity type', () {
      final feature = TestFeature();
      expect(feature.getEntity<DummyComponent>(), isNull);
    });

    test('multiple entities of same type returns first', () {
      final feature = TestFeature();
      final component1 = DummyComponent(10);
      final component2 = DummyComponent(20);
      feature.addEntity(component1);
      feature.addEntity(component2);
      final retrieved = feature.getEntity<DummyComponent>();
      expect(retrieved, equals(component1));
    });

    test('multiple systems of same type are all registered', () {
      final feature = TestFeature();
      final init1 = DummyInitSystem();
      final init2 = DummyInitSystem();
      feature.addSystem(init1);
      feature.addSystem(init2);
      expect(feature.initializeSystems.length, 2);
      expect(feature.initializeSystems, contains(init1));
      expect(feature.initializeSystems, contains(init2));
    });

    test('multiple reactive systems for same event type', () {
      final feature = TestFeature();
      final reactive1 = DummyReactiveSystem();
      final reactive2 = DummyReactiveSystem();
      feature.addSystem(reactive1);
      feature.addSystem(reactive2);
      expect(feature.reactiveSystems[DummyEvent]?.length, 2);
      expect(feature.reactiveSystems[DummyEvent], contains(reactive1));
      expect(feature.reactiveSystems[DummyEvent], contains(reactive2));
    });

    test('lifecycle methods work with multiple systems', () {
      final feature = TestFeature();
      final init1 = DummyInitSystem();
      final init2 = DummyInitSystem();
      final teardown1 = DummyTeardownSystem();
      final teardown2 = DummyTeardownSystem();
      feature.addSystem(init1);
      feature.addSystem(init2);
      feature.addSystem(teardown1);
      feature.addSystem(teardown2);

      feature.initialize();
      expect(init1.initialized, isTrue);
      expect(init2.initialized, isTrue);

      feature.teardown();
      expect(teardown1.tornDown, isTrue);
      expect(teardown2.tornDown, isTrue);
    });

    test('empty feature lifecycle methods work', () {
      final feature = TestFeature();
      expect(() => feature.initialize(), returnsNormally);
      expect(() => feature.teardown(), returnsNormally);
      expect(() => feature.cleanup(), returnsNormally);
      expect(() => feature.execute(Duration.zero), returnsNormally);
    });

    test('systemsCount is zero for empty feature', () {
      final feature = TestFeature();
      expect(feature.systemsCount, 0);
    });

    test('entities set contains all added entities', () {
      final feature = TestFeature();
      final component = DummyComponent();
      final event = DummyEvent();
      feature.addEntity(component);
      feature.addEntity(event);
      expect(feature.entities.length, 2);
      expect(feature.entities, contains(component));
      expect(feature.entities, contains(event));
    });

    test('reactive system with multiple reactsTo types', () {
      final feature = TestFeature();
      final multiReactiveSystem = MultiReactiveSystem();
      feature.addSystem(multiReactiveSystem);
      expect(feature.reactiveSystems[DummyEvent], contains(multiReactiveSystem));
      expect(feature.reactiveSystems[DummyComponent], contains(multiReactiveSystem));
    });
  });
}
