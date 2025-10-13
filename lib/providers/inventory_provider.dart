import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../models/category.dart';

// Product provider - manages all products
final productProvider = StateNotifierProvider<ProductNotifier, List<Product>>((ref) {
  return ProductNotifier();
});

class ProductNotifier extends StateNotifier<List<Product>> {
  ProductNotifier() : super([]) {
    _loadProducts();
  }

  Box<Product>? _productBox;

  Future<void> _loadProducts() async {
    _productBox = await Hive.openBox<Product>('products');
    state = _productBox!.values.toList();
  }

  Future<Product> addProduct({
    required String name,
    required String category,
    required double buyingPrice,
    required double sellingPrice,
    required int quantity,
    String? description,
  }) async {
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

    await _productBox?.put(product.id, product);
    state = [...state, product];
    return product;
  }

  Future<void> updateProduct(Product product) async {
    final updatedProduct = product.copyWith(updatedAt: DateTime.now());
    await _productBox?.put(updatedProduct.id, updatedProduct);
    state = [
      for (final p in state)
        if (p.id == updatedProduct.id) updatedProduct else p,
    ];
  }

  Future<void> deleteProduct(String productId) async {
    await _productBox?.delete(productId);
    state = state.where((p) => p.id != productId).toList();
  }

  Future<void> updateProductQuantity(String productId, int newQuantity) async {
    final product = state.firstWhere((p) => p.id == productId);
    final updatedProduct = product.copyWith(
      quantity: newQuantity,
      updatedAt: DateTime.now(),
    );
    await updateProduct(updatedProduct);
  }

  Product? getProductById(String productId) {
    try {
      return state.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }
}

// Transaction provider - manages all transactions
final transactionProvider = StateNotifierProvider<TransactionNotifier, List<Transaction>>((ref) {
  return TransactionNotifier();
});

class TransactionNotifier extends StateNotifier<List<Transaction>> {
  TransactionNotifier() : super([]) {
    _loadTransactions();
  }

  Box<Transaction>? _transactionBox;

  Future<void> _loadTransactions() async {
    _transactionBox = await Hive.openBox<Transaction>('transactions');
    state = _transactionBox!.values.toList();
  }

  Future<void> addTransaction(Transaction transaction) async {
    await _transactionBox?.put(transaction.id, transaction);
    state = [...state, transaction];
  }

  List<Transaction> getPurchaseTransactions() {
    return state.where((t) => t.type == 'purchase').toList();
  }

  List<Transaction> getSaleTransactions() {
    return state.where((t) => t.type == 'sale').toList();
  }

  List<Transaction> getTransactionsByProduct(String productId) {
    return state.where((t) => t.productId == productId).toList();
  }
}

// Account provider - manages financial account
final accountProvider = StateNotifierProvider<AccountNotifier, Account?>((ref) {
  return AccountNotifier();
});

class AccountNotifier extends StateNotifier<Account?> {
  AccountNotifier() : super(null) {
    _loadAccount();
  }

  Box<Account>? _accountBox;

  Future<void> _loadAccount() async {
    _accountBox = await Hive.openBox<Account>('account');
    if (_accountBox!.isEmpty) {
      // Create default account
      final account = Account(
        id: const Uuid().v4(),
        totalBalance: 0,
        totalRevenue: 0,
        totalExpenses: 0,
        totalProfit: 0,
        lastUpdated: DateTime.now(),
      );
      await _accountBox?.put('main', account);
      state = account;
    } else {
      state = _accountBox?.get('main');
    }
  }

  Future<void> recordSale(double saleAmount, double costAmount) async {
    if (state == null) return;

    final updatedAccount = state!.copyWith(
      totalBalance: state!.totalBalance + saleAmount,
      totalRevenue: state!.totalRevenue + saleAmount,
      totalExpenses: state!.totalExpenses + costAmount,
      totalProfit: state!.totalProfit + (saleAmount - costAmount),
      lastUpdated: DateTime.now(),
    );

    await _accountBox?.put('main', updatedAccount);
    state = updatedAccount;
  }

  Future<void> recordPurchase(double purchaseAmount) async {
    if (state == null) return;

    final updatedAccount = state!.copyWith(
      totalBalance: state!.totalBalance - purchaseAmount,
      totalExpenses: state!.totalExpenses + purchaseAmount,
      totalProfit: state!.totalProfit - purchaseAmount,
      lastUpdated: DateTime.now(),
    );

    await _accountBox?.put('main', updatedAccount);
    state = updatedAccount;
  }

  Future<void> resetAccount() async {
    final account = Account(
      id: const Uuid().v4(),
      totalBalance: 0,
      totalRevenue: 0,
      totalExpenses: 0,
      totalProfit: 0,
      lastUpdated: DateTime.now(),
    );
    await _accountBox?.put('main', account);
    state = account;
  }
}

// Computed providers
final totalInventoryValueProvider = Provider<double>((ref) {
  final products = ref.watch(productProvider);
  return products.fold(0.0, (sum, product) => sum + product.totalBuyingValue);
});

final potentialRevenueProvider = Provider<double>((ref) {
  final products = ref.watch(productProvider);
  return products.fold(0.0, (sum, product) => sum + product.potentialRevenue);
});

final lowStockProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productProvider);
  return products.where((p) => p.isLowStock).toList();
});

final outOfStockProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productProvider);
  return products.where((p) => !p.isInStock).toList();
});

// Category provider - manages all categories
final categoryProvider = StateNotifierProvider<CategoryNotifier, List<Category>>((ref) {
  return CategoryNotifier();
});

class CategoryNotifier extends StateNotifier<List<Category>> {
  CategoryNotifier() : super([]) {
    _loadCategories();
  }

  Box<Category>? _categoryBox;

  Future<void> _loadCategories() async {
    _categoryBox = await Hive.openBox<Category>('categories');
    state = _categoryBox!.values.toList();
  }

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

    await _categoryBox?.put(category.id, category);
    state = [...state, category];
    return category;
  }

  Future<void> updateCategory(Category category) async {
    final updatedCategory = category.copyWith(updatedAt: DateTime.now());
    await _categoryBox?.put(updatedCategory.id, updatedCategory);
    state = [
      for (final c in state)
        if (c.id == updatedCategory.id) updatedCategory else c,
    ];
  }

  Future<bool> deleteCategory(String categoryId) async {
    // Check if category is in use by any products
    final productBox = await Hive.openBox<Product>('products');
    final productsUsingCategory = productBox.values
        .where((product) => product.category == getCategoryById(categoryId)?.name)
        .toList();

    if (productsUsingCategory.isNotEmpty) {
      return false; // Cannot delete category that's in use
    }

    await _categoryBox?.delete(categoryId);
    state = state.where((c) => c.id != categoryId).toList();
    return true;
  }

  Category? getCategoryById(String categoryId) {
    try {
      return state.firstWhere((c) => c.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  Category? getCategoryByName(String categoryName) {
    try {
      return state.firstWhere((c) => c.name.toLowerCase() == categoryName.toLowerCase());
    } catch (e) {
      return null;
    }
  }
}
