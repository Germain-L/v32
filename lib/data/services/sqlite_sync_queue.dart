import '../models/sync_operation.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import 'sync_queue.dart';

/// SQLite implementation of SyncQueue.
/// Stores pending sync operations in the local database.
class SQLiteSyncQueue implements SyncQueue {
  static const String _tableName = 'sync_queue';

  @override
  Future<void> enqueue(SyncOperation operation) async {
    final db = await DatabaseService.database;
    await db.insert(
      _tableName,
      operation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<SyncOperation?> dequeue() async {
    final db = await DatabaseService.database;

    // Get oldest operation (FIFO)
    final results = await db.query(
      _tableName,
      orderBy: 'created_at ASC',
      limit: 1,
    );

    if (results.isEmpty) return null;

    final operation = SyncOperation.fromMap(results.first);

    // Remove from queue
    await db.delete(_tableName, where: 'id = ?', whereArgs: [operation.id]);

    return operation;
  }

  @override
  Future<void> markFailed(String operationId) async {
    final db = await DatabaseService.database;
    await db.rawUpdate(
      'UPDATE $_tableName SET retry_count = retry_count + 1 WHERE id = ?',
      [operationId],
    );
  }

  @override
  Future<void> markCompleted(String operationId) async {
    final db = await DatabaseService.database;
    await db.delete(_tableName, where: 'id = ?', whereArgs: [operationId]);
  }

  @override
  Future<List<SyncOperation>> getPendingOperations() async {
    final db = await DatabaseService.database;
    final results = await db.query(_tableName, orderBy: 'created_at ASC');

    return results.map((map) => SyncOperation.fromMap(map)).toList();
  }
}
