import 'package:flutter/material.dart';
import '../../utils/animation_helpers.dart';
import '../../utils/l10n_helper.dart';
import 'haptic_feedback_wrapper.dart';
import 'press_scale.dart';

/// A widget for displaying and selecting a day rating (1-3).
///
/// Used on both TodayScreen and DayDetailScreen.
class DayRatingWidget extends StatelessWidget {
  /// The current rating value (1-3), or null if not set.
  final int? rating;

  /// Callback when a rating is selected.
  final ValueChanged<int> onRatingSelected;

  /// The subtitle text to display below the title.
  final String subtitle;

  const DayRatingWidget({
    super.key,
    required this.rating,
    required this.onRatingSelected,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: options.map((option) {
                final selected = rating == option.value;
                final optionColor = ratingColor(colorScheme, option.value);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: PressScale(
                      onTap: () {
                        HapticFeedbackUtil.trigger(HapticLevel.light);
                        onRatingSelected(option.value);
                      },
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            HapticFeedbackUtil.trigger(HapticLevel.light);
                            onRatingSelected(option.value);
                          },
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
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
