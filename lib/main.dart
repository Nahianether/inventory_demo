import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/product.dart';
import 'models/transaction.dart';
import 'models/account.dart';
import 'screens/home_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/purchase_screen.dart';
import 'screens/sale_screen.dart';
import 'screens/account_screen.dart';
import 'widgets/app_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(AccountAdapter());

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        '/add-product': (context) => const AppLayout(currentRoute: '/add-product', child: AddProductScreen()),
        '/purchase': (context) => const AppLayout(currentRoute: '/purchase', child: PurchaseScreen()),
        '/sale': (context) => const AppLayout(currentRoute: '/sale', child: SaleScreen()),
        '/account': (context) => const AppLayout(currentRoute: '/account', child: AccountScreen()),
      },
    );
  }
}
