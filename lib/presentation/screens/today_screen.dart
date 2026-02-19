import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../data/models/meal.dart';
import '../../data/repositories/meal_repository.dart';
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

  @override
  void initState() {
    super.initState();
    if (widget.provider != null) {
      _provider = widget.provider!;
      _ownsProvider = false;
    } else {
      _provider = TodayProvider(MealRepository());
      _ownsProvider = true;
    }
    for (final slot in MealSlot.values) {
      _controllers[slot] = TextEditingController();
      _focusNodes[slot] = FocusNode();
    }
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    if (_ownsProvider) {
      _provider.dispose();
    }
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Today'),
            Text(
              _formatDate(now),
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
          if (_provider.error != null) {
            return _buildErrorWidget();
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 20),
            itemCount: MealSlot.values.length,
            itemBuilder: (context, index) {
              final slot = MealSlot.values[index];
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
