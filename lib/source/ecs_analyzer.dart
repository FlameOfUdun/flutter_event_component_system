part of '../flutter_event_component_system.dart';

final class ECSNode {
  final Type type;
  final String description;
  final Set<ECSEdge> outgoing = {};
  final Set<ECSEdge> incoming = {};

  ECSNode({
    required this.type,
    required this.description,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ECSNode && runtimeType == other.runtimeType && type == other.type;
  }

  @override
  int get hashCode {
    return type.hashCode;
  }

  @override
  String toString() {
    return '$description ($type)';
  }
}

final class ECSEdge {
  final ECSNode from;
  final ECSNode to;
  final Type? type;
  final String? description;

  ECSEdge({
    required this.from,
    required this.to,
    this.type,
    this.description,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ECSEdge && runtimeType == other.runtimeType && from == other.from && to == other.to && type == other.type;
  }

  @override
  int get hashCode {
    return Object.hash(from, to, type);
  }
}

final class ECSFlow {
  final List<ECSNode> nodes;
  final List<ECSEdge> edges;

  ECSFlow({
    required this.nodes,
    required this.edges,
  });

  int get length => nodes.length;

  bool get isCircular => nodes.isNotEmpty && nodes.first == nodes.last;
}

final class ECSSummary {
  final int totalEntities;
  final int totalConnections;
  final int cascadeTriggers;
  final int cascadeTargets;
  final int circularDependencies;
  final int maxFlowDepth;

  const ECSSummary({
    required this.totalEntities,
    required this.totalConnections,
    required this.cascadeTriggers,
    required this.cascadeTargets,
    required this.circularDependencies,
    required this.maxFlowDepth,
  });

  @override
  String toString() {
    return '''
      Cascade Summary:
      - Total Entities: $totalEntities
      - Total Connections: $totalConnections
      - Cascade Triggers: $cascadeTriggers
      - Cascade Targets: $cascadeTargets
      - Circular Dependencies: $circularDependencies
      - Max Flow Depth: $maxFlowDepth
    ''';
  }
}

final class ECSAnalysis {
  final Map<Type, ECSNode> nodes;
  final Set<ECSEdge> edges;

  const ECSAnalysis({
    required this.nodes,
    required this.edges,
  });

  /// Returns all entities that can potentially trigger cascades
  Set<Type> getCascadeTriggers() {
    return nodes.values.where((node) => node.outgoing.isNotEmpty).map((node) => node.type).toSet();
  }

  /// Returns all entities that can be affected by cascades
  Set<Type> getCascadeTargets() {
    return nodes.values.where((node) => node.incoming.isNotEmpty).map((node) => node.type).toSet();
  }

  /// Returns a summary of the cascade system
  ECSSummary getCascadeSummary() {
    final circular = getCircularDependencies();

    var maxDepth = 0;
    for (final type in nodes.keys) {
      final flows = getCascadeFlowsFrom(type, maxDepth: 20);
      for (final flow in flows) {
        if (!flow.isCircular && flow.length > maxDepth) {
          maxDepth = flow.length;
        }
      }
    }

    return ECSSummary(
      totalEntities: nodes.length,
      totalConnections: edges.length,
      cascadeTriggers: getCascadeTriggers().length,
      cascadeTargets: getCascadeTargets().length,
      circularDependencies: circular.length,
      maxFlowDepth: maxDepth,
    );
  }

  /// Finds all potential cascade flows from a specific entity type
  List<ECSFlow> getCascadeFlowsFrom(
    Type entityType, {
    int maxDepth = 10,
  }) {
    final startNode = nodes[entityType];
    if (startNode == null) return [];

    final flows = <ECSFlow>[];
    final visited = <ECSNode>{};

    void findFlowsRecursive(
      ECSNode currentNode,
      List<ECSNode> currentPath,
      List<ECSEdge> currentEdges,
      List<ECSFlow> flows,
      Set<ECSNode> visited,
      int remainingDepth,
    ) {
      if (remainingDepth <= 0) return;

      currentPath.add(currentNode);

      if (visited.contains(currentNode)) {
        flows.add(ECSFlow(
          nodes: List.from(currentPath),
          edges: List.from(currentEdges),
        ));
        currentPath.removeLast();
        return;
      }

      visited.add(currentNode);

      if (currentNode.outgoing.isEmpty) {
        flows.add(ECSFlow(
          nodes: List.from(currentPath),
          edges: List.from(currentEdges),
        ));
      } else {
        // Continue exploring outgoing edges
        for (final edge in currentNode.outgoing) {
          currentEdges.add(edge);
          findFlowsRecursive(
            edge.to,
            currentPath,
            currentEdges,
            flows,
            visited,
            remainingDepth - 1,
          );
          currentEdges.removeLast();
        }
      }

      visited.remove(currentNode);
      currentPath.removeLast();
    }

    findFlowsRecursive(
      startNode,
      [],
      [],
      flows,
      visited,
      maxDepth,
    );

    return flows;
  }

  /// Returns all circular dependencies in the system
  List<ECSFlow> getCircularDependencies() {
    final circularFlows = <ECSFlow>[];
    final visited = <ECSNode>{};
    final recursionStack = <ECSNode>{};

    void findCircularDependencies(
      ECSNode node,
      Set<ECSNode> visited,
      Set<ECSNode> recursionStack,
      List<ECSNode> path,
      List<ECSEdge> edges,
      List<ECSFlow> circularFlows,
    ) {
      visited.add(node);
      recursionStack.add(node);
      path.add(node);

      for (final edge in node.outgoing) {
        final neighbor = edge.to;
        edges.add(edge);

        if (!visited.contains(neighbor)) {
          findCircularDependencies(neighbor, visited, recursionStack, path, edges, circularFlows);
        } else if (recursionStack.contains(neighbor)) {
          final cycleStartIndex = path.indexOf(neighbor);
          final cyclePath = path.sublist(cycleStartIndex);
          cyclePath.add(neighbor);

          final cycleEdges = edges.sublist(cycleStartIndex);

          circularFlows.add(ECSFlow(
            nodes: List.from(cyclePath),
            edges: List.from(cycleEdges),
          ));
        }

        edges.removeLast();
      }

      path.removeLast();
      recursionStack.remove(node);
    }

    for (final node in nodes.values) {
      if (!visited.contains(node)) {
        findCircularDependencies(node, visited, recursionStack, [], [], circularFlows);
      }
    }

    return circularFlows;
  }

  /// Returns cascade analysis
  List<String> getCascadeAnalysis() {
    final steps = <String>[];

    steps.add('Circular Dependencies:');
    final circular = getCircularDependencies();
    if (circular.isEmpty) {
      steps.add('✅ No circular dependencies found');
    } else {
      for (var index = 0; index < circular.length; index++) {
        final flow = circular[index];
        final description = flow.nodes.map((node) => node.type.toString()).join(' -> ');
        final means = flow.edges.map((edge) => edge.type.toString()).join(', ');
        steps.add('${index + 1}. $description via $means');
      }
    }
    steps.add('');

    steps.add('Cascade Triggers:');
    final triggers = getCascadeTriggers();
    if (triggers.isEmpty) {
      steps.add('No cascade triggers found');
    } else {
      for (final trigger in triggers) {
        final flows = getCascadeFlowsFrom(trigger);
        steps.add('• $trigger -> ${flows.length} potential flows');
      }
    }
    steps.add('');

    steps.add('Cascade Targets:');
    final targets = getCascadeTargets();
    if (targets.isEmpty) {
      steps.add('No cascade targets found');
    } else {
      for (final target in targets) {
        steps.add('• $target');
      }
    }

    return steps;
  }

  /// Get detailed flows for a specific entity type
  List<String> getFlowsForEntity(Type entityType) {
    final steps = <String>[];

    final flows = getCascadeFlowsFrom(entityType);

    steps.add('=== FLOWS FROM $entityType ===');
    if (flows.isEmpty) {
      steps.add('No flows found from $entityType');
      return steps;
    }

    for (int i = 0; i < flows.length; i++) {
      final flow = flows[i];
      steps.add('Flow ${i + 1}:');

      if (flow.isCircular) {
        steps.add('  ⚠️  CIRCULAR DEPENDENCY');
      }

      for (int j = 0; j < flow.nodes.length; j++) {
        final node = flow.nodes[j];
        steps.add('  ${j + 1}. ${node.description}: ${node.type}');

        if (j < flow.edges.length) {
          final edge = flow.edges[j];
          steps.add('     └─ via ${edge.type}');
        }
      }
      steps.add('');
    }

    return steps;
  }

  /// Validates the cascade system and returns issues
  List<String> validateCascadeSystem() {
    final issues = <String>[];

    // Check for circular dependencies
    final circular = getCircularDependencies();
    for (final flow in circular) {
      issues.add('Circular dependency: ${flow.toString()}');
    }

    // Check for very deep cascades (potential performance issues)
    final summary = getCascadeSummary();
    if (summary.maxFlowDepth > 5) {
      issues.add('Very deep cascade flows detected (max depth: ${summary.maxFlowDepth})');
    }

    final triggers = getCascadeTriggers();
    for (final trigger in triggers) {
      final flows = getCascadeFlowsFrom(trigger);
      if (flows.length > 10) {
        issues.add('Entity $trigger has too many outgoing connections (${flows.length})');
      }
    }

    return issues;
  }

  /// Generates a DOT graph representation for visualization
  String generateDotGraph() {
    final buffer = StringBuffer();
    buffer.writeln('digraph ECS_Cascade_Flow {');
    buffer.writeln('  rankdir=TB;');
    buffer.writeln('  node [shape=box];');
    buffer.writeln('');

    for (final node in nodes.values) {
      if (node.incoming.isEmpty && node.outgoing.isEmpty) continue;
      final String color;
      if (node.type.toString().contains('Component')) {
        color = 'yellow';
      } else if (node.type.toString().contains('Event')) {
        color = 'green';
      } else if (["InitializeSystem", "ExecuteSystem"].contains(node.type.toString())) {
        color = 'red';
      } else {
        color = 'purple';
      }
      buffer.writeln('  "${node.type}" [fillcolor=$color, style=filled];');
    }

    buffer.writeln('');

    for (final edge in edges) {
      buffer.writeln('  "${edge.from.type}" -> "${edge.to.type}"');
      if (edge.type == null) {
        buffer.write(";");
      } else {
        buffer.write('[label="${edge.type}"];');
      }
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  /// Simulates a cascade flow from a specific entity type
  List<String> simulateCascadeFlow(Type triggerEntity) {
    final flows = getCascadeFlowsFrom(triggerEntity);

    final simulation = <String>[];
    simulation.add('Simulating cascade from $triggerEntity:');

    if (flows.isEmpty) {
      simulation.add('  No cascade flows triggered');
      return simulation;
    }

    for (int i = 0; i < flows.length; i++) {
      final flow = flows[i];
      simulation.add('  Flow ${i + 1}:');

      for (int j = 0; j < flow.edges.length; j++) {
        final edge = flow.edges[j];
        simulation.add('    ${edge.from.type} triggers ${edge.type}');
        simulation.add('    ${edge.type} affects ${edge.to.type}');
      }

      if (flow.isCircular) {
        simulation.add('    ⚠️  This creates a circular dependency!');
      }
    }

    return simulation;
  }
}

class ECSAnalyzer {
  static final Map<Type, ECSNode> _nodes = {};
  static final Set<ECSEdge> _edges = {};
  static ECSAnalysis? _graph;
  static final ECSNode _executeNode = ECSNode(
    type: ExecuteSystem,
    description: 'Execute',
  );
  static final ECSNode _initializeNode = ECSNode(
    type: InitializeSystem,
    description: 'Initialize',
  );

  ECSAnalyzer._();

  static ECSAnalysis? get graph {
    return _graph;
  }

  /// Builds the cascade graph for the ECS system
  static ECSAnalysis analize(ECSManager manager) {
    _nodes.clear();
    _nodes[_executeNode.type] = _executeNode;
    _nodes[_initializeNode.type] = _initializeNode;

    _edges.clear();

    for (final feature in manager.features) {
      for (final entity in feature.entities) {
        _createNodeForEntity(entity.runtimeType);
      }
    }

    for (final feature in manager.features) {
      for (final entry in feature.reactiveSystems.entries) {
        final triggerType = entry.key;
        final systems = entry.value;

        for (final system in systems) {
          _createEdgesForSystem(triggerType, system);
        }
      }

      for (final system in feature.initializeSystems) {
        _createNodeForInitializeSystem(system);
      }

      for (final system in feature.teardownSystems) {
        _createNodeForSystem(system);
      }

      for (final system in feature.cleanupSystems) {
        _createNodeForSystem(system);
      }

      for (final system in feature.executeSystems) {
        _createNodeForExecuteSystem(system);
      }
    }

    return ECSAnalysis(
      nodes: Map.unmodifiable(_nodes),
      edges: Set.unmodifiable(_edges),
    );
  }

  static void _createNodeForEntity(Type entityType) {
    if (_nodes.containsKey(entityType)) return;

    final String description;
    if (entityType.toString().contains('Component')) {
      description = 'Component';
    } else {
      description = 'Event';
    }

    _nodes[entityType] = ECSNode(
      type: entityType,
      description: description,
    );
  }

  static void _createEdgesForSystem(Type triggerType, ReactiveSystem system) {
    final fromNode = _nodes[triggerType];
    if (fromNode == null) return;

    for (final interactionType in system.interactsWith) {
      _createNodeForEntity(interactionType);
      final toNode = _nodes[interactionType];
      if (toNode == null) continue;

      final edge = ECSEdge(
        from: fromNode,
        to: toNode,
        type: system.runtimeType,
        description: system.runtimeType.toString(),
      );

      _edges.add(edge);
      fromNode.outgoing.add(edge);
      toNode.incoming.add(edge);
    }
  }

  static void _createNodeForSystem(ECSSystem system) {
    if (system.interactsWith.isEmpty) return;

    final systemNode = _nodes.putIfAbsent(system.runtimeType, () {
      return ECSNode(
        type: system.runtimeType,
        description: system.runtimeType.toString(),
      );
    });

    for (final type in system.interactsWith) {
      _createNodeForEntity(type);
      final entityNode = _nodes[type];
      if (entityNode == null) continue;

      final outgoingEdge = ECSEdge(
        from: systemNode,
        to: entityNode,
      );

      _edges.add(outgoingEdge);

      systemNode.outgoing.add(outgoingEdge);
      entityNode.incoming.add(outgoingEdge);
    }
  }

  static void _createNodeForInitializeSystem(InitializeSystem system) {
    if (system.interactsWith.isEmpty) return;

    for (final type in system.interactsWith) {
      _createNodeForEntity(type);
      final entityNode = _nodes[type];
      if (entityNode == null) continue;

      final outgoingEdge = ECSEdge(
        from: _initializeNode,
        to: entityNode,
        type: system.runtimeType,
      );

      _edges.add(outgoingEdge);

      _initializeNode.outgoing.add(outgoingEdge);
      entityNode.incoming.add(outgoingEdge);
    }
  }

  static void _createNodeForExecuteSystem(ExecuteSystem system) {
    if (system.interactsWith.isEmpty) return;

    for (final type in system.interactsWith) {
      _createNodeForEntity(type);
      final entityNode = _nodes[type];
      if (entityNode == null) continue;

      final outgoingEdge = ECSEdge(
        from: _executeNode,
        to: entityNode,
        type: system.runtimeType,
      );

      _edges.add(outgoingEdge);

      _executeNode.outgoing.add(outgoingEdge);
      entityNode.incoming.add(outgoingEdge);
    }
  }
}
