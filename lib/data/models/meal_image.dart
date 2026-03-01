class MealImage {
  final int? id;
  final int mealId;
  final String imagePath;
  final DateTime createdAt;

  MealImage({
    this.id,
    required this.mealId,
    required this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mealId': mealId,
      'imagePath': imagePath,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory MealImage.fromMap(Map<String, dynamic> map) {
    return MealImage(
      id: map['id'] as int?,
      mealId: map['mealId'] as int,
      imagePath: map['imagePath'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
    );
  }
}
