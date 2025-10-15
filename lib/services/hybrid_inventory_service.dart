import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/sync_operation.dart';
import 'inventory_api_service.dart';

/// Hybrid Inventory Service
/// Works offline-first: saves to Hive immediately, syncs to server when online
class HybridInventoryService {
  final InventoryApiService _apiService;

  HybridInventoryService(this._apiService);

  // Connection status
  bool _isOnline = false;
  bool get isOnline => _isOnline;

  /// Check if server is online
  Future<bool> checkConnection() async {
    try {
      _isOnline = await _apiService.healthCheck();
      return _isOnline;
    } catch (e) {
      _isOnline = false;
      return false;
    }
  }

  // ==================== PRODUCT OPERATIONS ====================

  /// Add product - saves to Hive immediately, queues for sync
  Future<Product> addProduct({
    required String name,
    String? description,
    required String category,
    required double buyingPrice,
    required double sellingPrice,
    required int quantity,
  }) async {
    // Create product locally
    final product = Product(
      id: const Uuid().v4(),
      name: name,
      category: category,
      buyingPrice: buyingPrice,
      sellingPrice: sellingPrice,
      quantity: quantity,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to Hive immediately
    final productBox = await Hive.openBox<Product>('products');
    await productBox.put(product.id, product);

    // Queue for sync
    await _queueOperation(
      type: 'create_product',
      data: {
        'id': product.id,
        'name': product.name,
        'description': product.description,
        'category': product.category,
        'buyingPrice': product.buyingPrice,
        'sellingPrice': product.sellingPrice,
        'quantity': product.quantity,
      },
    );

    // Try to sync immediately if online
    if (_isOnline) {
      _trySyncOperation('create_product', product.id);
    }

    return product;
  }

  /// Update product - updates Hive immediately, queues for sync
  Future<Product> updateProduct(Product product) async {
    final updatedProduct = product.copyWith(updatedAt: DateTime.now());

    // Update Hive immediately
    final productBox = await Hive.openBox<Product>('products');
    await productBox.put(updatedProduct.id, updatedProduct);

    // Queue for sync
    await _queueOperation(
      type: 'update_product',
      data: {
        'id': updatedProduct.id,
        'name': updatedProduct.name,
        'description': updatedProduct.description,
        'category': updatedProduct.category,
        'buyingPrice': updatedProduct.buyingPrice,
        'sellingPrice': updatedProduct.sellingPrice,
        'quantity': updatedProduct.quantity,
      },
    );

    // Try to sync immediately if online
    if (_isOnline) {
      _trySyncOperation('update_product', updatedProduct.id);
    }

    return updatedProduct;
  }

  /// Delete product - deletes from Hive immediately, queues for sync
  Future<void> deleteProduct(String productId) async {
    // Delete from Hive immediately
    final productBox = await Hive.openBox<Product>('products');
    await productBox.delete(productId);

    // Queue for sync
    await _queueOperation(
      type: 'delete_product',
      data: {'id': productId},
    );

    // Try to sync immediately if online
    if (_isOnline) {
      _trySyncOperation('delete_product', productId);
    }
  }

  /// Adjust stock - updates Hive immediately, queues for sync
  Future<void> adjustStock({
    required String productId,
    required int quantityChange,
    String? reason,
  }) async {
    // Get product from Hive
    final productBox = await Hive.openBox<Product>('products');
    final product = productBox.get(productId);

    if (product == null) {
      throw Exception('Product not found');
    }

    // Check if we have enough stock for removal
    if (quantityChange < 0 && product.quantity < -quantityChange) {
      throw InsufficientStockException('Insufficient stock');
    }

    // Update quantity in Hive immediately
    final updatedProduct = product.copyWith(
      quantity: product.quantity + quantityChange,
      updatedAt: DateTime.now(),
    );
    await productBox.put(productId, updatedProduct);

    // Queue for sync
    await _queueOperation(
      type: 'adjust_stock',
      data: {
        'productId': productId,
        'quantityChange': quantityChange,
        'reason': reason,
      },
    );

    // Try to sync immediately if online
    if (_isOnline) {
      _trySyncOperation('adjust_stock', productId);
    }
  }

  /// Get all products from Hive (always available offline)
  Future<List<Product>> getProducts() async {
    final productBox = await Hive.openBox<Product>('products');
    return productBox.values.toList();
  }

  /// Get product by ID from Hive
  Future<Product?> getProductById(String id) async {
    final productBox = await Hive.openBox<Product>('products');
    return productBox.get(id);
  }

  // ==================== CATEGORY OPERATIONS ====================

  /// Add category - saves to Hive immediately, queues for sync
  Future<Category> addCategory({
    required String name,
    String? description,
  }) async {
    final category = Category(
      id: const Uuid().v4(),
      name: name,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to Hive immediately
    final categoryBox = await Hive.openBox<Category>('categories');
    await categoryBox.put(category.id, category);

    // Queue for sync
    await _queueOperation(
      type: 'create_category',
      data: {
        'id': category.id,
        'name': category.name,
        'description': category.description,
      },
    );

    // Try to sync immediately if online
    if (_isOnline) {
      _trySyncOperation('create_category', category.id);
    }

    return category;
  }

  /// Get all categories from Hive
  Future<List<Category>> getCategories() async {
    final categoryBox = await Hive.openBox<Category>('categories');
    return categoryBox.values.toList();
  }

  // ==================== SYNC QUEUE MANAGEMENT ====================

  /// Queue an operation for later sync
  Future<void> _queueOperation({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final syncBox = await Hive.openBox<SyncOperation>('sync_queue');

    final operation = SyncOperation.fromData(
      id: const Uuid().v4(),
      type: type,
      data: data,
      createdAt: DateTime.now(),
      status: 'pending',
      retryCount: 0,
    );

    await syncBox.put(operation.id, operation);
    debugPrint('📝 Queued operation: $type');
  }

  /// Try to sync a specific operation (fire and forget)
  void _trySyncOperation(String type, String entityId) {
    // Fire and forget - don't await
    Future.microtask(() async {
      try {
        // This will be handled by the sync service
        debugPrint('🔄 Will sync $type for $entityId when sync is triggered');
      } catch (e) {
        debugPrint('⚠️ Sync will retry later: $e');
      }
    });
  }

  /// Get pending sync operations count
  Future<int> getPendingSyncCount() async {
    final syncBox = await Hive.openBox<SyncOperation>('sync_queue');
    return syncBox.values.where((op) => op.isPending || op.isFailed).length;
  }

  /// Get all pending operations
  Future<List<SyncOperation>> getPendingOperations() async {
    final syncBox = await Hive.openBox<SyncOperation>('sync_queue');
    return syncBox.values.where((op) => op.isPending || op.isFailed).toList();
  }

  /// Clear completed operations
  Future<void> clearCompletedOperations() async {
    final syncBox = await Hive.openBox<SyncOperation>('sync_queue');
    final completed = syncBox.values
        .where((op) => op.isCompleted)
        .map((op) => op.key)
        .toList();

    for (final key in completed) {
      await syncBox.delete(key);
    }
  }
}
