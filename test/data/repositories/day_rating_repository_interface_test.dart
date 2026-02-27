import 'package:flutter_test/flutter_test.dart';
import 'package:v32/data/repositories/day_rating_repository_interface.dart';

void main() {
  group('DayRatingRepository Interface', () {
    test('interface can be implemented', () {
      expect(() => _TestDayRatingRepository(), returnsNormally);
    });

    test('saveRating accepts date and score', () async {
      final repo = _TestDayRatingRepository();

      await expectLater(repo.saveRating(DateTime.now(), 3), completes);
    });

    test('getRatingForDate returns Future<int?>', () async {
      final repo = _TestDayRatingRepository();

      final result = await repo.getRatingForDate(DateTime.now());

      expect(result, isNull);
    });

    test('getRatingsForMonth returns Map<String, int>', () async {
      final repo = _TestDayRatingRepository();

      final result = await repo.getRatingsForMonth(2024, 1);

      expect(result, isA<Map<String, int>>());
    });
  });
}

class _TestDayRatingRepository implements DayRatingRepository {
  @override
  Future<void> saveRating(DateTime date, int score) async {}

  @override
  Future<int?> getRatingForDate(DateTime date) async => null;

  @override
  Future<Map<String, int>> getRatingsForMonth(int year, int month) async => {};
}
