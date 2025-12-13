import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

/// Offline Mode Indicator - Shows connection status and sync progress
class OfflineModeIndicator extends StatelessWidget {
  final bool compact;

  const OfflineModeIndicator({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ConnectivityService, SyncService>(
      builder: (context, connectivity, sync, _) {
        // Don't show anything if online and fully synced
        if (connectivity.isOnline && sync.pendingSyncCount == 0) {
          return const SizedBox.shrink();
        }

        if (compact) {
          return _buildCompactIndicator(connectivity, sync);
        }

        return _buildFullIndicator(context, connectivity, sync);
      },
    );
  }

  Widget _buildCompactIndicator(
    ConnectivityService connectivity,
    SyncService sync,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: connectivity.isOffline ? Colors.orange : Colors.blue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            connectivity.isOffline ? Icons.cloud_off : Icons.cloud_sync,
            color: Colors.white,
            size: 14,
          ),
          if (sync.pendingSyncCount > 0) ...[
            const SizedBox(width: 4),
            Text(
              '${sync.pendingSyncCount}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullIndicator(
    BuildContext context,
    ConnectivityService connectivity,
    SyncService sync,
  ) {
    final isOffline = connectivity.isOffline;
    final hasPending = sync.pendingSyncCount > 0;
    final isSyncing = sync.isSyncing;

    return Material(
      elevation: 4,
      color: isOffline ? Colors.orange.shade100 : Colors.blue.shade100,
      child: InkWell(
        onTap: () => _showSyncDetails(context, connectivity, sync),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                isOffline
                    ? Icons.cloud_off
                    : (isSyncing ? Icons.sync : Icons.cloud_done),
                color: isOffline
                    ? Colors.orange.shade900
                    : Colors.blue.shade900,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isOffline
                          ? 'Offline Mode'
                          : (isSyncing ? 'Syncing...' : 'Online'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isOffline
                            ? Colors.orange.shade900
                            : Colors.blue.shade900,
                      ),
                    ),
                    if (hasPending)
                      Text(
                        '${sync.pendingSyncCount} pending ${sync.pendingSyncCount == 1 ? 'item' : 'items'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOffline
                              ? Colors.orange.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                  ],
                ),
              ),
              if (isSyncing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: isOffline
                      ? Colors.orange.shade700
                      : Colors.blue.shade700,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSyncDetails(
    BuildContext context,
    ConnectivityService connectivity,
    SyncService sync,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              connectivity.isOffline ? Icons.cloud_off : Icons.cloud_sync,
              color: connectivity.isOffline ? Colors.orange : Colors.blue,
            ),
            const SizedBox(width: 12),
            Text(connectivity.isOffline ? 'Offline Mode' : 'Online Mode'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (connectivity.isOffline) ...[
              const Text(
                'You are currently offline. Data will be stored locally and synced when connection is restored.',
                style: TextStyle(fontSize: 14),
              ),
              if (connectivity.lastOnlineAt != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Last online: ${_formatDuration(DateTime.now().difference(connectivity.lastOnlineAt!))}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ] else ...[
              Text(
                sync.isSyncing
                    ? 'Syncing your data to cloud...'
                    : 'Connected to cloud. All data is up to date.',
                style: const TextStyle(fontSize: 14),
              ),
              if (sync.lastSyncAt != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Last synced: ${_formatDuration(DateTime.now().difference(sync.lastSyncAt!))}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
            if (sync.pendingSyncCount > 0) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pending items:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text('${sync.pendingSyncCount}'),
                ],
              ),
            ],
            if (sync.lastSyncError != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Error: ${sync.lastSyncError}',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          if (connectivity.isOnline &&
              sync.pendingSyncCount > 0 &&
              !sync.isSyncing)
            TextButton.icon(
              onPressed: () {
                sync.forceSyncNow();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.sync),
              label: const Text('Sync Now'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) return 'Just now';
    if (duration.inMinutes < 60) return '${duration.inMinutes}m ago';
    if (duration.inHours < 24) return '${duration.inHours}h ago';
    return '${duration.inDays}d ago';
  }
}
