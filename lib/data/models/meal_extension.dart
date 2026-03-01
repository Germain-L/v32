import 'meal.dart';

import '../repositories/meal_image_repository.dart';

/// Extension providing backward compatibility for image access during
/// the transition from single-image to multi-image support.
extension MealImageExtension on Meal {
  /// Get the first image path for this meal, or null if no images.
  Future<String?> get imagePath {
    if (id == null) return Future.value(null);
    return MealImageRepository().getImagesForMeal(id!).then((images) {
      return images.isNotEmpty ? images.first.imagePath : null;
    });
  }

  /// Check if this meal has any images.
  Future<bool> get hasImage {
    if (id == null) return Future.value(false);
    return MealImageRepository().getImagesForMeal(id!).then((images) {
      return images.isNotEmpty;
    });
  }
}
