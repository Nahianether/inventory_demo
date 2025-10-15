# Quick Offline-First Setup (5 Minutes!)

## ✨ Get Offline Support in 3 Steps

Your app will work offline and sync when ready!

---

## Step 1: Generate Hive Adapter (1 min)

Run this command:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates `sync_operation.g.dart`.

---

## Step 2: Register Adapter in main.dart (1 min)

Add this import at the top of `lib/main.dart`:

```dart
import 'models/sync_operation.dart';
```

Then in your `main()` function, add the adapter registration:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Register all adapters
  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(AccountAdapter());
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(SyncOperationAdapter()); // ← ADD THIS LINE

  runApp(const ProviderScope(child: MyApp()));
}
```

---

## Step 3: Add Sync Button (1 min)

Add the sync button to any screen.

**Option A: Add to Home Screen** (recommended)

```dart
import 'widgets/sync_button.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: YourContent(),
      floatingActionButton: SyncButton(), // ← ADD THIS
    );
  }
}
```

**Option B: Add to App Layout** (shows on all screens)

```dart
// In your app_layout.dart
import 'widgets/sync_button.dart';

Widget build(BuildContext context) {
  return Scaffold(
    // ... your existing code
    floatingActionButton: SyncButton(), // ← ADD THIS
  );
}
```

---

## 🎉 Done! Test It

### Test Offline Mode

1. **Run your app**
2. **Stop your backend server** (or turn off internet)
3. **Add a product** → It works! (saved to Hive)
4. **Make a sale** → Stock decreases! (in Hive)
5. **See sync button appear** → Shows "Sync (2)"

### Test Sync

1. **Start your backend server**
2. **Click the sync button**
3. **Wait for sync** → "Syncing..."
4. **See result** → "Total: 2, Synced: 2" ✅
5. **Check server** → Your data is there!

---

## 📊 What You Get

✅ **App works offline** - No internet? No problem!
✅ **Data saved locally** - Everything in Hive immediately
✅ **Auto-queue for sync** - All changes tracked
✅ **Manual sync button** - Sync when ready
✅ **Shows pending count** - "Sync (5)" badge
✅ **No data loss** - Ever!

---

## 🔧 How It Works

```
Offline:
User adds product → Saves to Hive → Queues for sync → Button shows "Sync (1)"

Online + Sync:
User clicks sync → Uploads to server → Marks complete → Button disappears
```

---

## 🎯 Quick Examples

### Add Sync Button to POS Screen

```dart
import 'widgets/sync_button.dart';

class SaleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('POS')),
      body: SaleForm(),
      floatingActionButton: SyncButton(), // ← One line!
    );
  }
}
```

### Show Connection Status

```dart
FutureBuilder<bool>(
  future: InventoryApiService().healthCheck(),
  builder: (context, snapshot) {
    final isOnline = snapshot.data ?? false;
    return Chip(
      avatar: Icon(
        isOnline ? Icons.cloud_done : Icons.cloud_off,
        color: isOnline ? Colors.green : Colors.red,
      ),
      label: Text(isOnline ? 'Online' : 'Offline'),
    );
  },
)
```

---

## 🚨 Important Notes

1. **Always generate adapter first** - Run build_runner before using
2. **Backend URL must be correct** - Check `inventory_api_service.dart`
3. **Sync manually when ready** - Button appears when needed
4. **Data is safe offline** - Everything in Hive first

---

## 🐛 Troubleshooting

### "SyncOperationAdapter not found"
**Fix:** Run `flutter pub run build_runner build`

### Sync button doesn't show
**Normal!** Button only appears when there are pending operations

### Sync fails
**Check:**
1. Is backend running? → `curl http://localhost:3000/health`
2. Is base URL correct for your device?
3. Are you connected to network?

---

## 📚 Want More?

- **Full Guide**: See `OFFLINE_SYNC_GUIDE.md`
- **Advanced Features**: Auto-sync, retry logic, etc.
- **API Integration**: See `API_INTEGRATION_README.md`

---

**That's it! 🎉**

Your app now works offline and syncs when ready. No more "No Internet" errors!
