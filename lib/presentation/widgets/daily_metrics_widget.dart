import 'package:flutter/material.dart';
import '../../utils/animation_helpers.dart';
import '../../utils/l10n_helper.dart';
import 'haptic_feedback_wrapper.dart';

/// A widget for displaying and editing daily metrics (water and exercise).
///
/// Used on both TodayScreen and DayDetailScreen.
class DailyMetricsWidget extends StatefulWidget {
  /// The current water amount in liters, or null if not set.
  final double? waterLiters;

  /// Whether the water goal (1.5L) has been met.
  final bool isWaterGoalMet;

  /// Whether exercise has been completed.
  final bool exerciseDone;

  /// Controller for the water input field.
  final TextEditingController waterController;

  /// Focus node for the water input field.
  final FocusNode waterFocusNode;

  /// Controller for the exercise note field.
  final TextEditingController exerciseNoteController;

  /// Focus node for the exercise note field.
  final FocusNode exerciseNoteFocusNode;

  /// Callback when water input changes.
  final ValueChanged<String> onWaterChanged;

  /// Callback when exercise toggle changes.
  final ValueChanged<bool> onExerciseDoneChanged;

  /// Callback when exercise note changes.
  final ValueChanged<String> onExerciseNoteChanged;

  /// The subtitle text to display below the title.
  final String subtitle;

  /// Hint text for the water input field.
  final String waterHintText;

  /// Whether to display water in milliliters (true) or liters (false).
  final bool displayWaterInMl;

  const DailyMetricsWidget({
    super.key,
    required this.waterLiters,
    required this.isWaterGoalMet,
    required this.exerciseDone,
    required this.waterController,
    required this.waterFocusNode,
    required this.exerciseNoteController,
    required this.exerciseNoteFocusNode,
    required this.onWaterChanged,
    required this.onExerciseDoneChanged,
    required this.onExerciseNoteChanged,
    required this.subtitle,
    required this.waterHintText,
    this.displayWaterInMl = false,
  });

  @override
  State<DailyMetricsWidget> createState() => _DailyMetricsWidgetState();
}

class _DailyMetricsWidgetState extends State<DailyMetricsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _badgeController;
  late Animation<double> _badgeAnimation;

  @override
  void initState() {
    super.initState();
    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _badgeAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _badgeController, curve: Curves.easeInOut),
        );
  }

  @override
  void didUpdateWidget(DailyMetricsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isWaterGoalMet && !oldWidget.isWaterGoalMet) {
      _badgeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _badgeController.dispose();
    super.dispose();
  }

  String _formatWaterLabel(double? liters) {
    if (liters == null) return '';
    if (widget.displayWaterInMl) {
      return (liters * 1000).toStringAsFixed(liters % 1 == 0 ? 0 : 1);
    }
    return formatWater(liters);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final waterLabel = widget.waterLiters == null
        ? l10n.notLogged
        : l10n.waterAmount(_formatWaterLabel(widget.waterLiters));

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
                if (widget.isWaterGoalMet)
                  ScaleTransition(
                    scale: _badgeAnimation,
                    child: Container(
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
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.subtitle,
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
                    controller: widget.waterController,
                    focusNode: widget.waterFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) {
                      HapticFeedbackUtil.trigger(HapticLevel.medium);
                      widget.onWaterChanged(value);
                    },
                    decoration: InputDecoration(
                      isDense: true,
                      suffixText: l10n.waterUnit,
                      hintText: widget.waterHintText,
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
                    color: widget.isWaterGoalMet
                        ? colorScheme.tertiary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: widget.isWaterGoalMet
                        ? FontWeight.w600
                        : FontWeight.w500,
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
                  value: widget.exerciseDone,
                  onChanged: (value) {
                    HapticFeedbackUtil.trigger(HapticLevel.medium);
                    widget.onExerciseDoneChanged(value);
                  },
                ),
              ],
            ),
            TextField(
              controller: widget.exerciseNoteController,
              focusNode: widget.exerciseNoteFocusNode,
              maxLines: 2,
              minLines: 1,
              onChanged: (value) {
                HapticFeedbackUtil.trigger(HapticLevel.medium);
                widget.onExerciseNoteChanged(value);
              },
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
}
