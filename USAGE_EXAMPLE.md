# API Integration Usage Examples

## Quick Start: Using API Screens in Your App

### Option 1: Use the Demo Home Screen (Easiest)

Simply replace your main app widget with the API demo home:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/api_demo_home.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const ApiDemoHome(), // Use API version
    );
  }
}
```

### Option 2: Add API Screens to Existing Navigation

If you have existing navigation, add the API screens:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/add_product_screen_api.dart';
import 'screens/sale_screen_api.dart';
import 'screens/inventory_screen_api.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = [
    const InventoryScreenApi(),
    const AddProductScreenApi(),
    const SaleScreenApi(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add Product',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Sales',
          ),
        ],
      ),
    );
  }
}
```

### Option 3: Individual Screen Usage

Use individual API screens where needed:

```dart
// Navigate to Add Product Screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const AddProductScreenApi()),
);

// Navigate to Sale Screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const SaleScreenApi()),
);

// Navigate to Inventory Screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const InventoryScreenApi()),
);
```

## Common Operations Examples

### 1. Adding a Product Programmatically

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/api_inventory_provider.dart';

class MyWidget extends ConsumerWidget {
  const MyWidget({super.key});

  Future<void> addProduct(WidgetRef ref) async {
    try {
      final product = await ref.read(apiProductProvider.notifier).addProduct(
        name: 'Coca Cola',
        sku: 'DRINK-001',
        price: 2.99,
        costPrice: 1.50,
        categoryId: 'category-uuid-here',
        initialStock: 100,
        description: 'Classic Coca Cola 330ml',
      );

      print('Product added: ${product.name}');
    } catch (e) {
      print('Error adding product: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => addProduct(ref),
      child: const Text('Add Product'),
    );
  }
}
```

### 2. Recording a Sale

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/api_inventory_provider.dart';

class SaleWidget extends ConsumerWidget {
  const SaleWidget({super.key});

  Future<void> recordSale(WidgetRef ref, String productId, int quantity) async {
    try {
      final inventoryService = ref.read(apiInventoryProvider);

      // Adjust stock (remove items)
      await inventoryService.adjustStock(
        productId: productId,
        quantityChange: -quantity,
        reason: 'Sale transaction',
      );

      // Refresh product list to show updated stock
      await ref.read(apiProductProvider.notifier).loadProducts();

      print('Sale recorded successfully');
    } catch (e) {
      print('Error recording sale: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => recordSale(ref, 'product-uuid', 5),
      child: const Text('Sell 5 Units'),
    );
  }
}
```

### 3. Restocking Products

```dart
Future<void> restockProduct(WidgetRef ref, String productId, int quantity) async {
  try {
    final inventoryService = ref.read(apiInventoryProvider);

    // Adjust stock (add items)
    await inventoryService.adjustStock(
      productId: productId,
      quantityChange: quantity,
      reason: 'Restock from supplier',
    );

    // Refresh product list
    await ref.read(apiProductProvider.notifier).loadProducts();

    print('Restocked successfully');
  } catch (e) {
    print('Error restocking: $e');
  }
}
```

### 4. Displaying Products in a Custom Widget

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/api_inventory_provider.dart';

class ProductListWidget extends ConsumerWidget {
  const ProductListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(apiProductProvider);

    return productsAsync.when(
      data: (products) => ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Text('Stock: ${product.stockQuantity}'),
            trailing: Text('\$${product.price.toStringAsFixed(2)}'),
            leading: Icon(
              product.isInStock ? Icons.check_circle : Icons.warning,
              color: product.isInStock ? Colors.green : Colors.red,
            ),
          );
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}
```

### 5. Checking Low Stock Products

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/api_inventory_provider.dart';

class LowStockAlert extends ConsumerWidget {
  const LowStockAlert({super.key});

  Future<void> checkLowStock(BuildContext context, WidgetRef ref) async {
    try {
      final inventoryService = ref.read(apiInventoryProvider);
      final lowStockProducts = await inventoryService.getLowStockProducts();

      if (lowStockProducts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All products are well stocked!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Show alert
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Low Stock Alert'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: lowStockProducts.map((product) {
                return ListTile(
                  title: Text(product.productName),
                  subtitle: Text('Current: ${product.currentQuantity}'),
                  trailing: Text(
                    'Need: ${product.stockDeficit}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () => checkLowStock(context, ref),
      child: const Text('Check Low Stock'),
    );
  }
}
```

### 6. Viewing Stock Movement History

```dart
Future<void> viewStockHistory(
  BuildContext context,
  WidgetRef ref,
  String productId,
) async {
  try {
    final inventoryService = ref.read(apiInventoryProvider);
    final movements = await inventoryService.getStockMovements(productId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stock Movement History'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: movements.length,
            itemBuilder: (context, index) {
              final movement = movements[index];
              return ListTile(
                leading: Icon(
                  movement.isAddition ? Icons.add_circle : Icons.remove_circle,
                  color: movement.isAddition ? Colors.green : Colors.red,
                ),
                title: Text(
                  '${movement.isAddition ? "+" : ""}${movement.quantityChange}',
                  style: TextStyle(
                    color: movement.isAddition ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(movement.reason ?? 'No reason provided'),
                trailing: Text(
                  movement.createdAt.toString().split('.')[0],
                  style: const TextStyle(fontSize: 11),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### 7. Adding Categories

```dart
Future<void> addCategory(WidgetRef ref, String name, String? description) async {
  try {
    final category = await ref.read(apiCategoryProvider.notifier).addCategory(
      name: name,
      description: description,
    );

    print('Category added: ${category.name}');
  } catch (e) {
    print('Error adding category: $e');
  }
}
```

### 8. Connection Status Check

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/api_inventory_provider.dart';

class ConnectionStatus extends ConsumerWidget {
  const ConnectionStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<bool>(
      future: ref.read(apiServiceProvider).healthCheck(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final isConnected = snapshot.data ?? false;

        return Row(
          children: [
            Icon(
              isConnected ? Icons.check_circle : Icons.error,
              color: isConnected ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(isConnected ? 'Connected' : 'Disconnected'),
          ],
        );
      },
    );
  }
}
```

## Configuration

### Setting Base URL

Before using the API, configure the base URL in `lib/services/inventory_api_service.dart`:

```dart
// For Android Emulator
static const String baseUrl = 'http://10.0.2.2:3000/api';

// For iOS Simulator
static const String baseUrl = 'http://localhost:3000/api';

// For Physical Device
static const String baseUrl = 'http://192.168.1.XXX:3000/api';
```

### Handling Errors

Always wrap API calls in try-catch blocks:

```dart
try {
  await inventoryService.adjustStock(...);
} on InsufficientStockException catch (e) {
  // Handle insufficient stock
  print('Not enough stock: $e');
} catch (e) {
  // Handle other errors
  print('Error: $e');
}
```

## Testing

Test the connection before making API calls:

```dart
final apiService = ref.read(apiServiceProvider);
final isHealthy = await apiService.healthCheck();

if (!isHealthy) {
  // Show error message to user
  print('Backend is not accessible');
  return;
}

// Proceed with API operations
await apiService.getProducts();
```

## Next Steps

1. Start your backend server
2. Update the base URL in `inventory_api_service.dart`
3. Run the app with `flutter run`
4. Test with the `ApiDemoHome` screen
5. Integrate individual screens into your existing navigation

For more details, see `API_INTEGRATION_README.md`
