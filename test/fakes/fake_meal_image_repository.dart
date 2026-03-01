import 'package:v32/data/models/meal_image.dart';
import 'package:v32/data/repositories/meal_image_repository.dart';

/// A fake implementation of [MealImageRepository] for unit testing.
/// Stores images in memory without any database dependencies.
class FakeMealImageRepository extends MealImageRepository {
  final Map<int, List<MealImage>> _imagesByMeal = {};
  int _nextId = 1;

  @override
  Future<List<MealImage>> getImagesForMeal(int mealId) async {
    final images = _imagesByMeal[mealId] ?? [];
    // Return sorted by createdAt DESC (same as real repository)
    final sorted = List<MealImage>.from(images)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  @override
  Future<MealImage> addImage(int mealId, String imagePath) async {
    final image = MealImage(
      id: _nextId++,
      mealId: mealId,
      imagePath: imagePath,
      createdAt: DateTime.now(),
    );
    _imagesByMeal.putIfAbsent(mealId, () => []).add(image);
    return image;
  }

  @override
  Future<void> deleteImage(int imageId) async {
    for (final images in _imagesByMeal.values) {
      images.removeWhere((img) => img.id == imageId);
    }
  }

  @override
  Future<void> deleteAllImagesForMeal(int mealId) async {
    _imagesByMeal.remove(mealId);
  }

  /// Clears all stored images and resets the ID counter.
  /// Call this between tests to ensure isolation.
  void clear() {
    _imagesByMeal.clear();
    _nextId = 1;
  }
}
