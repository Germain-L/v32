import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:v32/data/repositories/local_day_rating_repository.dart';
import 'package:v32/data/repositories/day_rating_repository_interface.dart';
import 'package:v32/data/services/database_service.dart';

void main() {
  group('LocalDayRatingRepository Integration', () {
    late LocalDayRatingRepository repository;

    setUp(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      await DatabaseService.useInMemoryDatabaseForTesting();
      repository = LocalDayRatingRepository();
    });

    tearDown(() async {
      await DatabaseService.resetForTesting();
    });

    test('implements DayRatingRepository', () {
      expect(repository, isA<DayRatingRepository>());
    });

    test('saveRating and getRatingForDate work', () async {
      final date = DateTime(2024, 1, 15);

      await repository.saveRating(date, 4);

      final retrieved = await repository.getRatingForDate(date);
      expect(retrieved, 4);
    });

    test('getRatingsForMonth returns all ratings', () async {
      await repository.saveRating(DateTime(2024, 1, 15), 4);
      await repository.saveRating(DateTime(2024, 1, 16), 5);

      final ratings = await repository.getRatingsForMonth(2024, 1);
      expect(ratings.length, 2);
    });
  });
}
