import 'package:flutter_test/flutter_test.dart';
import 'package:v32/data/repositories/local_meal_repository.dart';
import 'package:v32/data/repositories/meal_repository_interface.dart';
import 'package:v32/data/repositories/mock_meal_repository.dart';
import 'package:v32/data/repositories/repository_factory.dart';

void main() {
  group('RepositoryFactory', () {
    test('can be instantiated', () {
      expect(() => RepositoryFactory(), returnsNormally);
    });

    test('getMealRepository returns default implementation', () {
      final factory = RepositoryFactory();

      final repo = factory.getMealRepository();

      expect(repo, isA<MealRepository>());
      expect(repo, isA<LocalMealRepository>());
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

    test('reset clears cached repositories', () {
      final factory = RepositoryFactory();
      final repo1 = factory.getMealRepository();

      factory.reset();
      final repo2 = factory.getMealRepository();

      expect(identical(repo1, repo2), isFalse);
    });
  });
}
