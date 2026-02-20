import 'package:flutter/foundation.dart';
import '../../data/models/daily_metrics.dart';
import '../../data/models/meal.dart';
import '../../data/repositories/daily_metrics_repository.dart';
import '../../data/repositories/day_rating_repository.dart';
import '../../data/repositories/meal_repository.dart';

class CalendarProvider extends ChangeNotifier {
  CalendarProvider(
    this._repository,
    this._ratingRepository, {
    DailyMetricsRepository? metricsRepository,
  }) : _metricsRepository = metricsRepository ?? DailyMetricsRepository() {
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _loadMonth();
    _loadSelectedDate();
  }

  final MealRepository _repository;
  final DayRatingRepository _ratingRepository;
  final DailyMetricsRepository _metricsRepository;

  late DateTime _focusedMonth;
  late DateTime _selectedDate;
  bool _isLoadingMonth = false;
  bool _isLoadingDay = false;
  String? _error;
  final Map<String, bool> _monthHasMeals = {};
  final Map<String, int> _monthRatings = {};
  final Map<String, DailyMetrics> _monthMetrics = {};
  List<Meal> _selectedMeals = [];
  DailyMetrics? _selectedMetrics;

  DateTime get focusedMonth => _focusedMonth;
  DateTime get selectedDate => _selectedDate;
  bool get isLoadingMonth => _isLoadingMonth;
  bool get isLoadingDay => _isLoadingDay;
  String? get error => _error;
  List<Meal> get selectedMeals => List.unmodifiable(_selectedMeals);
  DailyMetrics? get selectedMetrics => _selectedMetrics;

  bool hasMealsForDate(DateTime date) {
    return _monthHasMeals[_dateKey(date)] ?? false;
  }

  int? ratingForDate(DateTime date) {
    return _monthRatings[_dateKey(date)];
  }

  DailyMetrics? metricsForDate(DateTime date) {
    return _monthMetrics[_dateKey(date)];
  }

  void selectDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (_selectedDate == normalized) return;
    _selectedDate = normalized;
    if (normalized.year != _focusedMonth.year ||
        normalized.month != _focusedMonth.month) {
      _focusedMonth = DateTime(normalized.year, normalized.month, 1);
      _loadMonth();
    }
    _loadSelectedDate();
    notifyListeners();
  }

  void goToPreviousMonth() {
    final prev = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    _focusedMonth = prev;
    _selectedDate = DateTime(prev.year, prev.month, 1);
    _loadMonth();
    _loadSelectedDate();
    notifyListeners();
  }

  void goToNextMonth() {
    final next = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    _focusedMonth = next;
    _selectedDate = DateTime(next.year, next.month, 1);
    _loadMonth();
    _loadSelectedDate();
    notifyListeners();
  }

  Future<void> refresh() async {
    await Future.wait([_loadMonth(), _loadSelectedDate()]);
  }

  Future<void> _loadMonth() async {
    _isLoadingMonth = true;
    _error = null;
    notifyListeners();

    final targetMonth = _focusedMonth;

    try {
      final mealsFuture = _repository.getMealsForMonth(
        targetMonth.year,
        targetMonth.month,
      );
      final ratingsFuture = _ratingRepository.getRatingsForMonth(
        targetMonth.year,
        targetMonth.month,
      );
      final metricsFuture = _metricsRepository.getMetricsForMonth(
        targetMonth.year,
        targetMonth.month,
      );
      final results = await Future.wait([
        mealsFuture,
        ratingsFuture,
        metricsFuture,
      ]);
      if (targetMonth != _focusedMonth) {
        return;
      }
      final meals = results[0] as List<Meal>;
      final ratings = results[1] as Map<String, int>;
      final metrics = results[2] as Map<String, DailyMetrics>;
      _monthHasMeals
        ..clear()
        ..addAll(_buildMonthMealMap(meals));
      _monthRatings
        ..clear()
        ..addAll(ratings);
      _monthMetrics
        ..clear()
        ..addAll(metrics);
    } catch (e) {
      _error = 'Failed to load calendar: $e';
    } finally {
      _isLoadingMonth = false;
      notifyListeners();
    }
  }

  Future<void> _loadSelectedDate() async {
    _isLoadingDay = true;
    _error = null;
    notifyListeners();

    final targetDate = _selectedDate;

    try {
      final meals = await _repository.getMealsForDate(targetDate);
      final metrics = await _metricsRepository.getMetricsForDate(targetDate);
      if (targetDate != _selectedDate) {
        return;
      }
      _selectedMeals = meals..sort((a, b) => a.date.compareTo(b.date));
      _selectedMetrics = metrics;
    } catch (e) {
      _error = 'Failed to load meals: $e';
    } finally {
      _isLoadingDay = false;
      notifyListeners();
    }
  }

  Map<String, bool> _buildMonthMealMap(List<Meal> meals) {
    final map = <String, bool>{};
    for (final meal in meals) {
      map[_dateKey(meal.date)] = true;
    }
    return map;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
