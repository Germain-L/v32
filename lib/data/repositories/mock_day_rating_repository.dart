import 'day_rating_repository_interface.dart';

/// In-memory implementation of DayRatingRepository for unit testing.
class MockDayRatingRepository implements DayRatingRepository {
  final Map<String, int> _ratings = {};

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<void> saveRating(DateTime date, int score) async {
    final normalized = DateTime(date.year, date.month, date.day);
    _ratings[_dateKey(normalized)] = score;
  }

  @override
  Future<int?> getRatingForDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    return _ratings[_dateKey(normalized)];
  }

  @override
  Future<Map<String, int>> getRatingsForMonth(int year, int month) async {
    return Map.unmodifiable(_ratings);
  }

  /// Clear all data (useful in tests)
  void clear() {
    _ratings.clear();
  }
}
