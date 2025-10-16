import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/category.dart';
import 'inventory_api_service.dart';
import '../models/api/api_product.dart';
import '../models/api/api_category.dart';
import 'package:uuid/uuid.dart';

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

  /// Pull/Download data from server to Hive (updates local inventory with server data)
  Future<SyncReport> pullFromServer({
    required Function(String) onProgress,
  }) async {
    int categoriesUpdated = 0;
    int productsUpdated = 0;
    int categoriesFailed = 0;
    int productsFailed = 0;
    final errors = <String>[];

    try {
      onProgress('Checking server connection...');
      final isOnline = await _apiService.healthCheck();
      if (!isOnline) {
        throw Exception('Server is not reachable');
      }

      // Pull categories from server
      onProgress('Fetching categories from server...');
      try {
        final serverCategories = await _apiService.getCategories();
        final categoryBox = await Hive.openBox<Category>('categories');

        debugPrint('Fetched ${serverCategories.length} categories from server');

        for (int i = 0; i < serverCategories.length; i++) {
          final serverCat = serverCategories[i];
          onProgress('Updating category ${i + 1}/${serverCategories.length}: ${serverCat.name}');

          try {
            // Find or create local category
            final existingCategory = categoryBox.values.firstWhere(
              (cat) => cat.name.toLowerCase() == serverCat.name.toLowerCase(),
              orElse: () => Category(
                id: const Uuid().v4(),
                name: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

            final localCategory = Category(
              id: existingCategory.name.isEmpty ? const Uuid().v4() : existingCategory.id,
              name: serverCat.name,
              description: serverCat.description,
              createdAt: existingCategory.name.isEmpty ? DateTime.now() : existingCategory.createdAt,
              updatedAt: DateTime.now(),
            );

            await categoryBox.put(localCategory.id, localCategory);
            categoriesUpdated++;
            debugPrint('✓ Updated category: ${localCategory.name}');
          } catch (e) {
            categoriesFailed++;
            final error = 'Failed to update category ${serverCat.name}: $e';
            errors.add(error);
            debugPrint('✗ $error');
          }
        }
      } catch (e) {
        final error = 'Failed to fetch categories: $e';
        errors.add(error);
        debugPrint('✗ $error');
      }

      // Pull products from server
      onProgress('Fetching products from server...');
      try {
        final serverProducts = await _apiService.getProducts();
        final productBox = await Hive.openBox<Product>('products');

        debugPrint('Fetched ${serverProducts.length} products from server');

        for (int i = 0; i < serverProducts.length; i++) {
          final serverProduct = serverProducts[i];
          onProgress('Updating product ${i + 1}/${serverProducts.length}: ${serverProduct.name}');

          try {
            // Find existing local product by name
            final existingProduct = productBox.values.firstWhere(
              (p) => p.name.toLowerCase() == serverProduct.name.toLowerCase(),
              orElse: () => Product(
                id: const Uuid().v4(),
                name: '',
                category: '',
                buyingPrice: 0,
                sellingPrice: 0,
                quantity: 0,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

            // Get category name from category ID
            String categoryName = 'Uncategorized';
            if (serverProduct.categoryId != null) {
              try {
                final serverCategories = await _apiService.getCategories();
                final category = serverCategories.firstWhere(
                  (cat) => cat.id == serverProduct.categoryId,
                );
                categoryName = category.name;
              } catch (e) {
                debugPrint('Could not find category for product ${serverProduct.name}');
              }
            }

            final localProduct = Product(
              id: existingProduct.name.isEmpty ? const Uuid().v4() : existingProduct.id,
              name: serverProduct.name,
              description: serverProduct.description,
              category: categoryName,
              buyingPrice: serverProduct.costPrice ?? 0.0,
              sellingPrice: serverProduct.price,
              quantity: serverProduct.stockQuantity,
              createdAt: existingProduct.name.isEmpty ? DateTime.now() : existingProduct.createdAt,
              updatedAt: DateTime.now(),
            );

            await productBox.put(localProduct.id, localProduct);
            productsUpdated++;
            debugPrint('✓ Updated product: ${localProduct.name} (qty: ${localProduct.quantity})');
          } catch (e) {
            productsFailed++;
            final error = 'Failed to update product ${serverProduct.name}: $e';
            errors.add(error);
            debugPrint('✗ $error');
          }
        }
      } catch (e) {
        final error = 'Failed to fetch products: $e';
        errors.add(error);
        debugPrint('✗ $error');
      }

      onProgress('Pull complete!');

      return SyncReport(
        categoriesSynced: categoriesUpdated,
        productsSynced: productsUpdated,
        categoriesFailed: categoriesFailed,
        productsFailed: productsFailed,
        errors: errors,
      );
    } catch (e) {
      errors.add('Pull failed: $e');
      return SyncReport(
        categoriesSynced: categoriesUpdated,
        productsSynced: productsUpdated,
        categoriesFailed: categoriesFailed,
        productsFailed: productsFailed,
        errors: errors,
      );
    }
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
