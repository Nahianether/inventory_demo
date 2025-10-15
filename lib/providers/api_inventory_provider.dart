import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api/api_product.dart';
import '../models/api/api_category.dart';
import '../models/api/api_inventory.dart';
import '../services/inventory_api_service.dart';

// API Service provider
final apiServiceProvider = Provider<InventoryApiService>((ref) {
  return InventoryApiService();
});

// ==================== PRODUCT PROVIDERS ====================

/// Product list provider - fetches all products from API
final apiProductProvider = StateNotifierProvider<ApiProductNotifier, AsyncValue<List<ApiProduct>>>((ref) {
  return ApiProductNotifier(ref.watch(apiServiceProvider));
});

class ApiProductNotifier extends StateNotifier<AsyncValue<List<ApiProduct>>> {
  ApiProductNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadProducts();
  }

  final InventoryApiService _apiService;

  /// Load all products from API
  Future<void> loadProducts({
    String? search,
    String? categoryId,
    bool? isActive,
  }) async {
    state = const AsyncValue.loading();
    try {
      final products = await _apiService.getProducts(
        search: search,
        categoryId: categoryId,
        isActive: isActive,
      );
      state = AsyncValue.data(products);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Add a new product
  Future<ApiProduct> addProduct({
    required String name,
    String? description,
    required String sku,
    required double price,
    double? costPrice,
    String? categoryId,
    int? initialStock,
  }) async {
    try {
      final request = CreateProductRequest(
        name: name,
        description: description,
        sku: sku,
        price: price,
        costPrice: costPrice,
        categoryId: categoryId,
        initialStock: initialStock,
      );

      final product = await _apiService.createProduct(request);

      // Refresh the product list
      await loadProducts();

      return product;
    } catch (e) {
      rethrow;
    }
  }

  /// Update an existing product
  Future<ApiProduct> updateProduct(
    String id, {
    String? name,
    String? description,
    String? sku,
    double? price,
    double? costPrice,
    String? categoryId,
    bool? isActive,
  }) async {
    try {
      final request = UpdateProductRequest(
        name: name,
        description: description,
        sku: sku,
        price: price,
        costPrice: costPrice,
        categoryId: categoryId,
        isActive: isActive,
      );

      final product = await _apiService.updateProduct(id, request);

      // Refresh the product list
      await loadProducts();

      return product;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a product
  Future<void> deleteProduct(String id) async {
    try {
      await _apiService.deleteProduct(id);

      // Refresh the product list
      await loadProducts();
    } catch (e) {
      rethrow;
    }
  }

  /// Get a product by ID
  ApiProduct? getProductById(String id) {
    final products = state.value;
    if (products == null) return null;
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}

// ==================== CATEGORY PROVIDERS ====================

/// Category list provider - fetches all categories from API
final apiCategoryProvider = StateNotifierProvider<ApiCategoryNotifier, AsyncValue<List<ApiCategory>>>((ref) {
  return ApiCategoryNotifier(ref.watch(apiServiceProvider));
});

class ApiCategoryNotifier extends StateNotifier<AsyncValue<List<ApiCategory>>> {
  ApiCategoryNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  final InventoryApiService _apiService;

  /// Load all categories from API
  Future<void> loadCategories() async {
    state = const AsyncValue.loading();
    try {
      final categories = await _apiService.getCategories();
      state = AsyncValue.data(categories);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Add a new category
  Future<ApiCategory> addCategory({
    required String name,
    String? description,
  }) async {
    try {
      final request = CreateCategoryRequest(
        name: name,
        description: description,
      );

      final category = await _apiService.createCategory(request);

      // Refresh the category list
      await loadCategories();

      return category;
    } catch (e) {
      rethrow;
    }
  }

  /// Update a category
  Future<ApiCategory> updateCategory(
    String id, {
    String? name,
    String? description,
  }) async {
    try {
      final request = UpdateCategoryRequest(
        name: name,
        description: description,
      );

      final category = await _apiService.updateCategory(id, request);

      // Refresh the category list
      await loadCategories();

      return category;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a category
  Future<void> deleteCategory(String id) async {
    try {
      await _apiService.deleteCategory(id);

      // Refresh the category list
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }

  /// Get a category by ID
  ApiCategory? getCategoryById(String id) {
    final categories = state.value;
    if (categories == null) return null;
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get a category by name
  ApiCategory? getCategoryByName(String name) {
    final categories = state.value;
    if (categories == null) return null;
    try {
      return categories.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}

// ==================== INVENTORY PROVIDERS ====================

/// Inventory operations provider
final apiInventoryProvider = Provider<ApiInventoryService>((ref) {
  return ApiInventoryService(ref.watch(apiServiceProvider));
});

class ApiInventoryService {
  ApiInventoryService(this._apiService);

  final InventoryApiService _apiService;

  /// Get inventory details for a product
  Future<ApiInventory> getInventory(String productId) async {
    return await _apiService.getInventory(productId);
  }

  /// Update inventory settings
  Future<ApiInventory> updateInventory(
    String productId, {
    int? quantity,
    int? minStockLevel,
    int? maxStockLevel,
    String? location,
  }) async {
    final request = UpdateInventoryRequest(
      quantity: quantity,
      minStockLevel: minStockLevel,
      maxStockLevel: maxStockLevel,
      location: location,
    );

    return await _apiService.updateInventory(productId, request);
  }

  /// Adjust stock with tracking (for sales and purchases)
  Future<ApiInventory> adjustStock({
    required String productId,
    required int quantityChange,
    String? reason,
  }) async {
    final request = AdjustStockRequest(
      productId: productId,
      quantityChange: quantityChange,
      reason: reason,
    );

    return await _apiService.adjustStock(request);
  }

  /// Get low stock products
  Future<List<LowStockProduct>> getLowStockProducts() async {
    return await _apiService.getLowStockProducts();
  }

  /// Get stock movement history
  Future<List<StockMovement>> getStockMovements(String productId) async {
    return await _apiService.getStockMovements(productId);
  }
}

// ==================== COMPUTED PROVIDERS ====================

/// Total inventory value provider
final totalInventoryValueProvider = Provider<double>((ref) {
  final productsAsync = ref.watch(apiProductProvider);
  return productsAsync.when(
    data: (products) => products.fold(
      0.0,
      (sum, product) => sum + product.totalBuyingValue,
    ),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// Potential revenue provider
final potentialRevenueProvider = Provider<double>((ref) {
  final productsAsync = ref.watch(apiProductProvider);
  return productsAsync.when(
    data: (products) => products.fold(
      0.0,
      (sum, product) => sum + product.potentialRevenue,
    ),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

/// Low stock products provider
final lowStockProductsProvider = Provider<List<ApiProduct>>((ref) {
  final productsAsync = ref.watch(apiProductProvider);
  return productsAsync.when(
    data: (products) => products.where((p) => p.isLowStock).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Out of stock products provider
final outOfStockProductsProvider = Provider<List<ApiProduct>>((ref) {
  final productsAsync = ref.watch(apiProductProvider);
  return productsAsync.when(
    data: (products) => products.where((p) => !p.isInStock).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});
