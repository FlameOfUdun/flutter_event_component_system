import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_event_component_system/src/ecs_base.dart';

class CounterComponent extends ECSComponent<int> {
  CounterComponent([super.value = 0]);
}

class MessageComponent extends ECSComponent<String> {
  MessageComponent([super.value = 'initial']);
}

class TestFeature extends ECSFeature {
  TestFeature();
}

class WatchingTestWidget extends ECSWidget {
  const WatchingTestWidget({super.key});

  @override
  Widget build(BuildContext context, ECSContext ecs) {
    final counter = ecs.watch<CounterComponent>();
    return Text('Counter: ${counter.value}');
  }
}

class ListeningTestWidget extends ECSWidget {
  final Function(CounterComponent) onCounterChanged;

  const ListeningTestWidget({
    super.key,
    required this.onCounterChanged,
  });

  @override
  Widget build(BuildContext context, ECSContext ecs) {
    ecs.listen<CounterComponent>(onCounterChanged);

    return const Text('Listening Widget');
  }
}

class BuildCounterWidget extends ECSWidget {
  final VoidCallback onBuild;

  const BuildCounterWidget({
    super.key,
    required this.onBuild,
  });

  @override
  Widget build(BuildContext context, ECSContext ecs) {
    onBuild();
    final counter = ecs.watch<CounterComponent>();
    return Text('Counter: ${counter.value}');
  }
}

class LifecycleTestWidget extends ECSWidget {
  final VoidCallback? onEnter;
  final VoidCallback? onExit;

  const LifecycleTestWidget({
    super.key,
    this.onEnter,
    this.onExit,
  });

  @override
  Widget build(BuildContext context, ECSContext ecs) {
    if (onEnter != null) {
      ecs.onEnter(onEnter!);
    }
    if (onExit != null) {
      ecs.onExit(onExit!);
    }
    return const Text('Lifecycle Widget');
  }
}

class MultipleEntitiesTestWidget extends ECSWidget {
  const MultipleEntitiesTestWidget({super.key});

  @override
  Widget build(BuildContext context, ECSContext ecs) {
    final counter = ecs.watch<CounterComponent>();
    final message = ecs.watch<MessageComponent>();
    return Column(
      children: [
        Text('Counter: ${counter.value}'),
        Text('Message: ${message.value}'),
      ],
    );
  }
}

void main() {
  group('ECSWidget', () {
    testWidgets('should watch entity changes and rebuild', (tester) async {
      final component = CounterComponent();

      final feature = TestFeature();
      feature.addEntity(component);

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            features: {feature},
            child: const WatchingTestWidget(),
          ),
        ),
      );

      expect(find.text('Counter: 0'), findsOneWidget);

      component.update(5);
      await tester.pump();

      expect(find.text('Counter: 5'), findsOneWidget);
      expect(find.text('Counter: 0'), findsNothing);
    });

    testWidgets('should handle multiple entity watches', (tester) async {
      final counterComponent = CounterComponent();
      final messageComponent = MessageComponent();

      final feature = TestFeature();
      feature.addEntity(counterComponent);
      feature.addEntity(messageComponent);

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            features: {feature},
            child: const MultipleEntitiesTestWidget(),
          ),
        ),
      );

      // Initial state
      expect(find.text('Counter: 0'), findsOneWidget);
      expect(find.text('Message: initial'), findsOneWidget);

      // Change counter
      counterComponent.update(10);
      await tester.pump();

      expect(find.text('Counter: 10'), findsOneWidget);
      expect(find.text('Message: initial'), findsOneWidget);

      // Change message (should not trigger rebuild since it's not watched)
      messageComponent.update('updated');
      await tester.pump();

      expect(find.text('Counter: 10'), findsOneWidget);
      expect(find.text('Message: updated'), findsOneWidget);
    });

    testWidgets('should call entity listeners', (tester) async {
      final counterComponent = CounterComponent();

      final feature = TestFeature();
      feature.addEntity(counterComponent);

      CounterComponent? listenerCallbackEntity;
      int listenerCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            features: {feature},
            child: ListeningTestWidget(
              onCounterChanged: (entity) {
                listenerCallbackEntity = entity;
                listenerCallCount++;
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Change the counter value
      counterComponent.update(7);
      await tester.pump();

      // Wait for microtask to complete
      await tester.pump(Duration.zero);

      expect(listenerCallCount, equals(1));
      expect(listenerCallbackEntity, equals(counterComponent));
    });

    testWidgets('should call onEnter lifecycle callback', (tester) async {
      bool onEnterCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            features: {TestFeature()},
            child: LifecycleTestWidget(
              onEnter: () => onEnterCalled = true,
            ),
          ),
        ),
      );

      await tester.pump();

      // Wait for postFrameCallback to execute
      await tester.pump(Duration.zero);

      expect(onEnterCalled, isTrue);
    });

    testWidgets('should call onExit lifecycle callback when disposed', (tester) async {
      bool onExitCalled = false;
      bool showWidget = true;

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            features: {TestFeature()},
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    if (showWidget)
                      LifecycleTestWidget(
                        onExit: () => onExitCalled = true,
                      ),
                    ElevatedButton(
                      onPressed: () => setState(() => showWidget = false),
                      child: const Text('Remove Widget'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Remove the widget
      await tester.tap(find.text('Remove Widget'));
      await tester.pump();

      // Wait for microtask to complete
      await tester.pump(Duration.zero);

      expect(onExitCalled, isTrue);
    });

    testWidgets('should not call onEnter multiple times', (tester) async {
      int onEnterCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            features: {TestFeature()},
            child: LifecycleTestWidget(
              onEnter: () => onEnterCallCount++,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(Duration.zero);

      // Trigger a rebuild
      await tester.pump();
      await tester.pump(Duration.zero);

      expect(onEnterCallCount, equals(1));
    });

    testWidgets('should not call onExit multiple times', (tester) async {
      int onExitCallCount = 0;
      bool showWidget = true;

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            features: {TestFeature()},
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    if (showWidget)
                      LifecycleTestWidget(
                        onExit: () => onExitCallCount++,
                      ),
                    ElevatedButton(
                      onPressed: () => setState(() => showWidget = false),
                      child: const Text('Remove Widget'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Remove the widget
      await tester.tap(find.text('Remove Widget'));
      await tester.pump();
      await tester.pump(Duration.zero);

      expect(onExitCallCount, equals(1));
    });

    testWidgets('should handle rapid entity changes without excessive rebuilds', (tester) async {
      final counterComponent = CounterComponent();

      final feature = TestFeature();
      feature.addEntity(counterComponent);

      int buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            features: {feature},
            child: BuildCounterWidget(
              onBuild: () => buildCount++,
            ),
          ),
        ),
      );

      await tester.pump();
      final initialBuildCount = buildCount;

      // Make rapid changes
      counterComponent.update(1);
      counterComponent.update(2);
      counterComponent.update(3);

      await tester.pump();

      // Should only rebuild once due to locking mechanism
      expect(buildCount, equals(initialBuildCount + 1));
    });

    testWidgets('should properly clean up watchers and listeners on dispose', (tester) async {
      final counterComponent = CounterComponent();

      final feature = TestFeature();
      feature.addEntity(counterComponent);

      bool showWidget = true;

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            features: {feature},
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    if (showWidget) const WatchingTestWidget(),
                    ElevatedButton(
                      onPressed: () => setState(() => showWidget = false),
                      child: const Text('Remove Widget'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify widget is watching
      expect(find.text('Counter: 0'), findsOneWidget);

      // Remove the widget
      await tester.tap(find.text('Remove Widget'));
      await tester.pump();

      // Change entity after widget disposal - should not cause any issues
      counterComponent.update(99);
      await tester.pump();

      // Widget should be gone and no errors should occur
      expect(find.text('Counter: 0'), findsNothing);
      expect(find.text('Counter: 99'), findsNothing);
    });

    testWidgets('should maintain reference across rebuilds', (tester) async {
      final counterComponent = CounterComponent();

      final feature = TestFeature();
      feature.addEntity(counterComponent);

      bool triggerRebuild = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            features: {feature},
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    const WatchingTestWidget(),
                    ElevatedButton(
                      onPressed: () => setState(() => triggerRebuild = !triggerRebuild),
                      child: Text('Rebuild $triggerRebuild'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // Initial state
      expect(find.text('Counter: 0'), findsOneWidget);

      // Change counter
      counterComponent.update(5);
      await tester.pump();
      expect(find.text('Counter: 5'), findsOneWidget);

      // Trigger parent rebuild
      await tester.tap(find.text('Rebuild false'));
      await tester.pump();

      // Should still show correct value
      expect(find.text('Counter: 5'), findsOneWidget);

      // Change counter again after rebuild
      counterComponent.update(10);
      await tester.pump();
      expect(find.text('Counter: 10'), findsOneWidget);
    });
  });
}
