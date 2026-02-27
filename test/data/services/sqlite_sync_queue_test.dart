import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:v32/data/models/sync_operation.dart';
import 'package:v32/data/services/database_service.dart';
import 'package:v32/data/services/sqlite_sync_queue.dart';

void main() {
  group('SQLiteSyncQueue', () {
    late SQLiteSyncQueue queue;

    setUp(() async {
      // Use FFI for testing
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      await DatabaseService.useInMemoryDatabaseForTesting();
      queue = SQLiteSyncQueue();
    });

    tearDown(() async {
      await DatabaseService.resetForTesting();
    });

    test('can be instantiated', () {
      expect(queue, isA<SQLiteSyncQueue>());
    });

    test('enqueue stores operation', () async {
      final op = SyncOperation(
        id: 'test-1',
        entityType: 'meal',
        operationType: OperationType.create,
        payload: {'data': 'test'},
        createdAt: DateTime.now(),
      );

      await queue.enqueue(op);

      final pending = await queue.getPendingOperations();
      expect(pending.length, 1);
      expect(pending.first.id, 'test-1');
    });

    test('dequeue returns FIFO order', () async {
      final op1 = SyncOperation(
        id: 'first',
        entityType: 'meal',
        operationType: OperationType.create,
        payload: {},
        createdAt: DateTime.now(),
      );
      final op2 = SyncOperation(
        id: 'second',
        entityType: 'meal',
        operationType: OperationType.create,
        payload: {},
        createdAt: DateTime.now().add(Duration(seconds: 1)),
      );

      await queue.enqueue(op1);
      await queue.enqueue(op2);

      final dequeued = await queue.dequeue();
      expect(dequeued?.id, 'first');
    });

    test('markCompleted removes operation', () async {
      final op = SyncOperation(
        id: 'test-1',
        entityType: 'meal',
        operationType: OperationType.create,
        payload: {},
        createdAt: DateTime.now(),
      );
      await queue.enqueue(op);

      await queue.markCompleted('test-1');

      final pending = await queue.getPendingOperations();
      expect(pending.length, 0);
    });

    test('markFailed increments retry count', () async {
      final op = SyncOperation(
        id: 'test-1',
        entityType: 'meal',
        operationType: OperationType.create,
        payload: {},
        createdAt: DateTime.now(),
        retryCount: 0,
      );
      await queue.enqueue(op);

      await queue.markFailed('test-1');

      final pending = await queue.getPendingOperations();
      expect(pending.first.retryCount, 1);
    });

    test('dequeue removes operation from queue', () async {
      final op = SyncOperation(
        id: 'test-1',
        entityType: 'meal',
        operationType: OperationType.create,
        payload: {},
        createdAt: DateTime.now(),
      );
      await queue.enqueue(op);

      await queue.dequeue();

      final pending = await queue.getPendingOperations();
      expect(pending.length, 0);
    });

    test('dequeue returns null when queue is empty', () async {
      final result = await queue.dequeue();
      expect(result, isNull);
    });
  });
}
