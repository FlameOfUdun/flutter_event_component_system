import 'dart:async';

import 'package:devtools_app_shared/service.dart';
import 'package:flutter/foundation.dart';

import '../models/inspector_data.dart';
import '../services/ecs_service.dart';

/// View mode for the inspector.
enum InspectorView { graph, entities, logs }

/// Filter state for entities.
final class EntityFilter {
  final String searchQuery;
  final String? featureName;
  final EntityType? type;

  const EntityFilter({
    this.searchQuery = '',
    this.featureName,
    this.type,
  });

  EntityFilter copyWith({
    String? searchQuery,
    String? featureName,
    EntityType? type,
    bool clearFeature = false,
    bool clearType = false,
  }) {
    return EntityFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      featureName: clearFeature ? null : (featureName ?? this.featureName),
      type: clearType ? null : (type ?? this.type),
    );
  }

  bool matches(EntityData entity) {
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      if (!entity.name.toLowerCase().contains(query) &&
          !entity.identifier.toLowerCase().contains(query)) {
        return false;
      }
    }

    if (featureName != null && entity.featureName != featureName) {
      return false;
    }

    if (type != null && entity.type != type) {
      return false;
    }

    return true;
  }
}

/// Filter state for logs.
final class LogFilter {
  final DateTime? clearTime;
  final String searchQuery;
  final Set<LogLevel> levels;
  final String? featureName;

  const LogFilter({
    this.clearTime,
    this.searchQuery = '',
    this.levels = const {},
    this.featureName,
  });

  LogFilter copyWith({
    String? searchQuery,
    Set<LogLevel>? levels,
    String? featureName,
    DateTime? clearTime,
    bool clearFeature = false,
  }) {
    return LogFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      levels: levels ?? this.levels,
      clearTime: clearTime ?? this.clearTime,
      featureName: clearFeature ? null : (featureName ?? this.featureName),
    );
  }

  bool matches(LogData log) {
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      if (!log.message.toLowerCase().contains(query)) {
        return false;
      }
    }

    if (levels.isNotEmpty && !levels.contains(log.level)) {
      return false;
    }

    if (featureName != null && log.featureName != featureName) {
      return false;
    }

    if (clearTime != null && log.time.isBefore(clearTime!)) {
      return false;
    }

    return true;
  }
}

/// Filter state for graph view.
final class GraphFilter {
  final String searchQuery;
  final Set<String> selectedFeatures;
  final bool showComponents;
  final bool showEvents;
  final bool showSystems;
  final bool showLifecycle;

  const GraphFilter({
    this.searchQuery = '',
    this.selectedFeatures = const {},
    this.showComponents = true,
    this.showEvents = true,
    this.showSystems = true,
    this.showLifecycle = true,
  });

  GraphFilter copyWith({
    String? searchQuery,
    Set<String>? selectedFeatures,
    bool? showComponents,
    bool? showEvents,
    bool? showSystems,
    bool? showLifecycle,
  }) {
    return GraphFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFeatures: selectedFeatures ?? this.selectedFeatures,
      showComponents: showComponents ?? this.showComponents,
      showEvents: showEvents ?? this.showEvents,
      showSystems: showSystems ?? this.showSystems,
      showLifecycle: showLifecycle ?? this.showLifecycle,
    );
  }

  /// Check if a feature matches the filter (empty set means all features).
  bool matchesFeature(String? featureName) {
    if (selectedFeatures.isEmpty) return true;
    if (featureName == null) return true; // Lifecycle nodes always match
    return selectedFeatures.contains(featureName);
  }
}

/// Central state manager for the inspector.
final class InspectorState extends ChangeNotifier {
  final ECSService _service;

  InspectorView _currentView = InspectorView.graph;
  InspectorData _data = InspectorData.empty;
  ConnectionStatus _connectionStatus = ConnectionStatus.disconnected;
  String? _error;

  EntityFilter _entityFilter = const EntityFilter();
  LogFilter _logFilter = const LogFilter();
  GraphFilter _graphFilter = const GraphFilter();

  String? _selectedNodeId;

  StreamSubscription? _statusSubscription;
  StreamSubscription? _dataSubscription;

  InspectorState(ServiceManager serviceManager)
      : _service = ECSService(serviceManager) {
    _statusSubscription = _service.statusStream.listen(_onStatusChanged);
    _dataSubscription = _service.dataStream.listen(_onDataChanged);
  }

  // Getters
  InspectorView get currentView => _currentView;
  InspectorData get data => _data;
  ConnectionStatus get connectionStatus => _connectionStatus;
  String? get error => _error;
  bool get isConnected => _connectionStatus == ConnectionStatus.connected;
  bool get isLoading => _connectionStatus == ConnectionStatus.connecting;

  EntityFilter get entityFilter => _entityFilter;
  LogFilter get logFilter => _logFilter;
  GraphFilter get graphFilter => _graphFilter;

  String? get selectedNodeId => _selectedNodeId;

  ECSService get service => _service;

  /// Initialize the inspector state.
  Future<void> initialize() async {
    final result = await _service.initialize();
    if (result is ServiceError) {
      _error = result.message;
      notifyListeners();
    } else {
      _service.startAutoRefresh();
    }
  }

  /// Switch to a different view.
  void setView(InspectorView view) {
    if (_currentView != view) {
      _currentView = view;
      notifyListeners();
    }
  }

  /// Update entity filter.
  void setEntityFilter(EntityFilter filter) {
    _entityFilter = filter;
    notifyListeners();
  }

  /// Update log filter.
  void setLogFilter(LogFilter filter) {
    _logFilter = filter;
    notifyListeners();
  }

  /// Update graph filter.
  void setGraphFilter(GraphFilter filter) {
    _graphFilter = filter;
    notifyListeners();
  }

  /// Select a node in the graph view.
  void selectNode(String? nodeId) {
    _selectedNodeId = nodeId;
    notifyListeners();
  }

  /// Get filtered entities.
  List<EntityData> get filteredEntities {
    return _data.allEntities.where(_entityFilter.matches).toList();
  }

  /// Get filtered logs.
  List<LogData> get filteredLogs {
    var logs = _service.getFilteredLogs();
    return logs.where(_logFilter.matches).toList()
      ..sort((a, b) => b.time.compareTo(a.time));
  }

  /// Manually refresh data.
  Future<void> refresh() async {
    await _service.refresh();
  }

  void _onStatusChanged(ConnectionStatus status) {
    _connectionStatus = status;
    _error = null;
    notifyListeners();
  }

  void _onDataChanged(InspectorData data) {
    _data = data;
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _dataSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
