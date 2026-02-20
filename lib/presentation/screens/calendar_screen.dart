import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/daily_metrics.dart';
import '../../data/models/meal.dart';
import '../../data/repositories/day_rating_repository.dart';
import '../../data/repositories/meal_repository.dart';
import '../../utils/animation_helpers.dart';
import '../../utils/date_formatter.dart';
import '../../utils/l10n_helper.dart';
import '../providers/calendar_provider.dart';
import '../widgets/haptic_feedback_wrapper.dart';
import '../widgets/press_scale.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final CalendarProvider _provider;
  int _monthDirection = 0; // -1 for previous, 1 for next, 0 for initial

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

    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.calendarTitle),
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
          PressScale(
            onTap: () {
              HapticFeedbackUtil.trigger(HapticLevel.light);
              setState(() => _monthDirection = -1);
              _provider.goToPreviousMonth();
            },
            child: IconButton(
              onPressed: null,
              icon: const Icon(Icons.chevron_left),
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Text(
              context.dateFormatter.formatMonthYear(_provider.focusedMonth),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          PressScale(
            onTap: () {
              HapticFeedbackUtil.trigger(HapticLevel.light);
              setState(() => _monthDirection = 1);
              _provider.goToNextMonth();
            },
            child: IconButton(
              onPressed: null,
              icon: const Icon(Icons.chevron_right),
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekdayRow(ThemeData theme, ColorScheme colorScheme) {
    // Generate locale-aware weekday labels (M, T, W, etc.)
    final labels = List.generate(7, (index) {
      final date = DateTime(2024, 1, 1 + index); // Monday = Jan 1 2024
      return DateFormat.E(
        context.dateFormatter.locale,
      ).format(date)[0].toUpperCase();
    });
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      transitionBuilder: (child, animation) {
        final isNext = _monthDirection > 0;
        final beginOffset = isNext
            ? const Offset(1.0, 0.0)
            : const Offset(-1.0, 0.0);
        return SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Padding(
        key: ValueKey(_provider.focusedMonth),
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
            final metrics = _provider.metricsForDate(day);
            return _buildDayCell(
              theme,
              colorScheme,
              day,
              isCurrentMonth: isCurrentMonth,
              isSelected: isSelected,
              rating: rating,
              metrics: metrics,
            );
          },
        ),
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
    required DailyMetrics? metrics,
  }) {
    final baseColor = isSelected
        ? colorScheme.primary
        : isCurrentMonth
        ? colorScheme.onSurface
        : colorScheme.onSurfaceVariant;
    final ratingColor = ratingColorTransparentOnNull(colorScheme, rating);
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
    final waterLiters = metrics?.waterLiters;
    final exerciseDone = metrics?.exerciseDone == true;
    final isWaterGoalMet = (waterLiters ?? 0) >= 1.5;
    final showDots = isCurrentMonth;

    return PressScale(
      onTap: () async {
        HapticFeedbackUtil.trigger(HapticLevel.selection);
        if (isSelected) {
          await context.push('/calendar/day/${_formatRouteDate(day)}');
          if (!mounted) return;
          await _provider.refresh();
          return;
        }
        _provider.selectDate(day);
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          HapticFeedbackUtil.trigger(HapticLevel.selection);
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
              if (showDots && isWaterGoalMet)
                Positioned(
                  left: 6,
                  top: 6,
                  child: _buildCornerDot(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.tertiary,
                    borderColor: isSelected
                        ? colorScheme.onPrimary.withValues(alpha: 0.7)
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
              if (showDots && exerciseDone)
                Positioned(
                  right: 6,
                  top: 6,
                  child: _buildCornerDot(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.secondary,
                    borderColor: isSelected
                        ? colorScheme.onPrimary.withValues(alpha: 0.7)
                        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCornerDot({required Color color, required Color borderColor}) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1),
      ),
    );
  }

  Widget _buildSelectedDaySummary(ThemeData theme, ColorScheme colorScheme) {
    if (_provider.error != null && _provider.selectedMeals.isEmpty) {
      return _buildErrorState(colorScheme);
    }

    final metrics = _provider.selectedMetrics;
    if (_provider.selectedMeals.isEmpty &&
        !_provider.isLoadingDay &&
        metrics == null) {
      return _buildEmptyState(theme, colorScheme);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: _provider.selectedMeals.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              context.dateFormatter.formatFullDate(_provider.selectedDate),
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }
        if (index == 1) {
          return _buildSelectedMetrics(theme, colorScheme, metrics);
        }
        final meal = _provider.selectedMeals[index - 2];
        return _buildMealRow(theme, colorScheme, meal);
      },
    );
  }

  Widget _buildSelectedMetrics(
    ThemeData theme,
    ColorScheme colorScheme,
    DailyMetrics? metrics,
  ) {
    final l10n = context.l10n;
    final water = metrics?.waterLiters;
    final exerciseDone = metrics?.exerciseDone == true;
    final note = metrics?.exerciseNote;
    final isGoalMet = (water ?? 0) >= 1.5;
    final exerciseLabel = metrics == null
        ? l10n.exerciseDash
        : (exerciseDone ? l10n.exerciseYes : l10n.exerciseNo);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.water_drop_outlined,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.dailyMetrics,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (isGoalMet)
                  Text(
                    l10n.goalMet,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              water == null
                  ? '${l10n.waterLabel}: ${l10n.waterDash}'
                  : '${l10n.waterLabel}: ${water.toStringAsFixed(water % 1 == 0 ? 0 : 1)} ${l10n.waterUnit}'
                        '${isGoalMet ? ' (${l10n.goalMet})' : ''}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${l10n.exerciseLabel}: $exerciseLabel',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            if (note != null && note.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                note,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMealRow(ThemeData theme, ColorScheme colorScheme, Meal meal) {
    final l10n = context.l10n;
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
                        meal.slot.localizedName(l10n),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        context.dateFormatter.formatTime(meal.date),
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
                      l10n.noDescription,
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
      return Hero(
        tag: 'meal-photo-${meal.id}',
        child: ClipRRect(
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
    final l10n = context.l10n;
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
              l10n.noMealsLogged,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noMealsLoggedSubtitle,
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
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              l10n.failedToLoadCalendar,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _provider.error ?? l10n.unknownError,
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
              label: Text(l10n.retry),
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

  String _formatRouteDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  IconData _getSlotIcon(MealSlot slot) {
    return switch (slot) {
      MealSlot.breakfast => Icons.wb_sunny_outlined,
      MealSlot.lunch => Icons.lunch_dining_outlined,
      MealSlot.afternoonSnack => Icons.coffee_outlined,
      MealSlot.dinner => Icons.nights_stay_outlined,
    };
  }
}
