import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/meal.dart';
import '../../data/repositories/day_rating_repository.dart';
import '../../data/repositories/meal_repository.dart';
import '../../utils/animation_helpers.dart';
import '../../utils/date_formatter.dart';
import '../../utils/l10n_helper.dart';
import '../providers/today_provider.dart';
import '../widgets/daily_metrics_widget.dart';
import '../widgets/day_rating_widget.dart';
import '../widgets/haptic_feedback_wrapper.dart';
import '../widgets/meal_slot.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/staggered_item.dart';

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
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
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
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8, end: 0), weight: 1),
    ]).animate(_shakeController);
  }

  @override
  void dispose() {
    unawaited(_disposeAsync());
    _disposeControllers();
    _disposeFocusNodes();
    _listController.dispose();
    _shakeController.dispose();
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
              : formatWater(_provider.waterLiters!);
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

          if (_provider.isLoadingInitial) {
            return ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              children: [
                SkeletonLoading(
                  child: Column(
                    children: List.generate(4, (index) => const SkeletonCard()),
                  ),
                ),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 20),
            itemCount: MealSlot.values.length + 2,
            itemBuilder: (context, index) {
              final l10n = context.l10n;
              if (index == 0) {
                return StaggeredItem(
                  index: index,
                  animationController: _listController,
                  child: DayRatingWidget(
                    rating: _provider.dayRating,
                    onRatingSelected: (value) =>
                        _provider.updateDayRating(value),
                    subtitle: l10n.dayRatingSubtitleToday,
                  ),
                );
              }
              if (index == 1) {
                return StaggeredItem(
                  index: index,
                  animationController: _listController,
                  child: DailyMetricsWidget(
                    waterLiters: _provider.waterLiters,
                    isWaterGoalMet: _provider.isWaterGoalMet,
                    exerciseDone: _provider.exerciseDone,
                    waterController: _waterController,
                    waterFocusNode: _waterFocusNode,
                    exerciseNoteController: _exerciseNoteController,
                    exerciseNoteFocusNode: _exerciseNoteFocusNode,
                    onWaterChanged: _provider.updateWaterLiters,
                    onExerciseDoneChanged: _provider.updateExerciseDone,
                    onExerciseNoteChanged: _provider.updateExerciseNote,
                    subtitle: l10n.dailyMetricsSubtitleToday,
                    waterHintText: l10n.waterHintText,
                    displayWaterInMl: false,
                  ),
                );
              }
              final slot = MealSlot.values[index - 2];
              return StaggeredItem(
                index: index,
                animationController: _listController,
                child: MealSlotWidget(
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
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    HapticFeedbackUtil.trigger(HapticLevel.error);
    _shakeController.forward(from: 0);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_shakeAnimation.value, 0),
                child: child,
              );
            },
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
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
    HapticFeedbackUtil.trigger(HapticLevel.heavy);
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
}
