import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/daily_metrics.dart';
import '../../data/models/meal.dart';
import '../../data/repositories/daily_metrics_repository.dart';
import '../../data/repositories/day_rating_repository.dart';
import '../../data/repositories/meal_repository.dart';
import '../../data/services/image_storage_service.dart';
import '../../gen_l10n/app_localizations.dart';

class TodayProvider extends ChangeNotifier {
  final MealRepository _repository;
  final DayRatingRepository _ratingRepository;
  final DailyMetricsRepository _metricsRepository;
  final _picker = ImagePicker();

  final Map<MealSlot, Meal?> _meals = {};
  final Map<MealSlot, bool> _isLoading = {};
  final Map<MealSlot, bool> _isSaving = {};
  final Map<MealSlot, String?> _descriptions = {};
  final Map<MealSlot, Timer?> _debounceTimers = {};
  final Map<MealSlot, bool> _hasPendingDescriptionSave = {};
  final Map<MealSlot, bool> _isClearing = {};
  String? _error;
  bool _isDisposed = false;
  AppLocalizations? _currentL10n;
  int? _dayRating;
  double? _waterLiters;
  bool? _exerciseDone;
  String _exerciseNote = '';
  Timer? _metricsDebounce;
  bool _isSavingMetrics = false;
  bool _hasPendingMetricsSave = false;

  TodayProvider(
    this._repository,
    this._ratingRepository, {
    DailyMetricsRepository? metricsRepository,
  }) : _metricsRepository = metricsRepository ?? DailyMetricsRepository() {
    _initializeSlots();
    loadTodayMeals();
    loadDayRating();
    loadDailyMetrics();
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
  int? get dayRating => _dayRating;
  double? get waterLiters => _waterLiters;
  bool get exerciseDone => _exerciseDone ?? false;
  String get exerciseNote => _exerciseNote;
  bool get isWaterGoalMet => (_waterLiters ?? 0) >= 1.5;

  Future<void> loadTodayMeals({AppLocalizations? l10n}) async {
    _currentL10n = l10n;
    try {
      final meals = await _repository.getMealsForDate(DateTime.now());

      for (final slot in MealSlot.values) {
        _meals[slot] = meals.where((m) => m.slot == slot).firstOrDefault;
        _descriptions[slot] = _meals[slot]?.description ?? '';
      }

      _notifyIfMounted();
    } catch (e) {
      _error = l10n != null
          ? '${l10n.errorLoadMeals}: $e'
          : 'Failed to load meals: $e';
      _notifyIfMounted();
    }
  }

  Future<void> loadDayRating({AppLocalizations? l10n}) async {
    try {
      _dayRating = await _ratingRepository.getRatingForDate(DateTime.now());
      _notifyIfMounted();
    } catch (e) {
      _error = l10n != null
          ? '${l10n.errorLoadDayRating}: $e'
          : 'Failed to load day rating: $e';
      _notifyIfMounted();
    }
  }

  Future<void> loadDailyMetrics({AppLocalizations? l10n}) async {
    try {
      final metrics = await _metricsRepository.getMetricsForDate(
        DateTime.now(),
      );
      _waterLiters = metrics?.waterLiters;
      _exerciseDone = metrics?.exerciseDone;
      _exerciseNote = metrics?.exerciseNote ?? '';
      _notifyIfMounted();
    } catch (e) {
      _error = l10n != null
          ? '${l10n.errorLoadDailyMetrics}: $e'
          : 'Failed to load daily metrics: $e';
      _notifyIfMounted();
    }
  }

  void updateWaterLiters(String input) {
    _waterLiters = _parseWaterInput(input);
    _scheduleMetricsSave();
    _notifyIfMounted();
  }

  void updateExerciseDone(bool value) {
    _exerciseDone = value;
    _scheduleMetricsSave(immediate: true);
    _notifyIfMounted();
  }

  void updateExerciseNote(String note) {
    _exerciseNote = note;
    if (note.trim().isNotEmpty) {
      _exerciseDone = true;
    }
    _scheduleMetricsSave();
    _notifyIfMounted();
  }

  Future<void> updateDayRating(int score, {AppLocalizations? l10n}) async {
    try {
      if (score < 1 || score > 3) {
        _error = l10n != null
            ? l10n.errorInvalidDayRating
            : 'Invalid day rating';
        _notifyIfMounted();
        return;
      }
      _dayRating = score;
      _notifyIfMounted();
      await _ratingRepository.saveRating(DateTime.now(), score);
    } catch (e) {
      _error = l10n != null
          ? '${l10n.errorSaveDayRating}: $e'
          : 'Failed to save day rating: $e';
      _notifyIfMounted();
    }
  }

  Future<void> capturePhoto(MealSlot slot, {AppLocalizations? l10n}) async {
    _currentL10n = l10n;
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
        _error = l10n != null ? l10n.errorSaveImage : 'Failed to save image';
        _setLoading(slot, false);
        return;
      }

      await _saveMealWithImage(slot, savedPath);
    } catch (e) {
      _error = l10n != null
          ? '${l10n.errorCapturePhoto}: $e'
          : 'Failed to capture photo: $e';
      _notifyIfMounted();
    } finally {
      _setLoading(slot, false);
    }
  }

  Future<void> pickImage(MealSlot slot, {AppLocalizations? l10n}) async {
    _currentL10n = l10n;
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
        _error = l10n != null ? l10n.errorSaveImage : 'Failed to save image';
        _setLoading(slot, false);
        return;
      }

      await _saveMealWithImage(slot, savedPath);
    } catch (e) {
      _error = l10n != null
          ? '${l10n.errorPickImage}: $e'
          : 'Failed to pick image: $e';
      _notifyIfMounted();
    } finally {
      _setLoading(slot, false);
    }
  }

  Future<void> _saveMealWithImage(MealSlot slot, String imagePath) async {
    final existingMeal = _meals[slot];

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
    if (existingMeal?.imagePath != null &&
        existingMeal?.imagePath != imagePath) {
      await ImageStorageService.deleteImage(existingMeal?.imagePath);
    }
    _meals[slot] = savedMeal;
    if (_hasPendingDescriptionSave[slot] == true) {
      await _saveDescription(slot);
    }
    _notifyIfMounted();
  }

  Future<void> updateDescription(MealSlot slot, String description) async {
    _descriptions[slot] = description;
    _hasPendingDescriptionSave[slot] = true;

    _debounceTimers[slot]?.cancel();
    _debounceTimers[slot] = Timer(const Duration(milliseconds: 250), () {
      _saveDescription(slot);
    });

    _notifyIfMounted();
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
    } catch (e) {
      final l10n = _currentL10n;
      _error = l10n != null
          ? '${l10n.errorSaveMeal}: $e'
          : 'Failed to save meal: $e';
      _notifyIfMounted();
    } finally {
      shouldRerun = _hasPendingDescriptionSave[slot] == true;
      _isSaving[slot] = false;
    }

    if (shouldRerun) {
      await _saveDescription(slot);
      return;
    }

    _notifyIfMounted();
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
    if (_hasPendingMetricsSave) {
      await _saveDailyMetrics();
    }
  }

  Future<void> deletePhoto(MealSlot slot, {AppLocalizations? l10n}) async {
    final meal = _meals[slot];
    if (meal == null || meal.imagePath == null) return;

    try {
      final updatedMeal = meal.copyWith(imagePath: null);
      final savedMeal = await _repository.saveMeal(updatedMeal);
      await ImageStorageService.deleteImage(meal.imagePath);
      _meals[slot] = savedMeal;
      _notifyIfMounted();
    } catch (e) {
      _error = l10n != null
          ? '${l10n.errorDeletePhoto}: $e'
          : 'Failed to delete photo: $e';
      _notifyIfMounted();
    }
  }

  Future<void> clearMeal(MealSlot slot, {AppLocalizations? l10n}) async {
    final meal = _meals[slot];
    if (meal == null && _hasPendingDescriptionSave[slot] != true) {
      return;
    }

    _isClearing[slot] = true;
    _debounceTimers[slot]?.cancel();
    _hasPendingDescriptionSave[slot] = false;
    _descriptions[slot] = '';
    _meals[slot] = null;
    _notifyIfMounted();

    if (meal != null) {
      try {
        if (meal.id != null) {
          await _repository.deleteMeal(meal.id!);
        }
        if (meal.imagePath != null) {
          await ImageStorageService.deleteImage(meal.imagePath);
        }
      } catch (e) {
        _error = l10n != null
            ? '${l10n.errorClearMeal}: $e'
            : 'Failed to clear meal: $e';
        _notifyIfMounted();
      }
    }

    _isClearing[slot] = false;
  }

  void _setLoading(MealSlot slot, bool value) {
    _isLoading[slot] = value;
    _notifyIfMounted();
    if (!value && _hasPendingDescriptionSave[slot] == true) {
      _saveDescription(slot);
    }
  }

  void clearError() {
    _error = null;
    _notifyIfMounted();
  }

  void _scheduleMetricsSave({bool immediate = false}) {
    _hasPendingMetricsSave = true;
    _metricsDebounce?.cancel();
    if (immediate) {
      _saveDailyMetrics();
    } else {
      _metricsDebounce = Timer(const Duration(milliseconds: 250), () {
        _saveDailyMetrics();
      });
    }
  }

  Future<void> _saveDailyMetrics() async {
    if (!_hasPendingMetricsSave) return;
    if (_isSavingMetrics) {
      _hasPendingMetricsSave = true;
      return;
    }

    _isSavingMetrics = true;
    _hasPendingMetricsSave = false;
    var didDelete = false;

    try {
      final normalized = DateTime.now();
      final shouldDelete =
          _waterLiters == null &&
          (_exerciseDone != true) &&
          _exerciseNote.trim().isEmpty;
      if (shouldDelete) {
        await _metricsRepository.deleteMetricsForDate(normalized);
        didDelete = true;
      } else {
        await _metricsRepository.saveMetrics(
          DailyMetrics(
            date: normalized,
            waterLiters: _waterLiters,
            exerciseDone: _exerciseDone,
            exerciseNote: _exerciseNote.trim().isEmpty
                ? null
                : _exerciseNote.trim(),
          ),
        );
      }
    } catch (e) {
      final l10n = _currentL10n;
      _error = l10n != null
          ? '${l10n.errorSaveDailyMetrics}: $e'
          : 'Failed to save daily metrics: $e';
      _notifyIfMounted();
    } finally {
      _isSavingMetrics = false;
    }

    if (_hasPendingMetricsSave) {
      await _saveDailyMetrics();
      return;
    }

    if (didDelete) {
      _notifyIfMounted();
    }
  }

  void _notifyIfMounted() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  double? _parseWaterInput(String input) {
    final cleaned = input.trim().replaceAll(',', '.');
    if (cleaned.isEmpty) return null;
    final value = double.tryParse(cleaned);
    if (value == null) return null;
    if (value < 0) return null;
    return value;
  }

  Future<void> flushAndDispose() async {
    _isDisposed = true;
    await flushPendingSaves();
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (final timer in _debounceTimers.values) {
      timer?.cancel();
    }
    _metricsDebounce?.cancel();
    super.dispose();
  }
}

extension _FirstOrDefaultExtension<T> on Iterable<T> {
  T? get firstOrDefault {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
