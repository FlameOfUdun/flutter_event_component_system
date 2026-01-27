import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart' as gv;

import '../../models/inspector_data.dart';
import '../../state/inspector_state.dart';
import '../../theme/inspector_theme.dart';
import '../components/filter_chip_row.dart';
import '../components/search_field.dart';

/// Graph visualization view for the ECS system.
class ECSGraphView extends StatefulWidget {
  final InspectorState state;

  const ECSGraphView({super.key, required this.state});

  @override
  State<ECSGraphView> createState() => _ECSGraphViewState();
}

class _ECSGraphViewState extends State<ECSGraphView> {
  final _graph = gv.Graph();
  final _builder = gv.SugiyamaConfiguration()
    ..nodeSeparation = 50
    ..levelSeparation = 100
    ..orientation = gv.SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;

  final _transformationController = TransformationController();
  final Map<String, _NodeData> _nodeDataMap = {};
  final Map<String, gv.Node> _nodeMap = {};

  InspectorData? _lastData;
  gv.Node? _selectedNode;
  Set<gv.Node> _cascadeNodes = {};
  List<gv.Node> _filteredNodes = [];

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// Select a node and highlight all connected edges/nodes in cascade.
  void _selectNode(gv.Node? node) {
    final visited = <gv.Node>{};

    void visit(gv.Node n) {
      if (visited.contains(n)) return;
      visited.add(n);

      for (final edge in _graph.edges) {
        if (edge.source == n) {
          visit(edge.destination);
          // Highlight edge in cascade
          edge.paint = Paint()
            ..color = InspectorTheme.selectedColor
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke;
        }
      }
    }

    if (node != null) {
      visit(node);
    }

    // Reset non-cascade edges to grey
    for (final edge in _graph.edges) {
      if (!visited.contains(edge.source) || !visited.contains(edge.destination)) {
        edge.paint = Paint()
          ..color = InspectorTheme.defaultEdgeColor
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
      }
    }

    _selectedNode = node;
    _cascadeNodes = visited;

    // Update the state's selected node
    final nodeId = node != null ? node.key?.value as String? : null;
    widget.state.selectNode(nodeId);

    setState(() {});
  }

  /// Filter nodes by search query.
  void _filterNodes(String query) {
    if (query.isEmpty) {
      _filteredNodes = [];
    } else {
      final lowerQuery = query.toLowerCase();
      _filteredNodes = _graph.nodes.where((node) {
        final nodeData = _nodeDataMap[node.key?.value as String?];
        if (nodeData == null) return false;
        return nodeData.name.toLowerCase().contains(lowerQuery) ||
            (nodeData.featureName?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) {
        final data = widget.state.data;
        final filter = widget.state.graphFilter;

        // Rebuild graph if data changed
        if (data != _lastData) {
          _lastData = data;
          _buildGraph(data);
        }

        return Column(
          children: [
            _buildToolbar(context, filter),
            const Divider(height: 1),
            Expanded(child: _buildGraphView(context)),
            _buildLegend(),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context, GraphFilter filter) {
    final features = widget.state.data.featureNames.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SearchField(
                  hintText: 'Filter nodes...',
                  onChanged: (query) {
                    _filterNodes(query);
                    widget.state.setGraphFilter(
                      filter.copyWith(searchQuery: query),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () => widget.state.refresh(),
                tooltip: 'Refresh',
                visualDensity: VisualDensity.compact,
              ),
              _buildZoomControls(),
            ],
          ),
          const SizedBox(height: 12),
          if (features.isNotEmpty)
            MultiFilterChipRow<String>(
              label: 'Features',
              options: features,
              selected: filter.selectedFeatures,
              labelBuilder: (f) => f,
              onChanged: (selectedSet) {
                widget.state.setGraphFilter(
                  filter.copyWith(selectedFeatures: selectedSet),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.zoom_out, size: 20),
          onPressed: _zoomOut,
          tooltip: 'Zoom Out',
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          icon: const Icon(Icons.fit_screen, size: 20),
          onPressed: _resetZoom,
          tooltip: 'Fit to Screen',
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          icon: const Icon(Icons.zoom_in, size: 20),
          onPressed: _zoomIn,
          tooltip: 'Zoom In',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildGraphView(BuildContext context) {
    if (_graph.nodeCount() == 0) {
      return const Center(
        child: Text('No data to display'),
      );
    }

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      minScale: 0.1,
      maxScale: 5.0,
      transformationController: _transformationController,
      child: gv.GraphView(
        graph: _graph,
        algorithm: gv.SugiyamaAlgorithm(_builder),
        paint: Paint()
          ..color = InspectorTheme.defaultEdgeColor
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
        builder: (node) => _buildNode(node),
      ),
    );
  }

  Widget _buildNode(gv.Node node) {
    final nodeId = node.key?.value as String?;
    final nodeData = _nodeDataMap[nodeId];
    if (nodeData == null) {
      return const SizedBox.shrink();
    }

    final filter = widget.state.graphFilter;
    final isSelected = _selectedNode == node;
    final inCascade = _cascadeNodes.contains(node);
    final inFilter = _filteredNodes.isEmpty || _filteredNodes.contains(node);

    // Check if node matches feature filter (empty set = show all)
    final matchesFeature = filter.matchesFeature(nodeData.featureName);

    if (!matchesFeature) {
      return Opacity(
        opacity: 0.2,
        child: _buildNodeContent(nodeData, false, false),
      );
    }

    return GestureDetector(
      onTap: () => _selectNode(isSelected ? null : node),
      child: _buildNodeContent(nodeData, isSelected, inCascade, inFilter: inFilter),
    );
  }

  Widget _buildNodeContent(_NodeData data, bool isSelected, bool inCascade, {bool inFilter = true}) {
    final color = switch (data.type) {
      _NodeType.component => InspectorTheme.componentColor,
      _NodeType.event => InspectorTheme.eventColor,
      _NodeType.system => InspectorTheme.systemColor,
      _NodeType.lifecycle => InspectorTheme.lifecycleColor,
    };

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: inFilter ? color : Colors.grey,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: inCascade ? InspectorTheme.selectedColor : Colors.grey.shade600,
          width: inCascade ? 4 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSelected && data.featureName != null)
            Text(
              data.featureName!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          Text(
            data.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (isSelected && data.subtitle != null)
            Text(
              data.subtitle!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: InspectorTheme.cardBackground,
        border: Border(
          top: BorderSide(color: InspectorTheme.elevatedBackground),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(color: InspectorTheme.componentColor, label: 'Component'),
          const SizedBox(width: 24),
          _LegendItem(color: InspectorTheme.eventColor, label: 'Event'),
          const SizedBox(width: 24),
          _LegendItem(color: InspectorTheme.systemColor, label: 'System'),
          const SizedBox(width: 24),
          _LegendItem(color: InspectorTheme.lifecycleColor, label: 'Lifecycle'),
          const Spacer(),
          if (_selectedNode != null)
            TextButton.icon(
              onPressed: () => _selectNode(null),
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear Selection'),
            ),
        ],
      ),
    );
  }

  void _buildGraph(InspectorData data) {
    // Preserve selected node ID before clearing
    final previousSelectedId = _selectedNode?.key?.value as String?;

    _graph.nodes.clear();
    _graph.edges.clear();
    _nodeDataMap.clear();
    _nodeMap.clear();
    _selectedNode = null;
    _cascadeNodes = {};

    // Add lifecycle nodes
    for (final lifecycle in ['OnInitialize', 'OnExecute', 'OnCleanup', 'OnTeardown']) {
      final id = 'Lifecycle.$lifecycle';
      final node = gv.Node.Id(id);
      _graph.addNode(node);
      _nodeMap[id] = node;
      _nodeDataMap[id] = _NodeData(
        id: id,
        name: lifecycle,
        type: _NodeType.lifecycle,
      );
    }

    // Add entities (components and events)
    for (final entity in data.allEntities) {
      final node = gv.Node.Id(entity.identifier);
      _graph.addNode(node);
      _nodeMap[entity.identifier] = node;
      _nodeDataMap[entity.identifier] = _NodeData(
        id: entity.identifier,
        name: entity.name,
        type: entity.isComponent ? _NodeType.component : _NodeType.event,
        featureName: entity.featureName,
        value: entity.value,
      );
    }

    // Add systems and their connections
    for (final system in data.allSystems) {
      final node = gv.Node.Id(system.identifier);
      _graph.addNode(node);
      _nodeMap[system.identifier] = node;
      _nodeDataMap[system.identifier] = _NodeData(
        id: system.identifier,
        name: system.name,
        type: _NodeType.system,
        featureName: system.featureName,
        subtitle: system.type,
      );

      // Connect system to lifecycle based on type
      final lifecycleId = _getLifecycleId(system.type);
      if (lifecycleId != null && _nodeMap.containsKey(lifecycleId)) {
        _graph.addEdge(_nodeMap[lifecycleId]!, node);
      } else {
        // ReactiveSystem - connect from reactsTo entities
        for (final reactsTo in system.reactsTo) {
          if (_nodeMap.containsKey(reactsTo)) {
            _graph.addEdge(_nodeMap[reactsTo]!, node);
          }
        }
      }

      // Connect system to interactsWith entities
      for (final interactsWith in system.interactsWith) {
        if (_nodeMap.containsKey(interactsWith)) {
          _graph.addEdge(node, _nodeMap[interactsWith]!);
        }
      }
    }

    // Restore selection if the node still exists
    if (previousSelectedId != null && _nodeMap.containsKey(previousSelectedId)) {
      _restoreSelection(_nodeMap[previousSelectedId]!);
    }
  }

  /// Restore selection without triggering state update (used during graph rebuild).
  void _restoreSelection(gv.Node node) {
    final visited = <gv.Node>{};

    void visit(gv.Node n) {
      if (visited.contains(n)) return;
      visited.add(n);

      for (final edge in _graph.edges) {
        if (edge.source == n) {
          visit(edge.destination);
          edge.paint = Paint()
            ..color = InspectorTheme.selectedColor
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke;
        }
      }
    }

    visit(node);

    // Reset non-cascade edges
    for (final edge in _graph.edges) {
      if (!visited.contains(edge.source) || !visited.contains(edge.destination)) {
        edge.paint = Paint()
          ..color = InspectorTheme.defaultEdgeColor
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
      }
    }

    _selectedNode = node;
    _cascadeNodes = visited;
  }

  String? _getLifecycleId(String systemType) {
    return switch (systemType) {
      'InitializeSystem' => 'Lifecycle.OnInitialize',
      'ExecuteSystem' => 'Lifecycle.OnExecute',
      'CleanupSystem' => 'Lifecycle.OnCleanup',
      'TeardownSystem' => 'Lifecycle.OnTeardown',
      _ => null, // ReactiveSystem has no lifecycle
    };
  }

  void _zoomIn() {
    final matrix = _transformationController.value.clone();
    matrix.multiply(Matrix4.diagonal3Values(1.2, 1.2, 1.0));
    _transformationController.value = matrix;
  }

  void _zoomOut() {
    final matrix = _transformationController.value.clone();
    matrix.multiply(Matrix4.diagonal3Values(0.8, 0.8, 1.0));
    _transformationController.value = matrix;
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: InspectorTheme.secondaryText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

enum _NodeType { component, event, system, lifecycle }

class _NodeData {
  final String id;
  final String name;
  final _NodeType type;
  final String? featureName;
  final String? subtitle;
  final String? value;

  const _NodeData({
    required this.id,
    required this.name,
    required this.type,
    this.featureName,
    this.subtitle,
    this.value,
  });
}
