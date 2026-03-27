class BodyMetric {
  final int? id;
  final int? serverId;
  final DateTime date;
  final double? weight;
  final double? bodyFat;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pendingSync;

  BodyMetric({
    this.id,
    this.serverId,
    required this.date,
    this.weight,
    this.bodyFat,
    this.notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.pendingSync = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'date': date.millisecondsSinceEpoch,
      'weight': weight,
      'body_fat': bodyFat,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'pending_sync': pendingSync ? 1 : 0,
    };
  }

  factory BodyMetric.fromMap(Map<String, dynamic> map) {
    return BodyMetric(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      weight: map['weight'] as double?,
      bodyFat: map['body_fat'] as double?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : DateTime.now(),
      pendingSync: (map['pending_sync'] as int?) == 1,
    );
  }

  factory BodyMetric.fromJson(Map<String, dynamic> json) {
    return BodyMetric(
      serverId: json['id'] as int?,
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      weight: json['weight'] as double?,
      bodyFat: json['bodyFat'] as double?,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int)
          : DateTime.now(),
      pendingSync: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (serverId != null) 'id': serverId,
      'date': date.millisecondsSinceEpoch,
      'weight': weight,
      'bodyFat': bodyFat,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  static const _unset = Object();

  BodyMetric copyWith({
    int? id,
    int? serverId,
    DateTime? date,
    double? weight,
    double? bodyFat,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pendingSync,
  }) {
    return BodyMetric(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      bodyFat: bodyFat ?? this.bodyFat,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }
}
