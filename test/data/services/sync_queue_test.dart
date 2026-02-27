import 'package:flutter_test/flutter_test.dart';
import 'package:v32/data/models/sync_operation.dart';
import 'package:v32/data/services/sync_queue.dart';

void main() {
  group('SyncQueue', () {
    test('interface can be implemented', () {
      expect(() => _TestSyncQueue(), returnsNormally);
    });

    test('enqueue adds operation to queue', () async {
      final queue = _TestSyncQueue();
      final op = SyncOperation(
        id: '1',
        entityType: 'meal',
        operationType: OperationType.create,
        payload: {},
        createdAt: DateTime.now(),
      );

      await queue.enqueue(op);

      final pending = await queue.getPendingOperations();
      expect(pending.length, 1);
    });

    test('dequeue removes and returns oldest operation', () async {
      final queue = _TestSyncQueue();
      final op = SyncOperation(
        id: '1',
        entityType: 'meal',
        operationType: OperationType.create,
        payload: {},
        createdAt: DateTime.now(),
      );
      await queue.enqueue(op);

      final dequeued = await queue.dequeue();

      expect(dequeued?.id, '1');
      expect((await queue.getPendingOperations()).length, 0);
    });

    test('markFailed increments retry count', () async {
      final queue = _TestSyncQueue();
      final op = SyncOperation(
        id: '1',
        entityType: 'meal',
        operationType: OperationType.create,
        payload: {},
        createdAt: DateTime.now(),
        retryCount: 0,
      );
      await queue.enqueue(op);

      await queue.markFailed('1');

      final pending = await queue.getPendingOperations();
      expect(pending.first.retryCount, 1);
    });

    test('markCompleted removes operation', () async {
      final queue = _TestSyncQueue();
      final op = SyncOperation(
        id: '1',
        entityType: 'meal',
        operationType: OperationType.create,
        payload: {},
        createdAt: DateTime.now(),
      );
      await queue.enqueue(op);

      await queue.markCompleted('1');

      final pending = await queue.getPendingOperations();
      expect(pending.length, 0);
    });

    test('getPendingOperations returns all pending ops', () async {
      final queue = _TestSyncQueue();

      await queue.enqueue(
        SyncOperation(
          id: '1',
          entityType: 'meal',
          operationType: OperationType.create,
          payload: {},
          createdAt: DateTime.now(),
        ),
      );
      await queue.enqueue(
        SyncOperation(
          id: '2',
          entityType: 'meal',
          operationType: OperationType.update,
          payload: {},
          createdAt: DateTime.now(),
        ),
      );

      final pending = await queue.getPendingOperations();
      expect(pending.length, 2);
    });
  });
}

class _TestSyncQueue implements SyncQueue {
  final List<SyncOperation> _operations = [];

  @override
  Future<void> enqueue(SyncOperation operation) async {
    _operations.add(operation);
  }

  @override
  Future<SyncOperation?> dequeue() async {
    if (_operations.isEmpty) return null;
    return _operations.removeAt(0);
  }

  @override
  Future<void> markFailed(String operationId) async {
    final index = _operations.indexWhere((op) => op.id == operationId);
    if (index >= 0) {
      _operations[index] = _operations[index].copyWith(
        retryCount: _operations[index].retryCount + 1,
      );
    }
  }

  @override
  Future<void> markCompleted(String operationId) async {
    _operations.removeWhere((op) => op.id == operationId);
  }

  @override
  Future<List<SyncOperation>> getPendingOperations() async =>
      List.unmodifiable(_operations);
}
