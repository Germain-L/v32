import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'data/services/sync_config.dart';
import 'data/services/sync_service.dart';
import 'data/services/sqlite_sync_queue.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sync service if enabled
  if (SyncConfig.enabled && SyncConfig.hasCredentials) {
    debugPrint('[MAIN] Initializing sync service: ${SyncConfig.baseUrl}');
    try {
      SyncService.init(
        baseUrl: SyncConfig.baseUrl,
        apiKey: SyncConfig.apiKey,
        syncQueue: SQLiteSyncQueue(),
      );

      // Perform initial sync on app start
      debugPrint('[MAIN] Performing initial sync...');
      unawaited(SyncService.instance.fullSync());

      // Start periodic sync (every 5 minutes)
      SyncService.instance.startPeriodicSync(
        interval: const Duration(minutes: 5),
      );

      // Listen for connectivity changes and sync when coming online
      _setupConnectivityListener();

      debugPrint('[MAIN] Sync service initialized successfully');
    } catch (e) {
      debugPrint('[MAIN] Failed to initialize sync service: $e');
    }
  } else {
    debugPrint('[MAIN] Sync disabled by config');
  }

  runApp(const DietApp());
}

/// Set up connectivity listener to sync when coming back online
void _setupConnectivityListener() {
  final connectivity = Connectivity();

  connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
    // If we have any connectivity (not none)
    final hasConnection = results.any(
      (r) => r != ConnectivityResult.none,
    );

    if (hasConnection && SyncService.isInitialized) {
      debugPrint('[MAIN] Connection restored, triggering sync...');
      unawaited(SyncService.instance.fullSync());
    }
  });
}
