import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/meal.dart';
import '../models/sync_operation.dart';
import 'database_service.dart';
import 'sync_queue.dart';

/// Service for syncing meals to the backend server.
/// Handles both immediate sync and retry logic via sync_queue.
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
  
  /// Initialize the sync service with configuration.
  /// Should be called once at app startup.
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
  }
  
  /// Get the singleton instance.
  /// Throws if not initialized.
  static SyncService get instance {
    if (_instance == null) {
      throw StateError('SyncService not initialized. Call SyncService.init() first.');
    }
    return _instance!;
  }
  
  /// Start periodic sync (every 5 minutes by default).
  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(interval, (_) => syncPendingOperations());
    
    // Also sync on startup
    syncPendingOperations();
  }
  
  /// Stop periodic sync.
  void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }
  
  /// Sync a meal immediately.
  /// If it fails, the operation is queued for retry.
  Future<bool> syncMeal(Meal meal, OperationType operation) async {
    final operationType = operation;
    
    try {
      final client = HttpClient();
      final uri = Uri.parse('$baseUrl/meals');
      final request = await client.postUrl(uri);
      
      request.headers.set('X-API-Key', apiKey);
      request.headers.contentType = ContentType.json;
      
      final payload = meal.toMap();
      request.write(jsonEncode(payload));
      
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        // Queue for retry
        await _enqueueFailedSync(meal, operationType);
        return false;
      }
    } catch (e) {
      // Network error or other failure - queue for retry
      await _enqueueFailedSync(meal, operationType);
      return false;
    }
  }
  
  /// Sync all pending operations from the queue.
  Future<void> syncPendingOperations() async {
    if (_isSyncing) return;
    _isSyncing = true;
    
    try {
      final operations = await syncQueue.getPendingOperations();
      
      for (final op in operations) {
        if (op.entityType != 'meal') continue;
        
        final success = await _syncOperation(op);
        if (success) {
          await syncQueue.markCompleted(op.id);
        } else {
          await syncQueue.markFailed(op.id);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
  
  Future<bool> _syncOperation(SyncOperation op) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('$baseUrl/meals');
      final request = await client.postUrl(uri);
      
      request.headers.set('X-API-Key', apiKey);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(op.payload));
      
      final response = await request.close();
      client.close();
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> _enqueueFailedSync(Meal meal, OperationType operationType) async {
    final operation = SyncOperation(
      id: '${DateTime.now().millisecondsSinceEpoch}_${meal.id ?? 'new'}',
      entityType: 'meal',
      operationType: operationType,
      payload: meal.toMap(),
      createdAt: DateTime.now(),
    );
    
    await syncQueue.enqueue(operation);
  }
  
  /// Get meals from the backend for a specific date.
  /// Useful for Clanker to query what was eaten.
  Future<List<Meal>> getMealsForDate(DateTime date) async {
    try {
      final client = HttpClient();
      final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final uri = Uri.parse('$baseUrl/meals?date=$dateStr');
      final request = await client.getUrl(uri);
      
      request.headers.set('X-API-Key', apiKey);
      
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(body);
        return data.map((json) => Meal.fromMap(json)).toList();
      } else {
        throw Exception('Failed to fetch meals: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
  
  /// Check if backend is reachable.
  Future<bool> healthCheck() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final uri = Uri.parse('$baseUrl/health');
      final request = await client.getUrl(uri);
      
      final response = await request.close();
      client.close();
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
