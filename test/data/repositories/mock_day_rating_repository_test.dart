import 'package:flutter_test/flutter_test.dart';
import 'package:v32/data/repositories/mock_day_rating_repository.dart';

void main() {
  group('MockDayRatingRepository', () {
    late MockDayRatingRepository repository;

    setUp(() {
      repository = MockDayRatingRepository();
    });

    tearDown(() {
      repository.clear();
    });

    test('implements DayRatingRepository', () {
      expect(repository, isA<MockDayRatingRepository>());
    });

    test('saveRating stores rating', () async {
      await repository.saveRating(DateTime(2024, 1, 15), 4);

      final retrieved = await repository.getRatingForDate(
        DateTime(2024, 1, 15),
      );
      expect(retrieved, 4);
    });

    test('getRatingForDate returns null for non-existent', () async {
      final result = await repository.getRatingForDate(DateTime(2024, 1, 15));
      expect(result, isNull);
    });

    test('getRatingsForMonth returns all ratings', () async {
      await repository.saveRating(DateTime(2024, 1, 15), 4);
      await repository.saveRating(DateTime(2024, 1, 16), 5);

      final ratings = await repository.getRatingsForMonth(2024, 1);
      expect(ratings.length, 2);
    });
  });
}
