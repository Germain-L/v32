/// Abstract interface for day rating repository operations.
abstract class DayRatingRepository {
  /// Save a rating score for a date (1-5 scale)
  Future<void> saveRating(DateTime date, int score);

  /// Get rating for a specific date
  Future<int?> getRatingForDate(DateTime date);

  /// Get all ratings for a month, keyed by date string (YYYY-MM-DD)
  Future<Map<String, int>> getRatingsForMonth(int year, int month);
}
