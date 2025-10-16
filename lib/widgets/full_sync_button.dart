import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_sync_service.dart';
import '../providers/inventory_provider.dart';

/// Button to trigger full sync of all Hive data to/from server
class FullSyncButton extends ConsumerStatefulWidget {
  const FullSyncButton({super.key});

  @override
  ConsumerState<FullSyncButton> createState() => _FullSyncButtonState();
}

class _FullSyncButtonState extends ConsumerState<FullSyncButton> {
  bool _isSyncing = false;

  Future<void> _syncAll() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final syncService = DataSyncService();

      final result = await syncService.syncAllToServer(
        onProgress: (message) {
          debugPrint(message);
        },
      );

      if (mounted) {
        _showSyncResult(result, isPull: false);
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

  Future<void> _pullFromServer() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final syncService = DataSyncService();

      final result = await syncService.pullFromServer(
        onProgress: (message) {
          debugPrint(message);
        },
      );

      // Refresh UI by reloading from Hive
      if (mounted) {
        await ref.read(productProvider.notifier).reloadProducts();
        await ref.read(categoryProvider.notifier).reloadCategories();
        _showSyncResult(result, isPull: true);
      }
    } catch (e) {
      if (mounted) {
        _showError('Pull failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  void _showSyncResult(SyncReport result, {required bool isPull}) {
    final action = isPull ? 'pulled' : 'synced';
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
            Text(isPull ? 'Pull Complete' : 'Sync Complete'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Categories $action: ${result.categoriesSynced}',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              Text(
                'Products $action: ${result.productsSynced}',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              if (result.categoriesFailed > 0)
                Text(
                  'Categories failed: ${result.categoriesFailed}',
                  style: const TextStyle(color: Colors.red),
                ),
              if (result.productsFailed > 0)
                Text(
                  'Products failed: ${result.productsFailed}',
                  style: const TextStyle(color: Colors.red),
                ),
              if (result.hasErrors) ...[
                const SizedBox(height: 16),
                const Text(
                  'Errors:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...result.errors.take(5).map((error) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $error',
                        style: const TextStyle(fontSize: 12),
                      ),
                    )),
                if (result.errors.length > 5)
                  Text('... and ${result.errors.length - 5} more errors'),
              ],
            ],
          ),
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

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cloud_upload, color: Colors.blue),
            SizedBox(width: 12),
            Text('Push to Server'),
          ],
        ),
        content: const Text(
          'This will upload all categories and products from local storage to the server.\n\n'
          'Existing items on the server will not be duplicated.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _syncAll();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Push Data'),
          ),
        ],
      ),
    );
  }

  void _showPullConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cloud_download, color: Colors.green),
            SizedBox(width: 12),
            Text('Pull from Server'),
          ],
        ),
        content: const Text(
          'This will download all products and categories from the server and update your local inventory.\n\n'
          'This will update quantities based on server data.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pullFromServer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Pull Data'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton.icon(
          onPressed: _isSyncing ? null : _showPullConfirmDialog,
          icon: _isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.cloud_download),
          label: Text(_isSyncing ? 'Syncing...' : 'Pull from Server'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _isSyncing ? null : _showConfirmDialog,
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
          label: Text(_isSyncing ? 'Syncing...' : 'Push to Server'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }
}
