import 'package:flutter/foundation.dart';
import '../../data/models/daily_metrics.dart';
import '../../data/models/meal.dart';
import '../../data/repositories/daily_metrics_repository.dart';
import '../../data/repositories/meal_repository.dart';
import '../../gen_l10n/app_localizations.dart';
import '../../utils/date_formatter.dart';

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
  final Set<String> _metricsFetchedDates = {};

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

  Future<void> loadMoreMeals([AppLocalizations? l10n]) async {
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
      _error = l10n != null
          ? '${l10n.errorLoadMeals}: $e'
          : 'Failed to load meals: $e';
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
    _metricsFetchedDates.clear();
    notifyListeners();
    await loadMoreMeals();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> deleteMeal(int mealId) async {
    try {
      await _repository.deleteMeal(mealId);
      _meals.removeWhere((m) => m.id == mealId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete meal: $e';
      notifyListeners();
      return false;
    }
  }

  String getFormattedDateGroup(DateTime date, [AppLocalizations? l10n]) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final mealDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(mealDate).inDays;

    if (difference == 0) return l10n?.today ?? 'Today';
    if (difference == 1) return l10n?.yesterday ?? 'Yesterday';

    final locale = l10n?.localeName ?? 'en';
    final formatter = DateFormatter(locale);

    if (difference < 7) {
      return formatter.formatWeekday(mealDate);
    }
    if (date.year == now.year) {
      return formatter.formatShortDate(mealDate);
    }
    return formatter.formatFullDate(mealDate);
  }

  Future<void> _loadMetricsForMeals(List<Meal> meals) async {
    if (meals.isEmpty) return;
    final uniqueDates = <DateTime>{};
    for (final meal in meals) {
      uniqueDates.add(_normalizeDate(meal.date));
    }
    final missingDates = uniqueDates.where((date) {
      return !_metricsFetchedDates.contains(_dateKey(date));
    }).toList();
    if (missingDates.isEmpty) return;
    missingDates.sort((a, b) => a.compareTo(b));
    final ranges = _buildDateRanges(missingDates);
    for (final range in ranges) {
      final metrics = await _metricsRepository.getMetricsForRange(
        range.start,
        range.end,
      );
      if (metrics.isNotEmpty) {
        _metricsByDate.addAll(metrics);
      }
      _markFetchedRange(range.start, range.end);
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<_DateRange> _buildDateRanges(List<DateTime> sortedDates) {
    if (sortedDates.isEmpty) return [];
    final ranges = <_DateRange>[];
    var start = sortedDates.first;
    var previous = sortedDates.first;
    for (var i = 1; i < sortedDates.length; i++) {
      final current = sortedDates[i];
      final isContiguous =
          current.difference(previous).inDays == 1 &&
          _isSameDay(previous.add(const Duration(days: 1)), current);
      if (!isContiguous) {
        ranges.add(_DateRange(start: start, end: previous));
        start = current;
      }
      previous = current;
    }
    ranges.add(_DateRange(start: start, end: previous));
    return ranges;
  }

  void _markFetchedRange(DateTime start, DateTime end) {
    var cursor = start;
    while (!cursor.isAfter(end)) {
      _metricsFetchedDates.add(_dateKey(cursor));
      cursor = cursor.add(const Duration(days: 1));
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _DateRange {
  final DateTime start;
  final DateTime end;

  const _DateRange({required this.start, required this.end});
}
