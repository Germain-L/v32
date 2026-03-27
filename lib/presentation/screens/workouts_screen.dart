import 'package:flutter/material.dart';
import '../../data/models/workout.dart';
import '../../data/repositories/workout_repository_interface.dart';
import '../../data/repositories/repository_factory.dart';
import '../../gen_l10n/app_localizations.dart';
import '../../utils/date_formatter.dart';
import '../../utils/l10n_helper.dart';
import '../widgets/haptic_feedback_wrapper.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/staggered_item.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen>
    with SingleTickerProviderStateMixin {
  late final WorkoutRepository _repository;
  late final AnimationController _listController;

  List<Workout> _workouts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = RepositoryFactory().getWorkoutRepository();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _loadWorkouts();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkouts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final workouts = await _repository.getWorkoutsBefore(
        DateTime.now(),
        limit: 50,
      );
      _workouts = workouts;
      _isLoading = false;
      _listController.forward(from: 0);
      setState(() {});
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = context.l10n.errorLoadWorkouts;
      });
    }
  }

  Future<void> _addWorkout() async {
    HapticFeedbackUtil.trigger(HapticLevel.light);
    final result = await showModalBottomSheet<Workout>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _AddWorkoutSheet(),
    );

    if (result != null) {
      try {
        await _repository.saveWorkout(result);
        await _loadWorkouts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.errorSaveWorkout),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteWorkout(Workout workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.workoutDelete),
        content: Text(context.l10n.workoutDeleteConfirmation),
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

    if (confirmed == true && workout.id != null) {
      HapticFeedbackUtil.trigger(HapticLevel.heavy);
      try {
        await _repository.deleteWorkout(workout.id!);
        await _loadWorkouts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.errorDeleteWorkout),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  List<_WorkoutGroup> _groupWorkouts(List<Workout> workouts) {
    final groups = <DateTime, List<Workout>>{};

    for (final workout in workouts) {
      final date = DateTime(
        workout.date.year,
        workout.date.month,
        workout.date.day,
      );
      groups.putIfAbsent(date, () => []).add(workout);
    }

    return groups.entries
        .map((e) => _WorkoutGroup(date: e.key, workouts: e.value))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.workoutsTitle),
      ),
      body: _buildBody(theme, l10n),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWorkout,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n) {
    if (_isLoading) {
      return SkeletonLoading(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SkeletonCard(),
            SizedBox(height: 12),
            SkeletonCard(),
            SizedBox(height: 12),
            SkeletonCard(),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadWorkouts,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_workouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.workoutsEmpty,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.workoutsEmptySubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final groups = _groupWorkouts(_workouts);
    var index = 0;

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: groups.length,
      itemBuilder: (context, groupIndex) {
        final group = groups[groupIndex];
        final items = <Widget>[];

        // Date separator
        items.add(
          StaggeredItem(
            index: index++,
            animationController: _listController,
            child: _DateSeparator(date: group.date),
          ),
        );

        // Workouts for this date
        for (final workout in group.workouts) {
          items.add(
            StaggeredItem(
              index: index++,
              animationController: _listController,
              child: _WorkoutCard(
                workout: workout,
                onDelete: () => _deleteWorkout(workout),
              ),
            ),
          );
        }

        return Column(children: items);
      },
    );
  }
}

class _WorkoutGroup {
  final DateTime date;
  final List<Workout> workouts;

  _WorkoutGroup({required this.date, required this.workouts});
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final label = context.dateFormatter.formatShortDate(date);

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
}

class _WorkoutCard extends StatelessWidget {
  final Workout workout;
  final VoidCallback onDelete;

  const _WorkoutCard({
    required this.workout,
    required this.onDelete,
  });

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  IconData _getIcon(WorkoutType type) {
    switch (type) {
      case WorkoutType.run:
        return Icons.directions_run;
      case WorkoutType.cycle:
        return Icons.directions_bike;
      case WorkoutType.gym:
        return Icons.fitness_center;
      case WorkoutType.swim:
        return Icons.pool;
      case WorkoutType.walk:
        return Icons.directions_walk;
      case WorkoutType.hiking:
        return Icons.hiking;
      case WorkoutType.other:
        return Icons.sports;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Dismissible(
      key: ValueKey('workout_${workout.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      onUpdate: (details) {
        if (details.progress >= 0.4 && details.progress < 0.5) {
          HapticFeedbackUtil.trigger(HapticLevel.medium);
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIcon(workout.type),
                      color: colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.type.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          context.dateFormatter.formatTime(workout.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (workout.source == 'strava')
                    Icon(
                      Icons.link,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (workout.durationSeconds != null)
                    _MetricChip(
                      icon: Icons.timer_outlined,
                      label: _formatDuration(workout.durationSeconds!),
                    ),
                  if (workout.distanceMeters != null)
                    _MetricChip(
                      icon: Icons.straighten,
                      label: _formatDistance(workout.distanceMeters!),
                    ),
                  if (workout.calories != null)
                    _MetricChip(
                      icon: Icons.local_fire_department_outlined,
                      label: l10n.workoutCalories(workout.calories.toString()),
                    ),
                  if (workout.heartRateAvg != null)
                    _MetricChip(
                      icon: Icons.favorite_outline,
                      label: l10n.workoutHeartRate(workout.heartRateAvg.toString()),
                    ),
                ],
              ),
              if (workout.notes != null && workout.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  workout.notes!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddWorkoutSheet extends StatefulWidget {
  const _AddWorkoutSheet();

  @override
  State<_AddWorkoutSheet> createState() => _AddWorkoutSheetState();
}

class _AddWorkoutSheetState extends State<_AddWorkoutSheet> {
  WorkoutType _type = WorkoutType.run;
  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _durationController.dispose();
    _distanceController.dispose();
    _caloriesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _save() {
    final durationMinutes = int.tryParse(_durationController.text);
    final distanceMeters = double.tryParse(_distanceController.text);
    final calories = int.tryParse(_caloriesController.text);

    final workout = Workout(
      type: _type,
      date: _date,
      durationSeconds: durationMinutes != null ? durationMinutes * 60 : null,
      distanceMeters: distanceMeters,
      calories: calories,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    Navigator.of(context).pop(workout);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.workoutAdd,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          
          // Workout type
          Text(
            l10n.workoutType,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: WorkoutType.values.map((type) {
              final selected = _type == type;
              return ChoiceChip(
                label: Text(type.displayName),
                selected: selected,
                onSelected: (v) {
                  if (v) {
                    HapticFeedbackUtil.trigger(HapticLevel.light);
                    setState(() => _type = type);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          
          // Duration
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.workoutDuration,
              suffixText: l10n.workoutDurationUnit,
            ),
          ),
          const SizedBox(height: 12),
          
          // Distance
          TextField(
            controller: _distanceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.workoutDistance,
              suffixText: l10n.workoutDistanceUnit,
            ),
          ),
          const SizedBox(height: 12),
          
          // Calories
          TextField(
            controller: _caloriesController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.workoutCaloriesLabel,
            ),
          ),
          const SizedBox(height: 12),
          
          // Date picker
          InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.workoutDate,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.dateFormatter.formatFullDate(_date)),
                  const Icon(Icons.calendar_today, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Notes
          TextField(
            controller: _notesController,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.workoutNotes,
            ),
          ),
          const SizedBox(height: 24),
          
          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: Text(l10n.workoutSave),
            ),
          ),
        ],
      ),
    );
  }
}
