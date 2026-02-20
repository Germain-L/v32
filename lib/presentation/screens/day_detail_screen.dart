import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/meal.dart';
import '../../data/repositories/day_rating_repository.dart';
import '../../data/repositories/meal_repository.dart';
import '../providers/day_detail_provider.dart';
import '../widgets/meal_slot.dart';

class DayDetailScreen extends StatefulWidget {
  final DateTime initialDate;

  const DayDetailScreen({super.key, required this.initialDate});

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  static const _pageAnchor = 10000;
  late final DateTime _anchorDate;
  late final PageController _pageController;
  late DateTime _currentDate;

  @override
  void initState() {
    super.initState();
    final normalized = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _anchorDate = normalized;
    _currentDate = normalized;
    _pageController = PageController(initialPage: _pageAnchor);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Day Detail'),
            Text(
              _formatDate(_currentDate),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Jump to today',
            icon: const Icon(Icons.today),
            onPressed: _jumpToToday,
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: _handlePageChanged,
        itemBuilder: (context, index) {
          final date = _dateForPage(index);
          return DayDetailPage(date: date);
        },
      ),
    );
  }

  DateTime _dateForPage(int index) {
    final offset = index - _pageAnchor;
    return DateTime(
      _anchorDate.year,
      _anchorDate.month,
      _anchorDate.day + offset,
    );
  }

  void _handlePageChanged(int index) {
    final date = _dateForPage(index);
    setState(() => _currentDate = date);
  }

  void _jumpToToday() {
    final today = DateTime.now();
    final normalized = DateTime(today.year, today.month, today.day);
    final diff = normalized.difference(_anchorDate).inDays;
    final targetPage = _pageAnchor + diff;
    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  String _formatDate(DateTime date) {
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
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}

class DayDetailPage extends StatefulWidget {
  final DateTime date;

  const DayDetailPage({super.key, required this.date});

  @override
  State<DayDetailPage> createState() => _DayDetailPageState();
}

class _DayDetailPageState extends State<DayDetailPage>
    with SingleTickerProviderStateMixin {
  late final DayDetailProvider _provider;
  late final AnimationController _listController;
  final Map<MealSlot, TextEditingController> _controllers = {};
  final Map<MealSlot, FocusNode> _focusNodes = {};
  late final TextEditingController _waterController;
  late final TextEditingController _exerciseNoteController;
  late final FocusNode _waterFocusNode;
  late final FocusNode _exerciseNoteFocusNode;

  @override
  void initState() {
    super.initState();
    _provider = DayDetailProvider(
      MealRepository(),
      DayRatingRepository(),
      widget.date,
    );
    for (final slot in MealSlot.values) {
      _controllers[slot] = TextEditingController();
      _focusNodes[slot] = FocusNode();
    }
    _waterController = TextEditingController();
    _exerciseNoteController = TextEditingController();
    _waterFocusNode = FocusNode();
    _exerciseNoteFocusNode = FocusNode();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    unawaited(_disposeAsync());
    _disposeControllers();
    _disposeFocusNodes();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _disposeAsync() async {
    await _provider.flushAndDispose();
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _waterController.dispose();
    _exerciseNoteController.dispose();
  }

  void _disposeFocusNodes() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _waterFocusNode.dispose();
    _exerciseNoteFocusNode.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListenableBuilder(
      listenable: _provider,
      builder: (context, child) {
        for (final slot in MealSlot.values) {
          final controller = _controllers[slot];
          final providerText = _provider.getDescription(slot);
          if (controller != null && controller.text != providerText) {
            controller.value = controller.value.copyWith(
              text: providerText,
              selection: TextSelection.collapsed(offset: providerText.length),
              composing: TextRange.empty,
            );
          }
        }
        final waterText = _provider.waterLiters == null
            ? ''
            : _formatWater(_provider.waterLiters!);
        if (_waterController.text != waterText && !_waterFocusNode.hasFocus) {
          _waterController.value = _waterController.value.copyWith(
            text: waterText,
            selection: TextSelection.collapsed(offset: waterText.length),
            composing: TextRange.empty,
          );
        }
        if (_exerciseNoteController.text != _provider.exerciseNote &&
            !_exerciseNoteFocusNode.hasFocus) {
          _exerciseNoteController.value = _exerciseNoteController.value
              .copyWith(
                text: _provider.exerciseNote,
                selection: TextSelection.collapsed(
                  offset: _provider.exerciseNote.length,
                ),
                composing: TextRange.empty,
              );
        }

        if (_provider.error != null) {
          return _buildErrorWidget(colorScheme);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          itemCount: MealSlot.values.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _buildStaggeredItem(_buildDayRating(theme), index);
            }
            if (index == 1) {
              return _buildStaggeredItem(_buildDailyMetrics(theme), index);
            }
            final slot = MealSlot.values[index - 2];
            return _buildStaggeredItem(
              MealSlotWidget(
                slot: slot,
                meal: _provider.getMeal(slot),
                isLoading: _provider.isLoading(slot),
                onCapturePhoto: () => _provider.capturePhoto(slot),
                onPickImage: () => _provider.pickImage(slot),
                onDeletePhoto: () => _provider.deletePhoto(slot),
                onClearMeal: () => _showClearConfirmation(slot),
                descriptionController: _controllers[slot],
                descriptionFocusNode: _focusNodes[slot],
                onDescriptionChanged: (value) =>
                    _provider.updateDescription(slot, value),
                onDescriptionEditingComplete: () =>
                    _provider.saveDescriptionNow(slot),
                isSavingDescription: _provider.isSaving(slot),
              ),
              index,
            );
          },
        );
      },
    );
  }

  Widget _buildDayRating(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final rating = _provider.dayRating;
    final options = [
      (value: 1, label: 'Bad', icon: Icons.sentiment_very_dissatisfied),
      (value: 2, label: 'Okay', icon: Icons.sentiment_neutral),
      (value: 3, label: 'Great', icon: Icons.sentiment_very_satisfied),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'How was your day?',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  rating == null ? 'Not set' : 'Logged',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Tap the mood that matches this day overall.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: options.map((option) {
                final selected = rating == option.value;
                final optionColor = _ratingColor(colorScheme, option.value);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _provider.updateDayRating(option.value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: selected
                                ? optionColor.withValues(alpha: 0.18)
                                : colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? optionColor
                                  : colorScheme.outlineVariant.withValues(
                                      alpha: 0.6,
                                    ),
                              width: selected ? 1.4 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                option.icon,
                                size: 22,
                                color: selected
                                    ? optionColor
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                option.label,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: selected
                                      ? optionColor
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyMetrics(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final goalMet = _provider.isWaterGoalMet;
    final waterLabel = _provider.waterLiters == null
        ? 'Not logged'
        : '${_formatWater(_provider.waterLiters!)} L';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.water_drop_outlined,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Daily Metrics',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (goalMet)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Goal met',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Log water and exercise for this day.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.opacity,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Water',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _waterController,
                    focusNode: _waterFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: _provider.updateWaterLiters,
                    decoration: InputDecoration(
                      isDense: true,
                      suffixText: 'L',
                      hintText: '0.0',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Goal: 1.5 L',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  waterLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: goalMet
                        ? colorScheme.tertiary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: goalMet ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.directions_run_outlined,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Exercise',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Switch.adaptive(
                  value: _provider.exerciseDone,
                  onChanged: _provider.updateExerciseDone,
                ),
              ],
            ),
            TextField(
              controller: _exerciseNoteController,
              focusNode: _exerciseNoteFocusNode,
              maxLines: 2,
              minLines: 1,
              onChanged: _provider.updateExerciseNote,
              decoration: InputDecoration(
                hintText: 'Optional: walk, gym, yoga',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _ratingColor(ColorScheme colorScheme, int rating) {
    return switch (rating) {
      1 => colorScheme.error,
      2 => colorScheme.tertiary,
      3 => colorScheme.primary,
      _ => colorScheme.outline,
    };
  }

  String _formatWater(double value) {
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  }

  Widget _buildStaggeredItem(Widget child, int index) {
    final start = (index * 0.12);
    final end = math.min(1.0, start + 0.6);
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

  Widget _buildErrorWidget(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            _provider.error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.error),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              _provider.clearError();
              _provider.loadMealsForDate();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearConfirmation(MealSlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Meal'),
        content: Text('Are you sure you want to clear ${slot.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _provider.clearMeal(slot);
    }
  }
}
