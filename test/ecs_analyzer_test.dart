import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_event_component_system/src/ecs_base.dart';

class TestEvent extends ECSEvent {}

class TestComponent extends ECSComponent<int> {
  TestComponent([super.value = 0]);
}

class AnotherEvent extends ECSEvent {}

// Test systems
class TestReactiveSystem extends ReactiveSystem {
  @override
  Set<Type> get reactsTo => {TestEvent};

  @override
  Set<Type> get interactsWith => {TestComponent, AnotherEvent};

  @override
  void react() {}
}

class AnotherReactiveSystem extends ReactiveSystem {
  @override
  Set<Type> get reactsTo => {TestComponent};

  @override
  Set<Type> get interactsWith => {AnotherEvent};

  @override
  void react() {}
}

class TestFeature extends ECSFeature {
  TestFeature() {
    addEntity(TestEvent());
    addEntity(TestComponent());
    addEntity(AnotherEvent());

    addSystem(TestReactiveSystem());
    addSystem(AnotherReactiveSystem());
  }
}

void main() {
  group('Cascade Flow Analysis Tests', () {
    late ECSManager manager;

    setUp(() {
      manager = ECSManager();
      manager.addFeature(TestFeature());
    });

    test('should build cascade graph', () {
      final graph = ECSAnalyzer.analize(manager);

      expect(graph.nodes.isNotEmpty, true);
      expect(graph.edges.isNotEmpty, true);
    });

    test('should detect cascade flows from TestEvent', () {
      final graph = ECSAnalyzer.analize(manager);
      final flows = graph.getCascadeFlowsFrom(TestEvent);

      expect(flows.isNotEmpty, true);

      // TestEvent should trigger flows through TestReactiveSystem
      final flow = flows.first;
      expect(flow.nodes.first.type, TestEvent);
    });

    test('should get cascade summary', () {
      final graph = ECSAnalyzer.analize(manager);
      final summary = graph.getCascadeSummary();

      expect(summary.totalEntities, greaterThan(0));
      expect(summary.totalConnections, greaterThan(0));
    });

    test('should identify cascade triggers', () {
      final graph = ECSAnalyzer.analize(manager);
      final triggers = graph.getCascadeTriggers();

      expect(triggers.contains(TestEvent), true);
      expect(triggers.contains(TestComponent), true);
    });

    test('should identify cascade targets', () {
      final graph = ECSAnalyzer.analize(manager);
      final targets = graph.getCascadeTargets();

      expect(targets.contains(TestComponent), true);
      expect(targets.contains(AnotherEvent), true);
    });

    test('should detect no circular dependencies in simple case', () {
      final graph = ECSAnalyzer.analize(manager);
      final circular = graph.getCircularDependencies();

      expect(circular.isEmpty, true);
    });

    test('should validate system without issues', () {
      final graph = ECSAnalyzer.analize(manager);
      final issues = graph.validateCascadeSystem();

      expect(issues.isEmpty, true);
    });

    test('should generate DOT graph', () {
      final graph = ECSAnalyzer.analize(manager);
      final dotGraph = graph.generateDotGraph();

      expect(dotGraph.contains('digraph ECS_Cascade_Flow'), true);
      expect(dotGraph.contains('TestEvent'), true);
      expect(dotGraph.contains('TestComponent'), true);
    });

    test('should simulate cascade flow', () {
      final graph = ECSAnalyzer.analize(manager);
      final simulation = graph.simulateCascadeFlow(TestEvent);

      expect(simulation.isNotEmpty, true);
      expect(simulation.first.contains('TestEvent'), true);
    });
  });

  group('Circular Dependency Detection Tests', () {
    test('should detect circular dependencies', () {
      final manager = ECSManager();

      // Create a circular dependency
      final feature = _CircularTestFeature();
      manager.addFeature(feature);

      final graph = ECSAnalyzer.analize(manager);
      final circular = graph.getCircularDependencies();

      expect(circular.isNotEmpty, true);

      final cycle = circular.first;
      expect(cycle.isCircular, true);
    });
  });
}

// Test feature that creates circular dependencies
class CircularEvent1 extends ECSEvent {}

class CircularEvent2 extends ECSEvent {}

class CircularSystem1 extends ReactiveSystem {
  @override
  Set<Type> get reactsTo => {CircularEvent1};

  @override
  Set<Type> get interactsWith => {CircularEvent2};

  @override
  void react() {}
}

class CircularSystem2 extends ReactiveSystem {
  @override
  Set<Type> get reactsTo => {CircularEvent2};

  @override
  Set<Type> get interactsWith => {CircularEvent1};

  @override
  void react() {}
}

class _CircularTestFeature extends ECSFeature {
  _CircularTestFeature() {
    addEntity(CircularEvent1());
    addEntity(CircularEvent2());

    addSystem(CircularSystem1());
    addSystem(CircularSystem2());
  }
}
