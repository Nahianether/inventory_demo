import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/data_migration.dart';
import '../services/inventory_api_service.dart';
import '../providers/api_inventory_provider.dart';

/// Data Migration Screen
/// Allows users to migrate their Hive data to the backend server
class DataMigrationScreen extends ConsumerStatefulWidget {
  const DataMigrationScreen({super.key});

  @override
  ConsumerState<DataMigrationScreen> createState() => _DataMigrationScreenState();
}

class _DataMigrationScreenState extends ConsumerState<DataMigrationScreen> {
  bool _isChecking = false;
  bool _isMigrating = false;
  bool _isConnected = false;
  String _progressMessage = '';
  MigrationResult? _result;
  Map<String, int>? _localDataStats;

  @override
  void initState() {
    super.initState();
    _checkConnection();
    _checkLocalData();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final migration = DataMigration(apiService);
      final isConnected = await migration.checkBackendConnection();

      setState(() {
        _isConnected = isConnected;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isChecking = false;
      });
    }
  }

  Future<void> _checkLocalData() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final migration = DataMigration(apiService);
      final stats = await migration.checkLocalData();

      setState(() {
        _localDataStats = stats;
      });
    } catch (e) {
      debugPrint('Error checking local data: $e');
    }
  }

  Future<void> _startMigration() async {
    if (!_isConnected) {
      _showError('Backend is not connected. Please check your connection.');
      return;
    }

    final confirm = await _showConfirmDialog();
    if (confirm != true) return;

    setState(() {
      _isMigrating = true;
      _progressMessage = 'Starting migration...';
      _result = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final migration = DataMigration(apiService);

      final result = await migration.migrateAll(
        onProgress: (message) {
          setState(() {
            _progressMessage = message;
          });
        },
      );

      setState(() {
        _result = result;
        _isMigrating = false;
        _progressMessage = 'Migration complete!';
      });

      // Refresh API data
      await ref.read(apiProductProvider.notifier).loadProducts();
      await ref.read(apiCategoryProvider.notifier).loadCategories();
    } catch (e) {
      setState(() {
        _isMigrating = false;
        _progressMessage = 'Migration failed: $e';
      });
      _showError('Migration failed: $e');
    }
  }

  Future<bool?> _showConfirmDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            const Text('Confirm Migration'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will upload your local data to the server.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 16),
            if (_localDataStats != null) ...[
              Text('Categories: ${_localDataStats!['categories']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Products: ${_localDataStats!['products']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
            ],
            const Text(
              'Note: Duplicate entries may be created if you run this multiple times.',
              style: TextStyle(fontSize: 13, color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Start Migration'),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Data Migration'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Migrate Local Data to Server',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload your Hive data to the backend API',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Connection Status Card
                _buildConnectionCard(),
                const SizedBox(height: 24),

                // Local Data Stats Card
                if (_localDataStats != null) _buildLocalDataCard(),
                const SizedBox(height: 24),

                // Migration Progress
                if (_isMigrating || _result != null) _buildProgressCard(),
                const SizedBox(height: 24),

                // Migration Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isMigrating || !_isConnected ? null : _startMigration,
                    icon: _isMigrating
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
                      _isMigrating ? 'Migrating...' : 'Start Migration',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Retry Connection Button
                if (!_isConnected)
                  OutlinedButton.icon(
                    onPressed: _isChecking ? null : _checkConnection,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Connection'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _isChecking
                      ? Colors.orange
                      : _isConnected
                          ? Colors.green
                          : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Backend Connection',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _isChecking
                ? 'Checking connection...'
                : _isConnected
                    ? 'Connected to backend server'
                    : 'Cannot connect to backend server',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          if (!_isConnected && !_isChecking) ...[
            const SizedBox(height: 12),
            Text(
              'Make sure your backend is running and the base URL is correct',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocalDataCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Local Data Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            'Categories',
            _localDataStats!['categories']!,
            Icons.category,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            'Products',
            _localDataStats!['products']!,
            Icons.inventory_2,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            'Transactions',
            _localDataStats!['transactions']!,
            Icons.receipt_long,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int count, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade900,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isMigrating ? 'Migration in Progress' : 'Migration Result',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          const SizedBox(height: 16),

          if (_isMigrating) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _progressMessage,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],

          if (_result != null) ...[
            _buildResultRow(
              'Categories Migrated',
              _result!.categoriesMigrated,
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildResultRow(
              'Products Migrated',
              _result!.productsMigrated,
              Colors.green,
            ),
            if (_result!.totalFailed > 0) ...[
              const SizedBox(height: 8),
              _buildResultRow(
                'Failed',
                _result!.totalFailed,
                Colors.red,
              ),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  _result!.isSuccess ? Icons.check_circle : Icons.warning,
                  color: _result!.isSuccess ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  _result!.isSuccess
                      ? 'Migration completed successfully!'
                      : 'Migration completed with errors',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _result!.isSuccess ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            if (_result!.hasErrors) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: const Text('View Errors'),
                children: _result!.errors.map((error) {
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                    title: Text(error, style: const TextStyle(fontSize: 12)),
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
