import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/meal.dart';
import '../../data/repositories/day_rating_repository.dart';
import '../../data/repositories/meal_repository.dart';
import '../../utils/date_formatter.dart';
import '../../utils/l10n_helper.dart';
import '../providers/today_provider.dart';
import '../widgets/meal_slot.dart';

class TodayScreen extends StatefulWidget {
  final TodayProvider? provider;

  const TodayScreen({super.key, this.provider});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen>
    with SingleTickerProviderStateMixin {
  late final TodayProvider _provider;
  late final bool _ownsProvider;
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
    if (widget.provider != null) {
      _provider = widget.provider!;
      _ownsProvider = false;
    } else {
      _provider = TodayProvider(MealRepository(), DayRatingRepository());
      _ownsProvider = true;
    }
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
    if (_ownsProvider) {
      await _provider.flushAndDispose();
    }
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
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(context.l10n.todayTitle),
            Text(
              context.dateFormatter.formatFullDate(now),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: ListenableBuilder(
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
            return _buildErrorWidget();
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
      ),
    );
  }

  Widget _buildDayRating(ThemeData theme) {
    final l10n = context.l10n;
    final colorScheme = theme.colorScheme;
    final rating = _provider.dayRating;
    final options = [
      (
        value: 1,
        label: l10n.ratingBad,
        icon: Icons.sentiment_very_dissatisfied,
      ),
      (value: 2, label: l10n.ratingOkay, icon: Icons.sentiment_neutral),
      (value: 3, label: l10n.ratingGreat, icon: Icons.sentiment_very_satisfied),
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
                  l10n.howWasYourDay,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  rating == null ? l10n.ratingNotSet : l10n.ratingLogged,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.dayRatingSubtitleToday,
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
    final l10n = context.l10n;
    final colorScheme = theme.colorScheme;
    final goalMet = _provider.isWaterGoalMet;
    final waterLabel = _provider.waterLiters == null
        ? l10n.notLogged
        : l10n.waterAmount(_formatWater(_provider.waterLiters!));

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
                  l10n.dailyMetrics,
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
                      l10n.goalMet,
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
              l10n.dailyMetricsSubtitleToday,
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
                  l10n.waterLabel,
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
                      suffixText: l10n.waterUnit,
                      hintText: l10n.waterHintText,
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
                  l10n.waterGoal,
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
                  l10n.exerciseLabel,
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
                hintText: l10n.exerciseHintText,
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

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _provider.error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              _provider.clearError();
              _provider.loadTodayMeals();
            },
            child: Text(context.l10n.retry),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearConfirmation(MealSlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.clearMeal),
        content: Text(
          context.l10n.clearMealConfirmation(slot.localizedName(context.l10n)),
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
      await _provider.clearMeal(slot);
    }
  }

  String _formatWater(double value) {
    return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
  }
}
