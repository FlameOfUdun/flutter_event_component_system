import 'package:flutter/material.dart';

import '../../services/ecs_service.dart';
import '../../theme/inspector_theme.dart';

/// Widget displaying the current connection status.
class ConnectionStatusIndicator extends StatelessWidget {
  final ConnectionStatus status;
  final VoidCallback? onRetry;

  const ConnectionStatusIndicator({
    super.key,
    required this.status,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon, text) = _getStatusInfo();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == ConnectionStatus.connecting)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            )
          else
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (status == ConnectionStatus.error && onRetry != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onRetry,
              child: Icon(Icons.refresh, size: 14, color: color),
            ),
          ],
        ],
      ),
    );
  }

  (Color, IconData, String) _getStatusInfo() {
    return switch (status) {
      ConnectionStatus.connected => (
          InspectorTheme.connectedColor,
          Icons.check_circle,
          'Connected',
        ),
      ConnectionStatus.connecting => (
          InspectorTheme.connectingColor,
          Icons.sync,
          'Connecting...',
        ),
      ConnectionStatus.disconnected => (
          InspectorTheme.disconnectedColor,
          Icons.circle_outlined,
          'Disconnected',
        ),
      ConnectionStatus.error => (
          InspectorTheme.errorStatusColor,
          Icons.error,
          'Error',
        ),
    };
  }
}
