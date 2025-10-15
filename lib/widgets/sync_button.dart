import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sync_operation.dart';
import '../services/sync_service.dart';
import '../services/inventory_api_service.dart';

/// Sync Button Widget
/// Shows pending sync count and allows manual sync
class SyncButton extends ConsumerStatefulWidget {
  final VoidCallback? onSyncComplete;

  const SyncButton({
    super.key,
    this.onSyncComplete,
  });

  @override
  ConsumerState<SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends ConsumerState<SyncButton> {
  bool _isSyncing = false;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    final syncBox = await Hive.openBox<SyncOperation>('sync_queue');
    setState(() {
      _pendingCount = syncBox.values
          .where((op) => op.isPending || op.isFailed)
          .length;
    });
  }

  Future<void> _sync() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final apiService = InventoryApiService();
      final syncService = SyncService(apiService);

      String progressMessage = '';

      final result = await syncService.syncAll(
        onProgress: (message) {
          setState(() {
            progressMessage = message;
          });
        },
      );

      if (mounted) {
        // Reload pending count
        await _loadPendingCount();

        // Show result
        _showSyncResult(result);

        // Callback
        widget.onSyncComplete?.call();
      }
    } catch (e) {
      if (mounted) {
        _showError('Sync failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  void _showSyncResult(SyncResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              result.isSuccess ? Icons.check_circle : Icons.warning,
              color: result.isSuccess ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 12),
            const Text('Sync Result'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ${result.totalOperations}'),
            Text('Synced: ${result.synced}',
                style: const TextStyle(color: Colors.green)),
            if (result.failed > 0)
              Text('Failed: ${result.failed}',
                  style: const TextStyle(color: Colors.red)),
            if (result.hasErrors) ...[
              const SizedBox(height: 16),
              const Text('Errors:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...result.errors.map((error) => Text('• $error',
                  style: const TextStyle(fontSize: 12))),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingCount == 0 && !_isSyncing) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        FloatingActionButton.extended(
          onPressed: _isSyncing ? null : _sync,
          backgroundColor: _isSyncing ? Colors.grey : Colors.orange,
          icon: _isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.cloud_upload),
          label: Text(
            _isSyncing ? 'Syncing...' : 'Sync ($_pendingCount)',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        if (_pendingCount > 0 && !_isSyncing)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$_pendingCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
