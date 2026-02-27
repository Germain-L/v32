enum OperationType { create, update, delete }

class SyncOperation {
  final String id;
  final String entityType; // 'meal', 'daily_metrics', 'day_rating'
  final OperationType operationType;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  SyncOperation({
    required this.id,
    required this.entityType,
    required this.operationType,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'operation_type': operationType.name,
      'payload': payload,
      'created_at': createdAt.millisecondsSinceEpoch,
      'retry_count': retryCount,
    };
  }

  factory SyncOperation.fromMap(Map<String, dynamic> map) {
    return SyncOperation(
      id: map['id'] as String,
      entityType: map['entity_type'] as String,
      operationType: OperationType.values.byName(
        map['operation_type'] as String,
      ),
      payload: Map<String, dynamic>.from(map['payload'] as Map),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      retryCount: map['retry_count'] as int,
    );
  }

  SyncOperation copyWith({int? retryCount}) {
    return SyncOperation(
      id: id,
      entityType: entityType,
      operationType: operationType,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
