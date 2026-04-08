import 'package:flutter/material.dart';

import '../../models/inspector_data.dart';
import '../../state/inspector_state.dart';
import '../../theme/inspector_theme.dart';
import '../components/filter_chip_row.dart';
import '../components/search_field.dart';

/// Log viewer for inspecting ECS system logs.
final class LogViewer extends StatelessWidget {
  final InspectorState state;

  const LogViewer({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final filter = state.logFilter;
        final logs = state.filteredLogs;

        return Column(
          children: [
            _buildToolbar(context, filter),
            const Divider(height: 1),
            Expanded(child: logs.isEmpty ? _buildEmptyState() : _buildLogList(logs)),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(BuildContext context, LogFilter filter) {
    final features = state.data.featureNames.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SearchField(
                  hintText: 'Search logs...',
                  onChanged: (query) {
                    state.setLogFilter(filter.copyWith(searchQuery: query));
                  },
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  state.setLogFilter(filter.copyWith(clearTime: DateTime.now()));
                },
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear'),
                style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (features.isNotEmpty)
            FilterChipRow<String>(
              label: 'Feature',
              options: features,
              selected: filter.featureName,
              labelBuilder: (f) => f,
              onSelected: (f) {
                state.setLogFilter(f == null ? filter.copyWith(clearFeature: true) : filter.copyWith(featureName: f));
              },
            ),
          const SizedBox(height: 8),
          MultiFilterChipRow<LogLevel>(
            label: 'Level',
            options: LogLevel.values,
            selected: filter.levels,
            labelBuilder: (l) => l.name.toUpperCase(),
            onChanged: (levels) {
              state.setLogFilter(filter.copyWith(levels: levels));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 64, color: InspectorTheme.mutedText),
          const SizedBox(height: 16),
          Text('No logs found', style: TextStyle(color: InspectorTheme.secondaryText, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Logs will appear here as they are generated', style: TextStyle(color: InspectorTheme.mutedText, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLogList(List<LogData> logs) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: logs.length,
      itemBuilder: (context, index) => _LogEntry(log: logs[index]),
    );
  }
}

final class _LogEntry extends StatelessWidget {
  final LogData log;

  const _LogEntry({required this.log});

  @override
  Widget build(BuildContext context) {
    final levelColor = _getLevelColor(log.level);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: _LevelIndicator(level: log.level, color: levelColor),
        title: Text(
          log.message,
          style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(_formatTime(log.time), style: TextStyle(color: InspectorTheme.mutedText, fontSize: 11)),
            if (log.featureName != null) ...[const SizedBox(width: 8), _Badge(label: log.featureName!)],
            if (log.systemName != null) ...[const SizedBox(width: 8), _Badge(label: log.systemName!)],
          ],
        ),
        children: [
          if (log.callStack.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(color: InspectorTheme.elevatedBackground, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Call Stack',
                    style: TextStyle(color: InspectorTheme.secondaryText, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...log.callStack
                      .take(10)
                      .map(
                        (frame) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: SelectableText(frame, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                        ),
                      ),
                  if (log.callStack.length > 10)
                    Text(
                      '... and ${log.callStack.length - 10} more frames',
                      style: TextStyle(color: InspectorTheme.mutedText, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getLevelColor(LogLevel level) {
    return switch (level) {
      LogLevel.verbose => InspectorTheme.verboseColor,
      LogLevel.debug => InspectorTheme.debugColor,
      LogLevel.info => InspectorTheme.infoColor,
      LogLevel.warning => InspectorTheme.warningColor,
      LogLevel.error => InspectorTheme.errorColor,
      LogLevel.fatal => InspectorTheme.fatalColor,
    };
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}:'
        '${dateTime.second.toString().padLeft(2, '0')}.'
        '${dateTime.millisecond.toString().padLeft(3, '0')}';
  }
}

final class _LevelIndicator extends StatelessWidget {
  final LogLevel level;
  final Color color;

  const _LevelIndicator({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    final icon = switch (level) {
      LogLevel.verbose => Icons.more_horiz,
      LogLevel.debug => Icons.bug_report_outlined,
      LogLevel.info => Icons.info_outline,
      LogLevel.warning => Icons.warning_amber_outlined,
      LogLevel.error => Icons.error_outline,
      LogLevel.fatal => Icons.dangerous_outlined,
    };

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

final class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: InspectorTheme.elevatedBackground, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: InspectorTheme.secondaryText, fontSize: 10)),
    );
  }
}
