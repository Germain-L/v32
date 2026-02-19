import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/meal.dart';
import '../../data/repositories/day_rating_repository.dart';
import '../../data/repositories/meal_repository.dart';
import '../providers/calendar_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final CalendarProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = CalendarProvider(MealRepository(), DayRatingRepository());
    _provider.addListener(_onProviderChanged);
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _provider.dispose();
    super.dispose();
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        centerTitle: true,
        actions: [
          if (_provider.isLoadingMonth || _provider.isLoadingDay)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _provider.refresh,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendarHeader(theme, colorScheme),
          _buildWeekdayRow(theme, colorScheme),
          _buildCalendarGrid(theme, colorScheme),
          const SizedBox(height: 8),
          Expanded(child: _buildSelectedDaySummary(theme, colorScheme)),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: _provider.goToPreviousMonth,
            icon: const Icon(Icons.chevron_left),
            color: colorScheme.onSurfaceVariant,
          ),
          Expanded(
            child: Text(
              _formatMonthYear(_provider.focusedMonth),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          IconButton(
            onPressed: _provider.goToNextMonth,
            icon: const Icon(Icons.chevron_right),
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayRow(ThemeData theme, ColorScheme colorScheme) {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: labels
            .map(
              (label) => Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid(ThemeData theme, ColorScheme colorScheme) {
    final days = _buildDaysForMonth(_provider.focusedMonth);
    final selected = _provider.selectedDate;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isCurrentMonth = day.month == _provider.focusedMonth.month;
          final isSelected = _isSameDay(day, selected);
          final rating = _provider.ratingForDate(day);
          return _buildDayCell(
            theme,
            colorScheme,
            day,
            isCurrentMonth: isCurrentMonth,
            isSelected: isSelected,
            rating: rating,
          );
        },
      ),
    );
  }

  Widget _buildDayCell(
    ThemeData theme,
    ColorScheme colorScheme,
    DateTime day, {
    required bool isCurrentMonth,
    required bool isSelected,
    required int? rating,
  }) {
    final baseColor = isSelected
        ? colorScheme.primary
        : isCurrentMonth
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant;
    final ratingColor = _ratingColor(colorScheme, rating);
    final textColor = isSelected
        ? colorScheme.onPrimary
        : rating != null
        ? colorScheme.onSurface
        : baseColor;
    final bgColor = isSelected
        ? colorScheme.primary
        : rating != null
        ? ratingColor.withValues(alpha: 0.28)
        : Colors.transparent;
    final borderColor = isSelected
        ? colorScheme.primary
        : rating != null
        ? ratingColor.withValues(alpha: 0.65)
        : colorScheme.outlineVariant.withValues(alpha: 0.4);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        if (isSelected) {
          await context.push('/calendar/day/${_formatRouteDate(day)}');
          if (!mounted) return;
          await _provider.refresh();
          return;
        }
        _provider.selectDate(day);
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '${day.day}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (rating != null)
              Positioned(
                left: 8,
                right: 8,
                bottom: 7,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: ratingColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDaySummary(ThemeData theme, ColorScheme colorScheme) {
    if (_provider.error != null && _provider.selectedMeals.isEmpty) {
      return _buildErrorState(colorScheme);
    }

    if (_provider.selectedMeals.isEmpty && !_provider.isLoadingDay) {
      return _buildEmptyState(theme, colorScheme);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: _provider.selectedMeals.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _formatSelectedDate(_provider.selectedDate),
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }
        final meal = _provider.selectedMeals[index - 1];
        return _buildMealRow(theme, colorScheme, meal);
      },
    );
  }

  Widget _buildMealRow(ThemeData theme, ColorScheme colorScheme, Meal meal) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMealThumbnail(colorScheme, meal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getSlotIcon(meal.slot),
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        meal.slot.displayName,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(meal.date),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (meal.description?.isNotEmpty == true)
                    Text(
                      meal.description!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    )
                  else
                    Text(
                      'No description',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealThumbnail(ColorScheme colorScheme, Meal meal) {
    if (meal.hasImage && meal.imagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 56,
          height: 56,
          child: Image.file(
            File(meal.imagePath!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildMealPlaceholder(colorScheme);
            },
          ),
        ),
      );
    }

    return _buildMealPlaceholder(colorScheme);
  }

  Widget _buildMealPlaceholder(ColorScheme colorScheme) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.restaurant_outlined,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        size: 24,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No meals logged',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select another date or add meals from Today tab',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load calendar',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _provider.error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _provider.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  List<DateTime> _buildDaysForMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final startOffset = firstDay.weekday - 1;

    final days = <DateTime>[];
    for (var i = 0; i < startOffset; i++) {
      days.add(firstDay.subtract(Duration(days: startOffset - i)));
    }
    for (var day = 1; day <= lastDay.day; day++) {
      days.add(DateTime(month.year, month.month, day));
    }
    var trailing = 1;
    while (days.length % 7 != 0) {
      days.add(lastDay.add(Duration(days: trailing)));
      trailing++;
    }
    return days;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatMonthYear(DateTime date) {
    final months = [
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
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatSelectedDate(DateTime date) {
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final months = [
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
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatRouteDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  IconData _getSlotIcon(MealSlot slot) {
    return switch (slot) {
      MealSlot.breakfast => Icons.wb_sunny_outlined,
      MealSlot.lunch => Icons.lunch_dining_outlined,
      MealSlot.afternoonSnack => Icons.coffee_outlined,
      MealSlot.dinner => Icons.nights_stay_outlined,
    };
  }

  Color _ratingColor(ColorScheme colorScheme, int? rating) {
    if (rating == null) return Colors.transparent;
    return switch (rating) {
      1 => colorScheme.error,
      2 => colorScheme.tertiary,
      3 => colorScheme.primary,
      _ => colorScheme.outline,
    };
  }
}
