import '../../gen_l10n/app_localizations.dart';

enum MealSlot { breakfast, lunch, afternoonSnack, dinner }

extension MealSlotExtension on MealSlot {
  String get displayName {
    switch (this) {
      case MealSlot.breakfast:
        return 'Breakfast';
      case MealSlot.lunch:
        return 'Lunch';
      case MealSlot.afternoonSnack:
        return 'Afternoon Snack';
      case MealSlot.dinner:
        return 'Dinner';
    }
  }

  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case MealSlot.breakfast:
        return l10n.breakfast;
      case MealSlot.lunch:
        return l10n.lunch;
      case MealSlot.afternoonSnack:
        return l10n.afternoonSnack;
      case MealSlot.dinner:
        return l10n.dinner;
    }
  }
}

class Meal {
  final int? id;
  final int? serverId;
  final MealSlot slot;
  final DateTime date;
  final String? description;
  final String? imagePath;
  final DateTime updatedAt;
  final bool pendingSync;

  Meal({
    this.id,
    this.serverId,
    required this.slot,
    required this.date,
    this.description,
    this.imagePath,
    DateTime? updatedAt,
    this.pendingSync = false,
  }) : updatedAt = updatedAt ?? DateTime.now();

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'slot': slot.name,
      'date': date.millisecondsSinceEpoch,
      'description': description,
      'imagePath': imagePath,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'pending_sync': pendingSync ? 1 : 0,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      slot: MealSlot.values.byName(map['slot'] as String),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      description: map['description'] as String?,
      imagePath: map['imagePath'] as String?,
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int)
          : DateTime.now(),
      pendingSync: (map['pending_sync'] as int?) == 1,
    );
  }

  /// Create from server JSON response
  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      serverId: json['id'] as int?,
      slot: MealSlot.values.byName(json['slot'] as String),
      date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      description: json['description'] as String?,
      imagePath: json['imagePath'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['updated_at'] as int)
          : DateTime.now(),
      pendingSync: false,
    );
  }

  /// Convert to JSON for server requests
  Map<String, dynamic> toJson() {
    return {
      if (serverId != null) 'id': serverId,
      'slot': slot.name,
      'date': date.millisecondsSinceEpoch,
      'description': description,
      'imagePath': imagePath,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  static const _unset = Object();

  Meal copyWith({
    int? id,
    int? serverId,
    MealSlot? slot,
    DateTime? date,
    String? description,
    Object? imagePath = _unset,
    DateTime? updatedAt,
    bool? pendingSync,
  }) {
    return Meal(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      slot: slot ?? this.slot,
      date: date ?? this.date,
      description: description ?? this.description,
      imagePath: identical(imagePath, _unset)
          ? this.imagePath
          : imagePath as String?,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }
}
