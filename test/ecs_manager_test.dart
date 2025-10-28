import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_event_component_system/src/ecs_base.dart';

class DummyComponent extends ECSComponent<int> {
  DummyComponent([super.value = 0]);
}

class DummyEvent extends ECSEvent {}

class DummyReactiveSystem extends ReactiveSystem {
  bool reacted = false;
  @override
  Set<Type> get interactsWith => {};
  @override
  Set<Type> get reactsTo => {DummyEvent};
  @override
  void react() => reacted = true;
}

class DummyFeature extends ECSFeature {
  DummyFeature() {
    addEntity(DummyComponent());
    addEntity(DummyEvent());
  }
}

class AnotherDummyFeature extends ECSFeature {
  bool initialized = false;
  bool tornDown = false;
  bool cleaned = false;
  bool executed = false;

  AnotherDummyFeature() {
    addSystem(DummyReactiveSystem());
  }

  @override
  void initialize() {
    initialized = true;
  }

  @override
  void teardown() {
    tornDown = true;
  }

  @override
  void cleanup() {
    cleaned = true;
  }

  @override
  void execute(Duration elapsed) {
    executed = true;
  }
}

class ComponentReactiveSystem extends ReactiveSystem {
  bool reacted = false;
  @override
  Set<Type> get interactsWith => {};
  @override
  Set<Type> get reactsTo => {DummyComponent};
  @override
  void react() => reacted = true;
}

void main() {
  group('ECSManager', () {
    test('addFeature adds feature and entities', () {
      final manager = ECSManager();
      final feature = DummyFeature();
      manager.addFeature(feature);
      expect(manager.features, contains(feature));
      expect(manager.entities.whereType<DummyComponent>().length, 1);
      expect(manager.entities.whereType<DummyEvent>().length, 1);
    });

    test('get returns correct entity', () {
      final manager = ECSManager();
      final feature = DummyFeature();
      manager.addFeature(feature);
      manager.activate();
      final component = manager.getEntity<DummyComponent>();
      expect(component, isA<DummyComponent>());
    });

    test('get throws if entity not found', () {
      final manager = ECSManager();
      manager.activate();
      expect(() => manager.getEntity<DummyComponent>(), throwsStateError);
    });

    test('onEntityChanged triggers reactive systems', () {
      final manager = ECSManager();
      final feature = DummyFeature();
      final reactive = DummyReactiveSystem();
      feature.addSystem(reactive);
      manager.addFeature(feature);
      manager.activate();
      feature.getEntity<DummyEvent>().trigger();
      expect(reactive.reacted, isTrue);
    });

    test('entities and getEntity work across multiple features', () {
      final manager = ECSManager();
      final feature1 = DummyFeature();
      final feature2 = DummyFeature();
      manager.addFeature(feature1);
      manager.addFeature(feature2);
      manager.activate();
      expect(manager.entities.whereType<DummyComponent>().length, 2);
      expect(manager.getEntity<DummyComponent>(), isA<DummyComponent>());
    });

    test('getEntity returns first found for duplicate types', () {
      final manager = ECSManager();
      final feature1 = DummyFeature();
      final feature2 = DummyFeature();
      manager.addFeature(feature1);
      manager.addFeature(feature2);
      manager.activate();
      final entity = manager.getEntity<DummyComponent>();
      expect(entity, anyOf(feature1.getEntity<DummyComponent>(), feature2.getEntity<DummyComponent>()));
    });

    test('multiple reactive systems for same entity type are triggered', () {
      final manager = ECSManager();
      final feature = DummyFeature();
      final reactive1 = DummyReactiveSystem();
      final reactive2 = DummyReactiveSystem();
      feature.addSystem(reactive1);
      feature.addSystem(reactive2);
      manager.addFeature(feature);
      manager.activate();
      feature.getEntity<DummyEvent>().trigger();
      expect(reactive1.reacted, isTrue);
      expect(reactive2.reacted, isTrue);
    });

    test('reactive systems only trigger for correct entity types', () {
      final manager = ECSManager();
      final feature = DummyFeature();
      final eventReactiveSystem = DummyReactiveSystem();
      final componentReactiveSystem = ComponentReactiveSystem();
      feature.addSystem(eventReactiveSystem);
      feature.addSystem(componentReactiveSystem);
      manager.addFeature(feature);
      manager.activate();

      // Trigger event - only event reactive system should react
      feature.getEntity<DummyEvent>().trigger();
      expect(eventReactiveSystem.reacted, isTrue);
      expect(componentReactiveSystem.reacted, isFalse);

      // Reset and trigger component
      eventReactiveSystem.reacted = false;
      feature.getEntity<DummyComponent>().update(42);
      expect(eventReactiveSystem.reacted, isFalse);
      expect(componentReactiveSystem.reacted, isTrue);
    });

    test('manager tracks entities from multiple features correctly', () {
      final manager = ECSManager();
      final feature1 = DummyFeature();
      final feature2 = AnotherDummyFeature();
      manager.addFeature(feature1);
      manager.addFeature(feature2);
      manager.activate();

      final allEntities = manager.entities;
      expect(allEntities.whereType<DummyComponent>().length, 1);
      expect(allEntities.whereType<DummyEvent>().length, 1);
      expect(allEntities.length, 2);
    });

    test('getEntity searches features in order', () {
      final manager = ECSManager();
      final feature1 = DummyFeature();
      final feature2 = DummyFeature();
      manager.addFeature(feature1);
      manager.addFeature(feature2);
      manager.activate();

      final component = manager.getEntity<DummyComponent>();
      expect(component, equals(feature1.getEntity<DummyComponent>()));
    });

    test('entity change triggers systems across all features', () {
      final manager = ECSManager();
      final feature1 = DummyFeature();
      final feature2 = AnotherDummyFeature();
      final reactive1 = DummyReactiveSystem();
      final reactive2 = DummyReactiveSystem();

      feature1.addSystem(reactive1);
      feature2.addSystem(reactive2);
      manager.addFeature(feature1);
      manager.addFeature(feature2);
      manager.activate();

      feature1.getEntity<DummyEvent>().trigger();
      expect(reactive1.reacted, isTrue);
      expect(reactive2.reacted, isTrue);
    });

    test('features property returns unmodifiable set', () {
      final manager = ECSManager();
      final feature = DummyFeature();
      manager.addFeature(feature);
      manager.activate();

      final features = manager.features;
      expect(features, contains(feature));
      expect(features.length, 1);
    });
  });
}
