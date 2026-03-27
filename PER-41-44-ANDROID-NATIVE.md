# PER-41 to PER-44: Android Screen Time Native Implementation

## Overview

The Flutter app needs to read Android's screen time data (app usage stats). This requires native Kotlin code because Flutter has no direct access to `UsageStatsManager`. The implementation follows a **Method Channel** pattern:

```
Flutter (Dart) → MethodChannel → Kotlin (native) → UsageStatsManager → Android OS
```

## Project Context

- **Package:** `com.germainleignel.diet`
- **MainActivity path:** `android/app/src/main/kotlin/com/germainleignel/diet/MainActivity.kt`
- **AndroidManifest:** `android/app/src/main/AndroidManifest.xml`
- **Min SDK:** Flutter default (likely 21)
- **Target SDK:** Flutter default

## Existing Code

### Models (already in Flutter)
```dart
// lib/data/models/screen_time.dart
class ScreenTime {
  final int? id, serverId;
  final DateTime date;
  final int totalMs;        // total screen time in milliseconds
  final int? pickups;        // number of phone pickups
  final List<ScreenTimeApp> apps;
}

class ScreenTimeApp {
  final int? id, serverId;
  final int screenTimeId;
  final String packageName;  // e.g. "com.whatsapp"
  final String appName;      // e.g. "WhatsApp"
  final int durationMs;      // time spent in app
}
```

### Repository Interface (already in Flutter)
```dart
// lib/data/repositories/screen_time_repository_interface.dart
abstract class ScreenTimeRepository {
  Future<ScreenTime> saveScreenTime(ScreenTime screenTime);
  Future<ScreenTime?> getScreenTimeForDate(DateTime date);
  Future<void> deleteScreenTime(int id);
  Future<void> saveScreenTimeApps(int screenTimeId, List<ScreenTimeApp> apps);
  Future<List<ScreenTimeApp>> getScreenTimeApps(int screenTimeId);
  // ... more methods
}
```

### Screen Time Screen (already in Flutter)
```dart
// lib/presentation/screens/screen_time_screen.dart
// This screen already exists and displays screen time data.
// It currently shows empty state because no data is being collected.
```

---

## PER-42: Android Permission + Manifest Config

### What to do

1. **Add permission to AndroidManifest.xml** (`android/app/src/main/AndroidManifest.xml`):

```xml
<!-- Add inside <manifest> tag, before <application> -->
<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS"
    tools:ignore="ProtectedPermissions"/>
```

Also add the `tools` namespace to the `<manifest>` tag:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
```

2. **Add intent for usage access settings** (optional, helps with permission flow):

```xml
<!-- Inside <queries> block -->
<intent>
    <action android:name="android.settings.USAGE_ACCESS_SETTINGS"/>
</intent>
```

### Why
`PACKAGE_USAGE_STATS` is a **special permission** — users must grant it manually through system settings. It cannot be requested at runtime like normal permissions. The app needs to direct users to the settings page.

---

## PER-41: Create Native Kotlin ScreenTimeWorker

### What to do

Create `android/app/src/main/kotlin/com/germainleignel/diet/ScreenTimeWorker.kt`:

```kotlin
package com.germainleignel.diet

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.util.Log
import java.util.Calendar

data class AppUsageInfo(
    val packageName: String,
    val appName: String,
    val durationMs: Long
)

data class DailyScreenTime(
    val date: String,           // "2026-03-27"
    val totalMs: Long,
    val pickups: Int,
    val apps: List<AppUsageInfo>
)

class ScreenTimeWorker(private val context: Context) {

    companion object {
        private const val TAG = "ScreenTimeWorker"
    }

    /**
     * Get screen time data for a specific date.
     * Returns null if PACKAGE_USAGE_STATS permission is not granted.
     */
    fun getScreenTimeForDate(year: Int, month: Int, day: Int): DailyScreenTime? {
        if (!hasUsageStatsPermission()) {
            Log.w(TAG, "PACKAGE_USAGE_STATS permission not granted")
            return null
        }

        val calendar = Calendar.getInstance().apply {
            set(year, month - 1, day, 0, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startTime = calendar.timeInMillis
        val endTime = startTime + 24 * 60 * 60 * 1000 // next day

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) 
            as UsageStatsManager

        // Get usage stats
        val usageStats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, startTime, endTime
        )

        // Calculate total time and per-app breakdown
        val apps = mutableListOf<AppUsageInfo>()
        var totalMs = 0L

        for (stat in usageStats) {
            val timeInForeground = stat.totalTimeInForeground
            if (timeInForeground > 0) {
                totalMs += timeInForeground
                val appName = try {
                    val appInfo = context.packageManager.getApplicationInfo(stat.packageName, 0)
                    context.packageManager.getApplicationLabel(appInfo).toString()
                } catch (e: Exception) {
                    stat.packageName
                }
                apps.add(AppUsageInfo(
                    packageName = stat.packageName,
                    appName = appName,
                    durationMs = timeInForeground
                ))
            }
        }

        // Sort apps by duration (descending)
        apps.sortByDescending { it.durationMs }

        // Count pickups using usage events
        val pickups = countPickups(usageStatsManager, startTime, endTime)

        val dateStr = String.format("%04d-%02d-%02d", year, month, day)

        return DailyScreenTime(
            date = dateStr,
            totalMs = totalMs,
            pickups = pickups,
            apps = apps
        )
    }

    /**
     * Get screen time for today.
     */
    fun getTodayScreenTime(): DailyScreenTime? {
        val now = Calendar.getInstance()
        return getScreenTimeForDate(
            now.get(Calendar.YEAR),
            now.get(Calendar.MONTH) + 1,
            now.get(Calendar.DAY_OF_MONTH)
        )
    }

    /**
     * Count phone pickups (screen-on events).
     */
    private fun countPickups(manager: UsageStatsManager, startTime: Long, endTime: Long): Int {
        var pickups = 0
        val events = manager.queryEvents(startTime, endTime)
        while (events.hasNextEvent()) {
            val event = UsageEvents.Event()
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.SCREEN_INTERACTIVE) {
                pickups++
            }
        }
        return pickups
    }

    /**
     * Check if PACKAGE_USAGE_STATS permission is granted.
     */
    fun hasUsageStatsPermission(): Boolean {
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) 
            as UsageStatsManager
        val now = System.currentTimeMillis()
        val stats = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY, now - 1000 * 60, now
        )
        return stats != null && stats.isNotEmpty()
    }
}
```

### Key points
- `UsageStatsManager.queryUsageStats()` returns usage data per package
- `UsageEvents.Event.SCREEN_INTERACTIVE` counts as a "pickup"
- App names are resolved via `PackageManager.getApplicationLabel()`
- `hasUsageStatsPermission()` checks by querying recent stats — if empty, permission not granted

---

## PER-43: Flutter Method Channel Bridge

### What to do

#### 3a. Set up MethodChannel in MainActivity

Update `android/app/src/main/kotlin/com/germainleignel/diet/MainActivity.kt`:

```kotlin
package com.germainleignel.diet

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.germainleignel.diet/screentime"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                val worker = ScreenTimeWorker(this)

                when (call.method) {
                    "hasPermission" -> {
                        result.success(worker.hasUsageStatsPermission())
                    }
                    "requestPermission" -> {
                        try {
                            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("PERMISSION_ERROR", e.message, null)
                        }
                    }
                    "getTodayScreenTime" -> {
                        val data = worker.getTodayScreenTime()
                        if (data != null) {
                            result.success(data.toMap())
                        } else {
                            result.success(null)
                        }
                    }
                    "getScreenTimeForDate" -> {
                        val year = call.argument<Int>("year") ?: 0
                        val month = call.argument<Int>("month") ?: 0
                        val day = call.argument<Int>("day") ?: 0
                        val data = worker.getScreenTimeForDate(year, month, day)
                        if (data != null) {
                            result.success(data.toMap())
                        } else {
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
```

Add a `toMap()` extension to `DailyScreenTime` in the worker file:

```kotlin
// Add to ScreenTimeWorker.kt
fun DailyScreenTime.toMap(): Map<String, Any?> {
    return mapOf(
        "date" to date,
        "totalMs" to totalMs,
        "pickups" to pickups,
        "apps" to apps.map { app ->
            mapOf(
                "packageName" to app.packageName,
                "appName" to app.appName,
                "durationMs" to app.durationMs
            )
        }
    )
}
```

#### 3b. Create Flutter service

Create `lib/data/services/screen_time_service.dart`:

```dart
import 'package:flutter/services.dart';

class ScreenTimeService {
  static const _channel = MethodChannel('com.germainleignel.diet/screentime');
  static ScreenTimeService? _instance;

  factory ScreenTimeService() => _instance ??= ScreenTimeService._();
  ScreenTimeService._();

  /// Check if we have usage stats permission
  Future<bool> hasPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Open system settings to request permission
  Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod<bool>('requestPermission');
    } on PlatformException {
      // Handle error
    }
  }

  /// Get today's screen time data
  Future<Map<String, dynamic>?> getTodayScreenTime() async {
    try {
      final result = await _channel.invokeMethod<Map>('getTodayScreenTime');
      return result?.cast<String, dynamic>();
    } on PlatformException {
      return null;
    }
  }

  /// Get screen time for a specific date
  Future<Map<String, dynamic>?> getScreenTimeForDate({
    required int year,
    required int month,
    required int day,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map>('getScreenTimeForDate', {
        'year': year,
        'month': month,
        'day': day,
      });
      return result?.cast<String, dynamic>();
    } on PlatformException {
      return null;
    }
  }
}
```

#### 3c. Wire into ScreenTimeRepository

Update `lib/data/repositories/local_screen_time_repository.dart` to use `ScreenTimeService` for fetching actual data. Add a method like:

```dart
Future<void> syncFromNative(DateTime date) async {
  final service = ScreenTimeService();
  final hasPermission = await service.hasPermission();
  if (!hasPermission) return;

  final data = await service.getScreenTimeForDate(
    year: date.year,
    month: date.month,
    day: date.day,
  );

  if (data != null) {
    // Parse and save to local DB
    final screenTime = ScreenTime(
      date: date,
      totalMs: data['totalMs'] as int,
      pickups: data['pickups'] as int?,
      apps: (data['apps'] as List).map((app) => ScreenTimeApp(
        packageName: app['packageName'] as String,
        appName: app['appName'] as String,
        durationMs: app['durationMs'] as int,
      )).toList(),
    );
    await saveScreenTime(screenTime);
  }
}
```

---

## PER-44: Screen Time Permission Flow UI

### What to do

The permission flow is already partially stubbed in `lib/presentation/screens/settings_screen.dart` (the screen time toggle). You need to:

1. **When user enables screen time tracking for the first time:**
   - Check `ScreenTimeService().hasPermission()`
   - If not granted, show a dialog explaining why
   - On confirm, call `ScreenTimeService().requestPermission()` which opens system settings
   - When user returns to app, check permission again

2. **Update the settings toggle handler** in `settings_screen.dart`:

```dart
void _onScreenTimeToggle(bool enabled) async {
  if (enabled) {
    final service = ScreenTimeService();
    final hasPermission = await service.hasPermission();
    
    if (!hasPermission) {
      if (!mounted) return;
      final granted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Screen Time Access'),
          content: Text(
            'To track your screen time, v32 needs access to your app usage data. '
            'You\'ll be redirected to system settings to grant this permission.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Open Settings'),
            ),
          ],
        ),
      );
      
      if (granted == true) {
        await service.requestPermission();
        // Check again when user comes back
        // (use WidgetsBindingObserver to detect app resume)
      }
    }
  }
  
  setState(() => _screenTimeEnabled = enabled);
  // Persist preference to shared_prefs or local DB
}
```

3. **Create a reusable permission check widget** (optional but nice):

`lib/presentation/widgets/permission_gate.dart` — a widget that checks permission on app resume and shows a prompt if needed.

---

## Implementation Order

1. **PER-42** first (manifest) — quickest, needed for everything else
2. **PER-41** next (Kotlin worker) — core native logic
3. **PER-43** next (method channel) — bridges Kotlin ↔ Dart
4. **PER-44** last (UI flow) — ties it all together

## Testing

After implementation:
1. Build and run on a real device (emulator may not have usage stats)
2. Go to Settings → enable Screen Time
3. Should redirect to system settings
4. Grant permission, return to app
5. Screen Time screen should show today's data
6. Verify data saves to SQLite and syncs to backend

## Files to Create/Modify

### New files:
- `android/app/src/main/kotlin/com/germainleignel/diet/ScreenTimeWorker.kt`
- `lib/data/services/screen_time_service.dart`
- `lib/presentation/widgets/permission_gate.dart` (optional)

### Modified files:
- `android/app/src/main/AndroidManifest.xml` (add permission)
- `android/app/src/main/kotlin/com/germainleignel/diet/MainActivity.kt` (add MethodChannel)
- `lib/presentation/screens/settings_screen.dart` (permission flow)
- `lib/data/repositories/local_screen_time_repository.dart` (sync from native)

## Reference

- [Android UsageStatsManager docs](https://developer.android.com/reference/android/app/usage/UsageStatsManager)
- [Flutter MethodChannel docs](https://docs.flutter.dev/platform-integration/platform-channels)
- [PACKAGE_USAGE_STATS permission](https://developer.android.com/reference/android/Manifest.permission#PACKAGE_USAGE_STATS)
