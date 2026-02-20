import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../utils/animation_helpers.dart';

/// A widget that animates its child with a staggered fade and slide animation.
///
/// Uses spring physics (easeOutBack curve) for a subtle bounce effect.
/// The animation timing can be customized via [startMultiplier] and [intervalDuration].
///
/// Example usage:
/// ```dart
/// StaggeredItem(
///   index: index,
///   animationController: _listController,
///   child: MyWidget(),
/// )
/// ```
class StaggeredItem extends StatelessWidget {
  /// The child widget to animate.
  final Widget child;

  /// The index of this item in the list, used to calculate stagger timing.
  final int index;

  /// The animation controller driving the stagger animation.
  final AnimationController animationController;

  /// Multiplier applied to [index] to determine the start of the animation interval.
  /// Default is 0.12 (12% per item).
  final double startMultiplier;

  /// The duration of the animation interval for each item.
  /// Default is 0.6 (60% of the total animation duration).
  final double intervalDuration;

  const StaggeredItem({
    super.key,
    required this.child,
    required this.index,
    required this.animationController,
    this.startMultiplier = 0.12,
    this.intervalDuration = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    final start = (index * startMultiplier);
    final end = math.min(1.0, start + intervalDuration);
    final animation = CurvedAnimation(
      parent: animationController,
      curve: Interval(start, end, curve: kSpringCurve),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: kStaggeredSlideDelta,
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}
