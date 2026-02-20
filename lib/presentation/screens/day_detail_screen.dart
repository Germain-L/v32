import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/meal.dart';
import '../../data/repositories/day_rating_repository.dart';
import '../../data/repositories/meal_repository.dart';
import '../../gen_l10n/app_localizations.dart';
import '../../utils/date_formatter.dart';
import '../../utils/l10n_helper.dart';
import '../../utils/meal_slot_localization.dart';
import '../providers/day_detail_provider.dart';
import '../widgets/daily_metrics_widget.dart';
import '../widgets/day_rating_widget.dart';
import '../widgets/haptic_feedback_wrapper.dart';
import '../widgets/meal_slot.dart';
import '../widgets/staggered_item.dart';

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
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(l10n.dayDetailTitle),
            Text(
              context.dateFormatter.formatFullDate(_currentDate),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l10n.jumpToToday,
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
    final l10n = context.l10n;

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
            : (_provider.waterLiters! * 1000).toStringAsFixed(
                _provider.waterLiters! % 1 == 0 ? 0 : 1,
              );
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
          return _buildErrorWidget(colorScheme, l10n);
        }

        return ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 20),
          itemCount: MealSlot.values.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return StaggeredItem(
                index: index,
                animationController: _listController,
                child: DayRatingWidget(
                  rating: _provider.dayRating,
                  onRatingSelected: (value) =>
                      _provider.updateDayRating(value, l10n),
                  subtitle: l10n.dayRatingSubtitleDay,
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
                  subtitle: l10n.dailyMetricsSubtitleDay,
                  waterHintText: '0',
                  displayWaterInMl: true,
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
                onCapturePhoto: () => _provider.capturePhoto(slot, l10n),
                onPickImage: () => _provider.pickImage(slot, l10n),
                onDeletePhoto: () => _provider.deletePhoto(slot, l10n),
                onClearMeal: () => _showClearConfirmation(slot, l10n),
                descriptionController: _controllers[slot],
                descriptionFocusNode: _focusNodes[slot],
                onDescriptionChanged: (value) =>
                    _provider.updateDescription(slot, value),
                onDescriptionEditingComplete: () =>
                    _provider.saveDescriptionNow(slot),
                isSavingDescription: _provider.isSaving(slot),
                heroTag: _provider.getMeal(slot)?.id != null
                    ? 'meal-photo-${_provider.getMeal(slot)!.id}'
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorWidget(ColorScheme colorScheme, AppLocalizations l10n) {
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
              color: colorScheme.error,
            ),
          ),
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
              _provider.loadMealsForDate(l10n);
            },
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearConfirmation(
    MealSlot slot,
    AppLocalizations l10n,
  ) async {
    HapticFeedbackUtil.trigger(HapticLevel.heavy);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearMeal),
        content: Text(
          l10n.clearMealConfirmation(
            MealSlotLocalization(slot).localizedName(l10n),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.clear),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _provider.clearMeal(slot, l10n);
    }
  }
}
