import 'package:v32/data/repositories/day_rating_repository.dart';

class FakeDayRatingRepository extends DayRatingRepository {
  FakeDayRatingRepository({int? initialRating}) : _rating = initialRating;

  int? _rating;

  @override
  Future<void> saveRating(DateTime date, int score) async {
    _rating = score;
  }

  @override
  Future<int?> getRatingForDate(DateTime date) async {
    return _rating;
  }

  @override
  Future<Map<String, int>> getRatingsForMonth(int year, int month) async {
    return {};
  }
}
