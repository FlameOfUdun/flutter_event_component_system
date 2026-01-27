import 'package:devtools_app_shared/service.dart';
import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'state/inspector_state.dart';
import 'theme/inspector_theme.dart';
import 'widgets/components/connection_status.dart';
import 'widgets/views/entity_browser.dart';
import 'widgets/views/graph_view.dart';
import 'widgets/views/log_viewer.dart';

/// Main inspector application widget.
class Inspector extends StatefulWidget {
  const Inspector({super.key});

  @override
  State<Inspector> createState() => _InspectorState();
}

class _InspectorState extends State<Inspector> {
  InspectorState? _state;
  bool _initialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  Future<void> _initializeState() async {
    try {
      final serviceManager = await _waitForServiceManager();
      _state = InspectorState(serviceManager);
      await _state!.initialize();

      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize: $e';
        });
      }
    }
  }

  Future<ServiceManager> _waitForServiceManager() async {
    // Wait for the service to be ready with timeout
    const timeout = Duration(seconds: 30);
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      if (serviceManager.service != null) {
        return serviceManager;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }

    throw StateError('Service manager not available within timeout');
  }

  @override
  void dispose() {
    _state?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ECS Inspector',
      theme: InspectorTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _ErrorScreen(
        message: _error!,
        onRetry: () {
          setState(() {
            _error = null;
            _initialized = false;
          });
          _initializeState();
        },
      );
    }

    if (!_initialized || _state == null) {
      return const _LoadingScreen();
    }

    return _InspectorShell(state: _state!);
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'Connecting to ECS...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Waiting for service connection',
              style: TextStyle(color: InspectorTheme.secondaryText),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorScreen({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: InspectorTheme.errorColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Connection Error',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: InspectorTheme.secondaryText),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InspectorShell extends StatelessWidget {
  final InspectorState state;

  const _InspectorShell({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return Scaffold(
          appBar: _buildAppBar(context),
          body: _buildCurrentView(),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Row(
        children: [
          Icon(Icons.schema_outlined, size: 24),
          SizedBox(width: 8),
          Text('ECS Inspector'),
        ],
      ),
      actions: [
        ConnectionStatusIndicator(
          status: state.connectionStatus,
          onRetry: state.refresh,
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: state.refresh,
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: _buildTabBar(),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _TabButton(
            icon: Icons.account_tree_outlined,
            label: 'Graph',
            isSelected: state.currentView == InspectorView.graph,
            onTap: () => state.setView(InspectorView.graph),
          ),
          const SizedBox(width: 8),
          _TabButton(
            icon: Icons.inventory_2_outlined,
            label: 'Entities',
            isSelected: state.currentView == InspectorView.entities,
            onTap: () => state.setView(InspectorView.entities),
          ),
          const SizedBox(width: 8),
          _TabButton(
            icon: Icons.article_outlined,
            label: 'Logs',
            isSelected: state.currentView == InspectorView.logs,
            onTap: () => state.setView(InspectorView.logs),
          ),
          const Spacer(),
          if (state.data.isNotEmpty)
            Text(
              '${state.data.allEntities.length} entities • ${state.data.allSystems.length} systems',
              style: TextStyle(
                color: InspectorTheme.mutedText,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentView() {
    return switch (state.currentView) {
      InspectorView.graph => ECSGraphView(state: state),
      InspectorView.entities => EntityBrowser(state: state),
      InspectorView.logs => LogViewer(state: state),
    };
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? InspectorTheme.systemColor.withValues(alpha: 0.2)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? InspectorTheme.systemColor
                    : InspectorTheme.secondaryText,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? InspectorTheme.systemColor
                      : InspectorTheme.secondaryText,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
