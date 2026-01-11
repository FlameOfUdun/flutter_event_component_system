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

    testWidgets('should rebuild when watched entity changes',
        (WidgetTester tester) async {
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

    testWidgets('should handle onEnter and onExit lifecycle',
        (WidgetTester tester) async {
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

    testWidgets('should not rebuild after disposal',
        (WidgetTester tester) async {
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

    testWidgets('should handle multiple ECSWidgets independently',
        (WidgetTester tester) async {
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
}
