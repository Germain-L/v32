import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/meal.dart';
import '../models/meal_image.dart';
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
  }
  
  static SyncService get instance {
    if (_instance == null) {
      throw StateError('SyncService not initialized. Call SyncService.init() first.');
    }
    return _instance!;
  }
  
  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(interval, (_) => syncPendingOperations());
    syncPendingOperations();
  }
  
  void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }
  
  /// Sync a meal to the backend.
  Future<bool> syncMeal(Meal meal, OperationType operation) async {
    try {
      final client = HttpClient();
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
      
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(body);
        final serverMealId = responseData['id'];
        
        // Upload images for this meal
        if (meal.images.isNotEmpty && serverMealId != null) {
          for (final image in meal.images) {
            await uploadImage(serverMealId, File(image.imagePath));
          }
        }
        
        return true;
      } else {
        await _enqueueFailedSync(meal, operation);
        return false;
      }
    } catch (e) {
      await _enqueueFailedSync(meal, operation);
      return false;
    }
  }
  
  /// Upload an image for a meal.
  Future<bool> uploadImage(int mealId, File imageFile) async {
    try {
      final client = HttpClient();
      final uri = Uri.parse('$baseUrl/upload');
      final request = await client.postUrl(uri);
      
      request.headers.set('X-API-Key', apiKey);
      
      // Multipart form data
      final boundary = '----ClankerBoundary${DateTime.now().millisecondsSinceEpoch}';
      request.headers.contentType = ContentType.parse('multipart/form-data; boundary=$boundary');
      
      final bytes = await imageFile.readAsBytes();
      final filename = imageFile.path.split('/').last;
      
      final body = StringBuffer();
      body.write('--$boundary\r\n');
      body.write('Content-Disposition: form-data; name="mealId"\r\n\r\n');
      body.write('$mealId\r\n');
      body.write('--$boundary\r\n');
      body.write('Content-Disposition: form-data; name="image"; filename="$filename"\r\n');
      body.write('Content-Type: image/jpeg\r\n\r\n');
      
      request.write(body.toString());
      request.write(bytes);
      request.write('\r\n--$boundary--\r\n');
      
      final response = await request.close();
      client.close();
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }
  
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
      final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
