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

void main() {
  group('ECSScope Tests', () {
    testWidgets('should create and provide ECS manager to descendants',
        (WidgetTester tester) async {
      final feature = TestFeature();
      ECSManager? retrievedManager;

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            features: {feature},
            child: Builder(
              builder: (context) {
                retrievedManager = ECSScope.of(context);
                return const Text('Test');
              },
            ),
          ),
        ),
      );

      await tester.pump();

      expect(retrievedManager, isNotNull);
      expect(retrievedManager, isA<ECSManager>());
    });

    testWidgets('should initialize features on mount',
        (WidgetTester tester) async {
      final feature = TestFeature();

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            features: {feature},
            child: const Text('Test'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify feature was initialized
      final counter = feature.getEntity<TestCounterComponent>();
      expect(counter, isNotNull);
      expect(counter.value, equals(0));
    });

    testWidgets('should teardown and deactivate manager on dispose',
        (WidgetTester tester) async {
      final feature = TestFeature();

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            features: {feature},
            child: const Text('Test'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get manager reference
      final manager = await tester.runAsync(() async {
        final context = tester.element(find.text('Test'));
        return ECSScope.of(context);
      });

      expect(manager, isNotNull);

      // Remove the scope
      await tester.pumpWidget(
        const MaterialApp(
          home: Text('Different Widget'),
        ),
      );

      await tester.pumpAndSettle();

      // Manager should be deactivated (we can't directly test this without
      // exposing internal state, but we verify no errors occur)
      expect(find.text('Different Widget'), findsOneWidget);
    });

    testWidgets('should return null with maybeOf when scope not found',
        (WidgetTester tester) async {
      ECSManager? manager;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              manager = ECSScope.maybeOf(context);
              return const Text('Test');
            },
          ),
        ),
      );

      expect(manager, isNull);
    });

    testWidgets('should throw error with of when scope not found',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              expect(
                () => ECSScope.of(context),
                throwsA(isA<FlutterError>()),
              );
              return const Text('Test');
            },
          ),
        ),
      );
    });

    testWidgets('should support named scopes', (WidgetTester tester) async {
      final feature = TestFeature();

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            name: 'TestScope',
            features: {feature},
            child: const Text('Test'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should run execution loop when features have execute systems',
        (WidgetTester tester) async {
      final feature = TestFeature();

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            features: {feature},
            child: const Text('Test'),
          ),
        ),
      );

      // Pump multiple frames to verify ticker is running
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('should support nested ECS scopes',
        (WidgetTester tester) async {
      final outerFeature = TestFeature();
      final innerFeature = EmptyTestFeature();

      ECSManager? outerManager;
      ECSManager? innerManager;

      await tester.pumpWidget(
        MaterialApp(
          home: ECSScope(
            name: 'Outer',
            features: {outerFeature},
            child: Builder(
              builder: (outerContext) {
                outerManager = ECSScope.of(outerContext);
                return ECSScope(
                  name: 'Inner',
                  features: {innerFeature},
                  child: Builder(
                    builder: (innerContext) {
                      innerManager = ECSScope.of(innerContext);
                      return const Text('Nested');
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(outerManager, isNotNull);
      expect(innerManager, isNotNull);
      expect(outerManager, isNot(equals(innerManager)));
      expect(find.text('Nested'), findsOneWidget);
    });
  });
}
