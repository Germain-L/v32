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

  Meal copyWith({
    int? id,
    MealSlot? slot,
    DateTime? date,
    String? description,
    String? imagePath,
  }) {
    return Meal(
      id: id ?? this.id,
      slot: slot ?? this.slot,
      date: date ?? this.date,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
