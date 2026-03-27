enum WorkoutType { run, cycle, gym, swim, walk, hiking, other }

extension WorkoutTypeExtension on WorkoutType {
  String get displayName {
    switch (this) {
      case WorkoutType.run:
        return 'Run';
      case WorkoutType.cycle:
        return 'Cycle';
      case WorkoutType.gym:
        return 'Gym';
      case WorkoutType.swim:
        return 'Swim';
      case WorkoutType.walk:
        return 'Walk';
      case WorkoutType.hiking:
        return 'Hiking';
      case WorkoutType.other:
        return 'Other';
    }
  }
}

class Workout {
  final int? id;
  final int? serverId;
  final WorkoutType type;
  final DateTime date;
  final int? durationSeconds;
  final double? distanceMeters;
  final int? calories;
  final int? heartRateAvg;
  final int? heartRateMax;
  final String? notes;
  final String source;
  final String? sourceId;
  final String? stravaData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pendingSync;

  Workout({
    this.id,
    this.serverId,
    required this.type,
    required this.date,
    this.durationSeconds,
    this.distanceMeters,
    this.calories,
    this.heartRateAvg,
    this.heartRateMax,
    this.notes,
    this.source = 'manual',
    this.sourceId,
    this.stravaData,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.pendingSync = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'type': type.name,
      'date': date.millisecondsSinceEpoch,
      'duration_seconds': durationSeconds,
      'distance_meters': distanceMeters,
      'calories': calories,
      'heart_rate_avg': heartRateAvg,
      'heart_rate_max': heartRateMax,
      'notes': notes,
      'source': source,
      'source_id': sourceId,
      'strava_data': stravaData,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'pending_sync': pendingSync ? 1 : 0,
    };
  }

  factory Workout.fromMap(Map<String, dynamic> map) {
    return Workout(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      type: WorkoutType.values.byName(map['type'] as String),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      durationSeconds: map['duration_seconds'] as int?,
      distanceMeters: map['distance_meters'] as double?,
      calories: map['calories'] as int?,
      heartRateAvg: map['heart_rate_avg'] as int?,
      heartRateMax: map['heart_rate_max'] as int?,
      notes: map['notes'] as String?,
      source: map['source'] as String? ?? 'manual',
      sourceId: map['source_id'] as String?,
      stravaData: map['strava_data'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : DateTime.now(),
      pendingSync: (map['pending_sync'] as int?) == 1,
    );
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      serverId: json['id'] as int?,
      type: WorkoutType.values.byName(json['type'] as String),
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      durationSeconds: json['durationSeconds'] as int?,
      distanceMeters: json['distanceMeters'] as double?,
      calories: json['calories'] as int?,
      heartRateAvg: json['heartRateAvg'] as int?,
      heartRateMax: json['heartRateMax'] as int?,
      notes: json['notes'] as String?,
      source: json['source'] as String? ?? 'manual',
      sourceId: json['sourceId'] as String?,
      stravaData: json['stravaData'] as String?,
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
      'type': type.name,
      'date': date.millisecondsSinceEpoch,
      'durationSeconds': durationSeconds,
      'distanceMeters': distanceMeters,
      'calories': calories,
      'heartRateAvg': heartRateAvg,
      'heartRateMax': heartRateMax,
      'notes': notes,
      'source': source,
      'sourceId': sourceId,
      'stravaData': stravaData,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  static const _unset = Object();

  Workout copyWith({
    int? id,
    int? serverId,
    WorkoutType? type,
    DateTime? date,
    int? durationSeconds,
    double? distanceMeters,
    int? calories,
    int? heartRateAvg,
    int? heartRateMax,
    String? notes,
    String? source,
    String? sourceId,
    Object? stravaData = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pendingSync,
  }) {
    return Workout(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      type: type ?? this.type,
      date: date ?? this.date,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      calories: calories ?? this.calories,
      heartRateAvg: heartRateAvg ?? this.heartRateAvg,
      heartRateMax: heartRateMax ?? this.heartRateMax,
      notes: notes ?? this.notes,
      source: source ?? this.source,
      sourceId: sourceId ?? this.sourceId,
      stravaData: identical(stravaData, _unset)
          ? this.stravaData
          : stravaData as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }
}
