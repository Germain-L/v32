class ScreenTimeApp {
  final int? id;
  final int? serverId;
  final int screenTimeId;
  final String packageName;
  final String appName;
  final int durationMs;

  ScreenTimeApp({
    this.id,
    this.serverId,
    required this.screenTimeId,
    required this.packageName,
    required this.appName,
    required this.durationMs,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'screen_time_id': screenTimeId,
      'package_name': packageName,
      'app_name': appName,
      'duration_ms': durationMs,
    };
  }

  factory ScreenTimeApp.fromMap(Map<String, dynamic> map) {
    return ScreenTimeApp(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      screenTimeId: map['screen_time_id'] as int,
      packageName: map['package_name'] as String,
      appName: map['app_name'] as String,
      durationMs: map['duration_ms'] as int,
    );
  }

  factory ScreenTimeApp.fromJson(Map<String, dynamic> json) {
    return ScreenTimeApp(
      serverId: json['id'] as int?,
      screenTimeId: json['screenTimeId'] as int,
      packageName: json['packageName'] as String,
      appName: json['appName'] as String,
      durationMs: json['durationMs'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (serverId != null) 'id': serverId,
      'screenTimeId': screenTimeId,
      'packageName': packageName,
      'appName': appName,
      'durationMs': durationMs,
    };
  }

  ScreenTimeApp copyWith({
    int? id,
    int? serverId,
    int? screenTimeId,
    String? packageName,
    String? appName,
    int? durationMs,
  }) {
    return ScreenTimeApp(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      screenTimeId: screenTimeId ?? this.screenTimeId,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      durationMs: durationMs ?? this.durationMs,
    );
  }
}

class ScreenTime {
  final int? id;
  final int? serverId;
  final DateTime date;
  final int totalMs;
  final int? pickups;
  final DateTime createdAt;
  final bool pendingSync;
  final List<ScreenTimeApp> apps;

  ScreenTime({
    this.id,
    this.serverId,
    required this.date,
    required this.totalMs,
    this.pickups,
    DateTime? createdAt,
    this.pendingSync = false,
    this.apps = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'date': date.millisecondsSinceEpoch,
      'total_ms': totalMs,
      'pickups': pickups,
      'created_at': createdAt.millisecondsSinceEpoch,
      'pending_sync': pendingSync ? 1 : 0,
    };
  }

  factory ScreenTime.fromMap(Map<String, dynamic> map) {
    return ScreenTime(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      totalMs: map['total_ms'] as int,
      pickups: map['pickups'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int)
          : DateTime.now(),
      pendingSync: (map['pending_sync'] as int?) == 1,
    );
  }

  factory ScreenTime.fromJson(Map<String, dynamic> json) {
    final apps = (json['apps'] as List<dynamic>?)
            ?.map((e) => ScreenTimeApp.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return ScreenTime(
      serverId: json['id'] as int?,
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      totalMs: json['totalMs'] as int,
      pickups: json['pickups'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int)
          : DateTime.now(),
      pendingSync: false,
      apps: apps,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (serverId != null) 'id': serverId,
      'date': date.millisecondsSinceEpoch,
      'totalMs': totalMs,
      'pickups': pickups,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'apps': apps.map((e) => e.toJson()).toList(),
    };
  }

  static const _unset = Object();

  ScreenTime copyWith({
    int? id,
    int? serverId,
    DateTime? date,
    int? totalMs,
    int? pickups,
    DateTime? createdAt,
    bool? pendingSync,
    List<ScreenTimeApp>? apps,
  }) {
    return ScreenTime(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      date: date ?? this.date,
      totalMs: totalMs ?? this.totalMs,
      pickups: pickups ?? this.pickups,
      createdAt: createdAt ?? this.createdAt,
      pendingSync: pendingSync ?? this.pendingSync,
      apps: apps ?? this.apps,
    );
  }
}
