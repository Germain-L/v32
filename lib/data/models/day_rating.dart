class DayRating {
  final DateTime date;
  final int score;

  DayRating({required this.date, required this.score});

  Map<String, dynamic> toMap() {
    return {'date': date.millisecondsSinceEpoch, 'score': score};
  }

  factory DayRating.fromMap(Map<String, dynamic> map) {
    return DayRating(
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      score: map['score'] as int,
    );
  }
}
