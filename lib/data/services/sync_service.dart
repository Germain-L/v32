import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import '../models/body_metric.dart';
import '../models/daily_checkin.dart';
import '../models/daily_metrics.dart';
import '../models/hydration.dart';
import '../models/meal.dart';
import '../models/screen_time.dart';
import '../models/sync_operation.dart';
import '../models/workout.dart';
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

  Future<({int statusCode, String body, dynamic data})> _requestJson({
    required String method,
    required String path,
    Object? payload,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);

    try {
      final uri = Uri.parse('$baseUrl$path');
      late HttpClientRequest request;

      switch (method) {
        case 'GET':
          request = await client.getUrl(uri);
          break;
        case 'POST':
          request = await client.postUrl(uri);
          break;
        case 'PUT':
          request = await client.putUrl(uri);
          break;
        case 'DELETE':
          request = await client.deleteUrl(uri);
          break;
        default:
          throw UnsupportedError('Unsupported method: $method');
      }

      request.headers.set('X-API-Key', apiKey);

      if (payload != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(payload));
      }

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      dynamic data;
      if (body.isNotEmpty) {
        try {
          data = jsonDecode(body);
        } catch (_) {
          data = null;
        }
      }

      return (
        statusCode: response.statusCode,
        body: body,
        data: data,
      );
    } finally {
      client.close();
    }
  }

  bool _isSuccessStatus(int statusCode) =>
      statusCode == 200 || statusCode == 201 || statusCode == 204;

  Future<void> _markRecordSynced(
    String table,
    int localId, {
    int? serverId,
  }) async {
    final db = await DatabaseService.database;
    final values = <String, Object>{'pending_sync': 0};
    if (serverId != null) {
      values['server_id'] = serverId;
    }

    await db.update(
      table,
      values,
      where: 'id = ?',
      whereArgs: [localId],
    );
    await DatabaseService.notifyChange(table: table);
    await _updatePendingCount();
  }

  Future<int> _pendingCountForTable(String table) async {
    final db = await DatabaseService.database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM $table WHERE pending_sync = 1',
      ),
    );
    return count ?? 0;
  }

  Future<List<ScreenTimeApp>> _getScreenTimeAppsForLocalId(
    int screenTimeId,
  ) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'screen_time_apps',
      where: 'screen_time_id = ?',
      whereArgs: [screenTimeId],
      orderBy: 'duration_ms DESC',
    );

    return maps.map((map) => ScreenTimeApp.fromMap(map)).toList();
  }

  Future<List<ScreenTime>> _getPendingScreenTimes() async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'screen_times',
      where: 'pending_sync = ?',
      whereArgs: [1],
      orderBy: 'created_at ASC',
    );

    final screenTimes = <ScreenTime>[];
    for (final map in maps) {
      final screenTime = ScreenTime.fromMap(map);
      final id = screenTime.id;
      if (id == null) {
        screenTimes.add(screenTime);
        continue;
      }

      final apps = await _getScreenTimeAppsForLocalId(id);
      screenTimes.add(screenTime.copyWith(apps: apps));
    }

    return screenTimes;
  }

  Future<void> _enqueueOperation(SyncOperation operation) async {
    await syncQueue.enqueue(operation);
    await _updatePendingCount();
  }

  Future<void> completeQueuedOperation(String operationId) async {
    await syncQueue.markCompleted(operationId);
    await _updatePendingCount();
  }

  String _operationId(String entityType, String key) => '$entityType:$key';

  Future<void> queueUpsertDailyMetrics(DailyMetrics metrics) async {
    final normalized = DateTime(
      metrics.date.year,
      metrics.date.month,
      metrics.date.day,
    );
    await _enqueueOperation(
      SyncOperation(
        id: _operationId(
          'daily_metrics',
          normalized.millisecondsSinceEpoch.toString(),
        ),
        entityType: 'daily_metrics',
        operationType: OperationType.update,
        payload: {
          'date': normalized.millisecondsSinceEpoch,
          'waterLiters': metrics.waterLiters,
          'exerciseDone': metrics.exerciseDone,
          'exerciseNote': metrics.exerciseNote,
        },
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> queueDeleteDailyMetrics(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    await _enqueueOperation(
      SyncOperation(
        id: _operationId(
          'daily_metrics_delete',
          normalized.millisecondsSinceEpoch.toString(),
        ),
        entityType: 'daily_metrics_delete',
        operationType: OperationType.delete,
        payload: {'date': normalized.millisecondsSinceEpoch},
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> queueUpsertDayRating(DateTime date, int score) async {
    final normalized = DateTime(date.year, date.month, date.day);
    await _enqueueOperation(
      SyncOperation(
        id: _operationId(
          'day_rating',
          normalized.millisecondsSinceEpoch.toString(),
        ),
        entityType: 'day_rating',
        operationType: OperationType.update,
        payload: {'date': normalized.millisecondsSinceEpoch, 'score': score},
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> queueDeleteMeal(int serverId) async {
    await _enqueueOperation(
      SyncOperation(
        id: _operationId('meal_delete', serverId.toString()),
        entityType: 'meal_delete',
        operationType: OperationType.delete,
        payload: {'serverId': serverId},
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> queueDeleteWorkout(int serverId) async {
    await _enqueueOperation(
      SyncOperation(
        id: _operationId('workout_delete', serverId.toString()),
        entityType: 'workout_delete',
        operationType: OperationType.delete,
        payload: {'serverId': serverId},
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> queueDeleteBodyMetric(int serverId) async {
    await _enqueueOperation(
      SyncOperation(
        id: _operationId('body_metric_delete', serverId.toString()),
        entityType: 'body_metric_delete',
        operationType: OperationType.delete,
        payload: {'serverId': serverId},
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> queueDeleteHydration(int serverId) async {
    await _enqueueOperation(
      SyncOperation(
        id: _operationId('hydration_delete', serverId.toString()),
        entityType: 'hydration_delete',
        operationType: OperationType.delete,
        payload: {'serverId': serverId},
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> queueDeleteCheckin(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    await _enqueueOperation(
      SyncOperation(
        id: _operationId(
          'checkin_delete',
          normalized.millisecondsSinceEpoch.toString(),
        ),
        entityType: 'checkin_delete',
        operationType: OperationType.delete,
        payload: {'date': normalized.millisecondsSinceEpoch},
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> queueDeleteScreenTime(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    await _enqueueOperation(
      SyncOperation(
        id: _operationId(
          'screen_time_delete',
          normalized.millisecondsSinceEpoch.toString(),
        ),
        entityType: 'screen_time_delete',
        operationType: OperationType.delete,
        payload: {'date': normalized.millisecondsSinceEpoch},
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> queueUploadPrimaryMealImage(
      int localMealId, String imagePath) async {
    await _enqueueOperation(
      SyncOperation(
        id: _operationId('meal_primary_image_upload', localMealId.toString()),
        entityType: 'meal_primary_image_upload',
        operationType: OperationType.update,
        payload: {
          'localMealId': localMealId,
          'imagePath': imagePath,
        },
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> queueUploadMealImage(
    int localMealId,
    int localImageId,
    String imagePath,
  ) async {
    await _enqueueOperation(
      SyncOperation(
        id: _operationId('meal_image_upload', localImageId.toString()),
        entityType: 'meal_image_upload',
        operationType: OperationType.update,
        payload: {
          'localMealId': localMealId,
          'localImageId': localImageId,
          'imagePath': imagePath,
        },
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> queueDeleteRemoteImage(String remoteUrl) async {
    await _enqueueOperation(
      SyncOperation(
        id: _operationId('remote_image_delete', remoteUrl),
        entityType: 'remote_image_delete',
        operationType: OperationType.delete,
        payload: {'remoteUrl': remoteUrl},
        createdAt: DateTime.now(),
      ),
    );
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
      final timestamp = lastSync?.millisecondsSinceEpoch ?? 0;
      var latestTimestamp = timestamp;
      final db = await DatabaseService.database;

      final mealsResponse = await _requestJson(
        method: 'GET',
        path: '/meals/since?timestamp=$timestamp',
      );
      if (mealsResponse.statusCode != 404) {
        if (mealsResponse.statusCode != 200) {
          throw Exception('Failed to sync meals: ${mealsResponse.statusCode}');
        }

        final data = mealsResponse.data as Map<String, dynamic>? ??
            const <String, dynamic>{};
        final meals = data['meals'] as List<dynamic>? ?? const <dynamic>[];
        final deletedIds =
            data['deletedIds'] as List<dynamic>? ?? const <dynamic>[];

        for (final mealJson in meals) {
          if (mealJson is! Map<String, dynamic>) {
            continue;
          }

          final serverId = mealJson['id'] as int?;
          if (serverId == null) {
            continue;
          }

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
            'updated_at':
                mealJson['updated_at'] ?? DateTime.now().millisecondsSinceEpoch,
            'pending_sync': 0,
          };

          if (existing.isNotEmpty) {
            await db.update(
              'meals',
              mealMap,
              where: 'server_id = ?',
              whereArgs: [serverId],
            );
          } else {
            await db.insert('meals', mealMap);
          }
        }

        for (final serverId in deletedIds) {
          await db.delete(
            'meals',
            where: 'server_id = ?',
            whereArgs: [serverId],
          );
        }

        latestTimestamp = [
          latestTimestamp,
          (data['timestamp'] as int?) ?? 0,
        ].reduce((a, b) => a > b ? a : b);
        await DatabaseService.notifyChange(table: 'meals');
      }

      latestTimestamp = [
        latestTimestamp,
        await _pullEntitySince(
          path: '/workouts/since?timestamp=$timestamp',
          collectionKey: 'workouts',
          applyItem: _upsertWorkoutFromJson,
          applyDeletes: (deletedIds) async {
            for (final serverId in deletedIds) {
              await db.delete(
                'workouts',
                where: 'server_id = ?',
                whereArgs: [serverId],
              );
            }
            await DatabaseService.notifyChange(table: 'workouts');
          },
        ),
      ].reduce((a, b) => a > b ? a : b);

      latestTimestamp = [
        latestTimestamp,
        await _pullEntitySince(
          path: '/body-metrics/since?timestamp=$timestamp',
          collectionKey: 'bodyMetrics',
          applyItem: _upsertBodyMetricFromJson,
          applyDeletes: (deletedIds) async {
            for (final serverId in deletedIds) {
              await db.delete(
                'body_metrics',
                where: 'server_id = ?',
                whereArgs: [serverId],
              );
            }
            await DatabaseService.notifyChange(table: 'body_metrics');
          },
        ),
      ].reduce((a, b) => a > b ? a : b);

      latestTimestamp = [
        latestTimestamp,
        await _pullEntitySince(
          path: '/checkins/since?timestamp=$timestamp',
          collectionKey: 'checkins',
          applyItem: _upsertDailyCheckinFromJson,
          applyDeletes: (deletedDates) async {
            for (final date in deletedDates) {
              await db.delete(
                'daily_checkins',
                where: 'date = ?',
                whereArgs: [date],
              );
            }
            await DatabaseService.notifyChange(table: 'daily_checkins');
          },
        ),
      ].reduce((a, b) => a > b ? a : b);

      latestTimestamp = [
        latestTimestamp,
        await _pullEntitySince(
          path: '/screen-time/since?timestamp=$timestamp',
          collectionKey: 'screenTimes',
          applyItem: _upsertScreenTimeFromJson,
          applyDeletes: (deletedDates) async {
            for (final date in deletedDates) {
              final existing = await db.query(
                'screen_times',
                columns: ['id'],
                where: 'date = ?',
                whereArgs: [date],
              );
              for (final row in existing) {
                await db.delete(
                  'screen_time_apps',
                  where: 'screen_time_id = ?',
                  whereArgs: [row['id']],
                );
              }
              await db.delete(
                'screen_times',
                where: 'date = ?',
                whereArgs: [date],
              );
            }
            await DatabaseService.notifyChange(table: 'screen_times');
            await DatabaseService.notifyChange(table: 'screen_time_apps');
          },
        ),
      ].reduce((a, b) => a > b ? a : b);

      latestTimestamp = [
        latestTimestamp,
        await _pullEntitySince(
          path: '/hydration/since?timestamp=$timestamp',
          collectionKey: 'hydrations',
          applyItem: _upsertHydrationFromJson,
          applyDeletes: (deletedIds) async {
            for (final serverId in deletedIds) {
              await db.delete(
                'hydrations',
                where: 'server_id = ?',
                whereArgs: [serverId],
              );
            }
            await DatabaseService.notifyChange(table: 'hydrations');
          },
        ),
      ].reduce((a, b) => a > b ? a : b);

      latestTimestamp = [
        latestTimestamp,
        await _pullEntitySince(
          path: '/daily-metrics/since?timestamp=$timestamp',
          collectionKey: 'dailyMetrics',
          applyItem: _upsertDailyMetricsFromJson,
          applyDeletes: (deletedDates) async {
            for (final date in deletedDates) {
              await db.delete(
                'daily_metrics',
                where: 'date = ?',
                whereArgs: [date],
              );
            }
            await DatabaseService.notifyChange(table: 'daily_metrics');
          },
        ),
      ].reduce((a, b) => a > b ? a : b);

      latestTimestamp = [
        latestTimestamp,
        await _pullEntitySince(
          path: '/rating/since?timestamp=$timestamp',
          collectionKey: 'ratings',
          applyItem: _upsertDayRatingFromJson,
          applyDeletes: (deletedDates) async {
            for (final date in deletedDates) {
              await db.delete(
                'day_ratings',
                where: 'date = ?',
                whereArgs: [date],
              );
            }
            await DatabaseService.notifyChange(table: 'day_ratings');
          },
        ),
      ].reduce((a, b) => a > b ? a : b);

      final now = DateTime.fromMillisecondsSinceEpoch(
        latestTimestamp > timestamp
            ? latestTimestamp
            : DateTime.now().millisecondsSinceEpoch,
      );
      await _saveLastSyncTimestamp(now);
      _statusProvider.setLastSync(now);
      _log('Pull complete');
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
      final pendingMeals = await db.query(
        'meals',
        where: 'pending_sync = ?',
        whereArgs: [1],
      );

      final pendingWorkouts = await db.query(
        'workouts',
        where: 'pending_sync = ?',
        whereArgs: [1],
        orderBy: 'updated_at ASC',
      );
      final pendingBodyMetrics = await db.query(
        'body_metrics',
        where: 'pending_sync = ?',
        whereArgs: [1],
        orderBy: 'updated_at ASC',
      );
      final pendingDailyCheckins = await db.query(
        'daily_checkins',
        where: 'pending_sync = ?',
        whereArgs: [1],
        orderBy: 'updated_at ASC',
      );
      final pendingHydrations = await db.query(
        'hydrations',
        where: 'pending_sync = ?',
        whereArgs: [1],
        orderBy: 'created_at ASC',
      );
      final pendingScreenTimes = await _getPendingScreenTimes();

      final totalPending = pendingMeals.length +
          pendingWorkouts.length +
          pendingBodyMetrics.length +
          pendingDailyCheckins.length +
          pendingHydrations.length +
          pendingScreenTimes.length;

      if (totalPending == 0) {
        _log('No pending changes to push');
        _statusProvider.setPendingChanges(0);
        return;
      }

      _log(
        'Found $totalPending pending changes '
        '(meals=${pendingMeals.length}, workouts=${pendingWorkouts.length}, '
        'bodyMetrics=${pendingBodyMetrics.length}, '
        'checkins=${pendingDailyCheckins.length}, '
        'screenTimes=${pendingScreenTimes.length}, '
        'hydrations=${pendingHydrations.length})',
      );

      if (pendingMeals.isNotEmpty) {
        final mealSyncSucceeded = await _pushMeals(pendingMeals);
        if (!mealSyncSucceeded) {
          _log('Meal push did not fully complete');
        }
      }

      for (final workoutMap in pendingWorkouts) {
        await syncWorkout(
          Workout.fromMap(workoutMap),
          workoutMap['server_id'] == null
              ? OperationType.create
              : OperationType.update,
        );
      }

      for (final bodyMetricMap in pendingBodyMetrics) {
        await syncBodyMetric(
          BodyMetric.fromMap(bodyMetricMap),
          bodyMetricMap['server_id'] == null
              ? OperationType.create
              : OperationType.update,
        );
      }

      for (final dailyCheckinMap in pendingDailyCheckins) {
        await syncDailyCheckin(
          DailyCheckin.fromMap(dailyCheckinMap),
          dailyCheckinMap['server_id'] == null
              ? OperationType.create
              : OperationType.update,
        );
      }

      for (final screenTime in pendingScreenTimes) {
        await syncScreenTime(
          screenTime,
          screenTime.serverId == null
              ? OperationType.create
              : OperationType.update,
        );
      }

      for (final hydrationMap in pendingHydrations) {
        await syncHydration(
          Hydration.fromMap(hydrationMap),
          hydrationMap['server_id'] == null
              ? OperationType.create
              : OperationType.update,
        );
      }

      await _updatePendingCount();
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

  Future<bool> _pushMeals(List<Map<String, dynamic>> pendingMeals) async {
    final db = await DatabaseService.database;
    final response = await _requestJson(
      method: 'POST',
      path: '/meals/bulk',
      payload: {
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
      },
    );

    if (_isSuccessStatus(response.statusCode)) {
      final data = response.data;
      final serverMeals = data is Map<String, dynamic>
          ? (data['meals'] as List<dynamic>? ?? [])
          : const <dynamic>[];

      for (final serverMeal in serverMeals) {
        if (serverMeal is! Map<String, dynamic>) {
          continue;
        }

        final serverId = serverMeal['id'] as int?;
        if (serverId == null) {
          continue;
        }

        await db.update(
          'meals',
          {
            'server_id': serverId,
            'pending_sync': 0,
            'updated_at': serverMeal['updated_at'] ??
                DateTime.now().millisecondsSinceEpoch,
          },
          where: 'slot = ? AND date = ? AND pending_sync = ?',
          whereArgs: [serverMeal['slot'], serverMeal['date'], 1],
        );
      }

      await db.update(
        'meals',
        {'pending_sync': 0},
        where: 'pending_sync = ?',
        whereArgs: [1],
      );
      await DatabaseService.notifyChange(table: 'meals');
      return true;
    }

    if (response.statusCode == 404) {
      _log('Bulk meal endpoint not available, pushing individually');
      await _pushMealsIndividually(pendingMeals);
      return true;
    }

    _log('Meal push failed: ${response.statusCode} - ${response.body}');
    _statusProvider.setError('Meal push failed');
    return false;
  }

  /// Fallback: push meals one by one
  Future<void> _pushMealsIndividually(
      List<Map<String, dynamic>> pendingMeals) async {
    final db = await DatabaseService.database;
    int successCount = 0;

    for (final mealMap in pendingMeals) {
      try {
        final response = await _requestJson(
          method: 'POST',
          path: '/meals',
          payload: {
            'slot': mealMap['slot'],
            'date': mealMap['date'],
            'description': mealMap['description'],
          },
        );

        if (_isSuccessStatus(response.statusCode)) {
          final data = response.data as Map<String, dynamic>? ??
              const <String, dynamic>{};
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

  Future<void> processQueuedOperations() async {
    final operations = await syncQueue.getPendingOperations();
    if (operations.isEmpty) {
      return;
    }

    _log('Processing ${operations.length} queued operations');

    for (final operation in operations) {
      try {
        final success = await _processQueuedOperation(operation);
        if (success) {
          await syncQueue.markCompleted(operation.id);
        } else {
          await syncQueue.markFailed(operation.id);
        }
      } catch (e) {
        _log('Queued operation ${operation.id} failed: $e');
        await syncQueue.markFailed(operation.id);
      }
    }

    await _updatePendingCount();
  }

  Future<bool> _processQueuedOperation(SyncOperation operation) async {
    switch (operation.entityType) {
      case 'daily_metrics':
        return syncDailyMetrics(
          DailyMetrics(
            date: DateTime.fromMillisecondsSinceEpoch(
              operation.payload['date'] as int,
            ),
            waterLiters: (operation.payload['waterLiters'] as num?)?.toDouble(),
            exerciseDone: operation.payload['exerciseDone'] as bool?,
            exerciseNote: operation.payload['exerciseNote'] as String?,
          ),
        );
      case 'daily_metrics_delete':
        return deleteDailyMetrics(
          DateTime.fromMillisecondsSinceEpoch(operation.payload['date'] as int),
        );
      case 'day_rating':
        return syncDayRating(
          DateTime.fromMillisecondsSinceEpoch(operation.payload['date'] as int),
          operation.payload['score'] as int,
        );
      case 'meal_delete':
        return deleteMeal(operation.payload['serverId'] as int);
      case 'workout_delete':
        return deleteWorkout(operation.payload['serverId'] as int);
      case 'body_metric_delete':
        return deleteBodyMetric(operation.payload['serverId'] as int);
      case 'hydration_delete':
        return deleteHydration(operation.payload['serverId'] as int);
      case 'checkin_delete':
        return deleteCheckin(
          DateTime.fromMillisecondsSinceEpoch(operation.payload['date'] as int),
        );
      case 'screen_time_delete':
        return deleteScreenTime(
          DateTime.fromMillisecondsSinceEpoch(operation.payload['date'] as int),
        );
      case 'meal_primary_image_upload':
        return _processPrimaryMealImageUpload(operation.payload);
      case 'meal_image_upload':
        return _processMealImageUpload(operation.payload);
      case 'remote_image_delete':
        return deleteRemoteImage(operation.payload['remoteUrl'] as String);
      default:
        _log('Unknown queued operation type: ${operation.entityType}');
        return true;
    }
  }

  Future<bool> _processPrimaryMealImageUpload(
    Map<String, dynamic> payload,
  ) async {
    final db = await DatabaseService.database;
    final mealId = payload['localMealId'] as int;
    final imagePath = payload['imagePath'] as String;

    final results = await db.query(
      'meals',
      columns: ['server_id', 'imagePath'],
      where: 'id = ?',
      whereArgs: [mealId],
      limit: 1,
    );
    if (results.isEmpty) {
      return true;
    }

    final meal = results.first;
    final serverId = meal['server_id'] as int?;
    final currentImagePath = meal['imagePath'] as String?;
    if (serverId == null) {
      return false;
    }
    if (currentImagePath == null || currentImagePath != imagePath) {
      return true;
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      return true;
    }

    final remoteUrl = await uploadImageWithRemoteUrl(serverId, file);
    if (remoteUrl == null) {
      return false;
    }

    await db.update(
      'meals',
      {'remote_image_url': remoteUrl},
      where: 'id = ?',
      whereArgs: [mealId],
    );
    return true;
  }

  Future<bool> _processMealImageUpload(Map<String, dynamic> payload) async {
    final db = await DatabaseService.database;
    final localMealId = payload['localMealId'] as int;
    final localImageId = payload['localImageId'] as int;
    final imagePath = payload['imagePath'] as String;

    final mealResults = await db.query(
      'meals',
      columns: ['server_id'],
      where: 'id = ?',
      whereArgs: [localMealId],
      limit: 1,
    );
    if (mealResults.isEmpty) {
      return true;
    }

    final serverId = mealResults.first['server_id'] as int?;
    if (serverId == null) {
      return false;
    }

    final imageResults = await db.query(
      'meal_images',
      columns: ['imagePath'],
      where: 'id = ? AND mealId = ?',
      whereArgs: [localImageId, localMealId],
      limit: 1,
    );
    if (imageResults.isEmpty) {
      return true;
    }

    final currentImagePath = imageResults.first['imagePath'] as String?;
    if (currentImagePath == null || currentImagePath != imagePath) {
      return true;
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      return true;
    }

    final remoteUrl = await uploadImageWithRemoteUrl(serverId, file);
    if (remoteUrl == null) {
      return false;
    }

    await db.update(
      'meal_images',
      {'remote_url': remoteUrl},
      where: 'id = ?',
      whereArgs: [localImageId],
    );
    return true;
  }

  Future<void> _upsertWorkoutFromJson(Map<String, dynamic> json) async {
    final db = await DatabaseService.database;
    final workout = Workout.fromJson(json);
    final values = workout.toMap()
      ..remove('id')
      ..['server_id'] = workout.serverId
      ..['pending_sync'] = 0;

    final existing = await db.query(
      'workouts',
      columns: ['id'],
      where: 'server_id = ?',
      whereArgs: [workout.serverId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.update(
        'workouts',
        values,
        where: 'server_id = ?',
        whereArgs: [workout.serverId],
      );
    } else {
      await db.insert('workouts', values);
    }
  }

  Future<void> _upsertBodyMetricFromJson(Map<String, dynamic> json) async {
    final db = await DatabaseService.database;
    final bodyMetric = BodyMetric.fromJson(json);
    final values = bodyMetric.toMap()
      ..remove('id')
      ..['server_id'] = bodyMetric.serverId
      ..['pending_sync'] = 0;

    final existing = await db.query(
      'body_metrics',
      columns: ['id'],
      where: 'server_id = ?',
      whereArgs: [bodyMetric.serverId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.update(
        'body_metrics',
        values,
        where: 'server_id = ?',
        whereArgs: [bodyMetric.serverId],
      );
    } else {
      await db.insert('body_metrics', values);
    }
  }

  Future<void> _upsertDailyCheckinFromJson(Map<String, dynamic> json) async {
    final db = await DatabaseService.database;
    final checkin = DailyCheckin.fromJson(json);
    final normalizedDate = DateTime(
      checkin.date.year,
      checkin.date.month,
      checkin.date.day,
    );
    final values = checkin.toMap()
      ..remove('id')
      ..['date'] = normalizedDate.millisecondsSinceEpoch
      ..['pending_sync'] = 0;

    final existing = await db.query(
      'daily_checkins',
      columns: ['id'],
      where: 'date = ?',
      whereArgs: [normalizedDate.millisecondsSinceEpoch],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.update(
        'daily_checkins',
        values,
        where: 'date = ?',
        whereArgs: [normalizedDate.millisecondsSinceEpoch],
      );
    } else {
      await db.insert('daily_checkins', values);
    }
  }

  Future<void> _upsertHydrationFromJson(Map<String, dynamic> json) async {
    final db = await DatabaseService.database;
    final hydration = Hydration.fromJson(json);
    final values = hydration.toMap()
      ..remove('id')
      ..['server_id'] = hydration.serverId
      ..['pending_sync'] = 0;

    final existing = await db.query(
      'hydrations',
      columns: ['id'],
      where: 'server_id = ?',
      whereArgs: [hydration.serverId],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      await db.update(
        'hydrations',
        values,
        where: 'server_id = ?',
        whereArgs: [hydration.serverId],
      );
    } else {
      await db.insert('hydrations', values);
    }
  }

  Future<void> _upsertScreenTimeFromJson(Map<String, dynamic> json) async {
    final db = await DatabaseService.database;
    final screenTime = ScreenTime.fromJson(json);
    final normalizedDate = DateTime(
      screenTime.date.year,
      screenTime.date.month,
      screenTime.date.day,
    );

    final existing = await db.query(
      'screen_times',
      columns: ['id'],
      where: 'date = ?',
      whereArgs: [normalizedDate.millisecondsSinceEpoch],
      limit: 1,
    );

    final values = screenTime.toMap()
      ..remove('id')
      ..['server_id'] = screenTime.serverId
      ..['date'] = normalizedDate.millisecondsSinceEpoch
      ..['pending_sync'] = 0;

    int localId;
    if (existing.isNotEmpty) {
      localId = existing.first['id'] as int;
      await db.update(
        'screen_times',
        values,
        where: 'id = ?',
        whereArgs: [localId],
      );
    } else {
      localId = await db.insert('screen_times', values);
    }

    await db.delete(
      'screen_time_apps',
      where: 'screen_time_id = ?',
      whereArgs: [localId],
    );

    if (screenTime.apps.isNotEmpty) {
      final batch = db.batch();
      for (final app in screenTime.apps) {
        batch.insert('screen_time_apps', {
          'server_id': app.serverId,
          'screen_time_id': localId,
          'package_name': app.packageName,
          'app_name': app.appName,
          'duration_ms': app.durationMs,
        });
      }
      await batch.commit(noResult: true);
    }
  }

  Future<void> _upsertDailyMetricsFromJson(Map<String, dynamic> json) async {
    final db = await DatabaseService.database;
    final date = DateTime.fromMillisecondsSinceEpoch(json['date'] as int);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    await db.insert(
      'daily_metrics',
      {
        'date': normalizedDate.millisecondsSinceEpoch,
        'water_liters': (json['waterLiters'] as num?)?.toDouble(),
        'exercise_done': switch (json['exerciseDone']) {
          true => 1,
          false => 0,
          _ => null,
        },
        'exercise_note': json['exerciseNote'] as String?,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _upsertDayRatingFromJson(Map<String, dynamic> json) async {
    final db = await DatabaseService.database;
    final date = DateTime.fromMillisecondsSinceEpoch(json['date'] as int);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    await db.insert(
      'day_ratings',
      {
        'date': normalizedDate.millisecondsSinceEpoch,
        'score': json['score'] as int,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> _pullEntitySince({
    required String path,
    required String collectionKey,
    List<String> deletionKeys = const ['deletedIds', 'deletedDates'],
    required Future<void> Function(Map<String, dynamic>) applyItem,
    required Future<void> Function(List<dynamic>) applyDeletes,
  }) async {
    final response = await _requestJson(
      method: 'GET',
      path: path,
    );
    if (response.statusCode == 404) {
      return 0;
    }
    if (response.statusCode != 200) {
      throw Exception('Pull failed for $path: ${response.statusCode}');
    }

    final data =
        response.data as Map<String, dynamic>? ?? const <String, dynamic>{};
    final items = data[collectionKey] as List<dynamic>? ?? const <dynamic>[];
    for (final item in items) {
      if (item is Map<String, dynamic>) {
        await applyItem(item);
      }
    }

    for (final deletionKey in deletionKeys) {
      final values = data[deletionKey] as List<dynamic>?;
      if (values != null) {
        await applyDeletes(values);
        break;
      }
    }

    return (data['timestamp'] as int?) ?? 0;
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

      // Then process queued retry operations
      await processQueuedOperations();

      // Update pending count
      await _updatePendingCount();
    } finally {
      _isSyncing = false;
    }
  }

  /// Update the pending changes count
  Future<void> _updatePendingCount() async {
    final total = await _pendingCountForTable('meals') +
        await _pendingCountForTable('workouts') +
        await _pendingCountForTable('body_metrics') +
        await _pendingCountForTable('daily_checkins') +
        await _pendingCountForTable('screen_times') +
        await _pendingCountForTable('hydrations') +
        (await syncQueue.getPendingOperations()).length;
    _statusProvider.setPendingChanges(total);
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

  Future<bool> syncWorkout(Workout workout, OperationType operation) async {
    _log(
        'Syncing workout: localId=${workout.id}, serverId=${workout.serverId}');

    try {
      final isUpdate = workout.serverId != null;
      final response = await _requestJson(
        method: isUpdate ? 'PUT' : 'POST',
        path: isUpdate ? '/workouts/${workout.serverId}' : '/workouts',
        payload: workout.toJson(),
      );

      if (_isSuccessStatus(response.statusCode)) {
        final data =
            response.data as Map<String, dynamic>? ?? const <String, dynamic>{};
        final serverId = (data['id'] as int?) ?? workout.serverId;
        if (workout.id != null) {
          await _markRecordSynced(
            'workouts',
            workout.id!,
            serverId: serverId,
          );
        }
        return true;
      }

      _log('Workout sync failed: ${response.statusCode} - ${response.body}');
      return false;
    } on SocketException {
      _statusProvider.setOnline(false);
      return false;
    } catch (e) {
      _log('Workout sync error: $e');
      return false;
    }
  }

  Future<bool> syncBodyMetric(
    BodyMetric bodyMetric,
    OperationType operation,
  ) async {
    _log(
      'Syncing body metric: localId=${bodyMetric.id}, serverId=${bodyMetric.serverId}',
    );

    try {
      final isUpdate = bodyMetric.serverId != null;
      final response = await _requestJson(
        method: isUpdate ? 'PUT' : 'POST',
        path:
            isUpdate ? '/body-metrics/${bodyMetric.serverId}' : '/body-metrics',
        payload: bodyMetric.toJson(),
      );

      if (_isSuccessStatus(response.statusCode)) {
        final data =
            response.data as Map<String, dynamic>? ?? const <String, dynamic>{};
        final serverId = (data['id'] as int?) ?? bodyMetric.serverId;
        if (bodyMetric.id != null) {
          await _markRecordSynced(
            'body_metrics',
            bodyMetric.id!,
            serverId: serverId,
          );
        }
        return true;
      }

      _log(
          'Body metric sync failed: ${response.statusCode} - ${response.body}');
      return false;
    } on SocketException {
      _statusProvider.setOnline(false);
      return false;
    } catch (e) {
      _log('Body metric sync error: $e');
      return false;
    }
  }

  Future<bool> syncDailyCheckin(
    DailyCheckin dailyCheckin,
    OperationType operation,
  ) async {
    _log(
      'Syncing daily checkin: localId=${dailyCheckin.id}, date=${dailyCheckin.date.millisecondsSinceEpoch}',
    );

    try {
      final response = await _requestJson(
        method: 'POST',
        path: '/checkins',
        payload: dailyCheckin.toJson(),
      );

      if (_isSuccessStatus(response.statusCode)) {
        final data =
            response.data as Map<String, dynamic>? ?? const <String, dynamic>{};
        final serverId = (data['id'] as int?) ?? dailyCheckin.serverId;
        if (dailyCheckin.id != null) {
          await _markRecordSynced(
            'daily_checkins',
            dailyCheckin.id!,
            serverId: serverId,
          );
        }
        return true;
      }

      _log(
          'Daily checkin sync failed: ${response.statusCode} - ${response.body}');
      return false;
    } on SocketException {
      _statusProvider.setOnline(false);
      return false;
    } catch (e) {
      _log('Daily checkin sync error: $e');
      return false;
    }
  }

  Future<bool> syncScreenTime(
    ScreenTime screenTime,
    OperationType operation,
  ) async {
    _log(
      'Syncing screen time: localId=${screenTime.id}, serverId=${screenTime.serverId}',
    );

    try {
      final response = await _requestJson(
        method: 'POST',
        path: '/screen-time',
        payload: screenTime.toJson(),
      );

      if (_isSuccessStatus(response.statusCode)) {
        final data =
            response.data as Map<String, dynamic>? ?? const <String, dynamic>{};
        final screenTimeData = data['screenTime'] as Map<String, dynamic>? ??
            const <String, dynamic>{};
        final serverId = (screenTimeData['id'] as int?) ?? screenTime.serverId;

        if (screenTime.id != null) {
          await _markRecordSynced(
            'screen_times',
            screenTime.id!,
            serverId: serverId,
          );
        }
        return true;
      }

      _log(
          'Screen time sync failed: ${response.statusCode} - ${response.body}');
      return false;
    } on SocketException {
      _statusProvider.setOnline(false);
      return false;
    } catch (e) {
      _log('Screen time sync error: $e');
      return false;
    }
  }

  Future<bool> syncHydration(
    Hydration hydration,
    OperationType operation,
  ) async {
    _log(
        'Syncing hydration: localId=${hydration.id}, serverId=${hydration.serverId}');

    try {
      final response = await _requestJson(
        method: 'POST',
        path: '/hydration',
        payload: hydration.toJson(),
      );

      if (_isSuccessStatus(response.statusCode)) {
        final data =
            response.data as Map<String, dynamic>? ?? const <String, dynamic>{};
        final serverId = (data['id'] as int?) ?? hydration.serverId;
        if (hydration.id != null) {
          await _markRecordSynced(
            'hydrations',
            hydration.id!,
            serverId: serverId,
          );
        }
        return true;
      }

      _log('Hydration sync failed: ${response.statusCode} - ${response.body}');
      return false;
    } on SocketException {
      _statusProvider.setOnline(false);
      return false;
    } catch (e) {
      _log('Hydration sync error: $e');
      return false;
    }
  }

  Future<bool> syncDayRating(DateTime date, int score) async {
    _log('Syncing day rating: date=${date.millisecondsSinceEpoch}');

    try {
      final response = await _requestJson(
        method: 'POST',
        path: '/rating',
        payload: {
          'date':
              DateTime(date.year, date.month, date.day).millisecondsSinceEpoch,
          'score': score,
        },
      );

      if (_isSuccessStatus(response.statusCode)) {
        return true;
      }

      _log('Day rating sync failed: ${response.statusCode} - ${response.body}');
      return false;
    } on SocketException {
      _statusProvider.setOnline(false);
      return false;
    } catch (e) {
      _log('Day rating sync error: $e');
      return false;
    }
  }

  Future<bool> syncDailyMetrics(DailyMetrics metrics) async {
    _log('Syncing daily metrics: date=${metrics.date.millisecondsSinceEpoch}');

    try {
      final response = await _requestJson(
        method: 'POST',
        path: '/daily-metrics',
        payload: {
          'date': DateTime(
            metrics.date.year,
            metrics.date.month,
            metrics.date.day,
          ).millisecondsSinceEpoch,
          'waterLiters': metrics.waterLiters,
          'exerciseDone': metrics.exerciseDone,
          'exerciseNote': metrics.exerciseNote,
        },
      );

      if (_isSuccessStatus(response.statusCode)) {
        return true;
      }

      _log(
          'Daily metrics sync failed: ${response.statusCode} - ${response.body}');
      return false;
    } on SocketException {
      _statusProvider.setOnline(false);
      return false;
    } catch (e) {
      _log('Daily metrics sync error: $e');
      return false;
    }
  }

  Future<bool> deleteWorkout(int serverId) async {
    try {
      final response = await _requestJson(
        method: 'DELETE',
        path: '/workouts/$serverId',
      );
      return _isSuccessStatus(response.statusCode) ||
          response.statusCode == 404;
    } catch (e) {
      _log('Workout delete sync error: $e');
      return false;
    }
  }

  Future<bool> deleteBodyMetric(int serverId) async {
    try {
      final response = await _requestJson(
        method: 'DELETE',
        path: '/body-metrics/$serverId',
      );
      return _isSuccessStatus(response.statusCode) ||
          response.statusCode == 404;
    } catch (e) {
      _log('Body metric delete sync error: $e');
      return false;
    }
  }

  Future<bool> deleteHydration(int serverId) async {
    try {
      final response = await _requestJson(
        method: 'DELETE',
        path: '/hydration/$serverId',
      );
      return _isSuccessStatus(response.statusCode) ||
          response.statusCode == 404;
    } catch (e) {
      _log('Hydration delete sync error: $e');
      return false;
    }
  }

  Future<bool> deleteDailyMetrics(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    try {
      final response = await _requestJson(
        method: 'DELETE',
        path: '/daily-metrics?date=${normalized.millisecondsSinceEpoch}',
      );
      return _isSuccessStatus(response.statusCode) ||
          response.statusCode == 404;
    } catch (e) {
      _log('Daily metrics delete sync error: $e');
      return false;
    }
  }

  Future<bool> deleteMeal(int serverId) async {
    try {
      final response = await _requestJson(
        method: 'DELETE',
        path: '/meals/$serverId',
      );
      return _isSuccessStatus(response.statusCode) ||
          response.statusCode == 404;
    } catch (e) {
      _log('Meal delete sync error: $e');
      return false;
    }
  }

  Future<bool> deleteCheckin(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    try {
      final response = await _requestJson(
        method: 'DELETE',
        path: '/checkins?date=${normalized.millisecondsSinceEpoch}',
      );
      return _isSuccessStatus(response.statusCode) ||
          response.statusCode == 404;
    } catch (e) {
      _log('Daily checkin delete sync error: $e');
      return false;
    }
  }

  Future<bool> deleteScreenTime(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    try {
      final response = await _requestJson(
        method: 'DELETE',
        path: '/screen-time?date=${normalized.millisecondsSinceEpoch}',
      );
      return _isSuccessStatus(response.statusCode) ||
          response.statusCode == 404;
    } catch (e) {
      _log('Screen time delete sync error: $e');
      return false;
    }
  }

  Future<bool> deleteDayRating(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    try {
      final response = await _requestJson(
        method: 'DELETE',
        path: '/rating?date=${normalized.millisecondsSinceEpoch}',
      );
      return _isSuccessStatus(response.statusCode) ||
          response.statusCode == 404;
    } catch (e) {
      _log('Day rating delete sync error: $e');
      return false;
    }
  }

  Future<bool> deleteRemoteImage(String remoteUrl) async {
    try {
      final response = await _requestJson(
        method: 'DELETE',
        path: remoteUrl,
      );
      return _isSuccessStatus(response.statusCode) ||
          response.statusCode == 404;
    } catch (e) {
      _log('Remote image delete sync error: $e');
      return false;
    }
  }

  /// Upload an image for a meal.
  Future<bool> uploadImage(int mealId, File imageFile) async {
    return (await uploadImageWithRemoteUrl(mealId, imageFile)) != null;
  }

  Future<String?> uploadImageWithRemoteUrl(int mealId, File imageFile) async {
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

      final multipartBody = StringBuffer();
      multipartBody.write('--$boundary\r\n');
      multipartBody.write(
        'Content-Disposition: form-data; name="mealId"\r\n\r\n',
      );
      multipartBody.write('$mealId\r\n');
      multipartBody.write('--$boundary\r\n');
      multipartBody.write(
        'Content-Disposition: form-data; name="image"; filename="$filename"\r\n',
      );
      multipartBody.write('Content-Type: image/jpeg\r\n\r\n');

      request.write(multipartBody.toString());
      request.write(bytes);
      request.write('\r\n--$boundary--\r\n');

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();

      final success = response.statusCode == 200 || response.statusCode == 201;
      _log(
        'Image upload ${success ? "success" : "failed"}: ${response.statusCode}',
      );
      if (!success) {
        return null;
      }

      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['url'] as String?;
    } catch (e) {
      _log('Image upload error: $e');
      return null;
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
