import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../models/meal.dart';
import '../models/sync_operation.dart';
import 'database_service.dart';
import 'sync_queue.dart';
import 'sync_status_provider.dart';

/// Service for syncing meals and images to the backend server.
/// Implements remote-first sync: backend is source of truth, local is cache.
class SyncService {
  static SyncService? _instance;

  final String baseUrl;
  final String apiKey;
  final SyncQueue syncQueue;
  final SyncStatusProvider _statusProvider = SyncStatusProvider();

  bool _isSyncing = false;
  Timer? _periodicSyncTimer;
  StreamSubscription? _connectivitySubscription;

  SyncService._({
    required this.baseUrl,
    required this.apiKey,
    required this.syncQueue,
  });

  static void init({
    required String baseUrl,
    required String apiKey,
    required SyncQueue syncQueue,
  }) {
    _instance = SyncService._(
      baseUrl: baseUrl,
      apiKey: apiKey,
      syncQueue: syncQueue,
    );
    _log('SyncService initialized: baseUrl=$baseUrl');
  }

  static SyncService get instance {
    if (_instance == null) {
      throw StateError(
        'SyncService not initialized. Call SyncService.init() first.',
      );
    }
    return _instance!;
  }

  /// Check if sync service is initialized
  static bool get isInitialized => _instance != null;

  /// Get the sync status provider for UI updates
  SyncStatusProvider get statusProvider => _statusProvider;

  /// Get current sync status
  SyncStatus get status => _statusProvider.status;

  static void _log(String message) {
    dev.log('[SYNC] $message', name: 'v32');
  }

  /// Start periodic sync and connectivity monitoring
  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(
      interval,
      (_) => fullSync(),
    );
    _log('Started periodic sync (every ${interval.inMinutes} minutes)');

    // Perform initial sync
    fullSync();
  }

  void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _log('Stopped periodic sync');
  }

  /// Get the last sync timestamp from the database
  Future<DateTime?> getLastSyncTimestamp() async {
    final db = await DatabaseService.database;
    final results = await db.query(
      'sync_metadata',
      where: 'key = ?',
      whereArgs: ['lastSyncTimestamp'],
    );

    if (results.isEmpty) return null;

    final value = results.first['value'] as String?;
    if (value == null) return null;

    try {
      return DateTime.fromMillisecondsSinceEpoch(int.parse(value));
    } catch (e) {
      _log('Error parsing last sync timestamp: $e');
      return null;
    }
  }

  /// Save the last sync timestamp to the database
  Future<void> _saveLastSyncTimestamp(DateTime timestamp) async {
    final db = await DatabaseService.database;
    await db.insert(
      'sync_metadata',
      {
        'key': 'lastSyncTimestamp',
        'value': timestamp.millisecondsSinceEpoch.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Pull all changes from the backend since last sync
  Future<void> pullChanges() async {
    _log('Pulling changes from server...');
    _statusProvider.setSyncing(true);

    try {
      final lastSync = await getLastSyncTimestamp();
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 30);

      // Build URL with timestamp if we have one
      Uri uri;
      if (lastSync != null) {
        uri = Uri.parse(
          '$baseUrl/meals/since?timestamp=${lastSync.millisecondsSinceEpoch}',
        );
      } else {
        // First sync - pull all meals
        uri = Uri.parse('$baseUrl/meals/recent?days=365');
      }

      final request = await client.getUrl(uri);
      request.headers.set('X-API-Key', apiKey);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode == 200) {
        final data = jsonDecode(body);

        // Handle both array response and object with meals/deletedIds
        List<dynamic> meals;
        List<int> deletedIds = [];

        if (data is Map<String, dynamic>) {
          meals = data['meals'] as List<dynamic>? ?? [];
          deletedIds = (data['deletedIds'] as List<dynamic>? ?? [])
              .map((e) => e as int)
              .toList();
        } else {
          meals = data as List<dynamic>;
        }

        _log('Received ${meals.length} meals, ${deletedIds.length} deletions');

        final db = await DatabaseService.database;

        // Process meals - upsert by server_id
        for (final mealJson in meals) {
          final serverId = mealJson['id'] as int?;
          if (serverId == null) continue;

          // Check if meal exists by server_id
          final existing = await db.query(
            'meals',
            where: 'server_id = ?',
            whereArgs: [serverId],
          );

          final mealMap = {
            'server_id': serverId,
            'slot': mealJson['slot'],
            'date': mealJson['date'],
            'description': mealJson['description'],
            'imagePath': mealJson['imagePath'],
            'updated_at': mealJson['updated_at'] ??
                DateTime.now().millisecondsSinceEpoch,
            'pending_sync': 0,
          };

          if (existing.isNotEmpty) {
            // Update existing
            await db.update(
              'meals',
              mealMap,
              where: 'server_id = ?',
              whereArgs: [serverId],
            );
          } else {
            // Insert new
            await db.insert('meals', mealMap);
          }
        }

        // Delete meals that were deleted on server
        for (final serverId in deletedIds) {
          await db.delete(
            'meals',
            where: 'server_id = ?',
            whereArgs: [serverId],
          );
        }

        // Update last sync timestamp
        final now = DateTime.now();
        await _saveLastSyncTimestamp(now);
        _statusProvider.setLastSync(now);

        await DatabaseService.notifyChange(table: 'meals');
        _log('Pull complete');
      } else if (response.statusCode == 404) {
        // Endpoint doesn't exist - backward compatible mode
        _log('Sync endpoints not available, running in local-only mode');
        _statusProvider.setOnline(true);
        _statusProvider.setError(null);
      } else {
        _log('Pull failed: ${response.statusCode}');
        _statusProvider.setError('Failed to sync: ${response.statusCode}');
      }
    } on SocketException {
      _log('Pull failed: offline');
      _statusProvider.setOnline(false);
      _statusProvider.setError('Offline');
    } catch (e) {
      _log('Pull error: $e');
      _statusProvider.setError('Sync error: $e');
    } finally {
      _statusProvider.setSyncing(false);
    }
  }

  /// Push all pending local changes to the backend
  Future<void> pushPending() async {
    _log('Pushing pending changes...');
    _statusProvider.setSyncing(true);

    try {
      final db = await DatabaseService.database;

      // Get all meals with pending_sync = 1
      final pendingMeals = await db.query(
        'meals',
        where: 'pending_sync = ?',
        whereArgs: [1],
      );

      if (pendingMeals.isEmpty) {
        _log('No pending changes to push');
        _statusProvider.setPendingChanges(0);
        return;
      }

      _log('Found ${pendingMeals.length} pending meals');

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 30);

      // Try bulk upload endpoint first
      final bulkUri = Uri.parse('$baseUrl/meals/bulk');
      final bulkRequest = await client.postUrl(bulkUri);
      bulkRequest.headers.set('X-API-Key', apiKey);
      bulkRequest.headers.contentType = ContentType.json;

      final payload = {
        'meals': pendingMeals.map((m) {
          return {
            'id': m['server_id'],
            'slot': m['slot'],
            'date': m['date'],
            'description': m['description'],
            'imagePath': m['imagePath'],
            'updated_at': m['updated_at'],
          };
        }).toList(),
      };
      bulkRequest.write(jsonEncode(payload));

      final response = await bulkRequest.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(body);
        final serverMeals = data['meals'] as List<dynamic>? ?? [];

        // Update local records with server IDs and clear pending flag
        for (final serverMeal in serverMeals) {
          final serverId = serverMeal['id'] as int?;
          if (serverId == null) continue;

          // Find matching local meal by slot and date
          final slot = serverMeal['slot'];
          final date = serverMeal['date'];

          await db.update(
            'meals',
            {
              'server_id': serverId,
              'pending_sync': 0,
              'updated_at': serverMeal['updated_at'] ??
                  DateTime.now().millisecondsSinceEpoch,
            },
            where: 'slot = ? AND date = ? AND pending_sync = ?',
            whereArgs: [slot, date, 1],
          );
        }

        // If bulk succeeded, all pending should be cleared
        await db.update(
          'meals',
          {'pending_sync': 0},
          where: 'pending_sync = ?',
          whereArgs: [1],
        );

        await DatabaseService.notifyChange(table: 'meals');
        _statusProvider.setPendingChanges(0);
        _log('Push complete');
      } else if (response.statusCode == 404) {
        // Fallback: push one by one
        _log('Bulk endpoint not available, pushing individually');
        await _pushIndividually(pendingMeals, client);
      } else {
        _log('Push failed: ${response.statusCode} - $body');
        _statusProvider.setError('Push failed');
      }

      client.close();
    } on SocketException {
      _log('Push failed: offline');
      _statusProvider.setOnline(false);
    } catch (e) {
      _log('Push error: $e');
      _statusProvider.setError('Sync error: $e');
    } finally {
      _statusProvider.setSyncing(false);
    }
  }

  /// Fallback: push meals one by one
  Future<void> _pushIndividually(
    List<Map<String, dynamic>> pendingMeals,
    HttpClient client,
  ) async {
    final db = await DatabaseService.database;
    int successCount = 0;

    for (final mealMap in pendingMeals) {
      try {
        final uri = Uri.parse('$baseUrl/meals');
        final request = await client.postUrl(uri);
        request.headers.set('X-API-Key', apiKey);
        request.headers.contentType = ContentType.json;

        final payload = {
          'slot': mealMap['slot'],
          'date': mealMap['date'],
          'description': mealMap['description'],
        };
        request.write(jsonEncode(payload));

        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(body);
          final serverId = data['id'] as int?;

          if (serverId != null) {
            await db.update(
              'meals',
              {'server_id': serverId, 'pending_sync': 0},
              where: 'id = ?',
              whereArgs: [mealMap['id']],
            );
          }
          successCount++;
        }
      } catch (e) {
        _log('Failed to push meal ${mealMap['id']}: $e');
      }
    }

    // Update pending count
    final remaining = await db.query(
      'meals',
      where: 'pending_sync = ?',
      whereArgs: [1],
    );
    _statusProvider.setPendingChanges(remaining.length);
    _log('Pushed $successCount meals individually');
  }

  /// Full sync: pull then push
  Future<void> fullSync() async {
    if (_isSyncing) {
      _log('Sync already in progress, skipping');
      return;
    }
    _isSyncing = true;

    try {
      _statusProvider.setOnline(true);
      _statusProvider.clearError();

      // First pull any remote changes
      await pullChanges();

      // Then push our pending changes
      await pushPending();

      // Update pending count
      await _updatePendingCount();
    } finally {
      _isSyncing = false;
    }
  }

  /// Update the pending changes count
  Future<void> _updatePendingCount() async {
    final db = await DatabaseService.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM meals WHERE pending_sync = 1',
      ),
    );
    _statusProvider.setPendingChanges(count ?? 0);
  }

  /// Mark a meal as needing sync
  Future<void> markPendingSync(int localId) async {
    final db = await DatabaseService.database;
    await db.update(
      'meals',
      {
        'pending_sync': 1,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
    await _updatePendingCount();
  }

  /// Sync a single meal to the backend (for immediate sync attempts)
  Future<bool> syncMeal(Meal meal, OperationType operation) async {
    _log(
      'Syncing meal: slot=${meal.slot.name}, date=${meal.date}, id=${meal.id}',
    );

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final uri = Uri.parse('$baseUrl/meals');
      final request = await client.postUrl(uri);

      request.headers.set('X-API-Key', apiKey);
      request.headers.contentType = ContentType.json;

      final payload = {
        'slot': meal.slot.name,
        'date': meal.date.millisecondsSinceEpoch,
        'description': meal.description,
      };
      request.write(jsonEncode(payload));

      _log('Sending POST $baseUrl/meals');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      _log('Response: ${response.statusCode} - $body');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(body);
        final serverMealId = responseData['id'];
        _log('Meal synced successfully, server ID: $serverMealId');

        // Update local record with server ID and clear pending flag
        if (meal.id != null && serverMealId != null) {
          final db = await DatabaseService.database;
          await db.update(
            'meals',
            {'server_id': serverMealId, 'pending_sync': 0},
            where: 'id = ?',
            whereArgs: [meal.id],
          );
          await _updatePendingCount();
        }

        // Upload image for this meal if exists
        if (meal.hasImage && serverMealId != null) {
          _log('Uploading image for meal...');
          await uploadImage(serverMealId, File(meal.imagePath!));
        }

        return true;
      } else {
        _log('Sync failed: ${response.statusCode}');
        return false;
      }
    } on SocketException {
      _log('Sync failed: offline');
      _statusProvider.setOnline(false);
      return false;
    } catch (e) {
      _log('Sync error: $e');
      return false;
    }
  }

  /// Upload an image for a meal.
  Future<bool> uploadImage(int mealId, File imageFile) async {
    _log('Uploading image for meal $mealId: ${imageFile.path}');

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 30);
      final uri = Uri.parse('$baseUrl/upload');
      final request = await client.postUrl(uri);

      request.headers.set('X-API-Key', apiKey);

      // Multipart form data
      final boundary =
          '----ClankerBoundary${DateTime.now().millisecondsSinceEpoch}';
      request.headers.contentType = ContentType.parse(
        'multipart/form-data; boundary=$boundary',
      );

      final bytes = await imageFile.readAsBytes();
      final filename = imageFile.path.split('/').last;

      final body = StringBuffer();
      body.write('--$boundary\r\n');
      body.write('Content-Disposition: form-data; name="mealId"\r\n\r\n');
      body.write('$mealId\r\n');
      body.write('--$boundary\r\n');
      body.write(
        'Content-Disposition: form-data; name="image"; filename="$filename"\r\n',
      );
      body.write('Content-Type: image/jpeg\r\n\r\n');

      request.write(body.toString());
      request.write(bytes);
      request.write('\r\n--$boundary--\r\n');

      final response = await request.close();
      client.close();

      final success = response.statusCode == 200 || response.statusCode == 201;
      _log(
        'Image upload ${success ? "success" : "failed"}: ${response.statusCode}',
      );
      return success;
    } catch (e) {
      _log('Image upload error: $e');
      return false;
    }
  }

  /// Get meals from the backend for a specific date.
  Future<List<Map<String, dynamic>>> getMealsForDate(DateTime date) async {
    try {
      final client = HttpClient();
      final dateStr =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final uri = Uri.parse('$baseUrl/meals?date=$dateStr');
      final request = await client.getUrl(uri);

      request.headers.set('X-API-Key', apiKey);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch meals: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get recent meals from the backend.
  Future<List<Map<String, dynamic>>> getRecentMeals({int days = 7}) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('$baseUrl/meals/recent?days=$days');
      final request = await client.getUrl(uri);

      request.headers.set('X-API-Key', apiKey);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch meals: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> healthCheck() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final uri = Uri.parse('$baseUrl/health');
      final request = await client.getUrl(uri);

      final response = await request.close();
      client.close();

      final healthy = response.statusCode == 200;
      _log('Health check: $healthy');
      _statusProvider.setOnline(healthy);
      return healthy;
    } catch (e) {
      _log('Health check failed: $e');
      _statusProvider.setOnline(false);
      return false;
    }
  }
}
