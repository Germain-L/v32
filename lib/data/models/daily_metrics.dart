class DailyMetrics {
  final DateTime date;
  final double? waterLiters;
  final bool? exerciseDone;
  final String? exerciseNote;

  DailyMetrics({
    required this.date,
    this.waterLiters,
    this.exerciseDone,
    this.exerciseNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.millisecondsSinceEpoch,
      'water_liters': waterLiters,
      'exercise_done': exerciseDone == null ? null : (exerciseDone! ? 1 : 0),
      'exercise_note': exerciseNote,
    };
  }

  factory DailyMetrics.fromMap(Map<String, dynamic> map) {
    return DailyMetrics(
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      waterLiters: (map['water_liters'] as num?)?.toDouble(),
      exerciseDone: map['exercise_done'] == null
          ? null
          : (map['exercise_done'] as int) == 1,
      exerciseNote: map['exercise_note'] as String?,
    );
  }
}
