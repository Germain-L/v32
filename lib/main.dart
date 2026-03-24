import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data/services/sync_config.dart';
import 'data/services/sync_service.dart';
import 'data/services/sqlite_sync_queue.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize sync service if enabled
  if (SyncConfig.enabled) {
    SyncService.init(
      baseUrl: SyncConfig.baseUrl,
      apiKey: SyncConfig.apiKey,
      syncQueue: SQLiteSyncQueue(),
    );
    SyncService.instance.startPeriodicSync();
  }

  runApp(const DietApp());
}
