package com.germainleignel.diet

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import android.os.Process
import android.util.Log
import java.util.Calendar
import kotlin.math.min

data class AppUsageInfo(
    val packageName: String,
    val appName: String,
    val durationMs: Long
)

data class DailyScreenTime(
    val date: String,
    val totalMs: Long,
    val pickups: Int,
    val apps: List<AppUsageInfo>
)

class ScreenTimeWorker(private val context: Context) {

    companion object {
        private const val TAG = "ScreenTimeWorker"
        private const val STATE_LOOKBACK_MS = 24 * 60 * 60 * 1000L
    }

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
        val endTime = Calendar.getInstance().apply {
            timeInMillis = startTime
            add(Calendar.DAY_OF_MONTH, 1)
        }.timeInMillis
        val effectiveEndTime = min(endTime, System.currentTimeMillis())

        val usageStatsManager =
            context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        val usageByPackage = calculateForegroundUsage(
            usageStatsManager = usageStatsManager,
            startTime = startTime,
            endTime = effectiveEndTime
        )
        val apps = usageByPackage.entries
            .filter { it.value > 0 }
            .map { (packageName, durationMs) ->
                AppUsageInfo(
                    packageName = packageName,
                    appName = resolveAppName(packageName),
                    durationMs = durationMs
                )
            }
            .sortedByDescending { it.durationMs }
        val totalMs = apps.sumOf { it.durationMs }

        return DailyScreenTime(
            date = String.format("%04d-%02d-%02d", year, month, day),
            totalMs = totalMs,
            pickups = countPickups(usageStatsManager, startTime, effectiveEndTime),
            apps = apps
        )
    }

    fun getTodayScreenTime(): DailyScreenTime? {
        val now = Calendar.getInstance()
        return getScreenTimeForDate(
            now.get(Calendar.YEAR),
            now.get(Calendar.MONTH) + 1,
            now.get(Calendar.DAY_OF_MONTH)
        )
    }

    private fun countPickups(
        usageStatsManager: UsageStatsManager,
        startTime: Long,
        endTime: Long
    ): Int {
        var pickups = 0
        val events = usageStatsManager.queryEvents(startTime, endTime)

        while (events.hasNextEvent()) {
            val event = UsageEvents.Event()
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.SCREEN_INTERACTIVE) {
                pickups++
            }
        }

        return pickups
    }

    private fun calculateForegroundUsage(
        usageStatsManager: UsageStatsManager,
        startTime: Long,
        endTime: Long
    ): Map<String, Long> {
        val totals = mutableMapOf<String, Long>()
        val initialState = resolveStateAtStart(usageStatsManager, startTime)
        val events = usageStatsManager.queryEvents(startTime, endTime)
        var currentPackage: String? = initialState.currentPackage
        var currentStartTime: Long? =
            if (initialState.currentPackage != null && initialState.screenInteractive) {
                startTime
            } else {
                null
            }
        var screenInteractive = initialState.screenInteractive

        fun closeCurrent(atTime: Long) {
            val packageName = currentPackage ?: return
            val startedAt = currentStartTime ?: return
            val duration = atTime - startedAt
            if (duration > 0) {
                totals[packageName] = (totals[packageName] ?: 0L) + duration
            }
            currentPackage = null
            currentStartTime = null
        }

        while (events.hasNextEvent()) {
            val event = UsageEvents.Event()
            events.getNextEvent(event)
            val packageName = event.packageName
            val timestamp = event.timeStamp

            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED,
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    if (!screenInteractive || packageName.isNullOrEmpty()) {
                        continue
                    }

                    if (currentPackage != packageName) {
                        closeCurrent(timestamp)
                        currentPackage = packageName
                        currentStartTime = timestamp
                    }
                }

                UsageEvents.Event.ACTIVITY_PAUSED,
                UsageEvents.Event.ACTIVITY_STOPPED,
                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    if (currentPackage == packageName) {
                        closeCurrent(timestamp)
                    }
                }

                UsageEvents.Event.SCREEN_NON_INTERACTIVE,
                UsageEvents.Event.KEYGUARD_SHOWN,
                UsageEvents.Event.DEVICE_SHUTDOWN -> {
                    closeCurrent(timestamp)
                    screenInteractive = false
                }

                UsageEvents.Event.SCREEN_INTERACTIVE,
                UsageEvents.Event.KEYGUARD_HIDDEN,
                UsageEvents.Event.DEVICE_STARTUP -> {
                    screenInteractive = true
                }
            }
        }

        closeCurrent(endTime)
        return totals
    }

    private fun resolveStateAtStart(
        usageStatsManager: UsageStatsManager,
        startTime: Long
    ): UsageState {
        val lookbackStart = maxOf(0L, startTime - STATE_LOOKBACK_MS)
        val events = usageStatsManager.queryEvents(lookbackStart, startTime)
        var currentPackage: String? = null
        var screenInteractive = true

        while (events.hasNextEvent()) {
            val event = UsageEvents.Event()
            events.getNextEvent(event)
            val packageName = event.packageName

            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED,
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    if (screenInteractive && !packageName.isNullOrEmpty()) {
                        currentPackage = packageName
                    }
                }

                UsageEvents.Event.ACTIVITY_PAUSED,
                UsageEvents.Event.ACTIVITY_STOPPED,
                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    if (currentPackage == packageName) {
                        currentPackage = null
                    }
                }

                UsageEvents.Event.SCREEN_NON_INTERACTIVE,
                UsageEvents.Event.KEYGUARD_SHOWN,
                UsageEvents.Event.DEVICE_SHUTDOWN -> {
                    currentPackage = null
                    screenInteractive = false
                }

                UsageEvents.Event.SCREEN_INTERACTIVE,
                UsageEvents.Event.KEYGUARD_HIDDEN,
                UsageEvents.Event.DEVICE_STARTUP -> {
                    screenInteractive = true
                }
            }
        }

        return UsageState(
            currentPackage = currentPackage,
            screenInteractive = screenInteractive
        )
    }

    private fun resolveAppName(packageName: String): String {
        return try {
            val appInfo = context.packageManager.getApplicationInfo(packageName, 0)
            context.packageManager.getApplicationLabel(appInfo).toString()
        } catch (_: Exception) {
            packageName
        }
    }

    private data class UsageState(
        val currentPackage: String?,
        val screenInteractive: Boolean
    )

    fun hasUsageStatsPermission(): Boolean {
        val appOpsManager =
            context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager

        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOpsManager.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOpsManager.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        }

        return mode == AppOpsManager.MODE_ALLOWED
    }
}

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
