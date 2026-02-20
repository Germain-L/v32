import 'package:flutter/foundation.dart';
import '../../data/models/daily_metrics.dart';
import '../../data/models/meal.dart';
import '../../data/repositories/daily_metrics_repository.dart';
import '../../data/repositories/meal_repository.dart';

class MealsProvider extends ChangeNotifier {
  final MealRepository _repository;
  final DailyMetricsRepository _metricsRepository;

  final List<Meal> _meals = [];
  final int _pageSize;
  final bool _autoLoad;
  DateTime? _lastMealDate;
  int? _lastMealId;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;
  final Map<String, DailyMetrics> _metricsByDate = {};

  MealsProvider(
    this._repository, {
    DailyMetricsRepository? metricsRepository,
    int pageSize = 20,
    bool autoLoad = true,
  }) : _metricsRepository = metricsRepository ?? DailyMetricsRepository(),
       _pageSize = pageSize,
       _autoLoad = autoLoad {
    if (_autoLoad) {
      loadMoreMeals();
    }
  }

  List<Meal> get meals => List.unmodifiable(_meals);
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  DailyMetrics? metricsForDate(DateTime date) {
    return _metricsByDate[_dateKey(date)];
  }

  Future<void> loadMoreMeals() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final date = _lastMealDate ?? DateTime.now();
      final newMeals = await _repository.getMealsBeforeCursor(
        date,
        id: _lastMealId,
        limit: _pageSize,
      );

      if (newMeals.isEmpty) {
        _hasMore = false;
      } else {
        final existingIds = _meals.map((m) => m.id).toSet();
        final uniqueNewMeals = newMeals
            .where((m) => !existingIds.contains(m.id))
            .toList();

        if (uniqueNewMeals.isEmpty) {
          _hasMore = false;
        } else {
          _meals.addAll(uniqueNewMeals);
          _lastMealDate = uniqueNewMeals.last.date;
          _lastMealId = uniqueNewMeals.last.id;

          await _loadMetricsForMeals(uniqueNewMeals);

          if (uniqueNewMeals.length < _pageSize) {
            _hasMore = false;
          }
        }
      }
    } catch (e) {
      _error = 'Failed to load meals: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _meals.clear();
    _lastMealDate = null;
    _lastMealId = null;
    _hasMore = true;
    _error = null;
    _metricsByDate.clear();
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

  Future<void> _loadMetricsForMeals(List<Meal> meals) async {
    if (meals.isEmpty) return;
    final dates = meals.map((meal) => meal.date).toList();
    dates.sort((a, b) => a.compareTo(b));
    final start = DateTime(
      dates.first.year,
      dates.first.month,
      dates.first.day,
    );
    final end = DateTime(dates.last.year, dates.last.month, dates.last.day);
    final metrics = await _metricsRepository.getMetricsForRange(start, end);
    if (metrics.isNotEmpty) {
      _metricsByDate.addAll(metrics);
    }
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
