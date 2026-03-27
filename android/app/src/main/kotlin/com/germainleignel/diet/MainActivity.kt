package com.germainleignel.diet

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.germainleignel.diet/screentime"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                val worker = ScreenTimeWorker(this)

                when (call.method) {
                    "hasPermission" -> {
                        result.success(worker.hasUsageStatsPermission())
                    }

                    "requestPermission" -> {
                        try {
                            startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("PERMISSION_ERROR", e.message, null)
                        }
                    }

                    "getTodayScreenTime" -> {
                        result.success(worker.getTodayScreenTime()?.toMap())
                    }

                    "getScreenTimeForDate" -> {
                        val year = call.argument<Int>("year")
                        val month = call.argument<Int>("month")
                        val day = call.argument<Int>("day")

                        if (year == null || month == null || day == null) {
                            result.error(
                                "INVALID_ARGS",
                                "year, month, and day are required",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        result.success(worker.getScreenTimeForDate(year, month, day)?.toMap())
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
