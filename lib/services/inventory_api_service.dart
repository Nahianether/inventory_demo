import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../models/api/api_product.dart';
import '../models/api/api_category.dart';
import '../models/api/api_inventory.dart';

/// Comprehensive API service for inventory management
/// Supports all backend endpoints from the API documentation
class InventoryApiService {
  // Base URL - Change based on your environment
  // For Android Emulator: http://10.0.2.2:3000/api
  // For iOS Simulator: http://localhost:3000/api
  // For Physical Device: http://YOUR_IP:3000/api
  static const String baseUrl = 'http://localhost:3000/api';

  // ==================== PRODUCTS MANAGEMENT ====================

  /// Get all products with stock information
  ///
  /// Optional parameters:
  /// - [search]: Search by product name or SKU
  /// - [categoryId]: Filter by category UUID
  /// - [isActive]: Filter active/inactive products
  Future<List<ApiProduct>> getProducts({
    String? search,
    String? categoryId,
    bool? isActive,
  }) async {
    final queryParams = <String, String>{};
    if (search != null) queryParams['search'] = search;
    if (categoryId != null) queryParams['category_id'] = categoryId;
    if (isActive != null) queryParams['is_active'] = isActive.toString();

    final uri = Uri.parse('$baseUrl/products')
        .replace(queryParameters: queryParams.isEmpty ? null : queryParams);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => ApiProduct.fromJson(item)).toList();
    }
    throw Exception('Failed to load products: ${response.body}');
  }

  /// Get a single product by ID
  Future<ApiProduct> getProduct(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/products/$id'));

    if (response.statusCode == 200) {
      return ApiProduct.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load product: ${response.body}');
  }

  /// Create a new product
  ///
  /// Automatically creates an inventory record with initial stock
  Future<ApiProduct> createProduct(CreateProductRequest product) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(product.toJson()),
    );

    if (response.statusCode == 201) {
      try {
        final responseData = json.decode(response.body);
        debugPrint('API Response: $responseData');
        return ApiProduct.fromJson(responseData);
      } catch (e) {
        debugPrint('Error parsing API response: $e');
        debugPrint('Response body: ${response.body}');
        rethrow;
      }
    }
    throw Exception('Failed to create product: ${response.body}');
  }

  /// Update a product
  Future<ApiProduct> updateProduct(String id, UpdateProductRequest product) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(product.toJson()),
    );

    if (response.statusCode == 200) {
      return ApiProduct.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to update product: ${response.body}');
  }

  /// Delete a product
  Future<void> deleteProduct(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete product: ${response.body}');
    }
  }

  // ==================== CATEGORIES MANAGEMENT ====================

  /// Get all categories
  Future<List<ApiCategory>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/categories'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => ApiCategory.fromJson(item)).toList();
    }
    throw Exception('Failed to load categories: ${response.body}');
  }

  /// Get a single category by ID
  Future<ApiCategory> getCategory(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/categories/$id'));

    if (response.statusCode == 200) {
      return ApiCategory.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load category: ${response.body}');
  }

  /// Create a new category
  Future<ApiCategory> createCategory(CreateCategoryRequest category) async {
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(category.toJson()),
    );

    if (response.statusCode == 201) {
      return ApiCategory.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to create category: ${response.body}');
  }

  /// Update a category
  Future<ApiCategory> updateCategory(
    String id,
    UpdateCategoryRequest category,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(category.toJson()),
    );

    if (response.statusCode == 200) {
      return ApiCategory.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to update category: ${response.body}');
  }

  /// Delete a category
  Future<void> deleteCategory(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$id'),
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete category: ${response.body}');
    }
  }

  // ==================== INVENTORY MANAGEMENT ====================

  /// Get inventory details for a specific product
  Future<ApiInventory> getInventory(String productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/inventory/$productId'),
    );

    if (response.statusCode == 200) {
      return ApiInventory.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load inventory: ${response.body}');
  }

  /// Update inventory settings
  ///
  /// Use this to update stock levels, thresholds, or location
  /// For tracking stock changes with history, use [adjustStock] instead
  Future<ApiInventory> updateInventory(
    String productId,
    UpdateInventoryRequest inventory,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/inventory/$productId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(inventory.toJson()),
    );

    if (response.statusCode == 200) {
      return ApiInventory.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to update inventory: ${response.body}');
  }

  /// Adjust stock quantity with tracking
  ///
  /// Use this for adding or removing stock with history tracking
  /// - Positive [quantityChange]: Add stock
  /// - Negative [quantityChange]: Remove stock
  ///
  /// Creates a record in stock_movements for tracking
  Future<ApiInventory> adjustStock(AdjustStockRequest adjustment) async {
    final response = await http.post(
      Uri.parse('$baseUrl/inventory/adjust'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(adjustment.toJson()),
    );

    if (response.statusCode == 200) {
      return ApiInventory.fromJson(json.decode(response.body));
    }

    // Handle specific errors
    if (response.statusCode == 400 &&
        response.body.contains('Insufficient stock')) {
      throw InsufficientStockException(
        'Not enough stock for this operation',
      );
    }

    throw Exception('Failed to adjust stock: ${response.body}');
  }

  /// Get products with low stock (quantity <= min_stock_level)
  Future<List<LowStockProduct>> getLowStockProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/inventory/low-stock'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => LowStockProduct.fromJson(item)).toList();
    }
    throw Exception('Failed to load low stock products: ${response.body}');
  }

  // ==================== STOCK MOVEMENTS & HISTORY ====================

  /// Get stock movement history for a product (last 100 records)
  Future<List<StockMovement>> getStockMovements(String productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/inventory/movements/$productId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => StockMovement.fromJson(item)).toList();
    }
    throw Exception('Failed to load stock movements: ${response.body}');
  }

  // ==================== HELPER METHODS ====================

  /// Generate unique SKU for a product
  /// Format: PREFIX-TIMESTAMP
  String generateSKU(String prefix) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$prefix-$timestamp';
  }

  /// Check if backend is reachable
  Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl.replaceAll('/api', '/health')),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Custom exception for insufficient stock errors
class InsufficientStockException implements Exception {
  final String message;
  InsufficientStockException(this.message);

  @override
  String toString() => message;
}

/// Custom exception for product not found errors
class ProductNotFoundException implements Exception {
  final String message;
  ProductNotFoundException(this.message);

  @override
  String toString() => message;
}
