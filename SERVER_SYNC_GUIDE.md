# Server Sync Guide

## Overview
Your inventory app uses a **Hive-only architecture** where all operations are performed locally first. Data is synced with the server only when you manually trigger sync operations using the dashboard buttons.

## Architecture

### Offline-First Design
- **All operations save to Hive immediately** (fast and reliable)
- **No automatic API calls** during normal operations
- **Manual sync buttons** to push/pull data when needed
- **Works perfectly offline** - no network delays or errors

### Why This Architecture?
✅ **Faster** - No network delays during operations
✅ **More reliable** - Works even when server is down
✅ **Predictable** - You control when sync happens
✅ **Easier to debug** - Clear separation between local and server operations

## Manual Sync Operations

### Pull from Server
**Button:** Green "Pull from Server" on Dashboard

**What it does:**
- Downloads all products from server
- Downloads all categories from server
- Updates local Hive with server quantities
- **Use this to sync POS sales to inventory app**

**When to use:**
- After making sales on POS
- To get latest inventory quantities
- To sync new products added via POS

### Push to Server
**Button:** Blue "Push to Server" on Dashboard

**What it does:**
- Uploads all local products to server
- Uploads all local categories to server
- Skips items that already exist
- **Use this for initial data migration**

**When to use:**
- First time setup
- After adding many products offline
- To backup local data to server

## How Operations Work

### All Operations (Add/Edit/Delete/Sale/Purchase)
1. **Saved to local Hive immediately** (instant, no delay)
2. **No automatic server sync** (works offline)
3. **UI updates instantly** from Hive
4. **Manually sync when ready** using dashboard buttons

### Sales from Inventory App
1. User selects product and quantity
2. Local inventory updated immediately
3. Transaction recorded locally
4. Account updated locally
5. **Changes stay local until you "Push to Server"**

### Sales from POS System
1. Sale processed on POS
2. Server inventory updated
3. Stock movement recorded
4. **Click "Pull from Server" to get updates in inventory app**

## Best Practices

### For Daily Use:
1. **Morning:** Click "Pull from Server" to get latest inventory from POS
2. **During Day:** Work normally (all operations save to Hive instantly)
3. **After making changes:** Click "Push to Server" to sync with POS
4. **Before closing:** Click "Pull from Server" one more time to get final updates

### Typical Workflow:
```
Start of Day:
1. Pull from Server → Get overnight changes

During Day:
2. Add products, make sales, etc. → All saved locally
3. Push to Server → Share your changes with POS

End of Day:
4. Pull from Server → Get any POS sales you missed
5. Push to Server → Ensure everything is synced
```

### For Offline Work:
1. Work completely offline (everything saved locally)
2. When back online, click "Push to Server" to upload all changes
3. Then click "Pull from Server" to get any remote changes

### Troubleshooting:
- **Inventory doesn't match POS:** Click "Pull from Server"
- **POS doesn't show new products:** Click "Push to Server"
- **Made sales offline:** Click "Push to Server" when online
- **UI not updating after pull:** Check that pull operation completed successfully

## Technical Details

### Local Storage:
- **Location:** `lib/providers/inventory_provider.dart`
- **Method:** All operations write directly to Hive boxes
- **Benefits:** Instant saves, no network latency, works offline

### Manual Sync Service:
- **Location:** `lib/services/data_sync_service.dart`
- **Pull Method:** `pullFromServer()` - Downloads server data and updates Hive
- **Push Method:** `syncAllToServer()` - Uploads all Hive data to server
- **UI Refresh:** After pull, providers automatically reload from Hive

### Sync Button Widget:
- **Location:** `lib/widgets/full_sync_button.dart`
- **Features:**
  - Shows progress during sync
  - Displays detailed sync report
  - Triggers provider refresh after pull
  - Handles errors gracefully

## Network Requirements
- **No network required** for normal operations
- **Internet connection needed** only for Push/Pull operations
- **Server must be running** at `http://localhost:3000` when syncing
- **App works completely offline** - all data stored in Hive locally
