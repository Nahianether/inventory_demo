import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/inventory_api_service.dart';
import '../models/api/api_product.dart';
import '../models/api/api_category.dart';

/// Migration result summary
class MigrationResult {
  final int categoriesMigrated;
  final int categoriesFailed;
  final int productsMigrated;
  final int productsFailed;
  final List<String> errors;

  MigrationResult({
    required this.categoriesMigrated,
    required this.categoriesFailed,
    required this.productsMigrated,
    required this.productsFailed,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => categoriesFailed == 0 && productsFailed == 0;
  int get totalSuccess => categoriesMigrated + productsMigrated;
  int get totalFailed => categoriesFailed + productsFailed;
}

/// Data Migration Utility
/// Migrates data from local Hive storage to the backend API
class DataMigration {
  final InventoryApiService _apiService;

  DataMigration(this._apiService);

  /// Migrate all data from Hive to API
  Future<MigrationResult> migrateAll({
    required Function(String) onProgress,
  }) async {
    final errors = <String>[];
    int categoriesMigrated = 0;
    int categoriesFailed = 0;
    int productsMigrated = 0;
    int productsFailed = 0;

    try {
      // Step 1: Migrate Categories first (products reference them)
      onProgress('Migrating categories...');
      final categoryBox = await Hive.openBox<Category>('categories');
      final categories = categoryBox.values.toList();

      // Create a mapping from old category names to new API category IDs
      final Map<String, String> categoryMapping = {};

      for (int i = 0; i < categories.length; i++) {
        final category = categories[i];
        onProgress('Migrating category ${i + 1}/${categories.length}: ${category.name}');

        try {
          final apiCategory = await _apiService.createCategory(
            CreateCategoryRequest(
              name: category.name,
              description: category.description,
            ),
          );

          categoryMapping[category.name] = apiCategory.id;
          categoriesMigrated++;
          debugPrint('✓ Migrated category: ${category.name}');
        } catch (e) {
          categoriesFailed++;
          final error = 'Failed to migrate category "${category.name}": $e';
          errors.add(error);
          debugPrint('✗ $error');
        }
      }

      // Step 2: Migrate Products
      onProgress('Migrating products...');
      final productBox = await Hive.openBox<Product>('products');
      final products = productBox.values.toList();

      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        onProgress('Migrating product ${i + 1}/${products.length}: ${product.name}');

        try {
          // Generate SKU if not present
          final sku = _generateSKU(product.name, i);

          // Get category ID from mapping
          final categoryId = categoryMapping[product.category];

          await _apiService.createProduct(
            CreateProductRequest(
              name: product.name,
              description: product.description,
              sku: sku,
              price: product.sellingPrice,
              costPrice: product.buyingPrice,
              categoryId: categoryId,
              initialStock: product.quantity,
            ),
          );

          productsMigrated++;
          debugPrint('✓ Migrated product: ${product.name} (Stock: ${product.quantity})');
        } catch (e) {
          productsFailed++;
          final error = 'Failed to migrate product "${product.name}": $e';
          errors.add(error);
          debugPrint('✗ $error');
        }
      }

      onProgress('Migration complete!');
    } catch (e) {
      errors.add('Migration failed: $e');
      debugPrint('Migration error: $e');
    }

    return MigrationResult(
      categoriesMigrated: categoriesMigrated,
      categoriesFailed: categoriesFailed,
      productsMigrated: productsMigrated,
      productsFailed: productsFailed,
      errors: errors,
    );
  }

  /// Migrate only categories
  Future<MigrationResult> migrateCategories({
    required Function(String) onProgress,
  }) async {
    final errors = <String>[];
    int categoriesMigrated = 0;
    int categoriesFailed = 0;

    try {
      onProgress('Loading categories from local storage...');
      final categoryBox = await Hive.openBox<Category>('categories');
      final categories = categoryBox.values.toList();

      onProgress('Found ${categories.length} categories to migrate');

      for (int i = 0; i < categories.length; i++) {
        final category = categories[i];
        onProgress('Migrating ${i + 1}/${categories.length}: ${category.name}');

        try {
          await _apiService.createCategory(
            CreateCategoryRequest(
              name: category.name,
              description: category.description,
            ),
          );

          categoriesMigrated++;
          debugPrint('✓ Migrated category: ${category.name}');
        } catch (e) {
          categoriesFailed++;
          final error = 'Failed to migrate category "${category.name}": $e';
          errors.add(error);
          debugPrint('✗ $error');
        }
      }

      onProgress('Category migration complete!');
    } catch (e) {
      errors.add('Category migration failed: $e');
    }

    return MigrationResult(
      categoriesMigrated: categoriesMigrated,
      categoriesFailed: categoriesFailed,
      productsMigrated: 0,
      productsFailed: 0,
      errors: errors,
    );
  }

  /// Migrate only products
  Future<MigrationResult> migrateProducts({
    required Function(String) onProgress,
  }) async {
    final errors = <String>[];
    int productsMigrated = 0;
    int productsFailed = 0;

    try {
      onProgress('Loading products from local storage...');
      final productBox = await Hive.openBox<Product>('products');
      final products = productBox.values.toList();

      onProgress('Found ${products.length} products to migrate');

      // Get existing categories from API to map names to IDs
      final apiCategories = await _apiService.getCategories();
      final Map<String, String> categoryMapping = {
        for (var cat in apiCategories) cat.name: cat.id
      };

      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        onProgress('Migrating ${i + 1}/${products.length}: ${product.name}');

        try {
          final sku = _generateSKU(product.name, i);
          final categoryId = categoryMapping[product.category];

          await _apiService.createProduct(
            CreateProductRequest(
              name: product.name,
              description: product.description,
              sku: sku,
              price: product.sellingPrice,
              costPrice: product.buyingPrice,
              categoryId: categoryId,
              initialStock: product.quantity,
            ),
          );

          productsMigrated++;
          debugPrint('✓ Migrated product: ${product.name}');
        } catch (e) {
          productsFailed++;
          final error = 'Failed to migrate product "${product.name}": $e';
          errors.add(error);
          debugPrint('✗ $error');
        }
      }

      onProgress('Product migration complete!');
    } catch (e) {
      errors.add('Product migration failed: $e');
    }

    return MigrationResult(
      categoriesMigrated: 0,
      categoriesFailed: 0,
      productsMigrated: productsMigrated,
      productsFailed: productsFailed,
      errors: errors,
    );
  }

  /// Check what data is available in Hive
  Future<Map<String, int>> checkLocalData() async {
    final productBox = await Hive.openBox<Product>('products');
    final categoryBox = await Hive.openBox<Category>('categories');
    final transactionBox = await Hive.openBox('transactions');

    return {
      'products': productBox.length,
      'categories': categoryBox.length,
      'transactions': transactionBox.length,
    };
  }

  /// Generate SKU for a product
  String _generateSKU(String productName, int index) {
    final prefix = productName.length >= 3
        ? productName.substring(0, 3).toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '')
        : 'PRD';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$prefix-$timestamp-$index';
  }

  /// Verify backend connectivity before migration
  Future<bool> checkBackendConnection() async {
    return await _apiService.healthCheck();
  }
}
