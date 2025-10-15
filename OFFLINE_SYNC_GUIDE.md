# Offline-First with Sync - Complete Guide

## 🎉 What You Got

Your inventory app now works **offline-first**! This means:

✅ **Works WITHOUT internet** - All operations save to Hive immediately
✅ **Auto-queues for sync** - When server is down, operations are queued
✅ **Manual sync button** - Press sync when ready to upload to server
✅ **No data loss** - Everything is safe in local storage
✅ **Seamless experience** - Works the same whether online or offline

---

## 🚀 Quick Start

### Step 1: Register the Sync Operation Adapter

Before using the hybrid system, you need to generate and register the Hive adapter for `SyncOperation`.

**Add this to your `main.dart`:**

```dart
import 'models/sync_operation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(AccountAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(SyncOperationAdapter()); // ← Add this

  runApp(const ProviderScope(child: MyApp()));
}
```

### Step 2: Generate Hive Adapter

Run the build runner to generate the adapter:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will create `sync_operation.g.dart`.

### Step 3: Add Sync Button to Your Screen

**Option 1: Add to any screen (easiest)**

```dart
import 'package:flutter/material.dart';
import 'widgets/sync_button.dart';

class YourScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Screen')),
      body: YourContent(),
      floatingActionButton: SyncButton(), // ← Add this
    );
  }
}
```

**Option 2: Add to App Layout (shows everywhere)**

```dart
// In your app_layout.dart or main screen
floatingActionButton: SyncButton(
  onSyncComplete: () {
    // Optional: Refresh data after sync
    print('Sync completed!');
  },
),
```

---

## 📱 How It Works

### When You're ONLINE (Server Running)

1. You add/update/delete a product
2. ✅ Saves to Hive **immediately** (fast!)
3. ✅ Queues operation for sync
4. 🔄 **Tries** to sync to server (fire and forget)
5. If successful: operation marked as completed
6. If failed: stays in queue for manual sync

### When You're OFFLINE (Server Stopped/No Internet)

1. You add/update/delete a product
2. ✅ Saves to Hive **immediately** (still works!)
3. ✅ Queues operation for sync
4. ⏸️ Server sync fails silently
5. 📝 Operation stays pending in queue
6. 🔵 **Sync button appears** showing pending count
7. When online: **Press sync button** to upload

---

## 🔄 Using the Sync Button

### What the Sync Button Shows

**No pending operations:**
- Button is hidden

**Has pending operations:**
- Shows "Sync (3)" with orange color
- Red badge shows pending count
- Click to sync all pending operations

**During sync:**
- Shows "Syncing..." with loading spinner
- Button is disabled

### How to Sync

1. **Start your backend server** (if not running)
2. **Click the Sync button**
3. Wait for sync to complete
4. See results:
   - ✅ Green checkmark = All synced!
   - ⚠️ Orange warning = Some failed
   - See detailed errors if any failed

### Sync Result Dialog

Shows you:
- Total operations synced
- How many succeeded (green)
- How many failed (red)
- Detailed error messages

Example:
```
Total: 5
Synced: 4
Failed: 1

Errors:
• Failed adjust_stock: Insufficient stock
```

---

## 🛠️ What Operations Are Tracked

All these operations work offline and sync later:

- ✅ **Create Product** - Add new products
- ✅ **Update Product** - Edit existing products
- ✅ **Delete Product** - Remove products
- ✅ **Adjust Stock** - Add/remove stock (sales, restocking)
- ✅ **Create Category** - Add new categories

---

## 📊 Example Workflows

### Scenario 1: Working Offline

```
1. Server is down/no internet
2. You add 3 products ✓ (saved to Hive)
3. You make 5 sales ✓ (stock adjusted in Hive)
4. Sync button shows "Sync (8)"
5. Later, server comes back online
6. Click sync button
7. All 8 operations upload to server
8. ✅ Server now has your data!
```

### Scenario 2: Intermittent Connection

```
1. You add a product
2. Server is online → Syncs immediately ✓
3. Server goes down
4. You make 2 sales (queued)
5. You restock a product (queued)
6. Sync button shows "Sync (3)"
7. Server comes back
8. Click sync → All caught up!
```

### Scenario 3: Multiple Devices (Future)

```
Device A (Offline):
1. Adds products to Hive
2. Queues for sync

Device B (Online):
1. Already synced with server

Later:
- Device A comes online
- Clicks sync
- Server receives Device A's data
- Device B can now see Device A's products
```

---

## 🎯 Technical Details

### Data Flow

```
User Action
    ↓
Save to Hive (IMMEDIATE)
    ↓
Queue Operation for Sync
    ↓
Try Sync if Online (Fire & Forget)
    ↓
Success? → Mark Completed
Failed? → Stay in Queue
    ↓
Manual Sync Button → Retry All Pending
```

### Sync Queue

Operations are stored in Hive box: `sync_queue`

Each operation has:
- **ID**: Unique identifier
- **Type**: create_product, update_product, etc.
- **Data**: The operation payload
- **Status**: pending, syncing, failed, completed
- **Error Message**: If failed
- **Retry Count**: How many times attempted

### Conflict Resolution

**What happens if local and server data conflict?**

Current behavior:
- Local changes **always win** during sync
- Server data is updated with local data
- No merging logic (simple override)

Future enhancement:
- Can add timestamp-based conflict resolution
- Can add manual conflict resolution UI

---

## ⚙️ Configuration & Customization

### Change Sync Button Appearance

```dart
// Custom sync button
floatingActionButton: SyncButton(
  onSyncComplete: () {
    // Refresh your data
    ref.read(productProvider.notifier).loadProducts();
  },
),
```

### Programmatic Sync

Sync from code without button:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/sync_service.dart';
import 'services/inventory_api_service.dart';

Future<void> syncNow() async {
  final apiService = InventoryApiService();
  final syncService = SyncService(apiService);

  final result = await syncService.syncAll(
    onProgress: (message) => print(message),
  );

  print('Synced: ${result.synced}');
  print('Failed: ${result.failed}');
}
```

### Check Pending Count

```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'models/sync_operation.dart';

Future<int> getPendingCount() async {
  final syncBox = await Hive.openBox<SyncOperation>('sync_queue');
  return syncBox.values
      .where((op) => op.isPending || op.isFailed)
      .length;
}
```

### Clear Completed Operations

```dart
final syncService = SyncService(InventoryApiService());
await syncService.clearCompleted();
```

---

## 🐛 Troubleshooting

### Sync Button Doesn't Appear

**Cause:** No pending operations
**Solution:** This is normal! Button only shows when needed

### Sync Fails with "Server not reachable"

**Cause:** Backend is down or network issue
**Solution:**
1. Start your backend server
2. Check base URL in `inventory_api_service.dart`
3. Verify network connection
4. Try sync again

### Some Operations Fail to Sync

**Cause:** Server validation errors
**Solutions:**
- Check error messages in sync result
- Common issues:
  - Duplicate SKU (product already exists)
  - Invalid category (category not on server)
  - Insufficient stock (trying to remove more than available)

### Sync Completed but Data Not on Server

**Verify:**
```bash
# Check if products are on server
curl http://localhost:3000/api/products

# Check specific product
curl http://localhost:3000/api/products/PRODUCT_ID
```

If not there:
1. Check sync result for errors
2. Check backend logs
3. Verify operations weren't marked as failed

---

## 🎨 UI Indicators

### Connection Status

You can add a connection indicator:

```dart
FutureBuilder<bool>(
  future: InventoryApiService().healthCheck(),
  builder: (context, snapshot) {
    final isOnline = snapshot.data ?? false;
    return Row(
      children: [
        Icon(
          isOnline ? Icons.cloud_done : Icons.cloud_off,
          color: isOnline ? Colors.green : Colors.grey,
        ),
        Text(isOnline ? 'Online' : 'Offline'),
      ],
    );
  },
)
```

### Sync Status Badge

```dart
// Show pending count in app bar
StreamBuilder<BoxEvent>(
  stream: Hive.box<SyncOperation>('sync_queue').watch(),
  builder: (context, snapshot) {
    final pending = getPendingCount();
    return Badge(
      label: Text('$pending'),
      isLabelVisible: pending > 0,
      child: Icon(Icons.cloud_upload),
    );
  },
)
```

---

## 📝 Best Practices

### 1. **Always Work Offline-First**
- Don't check connection before operations
- Let Hive handle it immediately
- Sync will happen automatically or manually

### 2. **Inform Users**
- Show connection status in UI
- Display pending sync count
- Notify when sync completes

### 3. **Sync Regularly**
- When app starts (if online)
- After important operations
- Before closing app
- On network reconnection

### 4. **Handle Failures Gracefully**
- Show clear error messages
- Allow retry
- Don't lose user data

### 5. **Clean Up**
- Periodically clear completed operations
- Monitor sync queue size
- Delete old completed syncs

---

## 🚀 Advanced Features

### Auto-Sync on Network Change

```dart
// Listen to connectivity changes
import 'package:connectivity_plus/connectivity_plus.dart';

Connectivity().onConnectivityChanged.listen((result) {
  if (result != ConnectivityResult.none) {
    // Network available, try sync
    syncNow();
  }
});
```

### Periodic Auto-Sync

```dart
import 'dart:async';

// Sync every 5 minutes if online
Timer.periodic(Duration(minutes: 5), (timer) {
  syncNow();
});
```

### Retry Failed Operations

```dart
final syncService = SyncService(InventoryApiService());
final result = await syncService.retryFailed(
  onProgress: (msg) => print(msg),
);
```

---

## ✅ Testing Checklist

Test these scenarios:

- [ ] Add product while offline → Shows in app
- [ ] Make sale while offline → Stock decreases
- [ ] Sync button appears showing count
- [ ] Click sync when online → Success
- [ ] Data appears on server
- [ ] Add product while online → Auto-syncs
- [ ] Turn off server mid-operation → Still works
- [ ] Multiple operations queue correctly
- [ ] Failed operations show errors
- [ ] Retry failed operations works

---

## 🎉 Summary

You now have a robust offline-first inventory system that:

✅ Works 100% offline
✅ Automatically queues changes
✅ Shows pending sync count
✅ Manual sync with one button
✅ No data loss ever
✅ Seamless user experience

**Your users can now:**
- Work without internet
- Make sales offline
- Add products offline
- Sync when ready
- Never lose data

**Perfect for:**
- Areas with poor internet
- Temporary network outages
- Mobile POS systems
- Reliable offline operation

---

Need help? Check the code examples above or review the service files:
- `lib/services/hybrid_inventory_service.dart`
- `lib/services/sync_service.dart`
- `lib/widgets/sync_button.dart`
