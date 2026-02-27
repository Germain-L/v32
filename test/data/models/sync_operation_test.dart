import 'package:flutter_test/flutter_test.dart';
import 'package:v32/data/models/sync_operation.dart';

void main() {
  group('SyncOperation', () {
    test('can be created with required fields', () {
      final op = SyncOperation(
        id: 'test-1',
        entityType: 'meal',
        operationType: OperationType.create,
        payload: {'id': 1, 'slot': 'breakfast'},
        createdAt: DateTime(2024, 1, 15, 10, 30),
        retryCount: 0,
      );

      expect(op.id, 'test-1');
      expect(op.entityType, 'meal');
      expect(op.operationType, OperationType.create);
    });

    test('can convert to and from map', () {
      final op = SyncOperation(
        id: 'test-1',
        entityType: 'meal',
        operationType: OperationType.create,
        payload: {'id': 1, 'slot': 'breakfast'},
        createdAt: DateTime(2024, 1, 15, 10, 30),
        retryCount: 2,
      );

      final map = op.toMap();
      final restored = SyncOperation.fromMap(map);

      expect(restored.id, op.id);
      expect(restored.retryCount, op.retryCount);
    });

    test('copyWith creates modified copy', () {
      final op = SyncOperation(
        id: 'test-1',
        entityType: 'meal',
        operationType: OperationType.create,
        payload: {},
        createdAt: DateTime.now(),
        retryCount: 0,
      );

      final updated = op.copyWith(retryCount: 1);

      expect(updated.id, op.id);
      expect(updated.retryCount, 1);
    });
  });
}
