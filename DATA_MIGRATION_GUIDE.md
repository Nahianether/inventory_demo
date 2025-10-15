# Data Migration Guide

## How to Upload Your Local Data to the Server

This guide will help you migrate your existing Hive data (products, categories) to the backend server so you can use them in your API-based POS system.

---

## Quick Start

### Step 1: Ensure Backend is Running

Make sure your backend server is running:

```bash
# Check if backend is running
curl http://localhost:3000/health
# Should return: OK
```

### Step 2: Configure Base URL

Make sure the base URL in `lib/services/inventory_api_service.dart` is correct for your device:

```dart
// For Android Emulator
static const String baseUrl = 'http://10.0.2.2:3000/api';

// For iOS Simulator
static const String baseUrl = 'http://localhost:3000/api';

// For Physical Device
static const String baseUrl = 'http://192.168.1.XXX:3000/api';
```

### Step 3: Add Migration Screen to Your App

Add a navigation route to the migration screen in your `main.dart`:

```dart
import 'screens/data_migration_screen.dart';

// In your routes
'/migration': (context) => const DataMigrationScreen(),
```

Or navigate to it directly from anywhere:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DataMigrationScreen(),
  ),
);
```

### Step 4: Run the Migration

1. Open the app
2. Navigate to the Data Migration screen
3. Check the connection status (should show "Connected")
4. Review the local data summary (categories and products count)
5. Click "Start Migration"
6. Wait for the migration to complete
7. Check the results

---

## Using the Migration Screen

### What You'll See

1. **Connection Status Card**
   - Green dot = Connected to backend
   - Red dot = Not connected
   - Orange dot = Checking connection

2. **Local Data Summary Card**
   - Shows how many categories you have
   - Shows how many products you have
   - Shows how many transactions you have (not migrated)

3. **Migration Button**
   - Click to start the migration process
   - Will ask for confirmation before starting

4. **Progress Card** (During/After Migration)
   - Shows real-time progress
   - Shows how many items were migrated
   - Shows any errors that occurred

### Migration Process

When you click "Start Migration", it will:

1. **Migrate Categories First**
   - Uploads all your categories to the server
   - Maps local category names to server category IDs

2. **Migrate Products**
   - Uploads all your products with their stock quantities
   - Generates SKUs automatically if needed
   - Links products to their categories

3. **Show Results**
   - Displays success/failure counts
   - Shows detailed error messages if any failed

---

## Programmatic Migration (Advanced)

If you want to trigger migration from code:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utils/data_migration.dart';
import 'providers/api_inventory_provider.dart';

Future<void> migrateData(WidgetRef ref) async {
  final apiService = ref.read(apiServiceProvider);
  final migration = DataMigration(apiService);

  // Check connection first
  final isConnected = await migration.checkBackendConnection();
  if (!isConnected) {
    print('Backend is not connected');
    return;
  }

  // Start migration
  final result = await migration.migrateAll(
    onProgress: (message) {
      print('Progress: $message');
    },
  );

  // Check results
  print('Categories migrated: ${result.categoriesMigrated}');
  print('Products migrated: ${result.productsMigrated}');
  print('Total failed: ${result.totalFailed}');

  if (result.hasErrors) {
    for (final error in result.errors) {
      print('Error: $error');
    }
  }

  // Refresh API data
  await ref.read(apiProductProvider.notifier).loadProducts();
  await ref.read(apiCategoryProvider.notifier).loadCategories();
}
```

---

## Migrate Only Categories or Products

### Migrate Only Categories

```dart
final result = await migration.migrateCategories(
  onProgress: (message) => print(message),
);
```

### Migrate Only Products

```dart
// Note: Make sure categories are already in the backend
final result = await migration.migrateProducts(
  onProgress: (message) => print(message),
);
```

---

## Important Notes

### ⚠️ Duplicates Warning

**The migration does NOT check for duplicates!**

If you run the migration multiple times, it will create duplicate entries in the backend. Only run the migration once, or clean up the backend database first.

### ✅ What Gets Migrated

- ✅ Categories (name and description)
- ✅ Products (name, description, prices, stock)
- ❌ Transactions (not migrated - can be added later if needed)
- ❌ Account balances (not migrated)

### 📝 SKU Generation

The migration automatically generates SKUs for products that don't have them:

- Format: `PREFIX-TIMESTAMP-INDEX`
- Example: `BUR-1234567890-0`
- Prefix is taken from first 3 letters of product name

### 🔗 Category Mapping

The migration creates a mapping between local category names and server category IDs to ensure products are linked correctly.

---

## Troubleshooting

### "Cannot connect to backend server"

**Solution:**
1. Make sure backend is running
2. Check base URL is correct for your device
3. For physical devices, ensure device and computer are on same network
4. Check firewall settings

### "Migration failed with errors"

**Solution:**
1. Check the error details in the expansion panel
2. Common errors:
   - Duplicate SKU: Product with same SKU already exists
   - Missing category: Category reference is invalid
   - Network timeout: Backend took too long to respond

### Products have no stock after migration

**Solution:**
The `initial_stock` parameter is sent during product creation. Check:
1. Backend logs to see if stock was received
2. Product creation endpoint is handling `initial_stock` correctly
3. Inventory records are being created automatically

### Categories not showing in products

**Solution:**
1. Make sure categories were migrated first
2. Check category mapping in migration logs
3. Verify category IDs match between local and server

---

## Verification After Migration

After migration completes, verify your data:

### 1. Check Backend API

```bash
# Get all products
curl http://localhost:3000/api/products

# Get all categories
curl http://localhost:3000/api/categories

# Get low stock products
curl http://localhost:3000/api/inventory/low-stock
```

### 2. Check in App

1. Navigate to the Inventory Screen (API version)
2. You should see all your products with stock quantities
3. Check if categories are correct
4. Verify stock quantities match your local data

### 3. Test POS Sale

1. Go to Sale Screen (API version)
2. Select a product
3. Make a test sale
4. Verify stock decreases correctly
5. Check stock movement history

---

## Post-Migration Steps

After successful migration:

1. **Switch to API Screens**
   - Replace Hive screens with API screens in your app
   - Use `ApiDemoHome` or integrate individual API screens

2. **Test All Features**
   - Add new products via API
   - Make sales
   - Restock products
   - Check low stock alerts

3. **Backup Local Data** (Optional)
   - Keep local Hive data as backup
   - Can export to JSON if needed

4. **Clean Up** (Optional)
   - Once verified, you can clear local Hive boxes if desired
   - Or keep both systems running in parallel

---

## Example: Adding to Home Screen

Add a migration button to your home screen:

```dart
ElevatedButton.icon(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DataMigrationScreen(),
      ),
    );
  },
  icon: const Icon(Icons.cloud_upload),
  label: const Text('Migrate Data to Server'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.orange,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  ),
)
```

---

## Migration Statistics

After migration, you'll see:

- **Categories Migrated**: Number of categories successfully uploaded
- **Products Migrated**: Number of products successfully uploaded
- **Failed**: Number of items that failed to upload
- **Errors**: Detailed error messages for failed items

Example successful result:
```
Categories Migrated: 5
Products Migrated: 23
Failed: 0
✓ Migration completed successfully!
```

Example with errors:
```
Categories Migrated: 5
Products Migrated: 20
Failed: 3
⚠ Migration completed with errors

Errors:
- Failed to migrate product "Burger": Duplicate SKU
- Failed to migrate product "Pizza": Network timeout
- Failed to migrate product "Fries": Invalid category ID
```

---

## Need Help?

If you encounter issues:

1. Check backend logs for detailed error messages
2. Verify API endpoints are working with curl
3. Test connection with the health check
4. Review migration errors in the app
5. Check network connectivity between device and server

---

**Important:** Always backup your local data before migration and verify the results after migration completes!
