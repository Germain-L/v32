import 'package:flutter/material.dart';

/// Returns a color based on the meal rating.
///
/// - 1 → error color (poor)
/// - 2 → tertiary color (average)
/// - 3 → primary color (good)
/// - null or other → outline color (neutral)
///
/// For calendar use cases where null should be transparent,
/// use [ratingColorTransparentOnNull] instead.
Color ratingColor(ColorScheme colorScheme, int? rating) {
  return switch (rating) {
    1 => colorScheme.error,
    2 => colorScheme.tertiary,
    3 => colorScheme.primary,
    _ => colorScheme.outline,
  };
}

/// Returns a color based on the meal rating, with null returning transparent.
///
/// This variant is used in calendar views where unrated items should
/// not show any color indicator.
Color ratingColorTransparentOnNull(ColorScheme colorScheme, int? rating) {
  if (rating == null) return Colors.transparent;
  return ratingColor(colorScheme, rating);
}

/// Formats a water amount value for display.
///
/// Shows no decimal places for whole numbers, one decimal place otherwise.
/// Examples: 1.0 → "1", 1.5 → "1.5"
String formatWater(double value) {
  return value.toStringAsFixed(value % 1 == 0 ? 0 : 1);
}

/// Spring curve for animations with slight overshoot.
///
/// Used for staggered list animations and other entrance effects
/// where a subtle bounce adds polish.
const Curve kSpringCurve = Curves.easeOutBack;

/// Default slide offset for staggered list animations.
///
/// Slides items up by 4% of the container height.
const Offset kStaggeredSlideDelta = Offset(0, 0.04);
