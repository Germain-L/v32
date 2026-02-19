import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/meal.dart';
import '../../data/repositories/meal_repository.dart';
import '../../data/services/image_storage_service.dart';

class TodayProvider extends ChangeNotifier {
  final MealRepository _repository;
  final _picker = ImagePicker();

  final Map<MealSlot, Meal?> _meals = {};
  final Map<MealSlot, bool> _isLoading = {};
  final Map<MealSlot, bool> _isSaving = {};
  final Map<MealSlot, String?> _descriptions = {};
  final Map<MealSlot, Timer?> _debounceTimers = {};
  final Map<MealSlot, bool> _hasPendingDescriptionSave = {};
  final Map<MealSlot, bool> _isClearing = {};
  String? _error;

  TodayProvider(this._repository) {
    _initializeSlots();
    loadTodayMeals();
  }

  void _initializeSlots() {
    for (final slot in MealSlot.values) {
      _isLoading[slot] = false;
      _isSaving[slot] = false;
      _descriptions[slot] = '';
      _debounceTimers[slot] = null;
      _hasPendingDescriptionSave[slot] = false;
      _isClearing[slot] = false;
    }
  }

  Meal? getMeal(MealSlot slot) => _meals[slot];
  bool isLoading(MealSlot slot) => _isLoading[slot] ?? false;
  bool isSaving(MealSlot slot) => _isSaving[slot] ?? false;
  String getDescription(MealSlot slot) => _descriptions[slot] ?? '';
  String? get error => _error;

  Future<void> loadTodayMeals() async {
    try {
      final meals = await _repository.getMealsForDate(DateTime.now());

      for (final slot in MealSlot.values) {
        _meals[slot] = meals.where((m) => m.slot == slot).firstOrDefault;
        _descriptions[slot] = _meals[slot]?.description ?? '';
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load meals: $e';
      notifyListeners();
    }
  }

  Future<void> capturePhoto(MealSlot slot) async {
    _setLoading(slot, true);

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        _setLoading(slot, false);
        return;
      }

      final savedPath = await ImageStorageService.saveImage(
        File(pickedFile.path),
      );

      if (savedPath == null) {
        _error = 'Failed to save image';
        _setLoading(slot, false);
        return;
      }

      await _saveMealWithImage(slot, savedPath);
    } catch (e) {
      _error = 'Failed to capture photo: $e';
    } finally {
      _setLoading(slot, false);
    }
  }

  Future<void> pickImage(MealSlot slot) async {
    _setLoading(slot, true);

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        _setLoading(slot, false);
        return;
      }

      final savedPath = await ImageStorageService.saveImage(
        File(pickedFile.path),
      );

      if (savedPath == null) {
        _error = 'Failed to save image';
        _setLoading(slot, false);
        return;
      }

      await _saveMealWithImage(slot, savedPath);
    } catch (e) {
      _error = 'Failed to pick image: $e';
    } finally {
      _setLoading(slot, false);
    }
  }

  Future<void> _saveMealWithImage(MealSlot slot, String imagePath) async {
    final existingMeal = _meals[slot];

    if (existingMeal != null && existingMeal.imagePath != null) {
      await ImageStorageService.deleteImage(existingMeal.imagePath);
    }

    final currentMeal = _meals[slot] ?? existingMeal;

    final meal = Meal(
      id: currentMeal?.id,
      slot: slot,
      date: DateTime.now(),
      description: _descriptions[slot],
      imagePath: imagePath,
    );

    final savedMeal = await _repository.saveMeal(meal);
    if (_isClearing[slot] == true) {
      if (savedMeal.id != null) {
        await _repository.deleteMeal(savedMeal.id!);
      }
      return;
    }
    _meals[slot] = savedMeal;
    if (_hasPendingDescriptionSave[slot] == true) {
      await _saveDescription(slot);
    }
    notifyListeners();
  }

  Future<void> updateDescription(MealSlot slot, String description) async {
    _descriptions[slot] = description;
    _hasPendingDescriptionSave[slot] = true;

    _debounceTimers[slot]?.cancel();
    _debounceTimers[slot] = Timer(const Duration(milliseconds: 250), () {
      _saveDescription(slot);
    });

    notifyListeners();
  }

  Future<void> _saveDescription(MealSlot slot) async {
    final description = _descriptions[slot] ?? '';

    if (_hasPendingDescriptionSave[slot] != true) {
      return;
    }

    if (_isLoading[slot] == true) {
      return;
    }

    if (_isClearing[slot] == true) {
      _hasPendingDescriptionSave[slot] = false;
      return;
    }

    // Prevent concurrent saves for the same slot
    if (_isSaving[slot] == true) {
      _hasPendingDescriptionSave[slot] = true;
      return;
    }

    _isSaving[slot] = true;

    var shouldRerun = false;

    try {
      _hasPendingDescriptionSave[slot] = false;
      final existingMeal = _meals[slot];
      if (existingMeal == null && description.trim().isEmpty) {
        return;
      }
      if (existingMeal != null && existingMeal.id != null) {
        final updatedMeal = existingMeal.copyWith(description: description);
        final savedMeal = await _repository.saveMeal(updatedMeal);
        if (_isClearing[slot] == true) {
          if (savedMeal.id != null) {
            await _repository.deleteMeal(savedMeal.id!);
          }
          return;
        }
        _meals[slot] = savedMeal;
      } else if (description.isNotEmpty) {
        // Check if a meal was created while we were waiting
        if (_meals[slot]?.id != null) {
          // Meal exists now, just update it
          final updatedMeal = _meals[slot]!.copyWith(description: description);
          final savedMeal = await _repository.saveMeal(updatedMeal);
          if (_isClearing[slot] == true) {
            if (savedMeal.id != null) {
              await _repository.deleteMeal(savedMeal.id!);
            }
            return;
          }
          _meals[slot] = savedMeal;
        } else {
          // Create new meal
          final meal = Meal(
            slot: slot,
            date: DateTime.now(),
            description: description,
          );
          final savedMeal = await _repository.saveMeal(meal);
          if (_isClearing[slot] == true) {
            if (savedMeal.id != null) {
              await _repository.deleteMeal(savedMeal.id!);
            }
            return;
          }
          _meals[slot] = savedMeal;
        }
      }
    } finally {
      shouldRerun = _hasPendingDescriptionSave[slot] == true;
      _isSaving[slot] = false;
    }

    if (shouldRerun) {
      await _saveDescription(slot);
      return;
    }

    notifyListeners();
  }

  Future<void> saveDescriptionNow(MealSlot slot) async {
    _debounceTimers[slot]?.cancel();
    _hasPendingDescriptionSave[slot] = true;
    await _saveDescription(slot);
  }

  Future<void> flushPendingSaves() async {
    for (final slot in MealSlot.values) {
      _debounceTimers[slot]?.cancel();
      if (_hasPendingDescriptionSave[slot] == true) {
        await _saveDescription(slot);
      }
    }
  }

  Future<void> deletePhoto(MealSlot slot) async {
    final meal = _meals[slot];
    if (meal == null || meal.imagePath == null) return;

    await ImageStorageService.deleteImage(meal.imagePath);

    final updatedMeal = meal.copyWith(imagePath: null);
    final savedMeal = await _repository.saveMeal(updatedMeal);
    _meals[slot] = savedMeal;
    notifyListeners();
  }

  Future<void> clearMeal(MealSlot slot) async {
    final meal = _meals[slot];
    if (meal == null && _hasPendingDescriptionSave[slot] != true) {
      return;
    }

    _isClearing[slot] = true;
    _debounceTimers[slot]?.cancel();
    _hasPendingDescriptionSave[slot] = false;
    _descriptions[slot] = '';
    _meals[slot] = null;
    notifyListeners();

    if (meal != null) {
      if (meal.imagePath != null) {
        await ImageStorageService.deleteImage(meal.imagePath);
      }

      if (meal.id != null) {
        await _repository.deleteMeal(meal.id!);
      }
    }

    _isClearing[slot] = false;
  }

  void _setLoading(MealSlot slot, bool value) {
    _isLoading[slot] = value;
    notifyListeners();
    if (!value && _hasPendingDescriptionSave[slot] == true) {
      _saveDescription(slot);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    flushPendingSaves();
    for (final timer in _debounceTimers.values) {
      timer?.cancel();
    }
    super.dispose();
  }
}

extension _FirstOrDefaultExtension<T> on Iterable<T> {
  T? get firstOrDefault {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
