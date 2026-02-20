import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Represents different intensities of haptic feedback.
enum HapticLevel {
  /// Light impact - used for tab switches, rating taps
  light,

  /// Medium impact - used for swipe-to-delete threshold, save confirmation
  medium,

  /// Heavy impact - used for delete confirmation
  heavy,

  /// Selection click - used for calendar day tap, meal slot selection
  selection,

  /// Error vibration - used for save/load failures
  error,
}

/// Utility class for triggering haptic feedback.
///
/// This class provides a single call site for all haptic feedback
/// in the app, making it easy to manage and adjust haptics globally.
class HapticFeedbackUtil {
  const HapticFeedbackUtil._();

  /// Triggers the appropriate haptic feedback for the given level.
  static void trigger(HapticLevel level) {
    switch (level) {
      case HapticLevel.light:
        HapticFeedback.lightImpact();
      case HapticLevel.medium:
        HapticFeedback.mediumImpact();
      case HapticLevel.heavy:
        HapticFeedback.heavyImpact();
      case HapticLevel.selection:
        HapticFeedback.selectionClick();
      case HapticLevel.error:
        HapticFeedback.vibrate();
    }
  }
}

/// A widget that wraps a child and triggers haptic feedback on tap.
///
/// This is useful for adding haptic feedback to any tappable widget
/// without modifying the widget itself.
class HapticWrapper extends StatelessWidget {
  /// The level of haptic feedback to trigger.
  final HapticLevel level;

  /// Callback to be invoked after the haptic feedback.
  final VoidCallback? onTap;

  /// The child widget to wrap.
  final Widget child;

  const HapticWrapper({
    super.key,
    this.level = HapticLevel.selection,
    this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }

  void _handleTap() {
    HapticFeedbackUtil.trigger(level);
    onTap?.call();
  }
}
