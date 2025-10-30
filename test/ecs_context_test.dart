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
class TestReactiveSystem extends ReactiveSystem {
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

    test('should watch entities and trigger rebuilds on change', () async {
      final counter = ecs.watch<TestCounterComponent>();

      expect(rebuildCount, equals(0));

      // Change the watched entity
      counter.update(5);

      // Wait for microtask to complete
      await Future.microtask(() {});

      expect(rebuildCount, equals(1));
    });

    test('should not trigger rebuild when locked', () async {
      final counter = ecs.watch<TestCounterComponent>();

      // Simulate locked state
      ecs.locked = true;

      counter.update(10);
      await Future.microtask(() {});

      expect(rebuildCount, equals(0));
    });

    test('should handle multiple watchers correctly', () async {
      final counter = ecs.watch<TestCounterComponent>();
      final stringComponent = ecs.watch<TestStringComponent>();

      expect(rebuildCount, equals(0));

      // Change first watched entity
      counter.update(3);
      await Future.microtask(() {});
      expect(rebuildCount, equals(1));

      // Change second watched entity
      stringComponent.update('changed');
      await Future.microtask(() {});
      expect(rebuildCount, equals(2));
    });

    test('should call listeners when entity changes', () async {
      bool listenerCalled = false;
      TestCounterComponent? receivedEntity;

      ecs.listen<TestCounterComponent>((entity) {
        listenerCalled = true;
        receivedEntity = entity;
      });

      final counter = ecs.get<TestCounterComponent>();
      counter.update(7);

      await Future.microtask(() {});

      expect(listenerCalled, isTrue);
      expect(receivedEntity, equals(counter));
      expect(receivedEntity!.value, equals(7));
    });

    test('should call onEnter callback when initialized', () async {
      bool onEnterCalled = false;

      ecs.onEnter(() {
        onEnterCalled = true;
      });

      ecs.initialize();
      await Future.microtask(() {});

      expect(onEnterCalled, isTrue);
    });

    test('should call onExit callback when disposed', () async {
      bool onExitCalled = false;

      ecs.onExit(() {
        onExitCalled = true;
      });

      ecs.dispose();
      await Future.microtask(() {});

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

  group('ECSWidget Integration Tests', () {
    testWidgets('should build with ECSContext', (WidgetTester tester) async {
      final feature = TestFeature();
      ECSContext? capturedecs;

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            features: {feature},
            child: TestECSWidget(
              onBuild: (ecs) {
                capturedecs = ecs;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(capturedecs, isNotNull);
      expect(capturedecs!.manager, isA<ECSManager>());
    });

    testWidgets('should rebuild when watched entity changes', (WidgetTester tester) async {
      final feature = TestFeature();

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            features: {feature},
            child: TestECSWidget(),
          ),
        ),
      );

      await Future.microtask(tester.pumpAndSettle);

      // Change the counter value
      final counter = feature.getEntity<TestCounterComponent>();
      counter.update(42);

      await Future.microtask(tester.pumpAndSettle);

      // Verify the widget rebuilt with new value
      expect(find.text('Counter: 42'), findsOneWidget);
      expect(find.text('Counter: 0'), findsNothing);
    });

    testWidgets('should handle onEnter and onExit lifecycle', (WidgetTester tester) async {
      final feature = TestFeature();
      bool onEnterCalled = false;
      bool onExitCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            features: {feature},
            child: TestECSWidget(
              customBuilder: (context, ecs) {
                ecs.onEnter(() {
                  onEnterCalled = true;
                });

                ecs.onExit(() {
                  onExitCalled = true;
                });

                return const Text('Test');
              },
            ),
          ),
        ),
      );

      // Wait for post-frame callback
      await tester.pump();

      expect(onEnterCalled, isTrue);
      expect(onExitCalled, isFalse);

      // Remove the widget to trigger onExit
      await tester.pumpWidget(
        const MaterialApp(
          home: Text('Different Widget'),
        ),
      );

      await tester.pump();

      expect(onExitCalled, isTrue);
    });

    testWidgets('should handle listen callbacks', (WidgetTester tester) async {
      final feature = TestFeature();
      int listenerCallCount = 0;
      TestCounterComponent? receivedEntity;

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            features: {feature},
            child: TestECSWidget(
              customBuilder: (context, ecs) {
                ecs.listen<TestCounterComponent>((entity) {
                  listenerCallCount++;
                  receivedEntity = entity;
                });

                final counter = ecs.watch<TestCounterComponent>();
                return Text('Counter: ${counter.value}');
              },
            ),
          ),
        ),
      );

      await tester.pump();

      expect(listenerCallCount, equals(0));

      // Change the counter
      final counter = feature.getEntity<TestCounterComponent>();
      counter.update(25);

      await tester.pump();

      expect(listenerCallCount, equals(1));
      expect(receivedEntity, equals(counter));
      expect(receivedEntity!.value, equals(25));
    });

    testWidgets('should not rebuild after disposal', (WidgetTester tester) async {
      final feature = TestFeature();

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            features: {feature},
            child: TestECSWidget(),
          ),
        ),
      );

      // Get ecs to counter before disposal
      final counter = feature.getEntity<TestCounterComponent>();

      // Remove the widget (this should dispose the ecs)
      await tester.pumpWidget(
        const MaterialApp(
          home: Text('Different Widget'),
        ),
      );

      await tester.pumpAndSettle();

      // Try to change the counter after disposal
      counter.update(99);

      // Pump again to see if any rebuilds happen (they shouldn't)
      await tester.pump();

      // Verify the old widget is gone
      expect(find.text('Counter: 99'), findsNothing);
    });

    testWidgets('should handle multiple ECSWidgets independently', (WidgetTester tester) async {
      final feature = TestFeature();

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            features: {feature},
            child: Column(
              children: [
                TestECSWidget(
                  key: const Key('widget1'),
                ),
                TestECSWidget(
                  key: const Key('widget2'),
                ),
              ],
            ),
          ),
        ),
      );

      // Both widgets should show the same initial value
      expect(find.text('Counter: 0'), findsNWidgets(2));

      // Change the counter
      final counter = feature.getEntity<TestCounterComponent>();
      counter.update(15);

      await tester.pump();

      // Both widgets should update
      expect(find.text('Counter: 15'), findsNWidgets(2));
      expect(find.text('Counter: 0'), findsNothing);
    });
  });

  group('Edge Cases and Error Handling', () {
    test('should handle rapid entity changes', () async {
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

      await Future.microtask(() {});

      // Should still only rebuild once due to microtask batching
      expect(rebuildCount, equals(1));

      ecs.dispose();
    });

    test('should prevent multiple builds when previous build is not completed', () async {
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

      await Future.microtask(() {});

      // Should only rebuild once despite multiple changes
      expect(rebuildCount, equals(1));
      
      // After microtask, ecs should be unlocked
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
