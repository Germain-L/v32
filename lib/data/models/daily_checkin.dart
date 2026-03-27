class DailyCheckin {
  final int? id;
  final int? serverId;
  final DateTime date; // epoch day (date only, no time)
  final int? mood;
  final int? energy;
  final int? focus;
  final int? stress;
  final double? sleepHours;
  final int? sleepQuality;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pendingSync;

  DailyCheckin({
    this.id,
    this.serverId,
    required this.date,
    this.mood,
    this.energy,
    this.focus,
    this.stress,
    this.sleepHours,
    this.sleepQuality,
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
      'mood': mood,
      'energy': energy,
      'focus': focus,
      'stress': stress,
      'sleep_hours': sleepHours,
      'sleep_quality': sleepQuality,
      'notes': notes,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'pending_sync': pendingSync ? 1 : 0,
    };
  }

  factory DailyCheckin.fromMap(Map<String, dynamic> map) {
    return DailyCheckin(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      mood: map['mood'] as int?,
      energy: map['energy'] as int?,
      focus: map['focus'] as int?,
      stress: map['stress'] as int?,
      sleepHours: map['sleep_hours'] as double?,
      sleepQuality: map['sleep_quality'] as int?,
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

  factory DailyCheckin.fromJson(Map<String, dynamic> json) {
    return DailyCheckin(
      serverId: json['id'] as int?,
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      mood: json['mood'] as int?,
      energy: json['energy'] as int?,
      focus: json['focus'] as int?,
      stress: json['stress'] as int?,
      sleepHours: json['sleepHours'] as double?,
      sleepQuality: json['sleepQuality'] as int?,
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
      'mood': mood,
      'energy': energy,
      'focus': focus,
      'stress': stress,
      'sleepHours': sleepHours,
      'sleepQuality': sleepQuality,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  static const _unset = Object();

  DailyCheckin copyWith({
    int? id,
    int? serverId,
    DateTime? date,
    int? mood,
    int? energy,
    int? focus,
    int? stress,
    double? sleepHours,
    int? sleepQuality,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pendingSync,
  }) {
    return DailyCheckin(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      focus: focus ?? this.focus,
      stress: stress ?? this.stress,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }
}
