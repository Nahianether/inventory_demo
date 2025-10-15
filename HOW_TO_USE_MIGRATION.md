# How to Use Data Migration - Quick Guide

## 🚀 Fastest Way to Migrate Your Data

### Method 1: Add to Existing Navigation (Recommended)

Update your `main.dart` to add the migration screen:

```dart
import 'screens/data_migration_screen.dart';

// Add this route to your routes map
'/migration': (context) => const DataMigrationScreen(),
```

Then navigate to it from anywhere:

```dart
Navigator.pushNamed(context, '/migration');
```

### Method 2: Add a Button to Home Screen

Add this button to your home screen:

```dart
import 'package:flutter/material.dart';
import 'screens/data_migration_screen.dart';

// Add this button somewhere in your home screen
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
  label: const Text('Upload Data to Server'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.orange,
  ),
)
```

### Method 3: Temporary Test (Quick & Easy)

For a quick test, temporarily replace your home screen in `main.dart`:

```dart
import 'screens/data_migration_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Management',
      theme: ThemeData(useMaterial3: true),
      home: const DataMigrationScreen(), // ← Temporary change
    );
  }
}
```

**Remember to change it back after migration!**

---

## 📝 Step-by-Step Migration Process

### Before You Start

1. ✅ Make sure your backend server is running
2. ✅ Update the base URL in `lib/services/inventory_api_service.dart`
3. ✅ Have your app open with existing Hive data

### The Migration Steps

1. **Open the Migration Screen**
   - Use one of the methods above

2. **Check Connection**
   - You should see a green dot and "Connected to backend server"
   - If red, check your backend and base URL

3. **Review Your Data**
   - The screen shows:
     - How many categories you have
     - How many products you have
     - How many transactions (won't be migrated)

4. **Click "Start Migration"**
   - A confirmation dialog will appear
   - Review the summary
   - Click "Start Migration" to proceed

5. **Wait for Completion**
   - You'll see progress messages
   - Migration happens in this order:
     1. Categories first
     2. Then products

6. **Check Results**
   - Green checkmark = Success!
   - Orange warning = Completed with some errors
   - Review the detailed results

7. **Verify in POS**
   - Navigate to API screens to see your data
   - Try the Inventory Screen (API version)
   - Your products should be there with stock!

---

## 🎯 After Migration

### Switch to API Screens

Now that your data is on the server, use the API screens:

```dart
// Use these screens instead of Hive versions
import 'screens/add_product_screen_api.dart';
import 'screens/sale_screen_api.dart';
import 'screens/inventory_screen_api.dart';

// Or use the complete demo
import 'screens/api_demo_home.dart';
```

### Quick Test in API Demo

To quickly test your migrated data:

```dart
// Temporarily change your home in main.dart
import 'screens/api_demo_home.dart';

home: const ApiDemoHome(), // ← Use this to test API screens
```

The ApiDemoHome includes:
- ✅ Inventory screen with all your products
- ✅ Add product screen
- ✅ Sale screen (POS)
- ✅ Low stock alerts
- ✅ Connection status indicator

---

## ⚠️ Important Warnings

### Don't Run Migration Twice!

**The migration does NOT check for duplicates.**

If you run it again, you'll get duplicate products and categories in your database.

**If you need to re-migrate:**
1. Clear your backend database first
2. Or manually delete the duplicate entries

### Transactions Are Not Migrated

Only products and categories are migrated. Your transaction history stays local.

If you need transactions migrated, that would require a separate migration tool.

---

## 🐛 Troubleshooting

### "Cannot connect to backend server"

**Fix:**
1. Start your backend: `npm start` or `node server.js`
2. Check it's running: `curl http://localhost:3000/health`
3. Update base URL for your device type (see below)

### Base URL by Device Type

```dart
// Android Emulator
static const String baseUrl = 'http://10.0.2.2:3000/api';

// iOS Simulator
static const String baseUrl = 'http://localhost:3000/api';

// Physical Device (Windows)
static const String baseUrl = 'http://192.168.1.XXX:3000/api';

// Physical Device (Mac)
static const String baseUrl = 'http://YOUR_MAC_IP:3000/api';
```

To find your IP:
- **Windows**: `ipconfig` (look for IPv4 Address)
- **Mac**: `ifconfig` (look for inet under en0)
- **Linux**: `ip addr` (look for inet)

### Migration Shows Errors

Check the "View Errors" expansion:
- **Duplicate SKU**: Product already exists with that SKU
- **Invalid category**: Category reference issue
- **Network timeout**: Backend slow/unresponsive

**Fix:**
- For duplicate SKU: Backend already has the product
- For invalid category: Migrate categories first
- For timeout: Check backend performance

### Products Don't Show Stock After Migration

**Verify:**
1. Backend received the stock: Check backend logs
2. API response includes stock: `curl http://localhost:3000/api/products`
3. Inventory endpoint works: `curl http://localhost:3000/api/inventory/PRODUCT_ID`

---

## ✅ Verification Checklist

After migration, verify:

- [ ] Categories appear in backend: `curl http://localhost:3000/api/categories`
- [ ] Products appear in backend: `curl http://localhost:3000/api/products`
- [ ] Products have correct stock quantities
- [ ] Products are linked to correct categories
- [ ] Inventory screen (API) shows all products
- [ ] Can make a sale and stock decreases
- [ ] Can restock a product and stock increases

---

## 🎉 Success!

Once migration is complete and verified:

1. Your data is now on the server
2. You can use API screens for POS
3. Multiple devices can access the same data
4. Stock is tracked with history
5. Low stock alerts work

**Next Steps:**
- Start using the API-based POS screens
- Test sales and inventory management
- Set up low stock alerts
- Enjoy your cloud-based inventory system!

---

## Quick Reference Commands

```bash
# Start backend
cd backend-directory
npm start

# Check backend health
curl http://localhost:3000/health

# View migrated products
curl http://localhost:3000/api/products

# View migrated categories
curl http://localhost:3000/api/categories

# Check a product's inventory
curl http://localhost:3000/api/inventory/PRODUCT_ID
```

Need more help? See `DATA_MIGRATION_GUIDE.md` for detailed documentation.
