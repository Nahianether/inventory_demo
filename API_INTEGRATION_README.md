# Inventory Management API Integration Guide

Complete guide for integrating your Flutter inventory app with the backend API.

## 📋 What's Been Implemented

### ✅ API Models
- `ApiProduct` - Product model matching backend schema
- `ApiCategory` - Category model matching backend schema
- `ApiInventory` - Inventory model with stock tracking
- `CreateProductRequest` - Request model for creating products
- `UpdateProductRequest` - Request model for updating products
- `AdjustStockRequest` - Request model for stock adjustments
- `LowStockProduct` - Model for low stock alerts
- `StockMovement` - Model for stock movement history

### ✅ API Service
- **Location**: `lib/services/inventory_api_service.dart`
- **Features**:
  - Complete CRUD operations for products
  - Complete CRUD operations for categories
  - Inventory management (get, update, adjust stock)
  - Low stock alerts
  - Stock movement history
  - Health check for backend connectivity
  - Custom exceptions for better error handling

### ✅ Providers
- **Location**: `lib/providers/api_inventory_provider.dart`
- **Providers**:
  - `apiProductProvider` - Manages product list from API
  - `apiCategoryProvider` - Manages category list from API
  - `apiInventoryProvider` - Handles inventory operations
  - Computed providers for inventory value, potential revenue, low stock, etc.

### ✅ Screens (API-based)
All screens have been created with API integration:

1. **Add Product Screen** (`lib/screens/add_product_screen_api.dart`)
   - Add new products with initial stock
   - Auto-generate SKUs
   - Category dropdown from API
   - Real-time validation

2. **Sale Screen** (`lib/screens/sale_screen_api.dart`)
   - Record sales with stock adjustment via API
   - Real-time stock validation
   - Profit calculation
   - Transaction tracking

3. **Inventory Screen** (`lib/screens/inventory_screen_api.dart`)
   - View all products with real-time stock
   - Search and filter functionality
   - Restock products
   - Adjust stock (add/remove)
   - Delete products
   - Status badges (In Stock, Low Stock, Out of Stock)

## 🚀 Quick Start

### Step 1: Configure Base URL

Open `lib/services/inventory_api_service.dart` and update the `baseUrl`:

```dart
class InventoryApiService {
  // For Android Emulator
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // For iOS Simulator
  // static const String baseUrl = 'http://localhost:3000/api';

  // For Physical Device (replace with your computer's IP)
  // static const String baseUrl = 'http://192.168.1.XXX:3000/api';

  // ...rest of the code
}
```

### Step 2: Ensure Backend is Running

Make sure your backend server is running on port 3000:

```bash
# Check if backend is accessible
curl http://localhost:3000/health
# Should return: OK
```

### Step 3: Test API Connection

The app includes a health check feature. You can test connectivity:

```dart
final apiService = InventoryApiService();
final isConnected = await apiService.healthCheck();
print('Backend connected: $isConnected');
```

### Step 4: Use API Screens in Your App

Replace your existing screens with the API versions. Update your navigation/routing:

```dart
// Example: Update your home screen or navigation
import 'package:inventory_demo/screens/add_product_screen_api.dart';
import 'package:inventory_demo/screens/sale_screen_api.dart';
import 'package:inventory_demo/screens/inventory_screen_api.dart';

// Then use these screens in your navigation
```

## 📱 Using the API Features

### Adding Products

```dart
// Via Provider
final productNotifier = ref.read(apiProductProvider.notifier);

await productNotifier.addProduct(
  name: 'Burger',
  sku: 'FOOD-001',
  price: 5.99,
  costPrice: 2.50,
  categoryId: categoryId,
  initialStock: 100,
  description: 'Classic beef burger',
);
```

### Recording Sales

```dart
// Adjust stock via inventory service
final inventoryService = ref.read(apiInventoryProvider);

await inventoryService.adjustStock(
  productId: productId,
  quantityChange: -10, // Negative for sale
  reason: 'Sale transaction',
);
```

### Restocking Products

```dart
// Add stock
await inventoryService.adjustStock(
  productId: productId,
  quantityChange: 50, // Positive for restock
  reason: 'New shipment received',
);
```

### Checking Low Stock

```dart
final inventoryService = ref.read(apiInventoryProvider);
final lowStockProducts = await inventoryService.getLowStockProducts();

for (final product in lowStockProducts) {
  print('${product.productName}: ${product.currentQuantity} (needs ${product.stockDeficit})');
}
```

### Viewing Stock History

```dart
final inventoryService = ref.read(apiInventoryProvider);
final movements = await inventoryService.getStockMovements(productId);

for (final movement in movements) {
  print('${movement.isAddition ? "Added" : "Removed"} ${movement.quantityChange.abs()} units');
  print('Reason: ${movement.reason}');
  print('Date: ${movement.createdAt}');
}
```

## 🔄 Migration from Hive to API

If you want to completely migrate from Hive to API:

1. **Update Main Navigation** - Replace Hive-based screens with API screens
2. **Data Migration** - Export data from Hive, import to backend
3. **Remove Hive Boxes** - Clean up local storage

### Side-by-Side Comparison

| Feature | Hive Version | API Version |
|---------|-------------|-------------|
| Add Product | `add_product_screen.dart` | `add_product_screen_api.dart` |
| Inventory | `inventory_screen.dart` | `inventory_screen_api.dart` |
| Sales | `sale_screen.dart` | `sale_screen_api.dart` |
| Storage | Local (Hive) | Backend (PostgreSQL) |
| Stock Tracking | Local only | Full history via API |
| Multi-device | No | Yes |

## 🎯 Key Features

### Stock Adjustment with History
Every stock change is tracked:
- Who made the change (optional)
- When it happened
- Reason for the change
- Quantity change (positive or negative)

### Low Stock Alerts
Automatically identifies products below minimum stock level:
```dart
final lowStockProducts = await apiService.getLowStockProducts();
```

### Real-time Stock Validation
The sale screen validates stock in real-time before completing sales:
- Checks current availability
- Prevents overselling
- Shows clear error messages

### SKU Generation
Auto-generate unique SKUs for products:
```dart
final sku = apiService.generateSKU('FOOD'); // Returns: FOOD-1234567890
```

## ⚠️ Error Handling

The API integration includes comprehensive error handling:

### InsufficientStockException
Thrown when trying to remove more stock than available:
```dart
try {
  await inventoryService.adjustStock(
    productId: productId,
    quantityChange: -100,
    reason: 'Sale',
  );
} on InsufficientStockException catch (e) {
  // Show user-friendly message
  print('Not enough stock!');
}
```

### Network Errors
```dart
try {
  await productNotifier.loadProducts();
} catch (e) {
  // Handle network errors
  print('Failed to connect to backend: $e');
}
```

## 📊 API Endpoints Reference

### Products
- `GET /api/products` - Get all products
- `GET /api/products/:id` - Get single product
- `POST /api/products` - Create product
- `PUT /api/products/:id` - Update product
- `DELETE /api/products/:id` - Delete product

### Categories
- `GET /api/categories` - Get all categories
- `POST /api/categories` - Create category
- `PUT /api/categories/:id` - Update category
- `DELETE /api/categories/:id` - Delete category

### Inventory
- `GET /api/inventory/:product_id` - Get inventory details
- `PUT /api/inventory/:product_id` - Update inventory settings
- `POST /api/inventory/adjust` - Adjust stock with tracking
- `GET /api/inventory/low-stock` - Get low stock products
- `GET /api/inventory/movements/:product_id` - Get stock history

## 🧪 Testing

### Test API Connection
```dart
final apiService = InventoryApiService();
final isHealthy = await apiService.healthCheck();
print('Backend status: ${isHealthy ? "Online" : "Offline"}');
```

### Test Product Creation
```dart
final product = await apiService.createProduct(
  CreateProductRequest(
    name: 'Test Product',
    sku: 'TEST-001',
    price: 9.99,
    costPrice: 5.00,
    initialStock: 10,
  ),
);
print('Created product: ${product.name} with ${product.stockQuantity} units');
```

### Test Stock Adjustment
```dart
final inventory = await apiService.adjustStock(
  AdjustStockRequest(
    productId: productId,
    quantityChange: 5,
    reason: 'Test restock',
  ),
);
print('New stock level: ${inventory.quantity}');
```

## 🔧 Configuration Options

### Change Base URL for Different Environments

```dart
class InventoryApiService {
  static const String baseUrl = _getBaseUrl();

  static String _getBaseUrl() {
    // You can use environment variables or build flavors
    const environment = String.fromEnvironment('ENV', defaultValue: 'dev');

    switch (environment) {
      case 'prod':
        return 'https://api.yourapp.com/api';
      case 'staging':
        return 'https://staging-api.yourapp.com/api';
      default:
        return 'http://10.0.2.2:3000/api';
    }
  }
}
```

### Timeout Configuration

```dart
final response = await http.get(uri).timeout(
  const Duration(seconds: 30),
  onTimeout: () {
    throw Exception('Request timeout');
  },
);
```

## 📝 Important Notes

1. **Base URL**: Always update the base URL based on your environment
2. **Stock Validation**: All sales validate stock availability before completing
3. **Transaction Tracking**: Transactions are still stored locally (can be moved to API)
4. **Error Messages**: User-friendly error messages are shown for all API failures
5. **Loading States**: All screens show loading indicators during API calls
6. **Refresh**: Inventory screen has a refresh button to reload data

## 🚨 Troubleshooting

### Cannot Connect to Backend
- Check if backend is running on correct port
- Verify base URL is correct for your device type
- For physical devices, ensure device and computer are on same network
- Check firewall settings

### Products Not Loading
- Check backend logs for errors
- Verify API endpoints are working: `curl http://localhost:3000/api/products`
- Check for CORS issues if using web

### Stock Adjustment Failing
- Verify product ID exists
- Check stock quantity is sufficient for removal
- Review backend logs for detailed error messages

## 📖 Next Steps

1. Test all screens with your backend
2. Migrate existing Hive data to backend (if needed)
3. Set up proper error logging
4. Add authentication if required
5. Configure production base URL
6. Test on physical devices

## 💡 Tips

- Use the API screens during development to ensure everything works
- Keep both Hive and API versions during migration for fallback
- Monitor backend logs while testing
- Use the stock movement history to debug inventory issues
- Set up low stock alerts for critical products

---

**Need Help?** Check the API documentation in your provided document or review the backend logs for detailed error messages.
