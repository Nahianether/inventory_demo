import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/api_home_screen.dart';
import 'screens/api_inventory_screen.dart';
import 'screens/api_sale_screen.dart';
import 'screens/api_purchase_screen.dart';
import 'screens/api_category_screen.dart';
import 'widgets/app_layout.dart';

// Old imports commented out for pure API approach
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:uuid/uuid.dart';
// import 'models/product.dart';
// import 'models/transaction.dart';
// import 'models/account.dart';
// import 'models/category.dart';
// import 'screens/home_screen.dart';
// import 'screens/inventory_screen.dart';
// import 'screens/add_product_screen.dart';
// import 'screens/purchase_screen.dart';
// import 'screens/sale_screen.dart';
// import 'screens/account_screen.dart';
// import 'screens/category_screen.dart';
// import 'providers/inventory_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // NOTE: Hive initialization commented out for pure API approach
  // Uncomment below if you want to use Hive-based screens
  /*
  await Hive.initFlutter();
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(AccountAdapter());
  Hive.registerAdapter(CategoryAdapter());
  await _migrateCategories();
  */

  runApp(const ProviderScope(
    child: MyApp(),
    overrides: [],
  ));
}

// Hive migration commented out for pure API approach
/*
Future<void> _migrateCategories() async {
  final productBox = await Hive.openBox<Product>('products');
  final categoryBox = await Hive.openBox<Category>('categories');

  if (categoryBox.isEmpty && productBox.isNotEmpty) {
    final uniqueCategories = <String>{};
    for (final product in productBox.values) {
      if (product.category.isNotEmpty) {
        uniqueCategories.add(product.category);
      }
    }
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
*/

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Commented out for pure API approach
    /*
    ProductNotifier.onCategoryCreated = () {
      ref.read(categoryProvider.notifier).reloadCategories();
    };
    */
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple), useMaterial3: true),
      initialRoute: '/api-home',
      routes: {
        // Pure API routes (active)
        '/': (context) => const AppLayout(currentRoute: '/api-home', child: ApiHomeScreen()), // Redirect / to API home
        '/api-home': (context) => const AppLayout(currentRoute: '/api-home', child: ApiHomeScreen()),
        '/api-inventory': (context) => const AppLayout(currentRoute: '/api-inventory', child: ApiInventoryScreen()),
        '/api-sale': (context) => const AppLayout(currentRoute: '/api-sale', child: ApiSaleScreen()),
        '/api-purchase': (context) => const AppLayout(currentRoute: '/api-purchase', child: ApiPurchaseScreen()),
        '/api-categories': (context) => const AppLayout(currentRoute: '/api-categories', child: ApiCategoryScreen()),

        // Old Hive-based routes (commented out - won't work without Hive)
        // '/inventory': (context) => const AppLayout(currentRoute: '/inventory', child: InventoryScreen()),
        // '/categories': (context) => const AppLayout(currentRoute: '/categories', child: CategoryScreen()),
        // '/add-product': (context) => const AppLayout(currentRoute: '/add-product', child: AddProductScreen()),
        // '/purchase': (context) => const AppLayout(currentRoute: '/purchase', child: PurchaseScreen()),
        // '/sale': (context) => const AppLayout(currentRoute: '/sale', child: SaleScreen()),
        // '/account': (context) => const AppLayout(currentRoute: '/account', child: AccountScreen()),
      },
    );
  }
}
