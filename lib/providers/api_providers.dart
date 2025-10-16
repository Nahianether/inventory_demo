import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api/api_product.dart';
import '../models/api/api_category.dart';
import '../models/api/api_inventory.dart';
import '../services/inventory_api_service.dart';

/// API-based product provider - fetches directly from server
final apiProductProvider = StateNotifierProvider<ApiProductNotifier, AsyncValue<List<ApiProduct>>>((ref) {
  return ApiProductNotifier();
});

class ApiProductNotifier extends StateNotifier<AsyncValue<List<ApiProduct>>> {
  ApiProductNotifier() : super(const AsyncValue.loading()) {
    loadProducts();
  }

  final InventoryApiService _apiService = InventoryApiService();

  /// Load all products from server
  Future<void> loadProducts() async {
    state = const AsyncValue.loading();
    try {
      final products = await _apiService.getProducts();
      state = AsyncValue.data(products);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new product on server
  Future<void> createProduct(CreateProductRequest request) async {
    try {
      await _apiService.createProduct(request);
      await loadProducts(); // Refresh list
    } catch (e) {
      rethrow;
    }
  }

  /// Update a product on server
  Future<void> updateProduct(String productId, UpdateProductRequest request) async {
    try {
      await _apiService.updateProduct(productId, request);
      await loadProducts(); // Refresh list
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a product from server
  Future<void> deleteProduct(String productId) async {
    try {
      await _apiService.deleteProduct(productId);
      await loadProducts(); // Refresh list
    } catch (e) {
      rethrow;
    }
  }

  /// Adjust stock quantity
  Future<void> adjustStock(AdjustStockRequest request) async {
    try {
      await _apiService.adjustStock(request);
      await loadProducts(); // Refresh list
    } catch (e) {
      rethrow;
    }
  }

  /// Get a single product by ID
  ApiProduct? getProductById(String productId) {
    return state.whenOrNull(
      data: (products) => products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found'),
      ),
    );
  }
}

/// API-based category provider - fetches directly from server
final apiCategoryProvider = StateNotifierProvider<ApiCategoryNotifier, AsyncValue<List<ApiCategory>>>((ref) {
  return ApiCategoryNotifier();
});

class ApiCategoryNotifier extends StateNotifier<AsyncValue<List<ApiCategory>>> {
  ApiCategoryNotifier() : super(const AsyncValue.loading()) {
    loadCategories();
  }

  final InventoryApiService _apiService = InventoryApiService();

  /// Load all categories from server
  Future<void> loadCategories() async {
    state = const AsyncValue.loading();
    try {
      final categories = await _apiService.getCategories();
      state = AsyncValue.data(categories);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Create a new category on server
  Future<ApiCategory> createCategory(CreateCategoryRequest request) async {
    try {
      final category = await _apiService.createCategory(request);
      await loadCategories(); // Refresh list
      return category;
    } catch (e) {
      rethrow;
    }
  }

  /// Update a category on server
  Future<void> updateCategory(String categoryId, UpdateCategoryRequest request) async {
    try {
      await _apiService.updateCategory(categoryId, request);
      await loadCategories(); // Refresh list
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a category from server
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _apiService.deleteCategory(categoryId);
      await loadCategories(); // Refresh list
    } catch (e) {
      rethrow;
    }
  }

  /// Get a single category by ID
  ApiCategory? getCategoryById(String categoryId) {
    return state.whenOrNull(
      data: (categories) => categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => throw Exception('Category not found'),
      ),
    );
  }
}

/// Computed providers for statistics (from API data)
final apiTotalInventoryValueProvider = Provider<double>((ref) {
  final products = ref.watch(apiProductProvider);
  return products.when(
    data: (productList) => productList.fold(
      0.0,
      (sum, product) => sum + ((product.costPrice ?? 0) * product.stockQuantity),
    ),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

final apiPotentialRevenueProvider = Provider<double>((ref) {
  final products = ref.watch(apiProductProvider);
  return products.when(
    data: (productList) => productList.fold(
      0.0,
      (sum, product) => sum + (product.price * product.stockQuantity),
    ),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

final apiLowStockProductsProvider = Provider<List<ApiProduct>>((ref) {
  final products = ref.watch(apiProductProvider);
  return products.when(
    data: (productList) => productList.where((p) => p.stockQuantity < 5).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final apiOutOfStockProductsProvider = Provider<List<ApiProduct>>((ref) {
  final products = ref.watch(apiProductProvider);
  return products.when(
    data: (productList) => productList.where((p) => p.stockQuantity == 0).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
