import 'package:flutter_test/flutter_test.dart';
import 'package:v32/data/repositories/body_metric_repository_interface.dart';
import 'package:v32/data/repositories/daily_checkin_repository_interface.dart';
import 'package:v32/data/repositories/hydration_repository_interface.dart';
import 'package:v32/data/repositories/local_meal_repository.dart';
import 'package:v32/data/repositories/meal_repository_interface.dart';
import 'package:v32/data/repositories/mock_body_metric_repository.dart';
import 'package:v32/data/repositories/mock_daily_checkin_repository.dart';
import 'package:v32/data/repositories/mock_hydration_repository.dart';
import 'package:v32/data/repositories/mock_meal_repository.dart';
import 'package:v32/data/repositories/mock_screen_time_repository.dart';
import 'package:v32/data/repositories/mock_workout_repository.dart';
import 'package:v32/data/repositories/repository_factory.dart';
import 'package:v32/data/repositories/screen_time_repository_interface.dart';
import 'package:v32/data/repositories/workout_repository_interface.dart';

void main() {
  group('RepositoryFactory', () {
    test('can be instantiated', () {
      expect(() => RepositoryFactory(), returnsNormally);
    });

    group('MealRepository', () {
      test('getMealRepository returns default implementation', () {
        final factory = RepositoryFactory();

        final repo = factory.getMealRepository();

        expect(repo, isA<MealRepository>());
        expect(repo, isA<MealRepository>());
      });

      test('setMealRepository allows custom implementation', () {
        final factory = RepositoryFactory();
        final mock = MockMealRepository();

        factory.setMealRepository(mock);

        expect(factory.getMealRepository(), mock);
      });

      test('isSingleton returns same instance', () {
        final factory = RepositoryFactory();
        final repo1 = factory.getMealRepository();
        final repo2 = factory.getMealRepository();

        expect(identical(repo1, repo2), isTrue);
      });
    });

    group('WorkoutRepository', () {
      test('getWorkoutRepository returns default implementation', () {
        final factory = RepositoryFactory();

        final repo = factory.getWorkoutRepository();

        expect(repo, isA<WorkoutRepository>());
      });

      test('setWorkoutRepository allows custom implementation', () {
        final factory = RepositoryFactory();
        final mock = MockWorkoutRepository();

        factory.setWorkoutRepository(mock);

        expect(factory.getWorkoutRepository(), mock);
      });

      test('isSingleton returns same instance', () {
        final factory = RepositoryFactory();
        final repo1 = factory.getWorkoutRepository();
        final repo2 = factory.getWorkoutRepository();

        expect(identical(repo1, repo2), isTrue);
      });
    });

    group('BodyMetricRepository', () {
      test('getBodyMetricRepository returns default implementation', () {
        final factory = RepositoryFactory();

        final repo = factory.getBodyMetricRepository();

        expect(repo, isA<BodyMetricRepository>());
      });

      test('setBodyMetricRepository allows custom implementation', () {
        final factory = RepositoryFactory();
        final mock = MockBodyMetricRepository();

        factory.setBodyMetricRepository(mock);

        expect(factory.getBodyMetricRepository(), mock);
      });

      test('isSingleton returns same instance', () {
        final factory = RepositoryFactory();
        final repo1 = factory.getBodyMetricRepository();
        final repo2 = factory.getBodyMetricRepository();

        expect(identical(repo1, repo2), isTrue);
      });
    });

    group('DailyCheckinRepository', () {
      test('getDailyCheckinRepository returns default implementation', () {
        final factory = RepositoryFactory();

        final repo = factory.getDailyCheckinRepository();

        expect(repo, isA<DailyCheckinRepository>());
      });

      test('setDailyCheckinRepository allows custom implementation', () {
        final factory = RepositoryFactory();
        final mock = MockDailyCheckinRepository();

        factory.setDailyCheckinRepository(mock);

        expect(factory.getDailyCheckinRepository(), mock);
      });

      test('isSingleton returns same instance', () {
        final factory = RepositoryFactory();
        final repo1 = factory.getDailyCheckinRepository();
        final repo2 = factory.getDailyCheckinRepository();

        expect(identical(repo1, repo2), isTrue);
      });
    });

    group('ScreenTimeRepository', () {
      test('getScreenTimeRepository returns default implementation', () {
        final factory = RepositoryFactory();

        final repo = factory.getScreenTimeRepository();

        expect(repo, isA<ScreenTimeRepository>());
      });

      test('setScreenTimeRepository allows custom implementation', () {
        final factory = RepositoryFactory();
        final mock = MockScreenTimeRepository();

        factory.setScreenTimeRepository(mock);

        expect(factory.getScreenTimeRepository(), mock);
      });

      test('isSingleton returns same instance', () {
        final factory = RepositoryFactory();
        final repo1 = factory.getScreenTimeRepository();
        final repo2 = factory.getScreenTimeRepository();

        expect(identical(repo1, repo2), isTrue);
      });
    });

    group('HydrationRepository', () {
      test('getHydrationRepository returns default implementation', () {
        final factory = RepositoryFactory();

        final repo = factory.getHydrationRepository();

        expect(repo, isA<HydrationRepository>());
      });

      test('setHydrationRepository allows custom implementation', () {
        final factory = RepositoryFactory();
        final mock = MockHydrationRepository();

        factory.setHydrationRepository(mock);

        expect(factory.getHydrationRepository(), mock);
      });

      test('isSingleton returns same instance', () {
        final factory = RepositoryFactory();
        final repo1 = factory.getHydrationRepository();
        final repo2 = factory.getHydrationRepository();

        expect(identical(repo1, repo2), isTrue);
      });
    });

    group('reset', () {
      test('reset clears cached MealRepository', () {
        final factory = RepositoryFactory();
        final repo1 = factory.getMealRepository();

        factory.reset();
        final repo2 = factory.getMealRepository();

        expect(identical(repo1, repo2), isFalse);
      });

      test('reset clears cached WorkoutRepository', () {
        final factory = RepositoryFactory();
        final repo1 = factory.getWorkoutRepository();

        factory.reset();
        final repo2 = factory.getWorkoutRepository();

        expect(identical(repo1, repo2), isFalse);
      });

      test('reset clears cached BodyMetricRepository', () {
        final factory = RepositoryFactory();
        final repo1 = factory.getBodyMetricRepository();

        factory.reset();
        final repo2 = factory.getBodyMetricRepository();

        expect(identical(repo1, repo2), isFalse);
      });

      test('reset clears cached DailyCheckinRepository', () {
        final factory = RepositoryFactory();
        final repo1 = factory.getDailyCheckinRepository();

        factory.reset();
        final repo2 = factory.getDailyCheckinRepository();

        expect(identical(repo1, repo2), isFalse);
      });

      test('reset clears cached ScreenTimeRepository', () {
        final factory = RepositoryFactory();
        final repo1 = factory.getScreenTimeRepository();

        factory.reset();
        final repo2 = factory.getScreenTimeRepository();

        expect(identical(repo1, repo2), isFalse);
      });

      test('reset clears cached HydrationRepository', () {
        final factory = RepositoryFactory();
        final repo1 = factory.getHydrationRepository();

        factory.reset();
        final repo2 = factory.getHydrationRepository();

        expect(identical(repo1, repo2), isFalse);
      });

      test('reset clears all repositories at once', () {
        final factory = RepositoryFactory();

        final meal1 = factory.getMealRepository();
        final workout1 = factory.getWorkoutRepository();
        final bodyMetric1 = factory.getBodyMetricRepository();
        final checkin1 = factory.getDailyCheckinRepository();
        final screenTime1 = factory.getScreenTimeRepository();
        final hydration1 = factory.getHydrationRepository();

        factory.reset();

        final meal2 = factory.getMealRepository();
        final workout2 = factory.getWorkoutRepository();
        final bodyMetric2 = factory.getBodyMetricRepository();
        final checkin2 = factory.getDailyCheckinRepository();
        final screenTime2 = factory.getScreenTimeRepository();
        final hydration2 = factory.getHydrationRepository();

        expect(identical(meal1, meal2), isFalse);
        expect(identical(workout1, workout2), isFalse);
        expect(identical(bodyMetric1, bodyMetric2), isFalse);
        expect(identical(checkin1, checkin2), isFalse);
        expect(identical(screenTime1, screenTime2), isFalse);
        expect(identical(hydration1, hydration2), isFalse);
      });
    });
  });
}
