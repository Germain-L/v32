import 'dart:io';
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

class _MealsScreenState extends State<MealsScreen> {
  late final MealsProvider _provider;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _provider = MealsProvider(MealRepository());
    _provider.addListener(_onProviderChanged);
    _scrollController.addListener(_onScroll);
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
    final groupedMeals = _groupMealsByDate(_provider.meals);

    return RefreshIndicator(
      onRefresh: _provider.refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount:
            groupedMeals.length +
            (_provider.hasMore || _provider.isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == groupedMeals.length) {
            return _buildLoadingFooter(colorScheme);
          }

          final group = groupedMeals[index];
          return _buildDateGroup(context, group, theme, colorScheme);
        },
      ),
    );
  }

  Widget _buildDateGroup(
    BuildContext context,
    _DateGroup group,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            group.dateLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...group.meals.map(
          (meal) => MealHistoryCard(meal: meal, onTap: () => _onMealTap(meal)),
        ),
      ],
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

  List<_DateGroup> _groupMealsByDate(List<Meal> meals) {
    final groups = <String, List<Meal>>{};

    for (final meal in meals) {
      final dateKey = _getDateKey(meal.date);
      groups.putIfAbsent(dateKey, () => []).add(meal);
    }

    final sortedKeys = groups.keys.toList()..sort((a, b) => b.compareTo(a));

    return sortedKeys.map((key) {
      final mealsInGroup = groups[key]!;
      mealsInGroup.sort((a, b) => b.date.compareTo(a.date));

      final date = mealsInGroup.first.date;
      return _DateGroup(
        dateLabel: _provider.getFormattedDateGroup(date),
        meals: mealsInGroup,
      );
    }).toList();
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _onMealTap(Meal meal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(meal.slot.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (meal.hasImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(File(meal.imagePath!), fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
            ],
            if (meal.description?.isNotEmpty == true)
              Text(meal.description!)
            else
              const Text(
                'No description',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 8),
            Text(
              'Recorded at ${_formatDateTime(meal.date)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
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

class _DateGroup {
  final String dateLabel;
  final List<Meal> meals;

  _DateGroup({required this.dateLabel, required this.meals});
}
