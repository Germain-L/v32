import 'package:flutter/foundation.dart';
import '../../data/models/meal.dart';
import '../../data/repositories/meal_repository.dart';

class MealsProvider extends ChangeNotifier {
  final MealRepository _repository;

  final List<Meal> _meals = [];
  final int _pageSize = 20;
  DateTime? _lastMealDate;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  MealsProvider(this._repository) {
    loadMoreMeals();
  }

  List<Meal> get meals => List.unmodifiable(_meals);
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> loadMoreMeals() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final date = _lastMealDate ?? DateTime.now();
      debugPrint('Loading meals before: $date');
      final newMeals = await _repository.getMealsBefore(date, limit: _pageSize);
      debugPrint(
        'Loaded ${newMeals.length} meals: ${newMeals.map((m) => 'id=${m.id}, slot=${m.slot}').join(', ')}',
      );

      if (newMeals.isEmpty) {
        _hasMore = false;
        debugPrint('No more meals to load');
      } else {
        final existingIds = _meals.map((m) => m.id).toSet();
        debugPrint('Existing meal IDs: $existingIds');
        final uniqueNewMeals = newMeals
            .where((m) => !existingIds.contains(m.id))
            .toList();
        debugPrint('Unique new meals: ${uniqueNewMeals.length}');

        if (uniqueNewMeals.isEmpty) {
          _hasMore = false;
          debugPrint('All meals were duplicates, stopping');
        } else {
          _meals.addAll(uniqueNewMeals);
          _lastMealDate = uniqueNewMeals.last.date;
          debugPrint('Total meals in list: ${_meals.length}');

          if (uniqueNewMeals.length < _pageSize) {
            _hasMore = false;
          }
        }
      }
    } catch (e) {
      _error = 'Failed to load meals: $e';
      debugPrint('Error loading meals: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _meals.clear();
    _lastMealDate = null;
    _hasMore = true;
    _error = null;
    notifyListeners();
    await loadMoreMeals();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String getFormattedDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final mealDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(mealDate).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) {
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return weekdays[mealDate.weekday - 1];
    }
    if (date.year == now.year) {
      return '${_getMonthName(date.month)} ${date.day}';
    }
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
