# Motion Overhaul Learnings

## Task 3: PressScale Widget - Implementation Notes

### Date: 2026-02-20

### What Was Built
Created `lib/presentation/widgets/press_scale.dart` - a reusable press feedback widget that scales down its child on tap.

### Key Implementation Details

**Animation Approach:**
- Uses `SingleTickerProviderStateMixin` for vsync
- `AnimationController` with configurable duration (default 120ms)
- `Tween<double>` from 1.0 to scaleFactor
- `Transform.scale` with `AnimatedBuilder` for performance

**Gesture Handling:**
- `onTapDown`: Triggers forward animation with `Curves.easeInOut`
- `onTapUp`: Triggers reverse animation with `Curves.easeOutBack` (spring bounce)
- `onTapCancel`: Same as onTapUp for consistent behavior
- `onTap`: Calls the provided callback

**Props:**
- `child` (Widget, required) - the widget to wrap
- `onTap` (VoidCallback?, optional) - tap callback
- `scaleFactor` (double, default 0.96) - subtle but noticeable press depth
- `duration` (Duration, default 120ms) - quick, responsive feedback

### Design Decisions

1. **Used Transform.scale instead of ScaleTransition:**
   - More direct control over the animation value
   - Allows for cleaner integration with GestureDetector

2. **Curves.easeOutBack for release:**
   - Provides subtle overshoot bounce that feels tactile
   - Different from press curve (easeInOut) for visual interest

3. **120ms duration:**
   - Quick enough to feel responsive
   - Within 400ms guardrail for micro-interactions
   - Default matches platform expectations

4. **0.96 scaleFactor:**
   - Subtle but noticeable (4% reduction)
   - Not too aggressive to be distracting
   - Customizable via prop for different contexts

### Integration Notes
- This widget wraps around children that may already have InkWell
- Does NOT replace InkWell - combines with it
- Haptic feedback should be added separately (Task 2)
- Integration wiring happens in Task 10

### Code Pattern Reference
Followed existing patterns from:
- `today_screen.dart` lines 51-54: AnimationController creation
- `meal_slot.dart` lines 37-53: StatefulWidget build structure

## Task 1: Extract Shared Animation Helpers

### Approach
Created `lib/utils/animation_helpers.dart` with unified helper functions extracted from screen files.

### Key Decisions

1. **ratingColor unification**: Created two variants to handle the null case difference:
   - `ratingColor()` - returns `colorScheme.outline` for null (used by today_screen, day_detail_screen)
   - `ratingColorTransparentOnNull()` - returns `Colors.transparent` for null (used by calendar_screen)

2. **formatWater**: Simple function that shows 0 decimals for whole numbers, 1 decimal otherwise.

3. **Animation constants**: 
   - `kSpringCurve = Curves.easeOutBack` for slight overshoot
   - `kStaggeredSlideDelta = Offset(0, 0.04)` for consistent slide animation

### Files Changed
- Created: lib/utils/animation_helpers.dart
- Modified: today_screen.dart, day_detail_screen.dart, calendar_screen.dart

### Verification
- flutter analyze: 0 errors
- grep: 0 duplicate implementations found in screen files

### Pattern
Following existing project pattern seen in lib/utils/date_formatter.dart for utility files.
