import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'models/product.dart';
import 'models/transaction.dart';
import 'models/account.dart';
import 'models/category.dart';
import 'screens/home_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/purchase_screen.dart';
import 'screens/sale_screen.dart';
import 'screens/account_screen.dart';
import 'screens/category_screen.dart';
import 'widgets/app_layout.dart';
import 'providers/inventory_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(AccountAdapter());
  Hive.registerAdapter(CategoryAdapter());

  // Migrate existing product categories to Category entities
  await _migrateCategories();

  runApp(ProviderScope(
    child: MyApp(),
    overrides: [],
  ));
}

Future<void> _migrateCategories() async {
  final productBox = await Hive.openBox<Product>('products');
  final categoryBox = await Hive.openBox<Category>('categories');

  // Only migrate if categories box is empty
  if (categoryBox.isEmpty && productBox.isNotEmpty) {
    final uniqueCategories = <String>{};

    // Collect all unique category names from products
    for (final product in productBox.values) {
      if (product.category.isNotEmpty) {
        uniqueCategories.add(product.category);
      }
    }

    // Create Category entities for each unique category
    for (final categoryName in uniqueCategories) {
      final category = Category(
        id: const Uuid().v4(),
        name: categoryName,
        description: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await categoryBox.put(category.id, category);
    }

    debugPrint('Migrated ${uniqueCategories.length} categories from existing products');
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Set up callback to reload categories when product creates a new category
    ProductNotifier.onCategoryCreated = () {
      ref.read(categoryProvider.notifier).reloadCategories();
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (context) => const AppLayout(currentRoute: '/', child: HomeScreen()),
        '/inventory': (context) => const AppLayout(currentRoute: '/inventory', child: InventoryScreen()),
        '/categories': (context) => const AppLayout(currentRoute: '/categories', child: CategoryScreen()),
        '/add-product': (context) => const AppLayout(currentRoute: '/add-product', child: AddProductScreen()),
        '/purchase': (context) => const AppLayout(currentRoute: '/purchase', child: PurchaseScreen()),
        '/sale': (context) => const AppLayout(currentRoute: '/sale', child: SaleScreen()),
        '/account': (context) => const AppLayout(currentRoute: '/account', child: AccountScreen()),
      },
    );
  }
}
