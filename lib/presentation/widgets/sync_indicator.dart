import 'package:flutter/material.dart';
import '../../data/services/sync_service.dart';

/// Small widget showing sync status in the app bar
class SyncIndicator extends StatefulWidget {
  const SyncIndicator({super.key});

  @override
  State<SyncIndicator> createState() => _SyncIndicatorState();
}

class _SyncIndicatorState extends State<SyncIndicator> {
  @override
  Widget build(BuildContext context) {
    // If sync isn't enabled, don't show anything
    if (!SyncService.isInitialized) {
      return const SizedBox.shrink();
    }

    final statusProvider = SyncService.instance.statusProvider;
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: statusProvider,
      builder: (context, child) {
        final status = statusProvider.status;
        final icon = _getIcon(status);
        final color = _getColor(status, theme);
        final tooltip = _getTooltip(status);

        return Tooltip(
          message: tooltip,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildContent(status, icon, color),
          ),
        );
      },
    );
  }

  Widget _buildContent(status, IconData icon, Color color) {
    if (status.isSyncing) {
      return SizedBox(
        key: const ValueKey('syncing'),
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
    }

    return Icon(
      icon,
      key: ValueKey(status.displayText),
      size: 20,
      color: color,
    );
  }

  IconData _getIcon(status) {
    if (!status.isOnline) {
      return Icons.cloud_off;
    }
    if (status.error != null) {
      return Icons.cloud_sync;
    }
    if (status.pendingChanges > 0) {
      return Icons.cloud_upload;
    }
    if (status.lastSync == null) {
      return Icons.cloud_sync;
    }
    return Icons.cloud_done;
  }

  Color _getColor(status, ThemeData theme) {
    if (!status.isOnline) {
      return theme.colorScheme.outline;
    }
    if (status.error != null) {
      return theme.colorScheme.error;
    }
    if (status.pendingChanges > 0) {
      return theme.colorScheme.primary;
    }
    return theme.colorScheme.primary.withValues(alpha: 0.7);
  }

  String _getTooltip(status) {
    if (!status.isOnline) {
      return 'Offline - changes will sync when connected';
    }
    if (status.isSyncing) {
      return 'Syncing...';
    }
    if (status.error != null) {
      return 'Sync error: ${status.error}';
    }
    if (status.pendingChanges > 0) {
      return '${status.pendingChanges} change${status.pendingChanges == 1 ? '' : 's'} pending';
    }
    if (status.lastSync != null) {
      final ago = DateTime.now().difference(status.lastSync!);
      if (ago.inMinutes < 1) {
        return 'Synced just now';
      } else if (ago.inMinutes < 60) {
        return 'Synced ${ago.inMinutes}m ago';
      } else if (ago.inHours < 24) {
        return 'Synced ${ago.inHours}h ago';
      } else {
        return 'Synced ${ago.inDays}d ago';
      }
    }
    return 'Never synced';
  }
}

/// An action button that triggers a manual sync
class SyncActionButton extends StatelessWidget {
  const SyncActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!SyncService.isInitialized) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.sync),
      tooltip: 'Sync now',
      onPressed: () {
        SyncService.instance.fullSync();
      },
    );
  }
}
