import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_event_component_system/src/ecs_base.dart';

// Test entities
class TestCounterComponent extends ECSComponent<int> {
  TestCounterComponent([super.value = 0]);
}

class TestStringComponent extends ECSComponent<String> {
  TestStringComponent([super.value = 'initial']);
}

class TestToggleEvent extends ECSEvent {
  TestToggleEvent();
}

class TestIncrementEvent extends ECSEvent {
  TestIncrementEvent();
}

// Test feature
class TestFeature extends ECSFeature {
  TestFeature() {
    addEntity(TestCounterComponent());
    addEntity(TestStringComponent());
    addEntity(TestToggleEvent());
    addEntity(TestIncrementEvent());
    addSystem(TestReactiveSystem());
  }
}

// Empty test feature for error testing
class EmptyTestFeature extends ECSFeature {
  EmptyTestFeature();
}

// Test system
class TestReactiveSystem extends ECSReactiveSystem {
  @override
  Set<Type> get interactsWith => {};
  @override
  Set<Type> get reactsTo => {TestIncrementEvent};
  @override
  void react() {
    // This would normally interact with components
  }
}

// Test widget that uses ECSContext
class TestECSWidget extends ECSWidget {
  final Function(ECSContext)? onBuild;
  final Widget Function(BuildContext, ECSContext)? customBuilder;

  const TestECSWidget({
    super.key,
    this.onBuild,
    this.customBuilder,
  });

  @override
  Widget build(BuildContext context, ECSContext ecs) {
    onBuild?.call(ecs);

    if (customBuilder != null) {
      return customBuilder!(context, ecs);
    }

    final counter = ecs.watch<TestCounterComponent>();
    final stringComponent = ecs.watch<TestStringComponent>();

    return Column(
      children: [
        Text('Counter: ${counter.value}'),
        Text('String: ${stringComponent.value}'),
      ],
    );
  }
}

void main() {
  group('ECSContext Tests', () {
    late ECSManager manager;
    late TestFeature feature;
    late ECSContext ecs;
    int rebuildCount = 0;

    setUp(() {
      rebuildCount = 0;
      manager = ECSManager();
      feature = TestFeature();
      manager.addFeature(feature);
      manager.activate();

      ecs = ECSContext(manager, () {
        rebuildCount++;
      });
    });

    tearDown(() {
      ecs.dispose();
    });

    test('should get entities from manager', () {
      final counter = ecs.get<TestCounterComponent>();
      final stringComponent = ecs.get<TestStringComponent>();

      expect(counter, isA<TestCounterComponent>());
      expect(counter.value, equals(0));
      expect(stringComponent, isA<TestStringComponent>());
      expect(stringComponent.value, equals('initial'));
    });

    testWidgets('should watch entities and trigger rebuilds on change',
        (WidgetTester tester) async {
      final counter = ecs.watch<TestCounterComponent>();

      expect(rebuildCount, equals(0));

      // Change the watched entity
      counter.update(5);

      // Pump frame to trigger callback
      await tester.pump();

      expect(rebuildCount, equals(1));
    });

    testWidgets('should not trigger rebuild when locked',
        (WidgetTester tester) async {
      final counter = ecs.watch<TestCounterComponent>();

      // Simulate locked state
      ecs.locked = true;

      counter.update(10);
      await tester.pump();

      expect(rebuildCount, equals(0));
    });

    testWidgets('should handle multiple watchers correctly',
        (WidgetTester tester) async {
      final counter = ecs.watch<TestCounterComponent>();
      final stringComponent = ecs.watch<TestStringComponent>();

      expect(rebuildCount, equals(0));

      // Change first watched entity
      counter.update(3);
      await tester.pump();
      expect(rebuildCount, equals(1));

      // Change second watched entity
      stringComponent.update('changed');
      await tester.pump();
      expect(rebuildCount, equals(2));
    });

    testWidgets('should call listeners when entity changes',
        (WidgetTester tester) async {
      bool listenerCalled = false;
      TestCounterComponent? receivedEntity;

      ecs.listen<TestCounterComponent>((entity) {
        listenerCalled = true;
        receivedEntity = entity;
      });

      final counter = ecs.get<TestCounterComponent>();
      counter.update(7);

      await tester.pump();

      expect(listenerCalled, isTrue);
      expect(receivedEntity, equals(counter));
      expect(receivedEntity!.value, equals(7));
    });

    testWidgets('should call onEnter callback when initialized',
        (WidgetTester tester) async {
      bool onEnterCalled = false;

      ecs.onEnter(() {
        onEnterCalled = true;
      });

      ecs.initialize();
      await tester.pump();

      expect(onEnterCalled, isTrue);
    });

    test('should call onExit callback when disposed', () {
      bool onExitCalled = false;

      ecs.onExit(() {
        onExitCalled = true;
      });

      ecs.dispose();

      expect(onExitCalled, isTrue);
    });

    test('should only set onEnter callback once', () {
      ecs.onEnter(() {
        // First callback
      });

      ecs.onEnter(() {
        // Second callback should be ignored
      });

      expect(ecs.onEnterListener, isNotNull);
      // Second callback should be ignored - the listener should not change
    });

    test('should clean up listeners on dispose', () async {
      final counter = ecs.watch<TestCounterComponent>();

      // Verify listener is added
      expect(counter.listeners.length, equals(1));

      ecs.dispose();

      // Verify listener is removed
      expect(counter.listeners.length, equals(0));
    });

    test('should handle disposed state correctly', () {
      ecs.dispose();

      expect(ecs.disposed, isTrue);
    });
  });

  group('Edge Cases and Error Handling', () {
    testWidgets('should handle rapid entity changes',
        (WidgetTester tester) async {
      final manager = ECSManager();
      final feature = TestFeature();
      manager.addFeature(feature);
      manager.activate();

      int rebuildCount = 0;
      final ecs = ECSContext(manager, () {
        rebuildCount++;
      });

      final counter = ecs.watch<TestCounterComponent>();

      // Rapid changes
      counter.update(1);
      counter.update(2);
      counter.update(3);
      counter.update(4);
      counter.update(5);

      await tester.pump();

      // Should still only rebuild once due to frame callback batching
      expect(rebuildCount, equals(1));

      ecs.dispose();
    });

    testWidgets(
        'should prevent multiple builds when previous build is not completed',
        (WidgetTester tester) async {
      final manager = ECSManager();
      final feature = TestFeature();
      manager.addFeature(feature);
      manager.activate();

      int rebuildCount = 0;

      final ecs = ECSContext(manager, () {
        rebuildCount++;
      });

      final counter = ecs.watch<TestCounterComponent>();

      // Trigger first build
      counter.update(1);

      // Immediately trigger more changes while first build is in progress
      counter.update(2);
      counter.update(3);
      counter.update(4);

      // Verify ecs is locked during build
      expect(ecs.locked, isTrue);

      await tester.pump();

      // Should only rebuild once despite multiple changes
      expect(rebuildCount, equals(1));

      // After frame callback, ecs should be unlocked
      expect(ecs.locked, isFalse);

      ecs.dispose();
    });

    test('should handle watching same entity multiple times', () {
      final manager = ECSManager();
      final feature = TestFeature();
      manager.addFeature(feature);
      manager.activate();

      final ecs = ECSContext(manager, () {});

      final counter1 = ecs.watch<TestCounterComponent>();
      final counter2 = ecs.watch<TestCounterComponent>();

      expect(counter1, equals(counter2));
      expect(ecs.watchers.length, equals(1));

      ecs.dispose();
    });
  });
}
