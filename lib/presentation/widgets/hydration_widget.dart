import 'package:flutter/material.dart';
import '../../data/models/hydration.dart';
import '../../data/repositories/repository_factory.dart';
import '../../gen_l10n/app_localizations.dart';
import '../../utils/l10n_helper.dart';
import 'haptic_feedback_wrapper.dart';

/// A widget for tracking daily hydration with water glass icons.
class HydrationWidget extends StatefulWidget {
  /// The list of hydration entries for today.
  final List<Hydration> hydrations;

  /// Callback when hydration is added.
  final void Function(int amountMl)? onAdd;

  /// Callback when a hydration entry is removed.
  final void Function(Hydration hydration)? onRemove;

  /// Whether the widget is in a loading state.
  final bool isLoading;

  const HydrationWidget({
    super.key,
    required this.hydrations,
    this.onAdd,
    this.onRemove,
    this.isLoading = false,
  });

  @override
  State<HydrationWidget> createState() => _HydrationWidgetState();
}

class _HydrationWidgetState extends State<HydrationWidget> {
  int get totalMl =>
      widget.hydrations.fold(0, (sum, h) => sum + h.amountMl);

  int get glassCount => (totalMl / 250).floor();

  bool get isGoalMet => totalMl >= 2000;

  void _addWater(int amountMl) {
    HapticFeedbackUtil.trigger(HapticLevel.light);
    widget.onAdd?.call(amountMl);
  }

  void _removeHydration(Hydration hydration) {
    HapticFeedbackUtil.trigger(HapticLevel.medium);
    widget.onRemove?.call(hydration);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.water_drop,
                  color: colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.hydrationTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (isGoalMet)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.goalMet,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Total display
            Center(
              child: Text(
                l10n.hydrationTotal(totalMl.toString()),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Glass icons (8 glasses = 2000ml goal)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(8, (index) {
                final isFilled = index < glassCount;
                return GestureDetector(
                  onTap: widget.isLoading
                      ? null
                      : () {
                          if (!isFilled && widget.onAdd != null) {
                            _addWater(250);
                          } else if (isFilled &&
                              index < widget.hydrations.length &&
                              widget.onRemove != null) {
                            _removeHydration(
                              widget.hydrations[index],
                            );
                          }
                        },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      isFilled ? Icons.water_drop : Icons.water_drop_outlined,
                      color: isFilled
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      size: 28,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            
            // Quick add buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _QuickAddButton(
                  label: l10n.hydrationAdd250ml,
                  icon: Icons.add,
                  onPressed: widget.isLoading ? null : () => _addWater(250),
                ),
                _QuickAddButton(
                  label: l10n.hydrationAdd500ml,
                  icon: Icons.add,
                  onPressed: widget.isLoading ? null : () => _addWater(500),
                ),
              ],
            ),
            
            // Recent entries
            if (widget.hydrations.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                l10n.hydrationRecent,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...widget.hydrations.reversed.take(5).map(
                (h) => _HydrationEntry(
                  hydration: h,
                  onDelete: widget.isLoading || widget.onRemove == null
                      ? null
                      : () => _removeHydration(h),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _QuickAddButton({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilledButton.tonal(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _HydrationEntry extends StatelessWidget {
  final Hydration hydration;
  final VoidCallback? onDelete;

  const _HydrationEntry({
    required this.hydration,
    this.onDelete,
  });

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.water_drop,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '${hydration.amountMl} ml',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTime(hydration.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: onDelete,
              color: colorScheme.error,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
        ],
      ),
    );
  }
}
