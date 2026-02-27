import '../models/sync_operation.dart';

/// Queue for pending sync operations that need to be retried.
/// Used when backend calls fail and need to be retried later.
abstract class SyncQueue {
  /// Add an operation to the queue
  Future<void> enqueue(SyncOperation operation);

  /// Get and remove the oldest pending operation (FIFO)
  Future<SyncOperation?> dequeue();

  /// Mark an operation as failed (increments retry count)
  Future<void> markFailed(String operationId);

  /// Mark an operation as completed (removes from queue)
  Future<void> markCompleted(String operationId);

  /// Get all pending operations without removing them
  Future<List<SyncOperation>> getPendingOperations();
}
