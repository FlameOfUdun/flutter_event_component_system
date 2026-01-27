import 'dart:async';

import 'package:devtools_app_shared/service.dart';
import 'package:flutter/foundation.dart';

import '../models/inspector_data.dart';

/// Service connection status.
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// Result of a service call.
sealed class ServiceResult<T> {
  const ServiceResult();
}

class ServiceSuccess<T> extends ServiceResult<T> {
  final T data;
  const ServiceSuccess(this.data);
}

class ServiceError<T> extends ServiceResult<T> {
  final String message;
  final Object? error;
  const ServiceError(this.message, [this.error]);
}

/// Service for communicating with the ECS system via DevTools service extensions.
class ECSService {
  final ServiceManager _serviceManager;

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _dataController = StreamController<InspectorData>.broadcast();

  ConnectionStatus _status = ConnectionStatus.disconnected;
  InspectorData _lastData = InspectorData.empty;
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  DateTime? _lastClearTime;

  ECSService(this._serviceManager);

  /// Current connection status.
  ConnectionStatus get status => _status;

  /// Stream of connection status changes.
  Stream<ConnectionStatus> get statusStream => _statusController.stream;

  /// Stream of inspector data updates.
  Stream<InspectorData> get dataStream => _dataController.stream;

  /// Last fetched inspector data.
  InspectorData get lastData => _lastData;

  /// Initialize the service and wait for connection.
  Future<ServiceResult<void>> initialize({Duration timeout = const Duration(seconds: 30)}) async {
    _setStatus(ConnectionStatus.connecting);

    try {
      final deadline = DateTime.now().add(timeout);

      while (DateTime.now().isBefore(deadline)) {
        if (_serviceManager.service != null &&
            _serviceManager.isolateManager.selectedIsolate.value != null) {
          _setStatus(ConnectionStatus.connected);
          return const ServiceSuccess(null);
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _setStatus(ConnectionStatus.error);
      return const ServiceError('Connection timeout - service not available');
    } catch (e) {
      _setStatus(ConnectionStatus.error);
      return ServiceError('Failed to initialize: $e', e);
    }
  }

  /// Start automatic data refresh.
  void startAutoRefresh({Duration interval = const Duration(seconds: 2)}) {
    stopAutoRefresh();
    _refreshTimer = Timer.periodic(interval, (_) => _safeRefresh());
    // Immediate first refresh
    _safeRefresh();
  }

  /// Stop automatic data refresh.
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  /// Safely refresh data, preventing concurrent requests.
  Future<void> _safeRefresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      await refresh();
    } finally {
      _isRefreshing = false;
    }
  }

  /// Manually refresh inspector data.
  Future<ServiceResult<InspectorData>> refresh() async {
    if (_status != ConnectionStatus.connected) {
      return const ServiceError('Service not connected');
    }

    try {
      final response = await _callExtension('ext.ecs.requestInspectorData');

      if (response == null) {
        return const ServiceError('No response from service extension');
      }

      final data = InspectorData.fromJson(response);
      _lastData = data;
      _dataController.add(data);

      return ServiceSuccess(data);
    } catch (e) {
      debugPrint('ECSService.refresh error: $e');
      return ServiceError('Failed to fetch data: $e', e);
    }
  }

  /// Call a service extension and return the JSON result.
  Future<Map<String, dynamic>?> _callExtension(String method) async {
    final service = _serviceManager.service;
    final isolate = _serviceManager.isolateManager.selectedIsolate.value;

    if (service == null || isolate == null) {
      throw StateError('Service or isolate not available');
    }

    final response = await service.callServiceExtension(
      method,
      isolateId: isolate.id,
    );

    if (response.json == null) {
      return null;
    }

    return response.json;
  }

  /// Set the timestamp for filtering logs (clear logs).
  void setLogClearTime(DateTime time) {
    _lastClearTime = time;
  }

  /// Get logs filtered by clear time.
  List<LogData> getFilteredLogs() {
    final logs = _lastData.allLogs;
    if (_lastClearTime == null) return logs;

    return logs.where((log) => log.timestamp.isAfter(_lastClearTime!)).toList();
  }

  void _setStatus(ConnectionStatus status) {
    _status = status;
    _statusController.add(status);
  }

  /// Dispose the service.
  void dispose() {
    stopAutoRefresh();
    _statusController.close();
    _dataController.close();
  }
}
