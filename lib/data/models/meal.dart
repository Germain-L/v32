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
  final MealSlot slot;
  final DateTime date;
  final String? description;
  final String? imagePath;

  Meal({
    this.id,
    required this.slot,
    required this.date,
    this.description,
    this.imagePath,
  });

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'slot': slot.name,
      'date': date.millisecondsSinceEpoch,
      'description': description,
      'imagePath': imagePath,
    };
  }

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: map['id'] as int?,
      slot: MealSlot.values.byName(map['slot'] as String),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      description: map['description'] as String?,
      imagePath: map['imagePath'] as String?,
    );
  }

  static const _unset = Object();

  Meal copyWith({
    int? id,
    MealSlot? slot,
    DateTime? date,
    String? description,
    Object? imagePath = _unset,
  }) {
    return Meal(
      id: id ?? this.id,
      slot: slot ?? this.slot,
      date: date ?? this.date,
      description: description ?? this.description,
      imagePath: imagePath == _unset ? this.imagePath : imagePath as String?,
    );
  }
}
