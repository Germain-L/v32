class Hydration {
  final int? id;
  final int? serverId;
  final DateTime date;
  final int amountMl;
  final DateTime createdAt;
  final bool pendingSync;

  Hydration({
    this.id,
    this.serverId,
    required this.date,
    required this.amountMl,
    DateTime? createdAt,
    this.pendingSync = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'date': date.millisecondsSinceEpoch,
      'amount_ml': amountMl,
      'created_at': createdAt.millisecondsSinceEpoch,
      'pending_sync': pendingSync ? 1 : 0,
    };
  }

  factory Hydration.fromMap(Map<String, dynamic> map) {
    return Hydration(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      amountMl: map['amount_ml'] as int,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
      pendingSync: (map['pending_sync'] as int?) == 1,
    );
  }

  factory Hydration.fromJson(Map<String, dynamic> json) {
    return Hydration(
      serverId: json['id'] as int?,
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      amountMl: json['amountMl'] as int,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : DateTime.now(),
      pendingSync: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (serverId != null) 'id': serverId,
      'date': date.millisecondsSinceEpoch,
      'amountMl': amountMl,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  static const _unset = Object();

  Hydration copyWith({
    int? id,
    int? serverId,
    DateTime? date,
    int? amountMl,
    DateTime? createdAt,
    bool? pendingSync,
  }) {
    return Hydration(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      date: date ?? this.date,
      amountMl: amountMl ?? this.amountMl,
      createdAt: createdAt ?? this.createdAt,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }
}
