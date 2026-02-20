import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/meal.dart';
import '../../data/repositories/meal_repository.dart';
import '../providers/meals_provider.dart';
import '../widgets/meal_history_card.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen>
    with SingleTickerProviderStateMixin {
  late final MealsProvider _provider;
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _provider = MealsProvider(MealRepository());
    _provider.addListener(_onProviderChanged);
    _scrollController.addListener(_onScroll);
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  void _onProviderChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_provider.isLoading &&
        _provider.hasMore) {
      _provider.loadMoreMeals();
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _scrollController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal History'),
        centerTitle: true,
        actions: [
          if (_provider.isLoading && _provider.meals.isEmpty)
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
      body: _buildBody(theme, colorScheme),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_provider.error != null && _provider.meals.isEmpty) {
      return _buildErrorState(colorScheme);
    }

    if (_provider.meals.isEmpty && !_provider.isLoading) {
      return _buildEmptyState(theme, colorScheme);
    }

    return _buildMealList(theme, colorScheme);
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
              'Failed to load meals',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _provider.error!,
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

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No meals yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking your meals in the Today tab',
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

  Widget _buildMealList(ThemeData theme, ColorScheme colorScheme) {
    final feedItems = _buildFeedItems(_provider.meals);

    return RefreshIndicator(
      onRefresh: _provider.refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount:
            feedItems.length +
            (_provider.hasMore || _provider.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == feedItems.length) {
            return _buildLoadingFooter(colorScheme);
          }

          final item = feedItems[index];
          if (item.isSeparator) {
            return _buildStaggeredItem(
              _buildDateSeparator(item.dateLabel!, theme, colorScheme),
              index,
            );
          }
          if (item.isMetrics) {
            return _buildStaggeredItem(
              _buildMetricsSummary(theme, colorScheme, item.metricsDate!),
              index,
            );
          }

          final meal = item.meal!;
          return _buildStaggeredItem(
            MealHistoryCard(meal: meal, onTap: () => _onMealTap(meal)),
            index,
          );
        },
      ),
    );
  }

  Widget _buildDateSeparator(
    String label,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSummary(
    ThemeData theme,
    ColorScheme colorScheme,
    DateTime date,
  ) {
    final metrics = _provider.metricsForDate(date);
    if (metrics == null) {
      return const SizedBox.shrink();
    }
    final water = metrics?.waterLiters;
    final exerciseDone = metrics?.exerciseDone == true;
    final note = metrics?.exerciseNote;
    final isGoalMet = (water ?? 0) >= 1.5;
    final exerciseLabel = metrics == null ? '—' : (exerciseDone ? 'Yes' : 'No');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 16,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              water == null
                  ? 'Water: —'
                  : 'Water: ${_formatWater(water)} L'
                        '${isGoalMet ? ' (goal met)' : ''}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Exercise: $exerciseLabel',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (note != null && note.trim().isNotEmpty) ...[
              const SizedBox(width: 10),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ] else
              const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildStaggeredItem(Widget child, int index) {
    final start = (index * 0.08);
    final end = math.min(1.0, start + 0.5);
    final animation = CurvedAnimation(
      parent: _listController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Widget _buildLoadingFooter(ColorScheme colorScheme) {
    if (!_provider.isLoading) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  List<_FeedItem> _buildFeedItems(List<Meal> meals) {
    if (meals.isEmpty) return [];

    final sortedMeals = meals.toList()
      ..sort((a, b) {
        final dayCompare = _compareDayDesc(a.date, b.date);
        if (dayCompare != 0) return dayCompare;

        final slotCompare = _slotOrder(b.slot).compareTo(_slotOrder(a.slot));
        if (slotCompare != 0) return slotCompare;

        return b.date.compareTo(a.date);
      });
    final items = <_FeedItem>[];
    DateTime? currentDate;

    for (final meal in sortedMeals) {
      if (currentDate == null || !_isSameDay(currentDate, meal.date)) {
        currentDate = meal.date;
        items.add(
          _FeedItem.separator(_provider.getFormattedDateGroup(meal.date)),
        );
        items.add(_FeedItem.metrics(meal.date));
      }
      items.add(_FeedItem.meal(meal));
    }

    return items;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _compareDayDesc(DateTime a, DateTime b) {
    final aDate = DateTime(a.year, a.month, a.day);
    final bDate = DateTime(b.year, b.month, b.day);
    return bDate.compareTo(aDate);
  }

  int _slotOrder(MealSlot slot) {
    return switch (slot) {
      MealSlot.breakfast => 0,
      MealSlot.lunch => 1,
      MealSlot.afternoonSnack => 2,
      MealSlot.dinner => 3,
    };
  }

  void _onMealTap(Meal meal) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _MealPreviewSheet(meal: meal),
    );
  }
}

class _FeedItem {
  final Meal? meal;
  final String? dateLabel;
  final DateTime? metricsDate;

  const _FeedItem._({this.meal, this.dateLabel, this.metricsDate});

  factory _FeedItem.meal(Meal meal) => _FeedItem._(meal: meal);

  factory _FeedItem.separator(String label) => _FeedItem._(dateLabel: label);

  factory _FeedItem.metrics(DateTime date) => _FeedItem._(metricsDate: date);

  bool get isSeparator => dateLabel != null;
  bool get isMetrics => metricsDate != null;
}

class _MealPreviewSheet extends StatelessWidget {
  final Meal meal;

  const _MealPreviewSheet({required this.meal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            meal.slot.displayName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Recorded at ${_formatDateTime(meal.date)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (meal.hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 5,
                child: Image.file(File(meal.imagePath!), fit: BoxFit.cover),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                meal.description?.isNotEmpty == true
                    ? meal.description!
                    : 'No description',
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: meal.description?.isNotEmpty == true
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  fontStyle: meal.description?.isNotEmpty == true
                      ? FontStyle.normal
                      : FontStyle.italic,
                  height: 1.45,
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (meal.hasImage)
            if (meal.description?.isNotEmpty == true)
              Text(
                meal.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  height: 1.4,
                ),
              )
            else
              Text(
                'No description',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

String _formatWater(double value) {
  return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
}
