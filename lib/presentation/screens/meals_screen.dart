import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/meal.dart';
import '../../data/repositories/daily_metrics_repository.dart';
import '../../data/repositories/meal_repository.dart';
import '../../utils/date_formatter.dart';
import '../../utils/l10n_helper.dart';
import '../providers/meals_provider.dart';
import '../widgets/haptic_feedback_wrapper.dart';
import '../widgets/meal_history_card.dart';
import '../widgets/press_scale.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/staggered_item.dart';

class MealsScreen extends StatefulWidget {
  final MealRepository? repository;
  final DailyMetricsRepository? metricsRepository;
  final bool autoLoad;

  const MealsScreen({
    super.key,
    this.repository,
    this.metricsRepository,
    this.autoLoad = true,
  });

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
    _provider = MealsProvider(
      widget.repository ?? MealRepository(),
      metricsRepository: widget.metricsRepository,
      autoLoad: widget.autoLoad,
    );
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
      _provider.loadMoreMeals(context.l10n);
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
        title: Text(context.l10n.mealHistoryTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _provider.refresh,
          ),
        ],
      ),
      body: _buildBody(theme, colorScheme, context),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    if (_provider.error != null && _provider.meals.isEmpty) {
      return _buildErrorState(colorScheme, context);
    }

    if (_provider.meals.isEmpty && !_provider.isLoading) {
      return _buildEmptyState(theme, colorScheme, context);
    }

    if (_provider.isLoading && _provider.meals.isEmpty) {
      return _buildSkeletonList();
    }

    return _buildMealList(theme, colorScheme, context);
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: 6,
      itemBuilder: (context, index) {
        return SkeletonLoading(
          child: Column(
            children: [
              const SkeletonDateSeparator(),
              const SkeletonMetricsSummary(),
              const SkeletonFeedCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme, BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            SizedBox(height: 16),
            Text(
              context.l10n.failedToLoadMeals,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _provider.error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _provider.refresh,
              icon: Icon(Icons.refresh),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
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
            SizedBox(height: 16),
            Text(
              context.l10n.noMealsYet,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              context.l10n.noMealsYetSubtitle,
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

  Widget _buildMealList(
    ThemeData theme,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    final feedItems = _buildFeedItems(_provider.meals, context);

    return RefreshIndicator(
      onRefresh: _provider.refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount:
            feedItems.length +
            (_provider.hasMore || _provider.isLoading ? 1 : 0),
        itemBuilder: (listContext, index) {
          if (index == feedItems.length) {
            return _buildLoadingFooter(colorScheme);
          }

          final item = feedItems[index];
          if (item.isSeparator) {
            return StaggeredItem(
              index: index,
              animationController: _listController,
              startMultiplier: 0.08,
              intervalDuration: 0.5,
              child: _buildDateSeparator(item.dateLabel!, theme, colorScheme),
            );
          }
          if (item.isMetrics) {
            return StaggeredItem(
              index: index,
              animationController: _listController,
              startMultiplier: 0.08,
              intervalDuration: 0.5,
              child: _buildMetricsSummary(
                theme,
                colorScheme,
                item.metricsDate!,
                context,
              ),
            );
          }

          final meal = item.meal!;
          return StaggeredItem(
            index: index,
            animationController: _listController,
            startMultiplier: 0.08,
            intervalDuration: 0.5,
            child: Dismissible(
              key: ValueKey('meal_${meal.id}'),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) => _showDeleteConfirmation(meal),
              onUpdate: (details) {
                if (details.progress >= 0.4 && details.progress < 0.5) {
                  HapticFeedbackUtil.trigger(HapticLevel.medium);
                }
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: colorScheme.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: colorScheme.onError,
                  size: 28,
                ),
              ),
              child: PressScale(
                onTap: () => _onMealTap(meal),
                child: MealHistoryCard(
                  meal: meal,
                  onTap: () => _onMealTap(meal),
                ),
              ),
            ),
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
    BuildContext context,
  ) {
    final metrics = _provider.metricsForDate(date);
    if (metrics == null) {
      return const SizedBox.shrink();
    }
    final water = metrics.waterLiters;
    final exerciseDone = metrics.exerciseDone == true;
    final note = metrics.exerciseNote;
    final isGoalMet = (water ?? 0) >= 1.5;
    final exerciseLabel = exerciseDone
        ? context.l10n.exerciseYes
        : context.l10n.exerciseNo;

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
            SizedBox(width: 6),
            Text(
              water == null
                  ? '${context.l10n.waterLabel}: ${context.l10n.waterDash}'
                  : context.l10n.waterAmountWithGoal(water.round().toString()) +
                        (isGoalMet ? ' (${context.l10n.goalMetSuffix})' : ''),
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 10),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 10),
            Text(
              '${context.l10n.exerciseLabel}: $exerciseLabel',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (note != null && note.trim().isNotEmpty) ...[
              SizedBox(width: 10),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 10),
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
              Spacer(),
          ],
        ),
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

  List<_FeedItem> _buildFeedItems(List<Meal> meals, BuildContext context) {
    if (meals.isEmpty) return [];

    final items = <_FeedItem>[];
    DateTime? currentDate;

    for (final meal in meals) {
      if (currentDate == null || !_isSameDay(currentDate, meal.date)) {
        currentDate = meal.date;
        items.add(
          _FeedItem.separator(
            _provider.getFormattedDateGroup(meal.date, context.l10n),
          ),
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

  Future<bool> _showDeleteConfirmation(Meal meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.clearMeal),
        content: Text(
          context.l10n.clearMealConfirmation(
            meal.slot.localizedName(context.l10n),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.clear),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      HapticFeedbackUtil.trigger(HapticLevel.heavy);
      final success = await _provider.deleteMeal(meal.id!);
      return success;
    }
    return false;
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
            meal.slot.localizedName(context.l10n),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            context.l10n.recordedAt(
              context.dateFormatter.formatTime(meal.date),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 16),
          if (meal.hasImage)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 4 / 3,
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
                    : context.l10n.noDescription,
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
          SizedBox(height: 16),
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
                context.l10n.noDescription,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
        ],
      ),
    );
  }
}
