import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import '../models/meal.dart';
import '../models/sync_operation.dart';
import 'database_service.dart';
import 'sync_queue.dart';

/// Service for syncing meals and images to the backend server.
class SyncService {
  static SyncService? _instance;

  final String baseUrl;
  final String apiKey;
  final SyncQueue syncQueue;

  bool _isSyncing = false;
  Timer? _periodicSyncTimer;

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

  static void _log(String message) {
    dev.log('[SYNC] $message', name: 'v32');
  }

  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(
      interval,
      (_) => syncPendingOperations(),
    );
    _log('Started periodic sync (every ${interval.inMinutes} minutes)');
    syncPendingOperations();
  }

  void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
    _log('Stopped periodic sync');
  }

  /// Sync a meal to the backend.
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

        // Upload image for this meal if exists
        if (meal.hasImage && serverMealId != null) {
          _log('Uploading image for meal...');
          await uploadImage(serverMealId, File(meal.imagePath!));
        }

        return true;
      } else {
        _log('Sync failed: ${response.statusCode}');
        await _enqueueFailedSync(meal, operation);
        return false;
      }
    } catch (e) {
      _log('Sync error: $e');
      await _enqueueFailedSync(meal, operation);
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

  Future<void> syncPendingOperations() async {
    if (_isSyncing) {
      _log('Sync already in progress, skipping');
      return;
    }
    _isSyncing = true;

    try {
      final operations = await syncQueue.getPendingOperations();
      _log('Found ${operations.length} pending operations');

      for (final op in operations) {
        if (op.entityType != 'meal') continue;

        final success = await _syncOperation(op);
        if (success) {
          await syncQueue.markCompleted(op.id);
          _log('Operation ${op.id} completed');
        } else {
          await syncQueue.markFailed(op.id);
          _log('Operation ${op.id} failed');
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<bool> _syncOperation(SyncOperation op) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);
      final uri = Uri.parse('$baseUrl/meals');
      final request = await client.postUrl(uri);

      request.headers.set('X-API-Key', apiKey);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(op.payload));

      final response = await request.close();
      client.close();

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      _log('Sync operation error: $e');
      return false;
    }
  }

  Future<void> _enqueueFailedSync(
    Meal meal,
    OperationType operationType,
  ) async {
    _log('Enqueueing failed sync for later retry');

    final operation = SyncOperation(
      id: '${DateTime.now().millisecondsSinceEpoch}_${meal.id ?? 'new'}',
      entityType: 'meal',
      operationType: operationType,
      payload: {
        'slot': meal.slot.name,
        'date': meal.date.millisecondsSinceEpoch,
        'description': meal.description,
      },
      createdAt: DateTime.now(),
    );

    await syncQueue.enqueue(operation);
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
      return healthy;
    } catch (e) {
      _log('Health check failed: $e');
      return false;
    }
  }
}
