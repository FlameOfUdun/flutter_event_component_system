import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import '../models/ecs_manager_data.dart';
import 'ecs_event_provider.dart';

final class ECSGraphView extends StatefulWidget {
  const ECSGraphView({super.key});

  @override
  State<ECSGraphView> createState() => _ECSGraphViewState();
}

final class _ECSGraphViewState extends State<ECSGraphView> {
  final graph = Graph();
  final data = <String, _NodeData>{};
  final controller = TextEditingController();
  final builder = SugiyamaConfiguration()
    ..nodeSeparation = 50
    ..levelSeparation = 100
    ..iterations = 1000
    ..orientation = SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

  Node? selected;
  List<Node> cascade = [];
  List<Node> filtered = [];

  void select(Node? start) {
    final visited = <Node>{};

    void visit(Node node) {
      if (visited.contains(node)) return;
      visited.add(node);
      for (final edge in graph.edges) {
        if (edge.source == node) {
          visit(edge.destination);
          edge.paint = Paint()
            ..color = Colors.yellow
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke;
        }
      }
    }

    if (start != null) {
      visit(start);
    }

    for (final edge in graph.edges) {
      if (!visited.contains(edge.source) || !visited.contains(edge.destination)) {
        edge.paint = Paint()
          ..color = Colors.grey
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
      }
    }

    selected = start;
    cascade = visited.toList();

    setState(() {});
  }

  void filter(String query) {
    if (query.isEmpty) {
      filtered = [];
    } else {
      final lowerQuery = query.toLowerCase();
      final matchedNodes = graph.nodes.where((node) {
        final nodeData = data[node.key!.value as String]!;
        return nodeData.label.toLowerCase().contains(lowerQuery) || nodeData.feature.toLowerCase().contains(lowerQuery);
      }).toSet();
      filtered = matchedNodes.toList();
    }

    setState(() {});
  }

  void update(ECSManagerData manager) {
    data.clear();

    graph.nodes.clear();
    graph.edges.clear();

    final initializeNode = Node.Id('Lifecycle.OnInitialize');
    graph.addNode(initializeNode);
    data['Lifecycle.OnInitialize'] = _NodeData(feature: 'Lifecycle', label: 'OnInitialize', color: Colors.purple);

    final executeNode = Node.Id('Lifecycle.OnExecute');
    graph.addNode(executeNode);
    data['Lifecycle.OnExecute'] = _NodeData(feature: 'Lifecycle', label: 'OnExecute', color: Colors.purple);

    final cleanupNode = Node.Id('Lifecycle.OnCleanup');
    graph.addNode(cleanupNode);
    data['Lifecycle.OnCleanup'] = _NodeData(feature: 'Lifecycle', label: 'OnCleanup', color: Colors.purple);

    final teardownNode = Node.Id('Lifecycle.OnTeardown');
    graph.addNode(teardownNode);
    data['Lifecycle.OnTeardown'] = _NodeData(feature: 'Lifecycle', label: 'OnTeardown', color: Colors.purple);

    for (final feature in manager.features) {
      for (final entity in feature.entities) {
        final entityNode = Node.Id(entity.id);
        graph.addNode(entityNode);
        data[entity.id] = _NodeData(feature: feature.name, label: entity.name, color: entity.type == "Component" ? Colors.green : Colors.orange);
      }

      for (final system in feature.systems) {
        final systemNode = Node.Id(system.id);
        graph.addNode(systemNode);
        data[system.id] = _NodeData(feature: feature.name, label: system.name, color: Colors.blue);
      }
    }

    for (final feature in manager.features) {
      for (final system in feature.systems) {
        final systemNode = Node.Id(system.id);

        if (system.type == "InitializeSystem") {
          graph.addEdge(Node.Id('Lifecycle.OnInitialize'), systemNode);
        } else if (system.type == "ExecuteSystem") {
          graph.addEdge(Node.Id('Lifecycle.OnExecute'), systemNode);
        } else if (system.type == "CleanupSystem") {
          graph.addEdge(Node.Id('Lifecycle.OnCleanup'), systemNode);
        } else if (system.type == "TeardownSystem") {
          graph.addEdge(Node.Id('Lifecycle.OnTeardown'), systemNode);
        } else {
          for (final reactTo in system.reactsTo) {
            graph.addEdge(Node.Id(reactTo), systemNode);
          }
        }

        for (final interactWith in system.interactsWith) {
          graph.addEdge(systemNode, Node.Id(interactWith));
        }
      }
    }

    setState(() {});
  }

  @override
  void initState() {
    controller.addListener(() {
      filter(controller.text);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      refresh();
    });

    super.initState();
  }

  void refresh() async {
    final provider = ECSEventProvider.of(context);
    await provider.waitForServiceInit();
    final data = await provider.requestManagerData();
    update(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                constrained: false,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.1,
                maxScale: 5,
                alignment: Alignment.center,
                child: GraphView(
                  graph: graph,
                  centerGraph: true,
                  algorithm: SugiyamaAlgorithm(builder),
                  paint: Paint()
                    ..color = Colors.grey
                    ..strokeWidth = 1
                    ..style = PaintingStyle.stroke,
                  builder: (node) {
                    final id = node.key!.value as String;
                    final nodeData = data[id]!;
                    final inFilter = filtered.isEmpty || filtered.contains(node);
                    final inCascade = cascade.contains(node);
                    final isSelected = selected == node;

                    return InkWell(
                      onTap: () {
                        select(node);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: inFilter ? nodeData.color : Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: inCascade ? Colors.yellow : Colors.grey.shade300, width: 4),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isSelected) Text(nodeData.feature, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
                            Text(
                              nodeData.label,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Filter nodes...',
                      fillColor: Colors.white,
                      filled: true,
                      isDense: true,
                      border: OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: IconButton(icon: Icon(Icons.clear), onPressed: controller.clear),
                      ),
                    ),
                  ),
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
                Spacer(),
                Container(width: 16, height: 16, color: Colors.green),
                const SizedBox(width: 8),
                const Text('Component', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 16),
                Container(width: 16, height: 16, color: Colors.orange),
                const SizedBox(width: 8),
                const Text('Event', style: TextStyle(color: Colors.white)),
                const SizedBox(width: 16),
                Container(width: 16, height: 16, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('System', style: TextStyle(color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final class _NodeData {
  final String feature;
  final String label;
  final Color color;

  const _NodeData({required this.feature, required this.label, required this.color});
}
