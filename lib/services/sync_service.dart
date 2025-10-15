import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sync_operation.dart';
import 'inventory_api_service.dart';
import '../models/api/api_product.dart';
import '../models/api/api_category.dart';
import '../models/api/api_inventory.dart';

/// Sync result
class SyncResult {
  final int totalOperations;
  final int synced;
  final int failed;
  final List<String> errors;

  SyncResult({
    required this.totalOperations,
    required this.synced,
    required this.failed,
    required this.errors,
  });

  bool get isSuccess => failed == 0;
  bool get hasErrors => errors.isNotEmpty;
}

/// Sync Service
/// Handles syncing pending operations from Hive to the server
class SyncService {
  final InventoryApiService _apiService;

  SyncService(this._apiService);

  /// Sync all pending operations
  Future<SyncResult> syncAll({
    required Function(String) onProgress,
  }) async {
    onProgress('Checking server connection...');

    // Check connection first
    final isOnline = await _apiService.healthCheck();
    if (!isOnline) {
      throw Exception('Server is not reachable');
    }

    final syncBox = await Hive.openBox<SyncOperation>('sync_queue');
    final pendingOps = syncBox.values
        .where((op) => op.isPending || op.isFailed)
        .toList();

    if (pendingOps.isEmpty) {
      onProgress('No pending operations to sync');
      return SyncResult(
        totalOperations: 0,
        synced: 0,
        failed: 0,
        errors: [],
      );
    }

    int synced = 0;
    int failed = 0;
    final errors = <String>[];

    onProgress('Found ${pendingOps.length} operations to sync');

    // Get category mapping for products
    final categoryMapping = await _buildCategoryMapping();

    for (int i = 0; i < pendingOps.length; i++) {
      final operation = pendingOps[i];
      onProgress('Syncing ${i + 1}/${pendingOps.length}: ${operation.type}');

      try {
        await _syncOperation(operation, categoryMapping);

        // Mark as completed
        final updated = operation.copyWith(status: 'completed');
        await syncBox.put(operation.key, updated);

        synced++;
        debugPrint('✓ Synced: ${operation.type}');
      } catch (e) {
        // Mark as failed and increment retry count
        final updated = operation.copyWith(
          status: 'failed',
          errorMessage: e.toString(),
          retryCount: operation.retryCount + 1,
        );
        await syncBox.put(operation.key, updated);

        failed++;
        final error = 'Failed ${operation.type}: $e';
        errors.add(error);
        debugPrint('✗ $error');
      }
    }

    onProgress('Sync complete!');

    return SyncResult(
      totalOperations: pendingOps.length,
      synced: synced,
      failed: failed,
      errors: errors,
    );
  }

  /// Build category name to ID mapping
  Future<Map<String, String>> _buildCategoryMapping() async {
    try {
      final apiCategories = await _apiService.getCategories();
      return {
        for (var cat in apiCategories) cat.name: cat.id
      };
    } catch (e) {
      debugPrint('Warning: Could not fetch categories: $e');
      return {};
    }
  }

  /// Sync a single operation
  Future<void> _syncOperation(
    SyncOperation operation,
    Map<String, String> categoryMapping,
  ) async {
    switch (operation.type) {
      case 'create_product':
        await _syncCreateProduct(operation, categoryMapping);
        break;

      case 'update_product':
        await _syncUpdateProduct(operation, categoryMapping);
        break;

      case 'delete_product':
        await _syncDeleteProduct(operation);
        break;

      case 'adjust_stock':
        await _syncAdjustStock(operation);
        break;

      case 'create_category':
        await _syncCreateCategory(operation);
        break;

      default:
        throw Exception('Unknown operation type: ${operation.type}');
    }
  }

  /// Sync create product operation
  Future<void> _syncCreateProduct(
    SyncOperation operation,
    Map<String, String> categoryMapping,
  ) async {
    final data = operation.data;
    final sku = _generateSKU(data['name']);

    // Get category ID from mapping
    final categoryId = categoryMapping[data['category']];

    await _apiService.createProduct(
      CreateProductRequest(
        name: data['name'],
        description: data['description'],
        sku: sku,
        price: data['sellingPrice'],
        costPrice: data['buyingPrice'],
        categoryId: categoryId,
        initialStock: data['quantity'],
      ),
    );
  }

  /// Sync update product operation
  Future<void> _syncUpdateProduct(
    SyncOperation operation,
    Map<String, String> categoryMapping,
  ) async {
    final data = operation.data;

    // First, check if product exists on server
    try {
      await _apiService.getProduct(data['id']);

      // Product exists, update it
      await _apiService.updateProduct(
        data['id'],
        UpdateProductRequest(
          name: data['name'],
          description: data['description'],
          price: data['sellingPrice'],
          costPrice: data['buyingPrice'],
        ),
      );
    } catch (e) {
      // Product doesn't exist, create it instead
      debugPrint('Product not found on server, creating instead');
      await _syncCreateProduct(operation, categoryMapping);
    }
  }

  /// Sync delete product operation
  Future<void> _syncDeleteProduct(SyncOperation operation) async {
    final data = operation.data;

    try {
      await _apiService.deleteProduct(data['id']);
    } catch (e) {
      // If product not found, consider it already deleted (success)
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        debugPrint('Product already deleted on server');
        return;
      }
      rethrow;
    }
  }

  /// Sync adjust stock operation
  Future<void> _syncAdjustStock(SyncOperation operation) async {
    final data = operation.data;

    await _apiService.adjustStock(
      AdjustStockRequest(
        productId: data['productId'],
        quantityChange: data['quantityChange'],
        reason: data['reason'] ?? 'Offline sync',
      ),
    );
  }

  /// Sync create category operation
  Future<void> _syncCreateCategory(SyncOperation operation) async {
    final data = operation.data;

    try {
      await _apiService.createCategory(
        CreateCategoryRequest(
          name: data['name'],
          description: data['description'],
        ),
      );
    } catch (e) {
      // If category already exists, consider it success
      if (e.toString().contains('already exists') ||
          e.toString().contains('duplicate')) {
        debugPrint('Category already exists on server');
        return;
      }
      rethrow;
    }
  }

  /// Generate SKU
  String _generateSKU(String productName) {
    final prefix = productName.length >= 3
        ? productName.substring(0, 3).toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '')
        : 'PRD';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$prefix-$timestamp';
  }

  /// Get sync statistics
  Future<Map<String, int>> getSyncStats() async {
    final syncBox = await Hive.openBox<SyncOperation>('sync_queue');
    final operations = syncBox.values.toList();

    return {
      'total': operations.length,
      'pending': operations.where((op) => op.isPending).length,
      'failed': operations.where((op) => op.isFailed).length,
      'completed': operations.where((op) => op.isCompleted).length,
    };
  }

  /// Clear all completed operations
  Future<void> clearCompleted() async {
    final syncBox = await Hive.openBox<SyncOperation>('sync_queue');
    final completed = syncBox.values
        .where((op) => op.isCompleted)
        .map((op) => op.key)
        .toList();

    for (final key in completed) {
      await syncBox.delete(key);
    }

    debugPrint('Cleared ${completed.length} completed operations');
  }

  /// Retry failed operations
  Future<SyncResult> retryFailed({
    required Function(String) onProgress,
  }) async {
    final syncBox = await Hive.openBox<SyncOperation>('sync_queue');

    // Reset failed operations to pending
    final failed = syncBox.values.where((op) => op.isFailed).toList();

    for (final operation in failed) {
      final updated = operation.copyWith(
        status: 'pending',
        errorMessage: null,
      );
      await syncBox.put(operation.key, updated);
    }

    // Sync all
    return await syncAll(onProgress: onProgress);
  }
}
