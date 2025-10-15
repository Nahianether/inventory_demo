import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/category.dart';
import 'inventory_api_service.dart';
import '../models/api/api_product.dart';
import '../models/api/api_category.dart';

/// Service to sync all existing Hive data to the server
class DataSyncService {
  final InventoryApiService _apiService = InventoryApiService();

  /// Sync all categories and products from Hive to server
  Future<SyncReport> syncAllToServer({
    required Function(String) onProgress,
  }) async {
    int categoriesSynced = 0;
    int productsSynced = 0;
    int categoriesFailed = 0;
    int productsFailed = 0;
    final errors = <String>[];

    try {
      onProgress('Checking server connection...');
      final isOnline = await _apiService.healthCheck();
      if (!isOnline) {
        throw Exception('Server is not reachable');
      }

      // First, sync all categories
      onProgress('Syncing categories...');
      final categoryBox = await Hive.openBox<Category>('categories');
      final localCategories = categoryBox.values.toList();

      debugPrint('Found ${localCategories.length} local categories to sync');

      for (int i = 0; i < localCategories.length; i++) {
        final category = localCategories[i];
        onProgress('Syncing category ${i + 1}/${localCategories.length}: ${category.name}');

        try {
          // Check if category already exists on server
          final serverCategories = await _apiService.getCategories();
          final exists = serverCategories.any(
            (cat) => cat.name.toLowerCase() == category.name.toLowerCase(),
          );

          if (!exists) {
            await _apiService.createCategory(
              CreateCategoryRequest(
                name: category.name,
                description: category.description,
              ),
            );
            categoriesSynced++;
            debugPrint('✓ Synced category: ${category.name}');
          } else {
            debugPrint('⊘ Category already exists: ${category.name}');
          }
        } catch (e) {
          categoriesFailed++;
          final error = 'Failed to sync category ${category.name}: $e';
          errors.add(error);
          debugPrint('✗ $error');
        }
      }

      // Build category name to ID mapping
      onProgress('Building category mapping...');
      final serverCategories = await _apiService.getCategories();
      final categoryMapping = {
        for (var cat in serverCategories) cat.name.toLowerCase(): cat.id
      };

      // Now sync all products
      onProgress('Syncing products...');
      final productBox = await Hive.openBox<Product>('products');
      final localProducts = productBox.values.toList();

      debugPrint('Found ${localProducts.length} local products to sync');

      for (int i = 0; i < localProducts.length; i++) {
        final product = localProducts[i];
        onProgress('Syncing product ${i + 1}/${localProducts.length}: ${product.name}');

        try {
          // Check if product already exists on server by name
          final serverProducts = await _apiService.getProducts();
          final exists = serverProducts.any(
            (p) => p.name.toLowerCase() == product.name.toLowerCase(),
          );

          if (!exists) {
            // Get category ID
            final categoryId = categoryMapping[product.category.toLowerCase()];
            if (categoryId == null) {
              throw Exception('Category "${product.category}" not found on server');
            }

            // Generate SKU
            final sku = _generateSKU(product.name);

            // Create product on server
            await _apiService.createProduct(
              CreateProductRequest(
                name: product.name,
                description: product.description?.isNotEmpty == true
                    ? product.description
                    : null,
                sku: sku,
                price: product.sellingPrice,
                costPrice: product.buyingPrice,
                categoryId: categoryId,
                initialStock: product.quantity,
              ),
            );
            productsSynced++;
            debugPrint('✓ Synced product: ${product.name}');
          } else {
            debugPrint('⊘ Product already exists: ${product.name}');
          }
        } catch (e) {
          productsFailed++;
          final error = 'Failed to sync product ${product.name}: $e';
          errors.add(error);
          debugPrint('✗ $error');
        }
      }

      onProgress('Sync complete!');

      return SyncReport(
        categoriesSynced: categoriesSynced,
        productsSynced: productsSynced,
        categoriesFailed: categoriesFailed,
        productsFailed: productsFailed,
        errors: errors,
      );
    } catch (e) {
      errors.add('Sync failed: $e');
      return SyncReport(
        categoriesSynced: categoriesSynced,
        productsSynced: productsSynced,
        categoriesFailed: categoriesFailed,
        productsFailed: productsFailed,
        errors: errors,
      );
    }
  }

  String _generateSKU(String productName) {
    final prefix = productName.length >= 3
        ? productName.substring(0, 3).toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '')
        : 'PRD';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$prefix-$timestamp';
  }
}

/// Report of sync operation
class SyncReport {
  final int categoriesSynced;
  final int productsSynced;
  final int categoriesFailed;
  final int productsFailed;
  final List<String> errors;

  SyncReport({
    required this.categoriesSynced,
    required this.productsSynced,
    required this.categoriesFailed,
    required this.productsFailed,
    required this.errors,
  });

  bool get isSuccess => categoriesFailed == 0 && productsFailed == 0;
  bool get hasErrors => errors.isNotEmpty;
  int get totalSynced => categoriesSynced + productsSynced;
  int get totalFailed => categoriesFailed + productsFailed;
}
