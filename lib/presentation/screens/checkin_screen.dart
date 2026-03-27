import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/models/daily_checkin.dart';
import '../../data/repositories/daily_checkin_repository_interface.dart';
import '../../data/repositories/repository_factory.dart';
import '../../gen_l10n/app_localizations.dart';
import '../../utils/date_formatter.dart';
import '../../utils/l10n_helper.dart';
import '../widgets/haptic_feedback_wrapper.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/staggered_item.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen>
    with SingleTickerProviderStateMixin {
  late final DailyCheckinRepository _repository;
  late final AnimationController _listController;

  DailyCheckin? _checkin;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  int _mood = 3;
  int _energy = 3;
  int _focus = 3;
  int _stress = 3;
  double _sleepHours = 7;
  int _sleepQuality = 3;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repository = RepositoryFactory().getDailyCheckinRepository();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _loadCheckin();
  }

  @override
  void dispose() {
    _listController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCheckin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final checkin = await _repository.getDailyCheckinForDate(DateTime.now());
      if (checkin != null) {
        _checkin = checkin;
        _mood = checkin.mood ?? 3;
        _energy = checkin.energy ?? 3;
        _focus = checkin.focus ?? 3;
        _stress = checkin.stress ?? 3;
        _sleepHours = checkin.sleepHours ?? 7;
        _sleepQuality = checkin.sleepQuality ?? 3;
        _notesController.text = checkin.notes ?? '';
      }
      _isLoading = false;
      _listController.forward(from: 0);
      setState(() {});
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = context.l10n.errorLoadCheckin;
      });
    }
  }

  Future<void> _saveCheckin() async {
    HapticFeedbackUtil.trigger(HapticLevel.medium);
    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final checkin = DailyCheckin(
        id: _checkin?.id,
        serverId: _checkin?.serverId,
        date: DateTime.now(),
        mood: _mood,
        energy: _energy,
        focus: _focus,
        stress: _stress,
        sleepHours: _sleepHours,
        sleepQuality: _sleepQuality,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      _checkin = await _repository.saveDailyCheckin(checkin);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.checkinSaved),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = context.l10n.errorSaveCheckin;
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(l10n.checkinTitle),
            Text(
              context.dateFormatter.formatFullDate(now),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: _buildBody(theme, l10n),
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

    if (_error != null && _checkin == null) {
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
              onPressed: _loadCheckin,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        StaggeredItem(
          index: 0,
          animationController: _listController,
          child: _SliderCard(
            title: l10n.checkinMood,
            icon: Icons.sentiment_satisfied_alt,
            value: _mood.toDouble(),
            min: 1.0,
            max: 5.0,
            divisions: 4,
            labels: [
              l10n.checkinVeryLow,
              l10n.checkinLow,
              l10n.checkinMedium,
              l10n.checkinHigh,
              l10n.checkinVeryHigh,
            ],
            onChanged: (v) => setState(() => _mood = v.round()),
          ),
        ),
        StaggeredItem(
          index: 1,
          animationController: _listController,
          child: _SliderCard(
            title: l10n.checkinEnergy,
            icon: Icons.bolt,
            value: _energy.toDouble(),
            min: 1.0,
            max: 5.0,
            divisions: 4,
            labels: [
              l10n.checkinVeryLow,
              l10n.checkinLow,
              l10n.checkinMedium,
              l10n.checkinHigh,
              l10n.checkinVeryHigh,
            ],
            onChanged: (v) => setState(() => _energy = v.round()),
          ),
        ),
        StaggeredItem(
          index: 2,
          animationController: _listController,
          child: _SliderCard(
            title: l10n.checkinFocus,
            icon: Icons.center_focus_strong,
            value: _focus.toDouble(),
            min: 1.0,
            max: 5.0,
            divisions: 4,
            labels: [
              l10n.checkinVeryLow,
              l10n.checkinLow,
              l10n.checkinMedium,
              l10n.checkinHigh,
              l10n.checkinVeryHigh,
            ],
            onChanged: (v) => setState(() => _focus = v.round()),
          ),
        ),
        StaggeredItem(
          index: 3,
          animationController: _listController,
          child: _SliderCard(
            title: l10n.checkinStress,
            icon: Icons.psychology_alt,
            value: _stress.toDouble(),
            min: 1.0,
            max: 5.0,
            divisions: 4,
            labels: [
              l10n.checkinVeryLow,
              l10n.checkinLow,
              l10n.checkinMedium,
              l10n.checkinHigh,
              l10n.checkinVeryHigh,
            ],
            onChanged: (v) => setState(() => _stress = v.round()),
          ),
        ),
        StaggeredItem(
          index: 4,
          animationController: _listController,
          child: _SleepCard(
            hours: _sleepHours,
            quality: _sleepQuality,
            qualityLabels: [
              l10n.checkinVeryLow,
              l10n.checkinLow,
              l10n.checkinMedium,
              l10n.checkinHigh,
              l10n.checkinVeryHigh,
            ],
            onHoursChanged: (v) => setState(() => _sleepHours = v),
            onQualityChanged: (v) => setState(() => _sleepQuality = v.round()),
          ),
        ),
        StaggeredItem(
          index: 5,
          animationController: _listController,
          child: _NotesCard(
            controller: _notesController,
            onChanged: () => setState(() {}),
          ),
        ),
        StaggeredItem(
          index: 6,
          animationController: _listController,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _isSaving ? null : _saveCheckin,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(l10n.checkinSave),
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _SliderCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final List<String> labels;
  final ValueChanged<double> onChanged;

  const _SliderCard({
    required this.title,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final index = (value - min).round();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  labels[index],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: (v) {
                HapticFeedbackUtil.trigger(HapticLevel.light);
                onChanged(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepCard extends StatelessWidget {
  final double hours;
  final int quality;
  final List<String> qualityLabels;
  final ValueChanged<double> onHoursChanged;
  final ValueChanged<double> onQualityChanged;

  const _SleepCard({
    required this.hours,
    required this.quality,
    required this.qualityLabels,
    required this.onHoursChanged,
    required this.onQualityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bedtime, color: colorScheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  l10n.checkinSleep,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Sleep hours
            Row(
              children: [
                Text(
                  l10n.checkinSleepHours,
                  style: theme.textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  l10n.checkinSleepHoursValue(hours.toStringAsFixed(1)),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Slider(
              value: hours,
              min: 0,
              max: 12,
              divisions: 24,
              onChanged: (v) {
                HapticFeedbackUtil.trigger(HapticLevel.light);
                onHoursChanged(v);
              },
            ),
            const SizedBox(height: 8),
            
            // Sleep quality
            Row(
              children: [
                Text(
                  l10n.checkinSleepQuality,
                  style: theme.textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  qualityLabels[quality - 1],
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Slider(
              value: quality.toDouble(),
              min: 1.0,
              max: 5.0,
              divisions: 4,
              onChanged: (v) {
                HapticFeedbackUtil.trigger(HapticLevel.light);
                onQualityChanged(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _NotesCard({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notes,
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.checkinNotes,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: l10n.checkinNotesHint,
              ),
              onChanged: (_) => onChanged(),
            ),
          ],
        ),
      ),
    );
  }
}
