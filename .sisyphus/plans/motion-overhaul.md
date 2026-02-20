# Motion Design Overhaul — Disney's 12 Principles

## TL;DR

> **Quick Summary**: Apply Disney's 12 animation principles to the diet-tracking app through a systematic motion overhaul — adding haptic feedback, spring physics, Hero transitions, skeleton loading, button press scale, calendar month transitions, swipe-to-delete, and polished error/success states. Simultaneously deduplicate shared helpers (`_buildStaggeredItem`, `_ratingColor`, `_formatWater`), extract `_buildDayRating`/`_buildDailyMetrics` into reusable widgets, and add widget tests for animation verification.
>
> **Deliverables**:
> - Haptic feedback layer across all interactive elements (5-tier intensity map)
> - Spring physics on staggered list animations (replacing linear easing)
> - Hero transitions on DayDetailScreen photo navigation
> - Skeleton/shimmer loading states replacing bare CircularProgressIndicator
> - Button press scale feedback on all tappable cards and rating buttons
> - Animated month transitions on CalendarScreen
> - Swipe-to-delete on meal cards in MealsScreen feed
> - Error/success animation polish (shake on error, checkmark on save)
> - Shared animation helpers extracted to `lib/presentation/widgets/`
> - `DayRatingWidget` and `DailyMetricsWidget` extracted as reusable widgets
> - Widget tests verifying animation controllers, curves, and durations
>
> **Estimated Effort**: Large
> **Parallel Execution**: YES — 4 waves
> **Critical Path**: Task 1 (helpers) → Task 2 (haptics) → Tasks 3-8 (parallel motion work) → Task 12 (widget tests) → Final Verification

---

## Context

### Original Request
User asked for a full review of the Flutter diet-tracking app. After a comprehensive audit scoring the app 5/10 on animation maturity, user chose "Full motion overhaul" to systematically apply Disney's 12 animation principles.

### Interview Summary
**Key Discussions**:
- **Hero transitions**: Hero only on DayDetailScreen (it's a proper route push via `/calendar/day/:date`). ModalBottomSheet in MealsScreen cannot support Hero — skip it there.
- **Haptic intensity map**: Accepted 5-tier mapping: `lightImpact` (tab switches, rating tap), `mediumImpact` (swipe-to-delete threshold, save confirmation), `heavyImpact` (delete confirmation), `selectionClick` (calendar day tap, meal slot selection), `notificationError` (save/load failure).
- **Scope exclusions**: No provider refactoring (TodayProvider/DayDetailProvider stay as-is). User DOES want `_buildDayRating`/`_buildDailyMetrics` extraction. User allows new packages if they simplify implementation.
- **Swipe-to-delete**: Yes, on meal feed cards in MealsScreen.
- **Code dedup**: Yes, clean up `_buildStaggeredItem`, `_ratingColor`, `_formatWater` duplication.
- **Widget tests**: Yes, for animation verification.

**Research Findings**:
- `_buildStaggeredItem` duplicated in 3 files with slightly different timing parameters (today: 0.12/0.6/650ms, meals: 0.08/0.5/800ms, day_detail: 0.12/0.6/650ms)
- `_ratingColor` duplicated in 3 files (today, day_detail: `int rating`; calendar: `int? rating` with null check)
- `_formatWater` duplicated in 3 files (today:564, day_detail:575, meals:535) — identical implementations
- Zero `HapticFeedback` imports anywhere in codebase
- Zero Hero widgets in codebase
- Zero spring physics in codebase
- CalendarScreen month changes are instant rebuilds with no transition
- All interactive elements use basic `InkWell` with no scale/press feedback
- DayDetailScreen uses `PageView.builder` with `animateToPage(280ms)` for day navigation
- ShellRoute transition already uses custom fade + micro-slide (260ms/220ms easeOutCubic) — preserve this

### Metis Review
**Identified Gaps** (addressed):
- **Hero on ModalBottomSheet**: Resolved — Hero only on DayDetailScreen route push
- **Haptic intensity mapping**: Resolved — user accepted proposed 5-tier map
- **Scope boundary confirmation**: Resolved — user confirmed no provider refactoring but added widget extraction and package allowance

---

## Work Objectives

### Core Objective
Transform the app from functional-but-static UI (5/10 animation maturity) to a polished, tactile experience (8+/10) by systematically applying Disney's 12 animation principles while deduplicating shared code and adding test coverage.

### Concrete Deliverables
- `lib/presentation/widgets/staggered_item.dart` — Shared staggered animation wrapper with configurable timing
- `lib/presentation/widgets/haptic_feedback_wrapper.dart` — Haptic feedback utility layer
- `lib/presentation/widgets/press_scale.dart` — Button/card press scale feedback widget
- `lib/presentation/widgets/skeleton_loading.dart` — Shimmer/skeleton loading widget
- `lib/presentation/widgets/day_rating_widget.dart` — Extracted from today_screen + day_detail_screen
- `lib/presentation/widgets/daily_metrics_widget.dart` — Extracted from today_screen + day_detail_screen
- `lib/utils/animation_helpers.dart` — Shared `_ratingColor`, `_formatWater`, spring curves
- Updated `lib/presentation/screens/today_screen.dart` — spring physics, haptics, press scale, extracted widgets
- Updated `lib/presentation/screens/meals_screen.dart` — swipe-to-delete, skeleton loading, haptics, press scale
- Updated `lib/presentation/screens/calendar_screen.dart` — animated month transition, haptics, press scale
- Updated `lib/presentation/screens/day_detail_screen.dart` — Hero transitions, spring physics, haptics, extracted widgets
- Updated `lib/presentation/widgets/meal_history_card.dart` — press scale, haptics
- Updated `lib/presentation/widgets/meal_slot.dart` — press scale, haptics, save success animation
- `test/widgets/staggered_item_test.dart` — Animation controller tests
- `test/widgets/press_scale_test.dart` — Scale animation tests
- `test/widgets/day_rating_widget_test.dart` — Rating widget tests
- `test/widgets/swipe_to_delete_test.dart` — Dismissible behavior tests

### Definition of Done
- [ ] `flutter analyze` — zero new warnings
- [ ] `flutter test` — all tests pass
- [ ] Every interactive element has haptic feedback (grep for `HapticFeedback` in all screen files)
- [ ] Zero remaining duplicated `_buildStaggeredItem`, `_ratingColor`, `_formatWater` methods
- [ ] `_buildDayRating` and `_buildDailyMetrics` extracted to standalone widgets
- [ ] Calendar month changes animate (not instant rebuild)
- [ ] Meal feed cards are swipe-to-delete capable
- [ ] All tappable cards/buttons have press scale feedback

### Must Have
- Haptic feedback on every interactive element (5-tier intensity map)
- Spring physics on staggered list entry animations
- Press scale feedback on tappable cards and rating buttons
- Animated calendar month transitions
- Swipe-to-delete on MealsScreen feed cards
- Hero transition on meal photo in DayDetailScreen
- Skeleton/shimmer loading replacing bare spinners
- Code dedup: shared helpers extracted
- Widget extraction: DayRatingWidget, DailyMetricsWidget
- Widget tests for animation behavior

### Must NOT Have (Guardrails)
- **No provider refactoring** — TodayProvider and DayDetailProvider stay as-is (~550 lines each)
- **No over-engineering** — Don't create abstract animation frameworks; keep helpers simple and concrete
- **No timing changes to existing ShellRoute transition** — The 260ms/220ms easeOutCubic fade+slide is intentional. Preserve it exactly.
- **No PageView removal** — DayDetailScreen's PageView.builder day swiping is a core UX pattern. Enhance but don't replace.
- **No AI slop** — No excessive JSDoc/comments, no generic `data`/`result` variable names, no unnecessary abstraction layers
- **No Cupertino-only patterns** — App uses Material 3. Keep all animations Material-consistent.
- **No breaking existing gesture recognizers** — `InkWell` must remain functional; press scale wraps it, doesn't replace it
- **No animation duration > 400ms** for micro-interactions (press scale, haptic triggers)
- **No animation duration < 150ms** for transitions (skeleton shimmer, month slide)

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: YES — `flutter_test` in dev_dependencies, `sqflite_common_ffi` for DB mocking
- **Automated tests**: YES (tests-after) — widget tests added after implementation
- **Framework**: `flutter_test` (built-in)

### QA Policy
Every task MUST include agent-executed QA scenarios.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **All tasks**: Use `flutter analyze` (zero new warnings) and `flutter test` (all pass)
- **UI verification**: Use `flutter test` widget tests — pump widgets, verify animation controllers, assert curves/durations
- **Code verification**: Use grep to verify dedup (no remaining duplicates), imports exist, etc.

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Foundation — shared helpers and infrastructure):
├── Task 1: Extract shared animation helpers (ratingColor, formatWater, spring curves) [quick]
├── Task 2: Create haptic feedback utility layer [quick]
└── Task 3: Create press scale feedback widget [quick]

Wave 2 (Core motion work — MAX PARALLEL):
├── Task 4: Extract DayRatingWidget + DailyMetricsWidget (depends: 1) [unspecified-high]
├── Task 5: Staggered list → spring physics + shared wrapper (depends: 1) [unspecified-high]
├── Task 6: Skeleton/shimmer loading widget + integration (depends: none new) [visual-engineering]
├── Task 7: Calendar month animated transition + haptics (depends: 2, 3) [visual-engineering]
├── Task 8: Swipe-to-delete on MealsScreen feed (depends: 2) [unspecified-high]
└── Task 9: Hero transition on DayDetailScreen photos (depends: none new) [unspecified-high]

Wave 3 (Integration — wire everything together):
├── Task 10: Integrate haptics + press scale into all screens (depends: 2, 3, 4, 5) [unspecified-high]
└── Task 11: Error/success animation polish (depends: 2) [visual-engineering]

Wave 4 (Verification):
├── Task 12: Widget tests for animation behavior (depends: all above) [unspecified-high]
└── Task 13: Final lint + analyze + format pass (depends: 12) [quick]

Wave FINAL (After ALL tasks — independent review, 4 parallel):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA (unspecified-high)
└── Task F4: Scope fidelity check (deep)

Critical Path: Task 1 → Task 5 → Task 10 → Task 12 → Task 13 → F1-F4
Parallel Speedup: ~60% faster than sequential
Max Concurrent: 6 (Wave 2)
```

### Dependency Matrix

| Task | Depends On | Blocks |
|------|-----------|--------|
| 1 | — | 4, 5, 10 |
| 2 | — | 7, 8, 10, 11 |
| 3 | — | 7, 10 |
| 4 | 1 | 10 |
| 5 | 1 | 10 |
| 6 | — | 10 |
| 7 | 2, 3 | 10 |
| 8 | 2 | 10 |
| 9 | — | 10 |
| 10 | 2, 3, 4, 5 | 12 |
| 11 | 2 | 12 |
| 12 | all 1-11 | 13 |
| 13 | 12 | F1-F4 |

### Agent Dispatch Summary

- **Wave 1**: **3 tasks** — T1 → `quick`, T2 → `quick`, T3 → `quick`
- **Wave 2**: **6 tasks** — T4 → `unspecified-high`, T5 → `unspecified-high`, T6 → `visual-engineering`, T7 → `visual-engineering`, T8 → `unspecified-high`, T9 → `unspecified-high`
- **Wave 3**: **2 tasks** — T10 → `unspecified-high`, T11 → `visual-engineering`
- **Wave 4**: **2 tasks** — T12 → `unspecified-high`, T13 → `quick`
- **FINAL**: **4 tasks** — F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

- [ ] 1. Extract shared animation helpers (`ratingColor`, `formatWater`, spring curves)

  **What to do**:
  - Create `lib/utils/animation_helpers.dart` with:
    - `Color ratingColor(ColorScheme colorScheme, int? rating)` — unified version handling both `int` and `int?` (calendar uses nullable). Logic: `1 → error`, `2 → tertiary`, `3 → primary`, `null/_ → outline`. Calendar variant returns `Colors.transparent` for null — unify with `colorScheme.outline` or keep transparent via optional param.
    - `String formatWater(double value)` — `value.toStringAsFixed(value % 1 == 0 ? 0 : 1)`
    - `const kSpringCurve` — a custom `SpringDescription`-based curve or `Curves.elasticOut` tuned for list entry (bouncier than easeOutCubic but not cartoonish). Recommend `spring(mass: 1, stiffness: 180, damping: 18)` via `SpringSimulation` or simply `Curves.easeOutBack` as a pragmatic starting point.
    - `const kStaggeredSlideDelta = Offset(0, 0.04)` — shared slide offset constant
  - Update `today_screen.dart`: remove `_ratingColor` (line 480-487), `_formatWater` (line 564-566). Import from `animation_helpers.dart`.
  - Update `day_detail_screen.dart`: remove `_ratingColor` (line 566-572), `_formatWater` (line 575-577). Import from `animation_helpers.dart`.
  - Update `calendar_screen.dart`: remove `_ratingColor` (line 668-676). Import from `animation_helpers.dart`. Ensure the nullable variant works.
  - Update `meals_screen.dart`: remove `_formatWater` (line 535 area). Import from `animation_helpers.dart`.

  **Must NOT do**:
  - Do not create an abstract animation framework — just plain helper functions
  - Do not modify any animation timing in this task (that's Task 5)
  - Do not touch `_buildStaggeredItem` yet (that's Task 5)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Pure extraction refactor — move existing code to shared file, update imports
  - **Skills**: [`flutter-expert`]
    - `flutter-expert`: Dart/Flutter conventions for utility file organization
  - **Skills Evaluated but Omitted**:
    - `visual-engineering`: No UI changes, just code extraction

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 2, 3)
  - **Blocks**: Tasks 4, 5, 10
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References** (existing code to follow):
  - `lib/presentation/screens/today_screen.dart:480-487` — `_ratingColor` implementation (int param)
  - `lib/presentation/screens/today_screen.dart:564-566` — `_formatWater` implementation
  - `lib/presentation/screens/day_detail_screen.dart:566-572` — `_ratingColor` duplicate (int param)
  - `lib/presentation/screens/day_detail_screen.dart:575-577` — `_formatWater` duplicate
  - `lib/presentation/screens/calendar_screen.dart:668-676` — `_ratingColor` variant (int? param, returns Colors.transparent for null)
  - `lib/utils/date_formatter.dart` — Example of existing utility file pattern in this project

  **API/Type References**:
  - `package:flutter/material.dart` → `ColorScheme`, `Colors`, `Offset`
  - `package:flutter/physics.dart` → `SpringDescription` (if using spring-based curve)

  **WHY Each Reference Matters**:
  - The three `_ratingColor` implementations differ in nullability — executor must unify carefully
  - `date_formatter.dart` shows how this project structures utility files (extension vs top-level functions)

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Verify deduplication complete
    Tool: Bash (grep)
    Preconditions: Task implementation complete
    Steps:
      1. Run: grep -rn "_ratingColor" lib/presentation/screens/
      2. Assert: 0 matches (all removed from screen files)
      3. Run: grep -rn "_formatWater" lib/presentation/screens/
      4. Assert: 0 matches (all removed from screen files)
      5. Run: grep -rn "ratingColor\|formatWater" lib/utils/animation_helpers.dart
      6. Assert: Both functions present in helpers file
    Expected Result: Zero private duplicates in screens, both functions in shared helpers
    Failure Indicators: Any grep match for _ratingColor or _formatWater in screen files
    Evidence: .sisyphus/evidence/task-1-dedup-verification.txt

  Scenario: Verify compilation
    Tool: Bash (flutter analyze)
    Preconditions: All file changes saved
    Steps:
      1. Run: flutter analyze lib/utils/animation_helpers.dart
      2. Run: flutter analyze lib/presentation/screens/
      3. Assert: No errors in any analyzed file
    Expected Result: flutter analyze reports no issues
    Failure Indicators: Any error or warning about missing imports, wrong types
    Evidence: .sisyphus/evidence/task-1-analyze.txt
  ```

  **Commit**: YES (groups with Wave 1)
  - Message: `refactor(utils): extract ratingColor, formatWater, spring curve to animation_helpers`
  - Files: `lib/utils/animation_helpers.dart`, `lib/presentation/screens/today_screen.dart`, `lib/presentation/screens/day_detail_screen.dart`, `lib/presentation/screens/calendar_screen.dart`, `lib/presentation/screens/meals_screen.dart`
  - Pre-commit: `flutter analyze`

- [ ] 2. Create haptic feedback utility layer

  **What to do**:
  - Create `lib/presentation/widgets/haptic_feedback_wrapper.dart` with:
    - `enum HapticLevel { light, medium, heavy, selection, error }` mapping to:
      - `light` → `HapticFeedback.lightImpact()` — tab switches, rating tap
      - `medium` → `HapticFeedback.mediumImpact()` — swipe-to-delete threshold, save confirmation
      - `heavy` → `HapticFeedback.heavyImpact()` — delete confirmation
      - `selection` → `HapticFeedback.selectionClick()` — calendar day tap, meal slot selection
      - `error` → `HapticFeedback.vibrate()` — save/load failure (notificationError-like)
    - `static void trigger(HapticLevel level)` — single call site
    - `class HapticWrapper extends StatelessWidget` — wraps a child with onTap haptic. Takes `HapticLevel`, `VoidCallback? onTap`, `Widget child`. Fires haptic then calls onTap.
  - Import `package:flutter/services.dart` for `HapticFeedback`
  - This is infrastructure only — no screen integration yet (that's Task 10)

  **Must NOT do**:
  - Do not integrate into screens yet (Task 10 does that)
  - Do not add any third-party haptic packages — use Flutter SDK `HapticFeedback` only
  - Do not create a provider or state management for haptics — keep it stateless utility

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Small utility file creation, ~50 lines
  - **Skills**: [`flutter-expert`]
    - `flutter-expert`: Flutter services API knowledge
  - **Skills Evaluated but Omitted**:
    - `mobile-touch`: Could help but task is simple enough without it

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 3)
  - **Blocks**: Tasks 7, 8, 10, 11
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References**:
  - `lib/presentation/widgets/meal_slot.dart` — Example of existing widget file in this project's structure
  - `lib/presentation/widgets/meal_history_card.dart:23` — `InkWell` usage pattern that haptics will wrap

  **API/Type References**:
  - `package:flutter/services.dart` → `HapticFeedback.lightImpact()`, `HapticFeedback.mediumImpact()`, `HapticFeedback.heavyImpact()`, `HapticFeedback.selectionClick()`, `HapticFeedback.vibrate()`

  **WHY Each Reference Matters**:
  - `meal_slot.dart` shows the widget file pattern (StatelessWidget with named constructor params)
  - `HapticFeedback` API is platform-aware — works on iOS/Android, no-ops on web

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Verify haptic wrapper file exists and compiles
    Tool: Bash (flutter analyze)
    Preconditions: File created
    Steps:
      1. Run: flutter analyze lib/presentation/widgets/haptic_feedback_wrapper.dart
      2. Assert: No errors
      3. Run: grep -c "HapticLevel" lib/presentation/widgets/haptic_feedback_wrapper.dart
      4. Assert: At least 5 matches (enum values + trigger function)
      5. Run: grep "HapticFeedback" lib/presentation/widgets/haptic_feedback_wrapper.dart
      6. Assert: At least 4 matches (light, medium, heavy, selection/vibrate)
    Expected Result: File compiles, contains all 5 haptic levels and trigger method
    Failure Indicators: Analyze errors, missing enum values
    Evidence: .sisyphus/evidence/task-2-haptic-layer.txt

  Scenario: Verify enum covers all intensity levels
    Tool: Bash (grep)
    Preconditions: File created
    Steps:
      1. Run: grep -E "light|medium|heavy|selection|error" lib/presentation/widgets/haptic_feedback_wrapper.dart
      2. Assert: All 5 levels present
    Expected Result: All 5 haptic levels defined in enum
    Failure Indicators: Any missing level
    Evidence: .sisyphus/evidence/task-2-haptic-enum.txt
  ```

  **Commit**: YES (groups with Wave 1)
  - Message: `feat(haptics): add HapticLevel enum and HapticWrapper utility widget`
  - Files: `lib/presentation/widgets/haptic_feedback_wrapper.dart`
  - Pre-commit: `flutter analyze`

- [ ] 3. Create press scale feedback widget

  **What to do**:
  - Create `lib/presentation/widgets/press_scale.dart` with:
    - `class PressScale extends StatefulWidget` — wraps any child widget with scale-down-on-press effect
    - Props: `Widget child`, `VoidCallback? onTap`, `double scaleFactor = 0.96`, `Duration duration = Duration(milliseconds: 120)`
    - Implementation:
      - Use `AnimationController` + `Tween<double>(begin: 1.0, end: scaleFactor)`
      - On `GestureDetector.onTapDown` → `controller.forward()`
      - On `GestureDetector.onTapUp` / `onTapCancel` → `controller.reverse()`
      - On `GestureDetector.onTap` → call `onTap` callback
      - Wrap child in `ScaleTransition` or `Transform.scale` with animation value
    - Use spring curve for the release (reverse) — `Curves.easeOutBack` for slight overshoot bounce on release
    - Forward (press down) uses `Curves.easeInOut` for quick response
  - This is infrastructure only — integration happens in Task 10

  **Must NOT do**:
  - Do not replace existing `InkWell` — `PressScale` wraps around widgets that already have `InkWell`
  - Do not add haptic feedback here — that's separate (Task 2 handles haptics, Task 10 wires both)
  - Duration must be ≤ 400ms per guardrails

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single widget file, ~80 lines, well-defined behavior
  - **Skills**: [`flutter-expert`]
    - `flutter-expert`: AnimationController lifecycle in StatefulWidget
  - **Skills Evaluated but Omitted**:
    - `visual-engineering`: This is a behavior widget, not visual design
    - `mobile-touch`: Simple scale transform, not complex gesture handling

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Tasks 1, 2)
  - **Blocks**: Tasks 7, 10
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References**:
  - `lib/presentation/widgets/meal_slot.dart:37-53` — StatefulWidget build pattern in this project
  - `lib/presentation/screens/today_screen.dart:51-54` — AnimationController creation pattern (`vsync: this`, `..forward()`)

  **API/Type References**:
  - `package:flutter/widgets.dart` → `AnimationController`, `ScaleTransition`, `GestureDetector`, `Tween<double>`
  - `Curves.easeOutBack` — spring-like overshoot for release bounce
  - `Curves.easeInOut` — smooth press-down response

  **WHY Each Reference Matters**:
  - `today_screen.dart` AnimationController pattern shows how this codebase creates/disposes controllers with `SingleTickerProviderStateMixin`
  - `meal_slot.dart` widget structure shows the constructor convention (named params, `super.key`)

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Verify press scale widget compiles and has correct API
    Tool: Bash (flutter analyze + grep)
    Preconditions: File created
    Steps:
      1. Run: flutter analyze lib/presentation/widgets/press_scale.dart
      2. Assert: No errors
      3. Run: grep "scaleFactor" lib/presentation/widgets/press_scale.dart
      4. Assert: Default value 0.96 present
      5. Run: grep "GestureDetector\|onTapDown\|onTapUp\|onTapCancel" lib/presentation/widgets/press_scale.dart
      6. Assert: All 3 gesture handlers present
      7. Run: grep "AnimationController\|ScaleTransition\|Transform.scale" lib/presentation/widgets/press_scale.dart
      8. Assert: Animation infrastructure present
    Expected Result: Widget compiles, uses GestureDetector with scale animation
    Failure Indicators: Missing gesture handlers, no animation controller
    Evidence: .sisyphus/evidence/task-3-press-scale.txt

  Scenario: Verify duration within guardrails
    Tool: Bash (grep)
    Preconditions: File created
    Steps:
      1. Run: grep -n "Duration\|milliseconds" lib/presentation/widgets/press_scale.dart
      2. Assert: Default duration is 120ms (≤ 400ms guardrail)
    Expected Result: Animation duration respects 400ms maximum guardrail
    Failure Indicators: Any duration > 400ms
    Evidence: .sisyphus/evidence/task-3-duration-check.txt
  ```

  **Commit**: YES (groups with Wave 1)
  - Message: `feat(motion): add PressScale widget with spring-release animation`
  - Files: `lib/presentation/widgets/press_scale.dart`
  - Pre-commit: `flutter analyze`

- [ ] 4. Extract DayRatingWidget and DailyMetricsWidget into reusable widgets

  **What to do**:
  - Create `lib/presentation/widgets/day_rating_widget.dart`:
    - Extract `_buildDayRating` from `today_screen.dart:183-306` and `day_detail_screen.dart:270-393`
    - `class DayRatingWidget extends StatelessWidget`
    - Props: `int? rating`, `ValueChanged<int> onRatingChanged`, `String subtitle` (differs: "today" vs "day" subtitle text)
    - Uses `ratingColor` from `animation_helpers.dart` (Task 1)
    - Preserves the existing `AnimatedContainer(duration: 180ms, curve: easeOutCubic)` on rating buttons
    - The two implementations are nearly identical — the only differences are:
      1. Subtitle text: `l10n.dayRatingSubtitleToday` vs `l10n.dayRatingSubtitleDay`
      2. `onTap` callback: `_provider.updateDayRating(option.value)` vs `_provider.updateDayRating(option.value, l10n)`
    - Handle both via constructor params: `subtitle` string and `onRatingChanged` callback

  - Create `lib/presentation/widgets/daily_metrics_widget.dart`:
    - Extract `_buildDailyMetrics` from `today_screen.dart:308-477` and `day_detail_screen.dart:395-564`
    - `class DailyMetricsWidget extends StatelessWidget`
    - Props: `double? waterLiters`, `bool isWaterGoalMet`, `bool exerciseDone`, `String exerciseNote`, `String subtitle`, `TextEditingController waterController`, `TextEditingController exerciseNoteController`, `FocusNode waterFocusNode`, `FocusNode exerciseNoteFocusNode`, `ValueChanged<String> onWaterChanged`, `ValueChanged<bool?> onExerciseDoneChanged`, `ValueChanged<String> onExerciseNoteChanged`
    - Uses `formatWater` from `animation_helpers.dart` (Task 1)
    - Differences between the two implementations:
      1. Subtitle text: `l10n.dailyMetricsSubtitleToday` vs `l10n.dailyMetricsSubtitleDay`
      2. Day detail hardcodes `'L'` for suffixText and `'0.0'` for hintText instead of using l10n — normalize to use l10n
    - Handle via constructor param: `subtitle` string

  - Update `today_screen.dart`:
    - Replace `_buildDayRating(theme)` call (line 151) with `DayRatingWidget(...)` 
    - Replace `_buildDailyMetrics(theme)` call (line 154) with `DailyMetricsWidget(...)`
    - Remove both private methods (`_buildDayRating`: lines 183-306, `_buildDailyMetrics`: lines 308-477)
    - This reduces today_screen.dart by ~290 lines

  - Update `day_detail_screen.dart`:
    - Replace `_buildDayRating(theme, l10n)` call (line 236) with `DayRatingWidget(...)`
    - Replace `_buildDailyMetrics(theme, l10n)` call (line 240) with `DailyMetricsWidget(...)`
    - Remove both private methods (`_buildDayRating`: lines 270-393, `_buildDailyMetrics`: lines 395-564)
    - This reduces day_detail_screen.dart by ~290 lines

  **Must NOT do**:
  - Do not refactor provider logic — just pass callbacks through
  - Do not change the visual appearance or layout of either widget
  - Do not add animations beyond what's already there (AnimatedContainer 180ms on rating)
  - Do not create a common "DaySection" base class — keep them as two separate simple widgets

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Touches 4 files, requires careful parameter threading, significant code movement
  - **Skills**: [`flutter-expert`]
    - `flutter-expert`: Widget extraction patterns, constructor param design
  - **Skills Evaluated but Omitted**:
    - `visual-engineering`: No visual changes, pure extraction

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 5, 6, 7, 8, 9)
  - **Blocks**: Task 10
  - **Blocked By**: Task 1 (needs `ratingColor` and `formatWater` from animation_helpers.dart)

  **References**:

  **Pattern References** (existing code to follow):
  - `lib/presentation/screens/today_screen.dart:183-306` — `_buildDayRating` source (today variant, uses `context.l10n`)
  - `lib/presentation/screens/today_screen.dart:308-477` — `_buildDailyMetrics` source (today variant, has water+exercise)
  - `lib/presentation/screens/day_detail_screen.dart:270-393` — `_buildDayRating` source (day variant, takes explicit `l10n` param)
  - `lib/presentation/screens/day_detail_screen.dart:395-564` — `_buildDailyMetrics` source (day variant, hardcodes some strings)
  - `lib/presentation/widgets/meal_slot.dart` — Example of existing extracted widget with many constructor params
  - `lib/presentation/screens/today_screen.dart:146-177` — ListView.builder showing how widgets are used in context

  **API/Type References**:
  - `lib/utils/animation_helpers.dart` — `ratingColor()` and `formatWater()` from Task 1
  - `lib/gen_l10n/app_localizations.dart` — `AppLocalizations` type for l10n strings

  **WHY Each Reference Matters**:
  - The two `_buildDayRating` implementations must be compared line-by-line to identify differences (subtitle text, callback signature)
  - `meal_slot.dart` shows how this project passes controllers and focus nodes as widget props — same pattern needed for DailyMetricsWidget

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Verify extraction completeness
    Tool: Bash (grep + flutter analyze)
    Preconditions: All 4 files updated
    Steps:
      1. Run: grep -n "_buildDayRating" lib/presentation/screens/today_screen.dart lib/presentation/screens/day_detail_screen.dart
      2. Assert: 0 matches (private methods fully removed)
      3. Run: grep -n "_buildDailyMetrics" lib/presentation/screens/today_screen.dart lib/presentation/screens/day_detail_screen.dart
      4. Assert: 0 matches (private methods fully removed)
      5. Run: grep -n "DayRatingWidget" lib/presentation/screens/today_screen.dart lib/presentation/screens/day_detail_screen.dart
      6. Assert: At least 1 match in each file (widget is used)
      7. Run: grep -n "DailyMetricsWidget" lib/presentation/screens/today_screen.dart lib/presentation/screens/day_detail_screen.dart
      8. Assert: At least 1 match in each file (widget is used)
      9. Run: flutter analyze lib/presentation/
      10. Assert: No errors
    Expected Result: Both widgets extracted, both screens use them, no private methods remain
    Failure Indicators: Any _buildDayRating or _buildDailyMetrics still in screen files
    Evidence: .sisyphus/evidence/task-4-extraction.txt

  Scenario: Verify line count reduction
    Tool: Bash (wc)
    Preconditions: Extraction complete
    Steps:
      1. Run: wc -l lib/presentation/screens/today_screen.dart
      2. Assert: Roughly ~280 lines (was 567, removed ~290 lines of _buildDayRating + _buildDailyMetrics)
      3. Run: wc -l lib/presentation/screens/day_detail_screen.dart
      4. Assert: Roughly ~365 lines (was 654, removed ~290 lines)
    Expected Result: Both files significantly shorter
    Failure Indicators: File sizes unchanged or only marginally smaller
    Evidence: .sisyphus/evidence/task-4-line-count.txt
  ```

  **Commit**: YES
  - Message: `refactor(widgets): extract DayRatingWidget and DailyMetricsWidget from screens`
  - Files: `lib/presentation/widgets/day_rating_widget.dart`, `lib/presentation/widgets/daily_metrics_widget.dart`, `lib/presentation/screens/today_screen.dart`, `lib/presentation/screens/day_detail_screen.dart`
  - Pre-commit: `flutter analyze`

- [ ] 5. Convert staggered list animations to spring physics + shared wrapper

  **What to do**:
  - Create `lib/presentation/widgets/staggered_item.dart`:
    - `class StaggeredItem extends StatelessWidget` — shared staggered animation wrapper
    - Props: `AnimationController controller`, `int index`, `Widget child`, `double staggerFraction = 0.12`, `double animationSpan = 0.6`
    - Implementation:
      - Compute interval: `start = index * staggerFraction`, `end = min(1.0, start + animationSpan)`
      - Create `CurvedAnimation(parent: controller, curve: Interval(start, end, curve: Curves.easeOutBack))` — use `easeOutBack` for slight spring overshoot instead of `easeOutCubic`
      - Wrap child in `FadeTransition` + `SlideTransition(Offset(0, 0.04) → Offset.zero)`
    - The three screens had slightly different timing:
      - `today_screen`: stagger=0.12, span=0.6, duration=650ms
      - `meals_screen`: stagger=0.08, span=0.5, duration=800ms
      - `day_detail_screen`: stagger=0.12, span=0.6, duration=650ms
    - Expose `staggerFraction` and `animationSpan` as params so each screen can keep its timing
    - Replace the private `_buildStaggeredItem` in all 3 screens with `StaggeredItem` widget

  - Update `today_screen.dart`:
    - Remove `_buildStaggeredItem` method (lines 489-507)
    - Replace calls at lines 151, 154, 157 with `StaggeredItem(controller: _listController, index: index, child: ...)`
    - Keep existing duration (650ms) on `_listController`

  - Update `meals_screen.dart`:
    - Remove `_buildStaggeredItem` method (lines 349-367)
    - Replace usage with `StaggeredItem(controller: _listController, index: index, staggerFraction: 0.08, animationSpan: 0.5, child: ...)`
    - Keep existing duration (800ms) on controller

  - Update `day_detail_screen.dart`:
    - Remove `_buildStaggeredItem` method (lines 579-597)
    - Replace usage with `StaggeredItem(controller: _listController, index: index, child: ...)`
    - Keep existing duration (650ms)

  **Must NOT do**:
  - Do not change animation durations on the controllers — only change the curve from `easeOutCubic` to `easeOutBack`
  - Do not remove `AnimationController` from screens — they still need it for controller lifecycle
  - Do not use `physics`-based `ScrollPhysics` here — this is about list item entry animation curves, not scroll physics

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Touches 4 files, must preserve per-screen timing differences
  - **Skills**: [`flutter-expert`]
    - `flutter-expert`: Animation curves, CurvedAnimation, Interval
  - **Skills Evaluated but Omitted**:
    - `visual-engineering`: This is animation behavior, not visual design

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 6, 7, 8, 9)
  - **Blocks**: Task 10
  - **Blocked By**: Task 1 (needs spring curve constants from animation_helpers.dart)

  **References**:

  **Pattern References**:
  - `lib/presentation/screens/today_screen.dart:489-507` — `_buildStaggeredItem` source (stagger=0.12, span=0.6)
  - `lib/presentation/screens/meals_screen.dart:349-367` — `_buildStaggeredItem` source (stagger=0.08, span=0.5)
  - `lib/presentation/screens/day_detail_screen.dart:579-597` — `_buildStaggeredItem` source (stagger=0.12, span=0.6)
  - `lib/presentation/screens/today_screen.dart:51-54` — AnimationController creation (650ms, ..forward())
  - `lib/presentation/screens/today_screen.dart:151-175` — Usage of `_buildStaggeredItem` in ListView.builder

  **API/Type References**:
  - `Curves.easeOutBack` — spring-like curve with slight overshoot (Disney's "follow through" principle)
  - `CurvedAnimation`, `Interval`, `FadeTransition`, `SlideTransition`

  **WHY Each Reference Matters**:
  - The three implementations have different stagger/span values — executor must preserve these via constructor params
  - `easeOutBack` gives ~10% overshoot then settles — more lively than `easeOutCubic` without being cartoonish

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Verify dedup of staggered item
    Tool: Bash (grep + flutter analyze)
    Preconditions: All files updated
    Steps:
      1. Run: grep -rn "_buildStaggeredItem" lib/presentation/screens/
      2. Assert: 0 matches (all private methods removed)
      3. Run: grep -rn "StaggeredItem" lib/presentation/screens/
      4. Assert: At least 1 match in each of 3 screen files
      5. Run: flutter analyze lib/presentation/
      6. Assert: No errors
    Expected Result: Zero private staggered item methods, all screens use shared widget
    Failure Indicators: Any _buildStaggeredItem still in screen files
    Evidence: .sisyphus/evidence/task-5-staggered-dedup.txt

  Scenario: Verify spring curve applied
    Tool: Bash (grep)
    Preconditions: StaggeredItem widget created
    Steps:
      1. Run: grep "easeOutBack" lib/presentation/widgets/staggered_item.dart
      2. Assert: At least 1 match (spring curve used)
      3. Run: grep "easeOutCubic" lib/presentation/widgets/staggered_item.dart
      4. Assert: 0 matches (old curve replaced)
    Expected Result: StaggeredItem uses easeOutBack instead of easeOutCubic
    Failure Indicators: Still using easeOutCubic
    Evidence: .sisyphus/evidence/task-5-spring-curve.txt
  ```

  **Commit**: YES
  - Message: `refactor(motion): extract StaggeredItem widget with spring curve (easeOutBack)`
  - Files: `lib/presentation/widgets/staggered_item.dart`, `lib/presentation/screens/today_screen.dart`, `lib/presentation/screens/meals_screen.dart`, `lib/presentation/screens/day_detail_screen.dart`
  - Pre-commit: `flutter analyze`

- [ ] 6. Create skeleton/shimmer loading widget and integrate

  **What to do**:
  - Create `lib/presentation/widgets/skeleton_loading.dart`:
    - `class SkeletonLoading extends StatefulWidget` — shimmer placeholder widget
    - Props: `double width`, `double height`, `BorderRadius borderRadius = BorderRadius.circular(12)`, `bool isLoading = true`
    - Implementation:
      - Use `AnimationController` with `repeat(reverse: true)` for shimmer pulse
      - Duration: 1200ms per cycle (within guardrail ≥150ms for transitions)
      - Animate between `surfaceContainerHighest` (from theme) and a slightly lighter variant
      - Use `AnimatedBuilder` + `Container` with animated color
      - When `isLoading == false`, show nothing (SizedBox.shrink)
    - `class SkeletonCard extends StatelessWidget` — pre-built card-shaped skeleton matching `MealSlotWidget` layout:
      - Header bar (shimmer rectangle)
      - Photo area (shimmer square, aspect ratio 4/5)
      - Text line (shimmer rectangle)
    - `class SkeletonFeedCard extends StatelessWidget` — pre-built skeleton matching `MealHistoryCard` layout

  - Integrate into `today_screen.dart`:
    - When `_provider.isInitialLoad` (or equivalent first-load state), show `SkeletonCard` widgets instead of `MealSlotWidget`
    - Check: `TodayProvider` may not have an `isInitialLoad` flag — if not, use `_provider.meals.isEmpty && !_provider.error` as heuristic (common pattern in this codebase)

  - Integrate into `meals_screen.dart`:
    - Replace bare `CircularProgressIndicator` in `_buildLoadingFooter` (lines 369-385) with `SkeletonFeedCard` shimmer
    - For initial load state, show skeleton feed cards

  **Must NOT do**:
  - Do not use any third-party shimmer package — build with Flutter SDK Animation
  - Do not make shimmer animation > 2000ms or < 800ms per cycle
  - Do not add skeleton to `calendar_screen.dart` (it has its own loading indicator pattern)
  - Do not modify provider loading state logic

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: Visual design work — shimmer effect, matching existing card layouts
  - **Skills**: [`flutter-expert`]
    - `flutter-expert`: AnimationController with repeat, Material 3 color system
  - **Skills Evaluated but Omitted**:
    - `mobile-touch`: No touch interaction in loading states

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 5, 7, 8, 9)
  - **Blocks**: Task 10
  - **Blocked By**: None (no dependency on Wave 1 tasks)

  **References**:

  **Pattern References**:
  - `lib/presentation/widgets/meal_slot.dart:37-53` — MealSlotWidget layout to match in SkeletonCard
  - `lib/presentation/widgets/meal_history_card.dart:14-43` — MealHistoryCard layout to match in SkeletonFeedCard
  - `lib/presentation/screens/meals_screen.dart:369-385` — Current loading footer (CircularProgressIndicator) to replace
  - `lib/config/theme.dart` — Theme colors for shimmer base/highlight

  **API/Type References**:
  - `package:flutter/material.dart` → `AnimationController`, `AnimatedBuilder`, `ColorTween`
  - `ColorScheme.surfaceContainerHighest` — shimmer base color
  - `ColorScheme.surfaceContainerHigh` — shimmer highlight color (slightly lighter)

  **WHY Each Reference Matters**:
  - `meal_slot.dart` layout determines the skeleton card proportions — must match so transition from skeleton→real content feels seamless
  - `meal_history_card.dart` layout determines the skeleton feed card proportions
  - `theme.dart` provides the exact color system — shimmer must use theme-aware colors, not hardcoded

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Verify skeleton widget compiles and has shimmer animation
    Tool: Bash (flutter analyze + grep)
    Preconditions: File created
    Steps:
      1. Run: flutter analyze lib/presentation/widgets/skeleton_loading.dart
      2. Assert: No errors
      3. Run: grep "repeat" lib/presentation/widgets/skeleton_loading.dart
      4. Assert: At least 1 match (shimmer uses repeat animation)
      5. Run: grep "SkeletonCard\|SkeletonFeedCard" lib/presentation/widgets/skeleton_loading.dart
      6. Assert: Both classes present
    Expected Result: Skeleton widget compiles with shimmer animation and pre-built card variants
    Failure Indicators: Missing repeat animation, missing card variants
    Evidence: .sisyphus/evidence/task-6-skeleton.txt

  Scenario: Verify integration into loading states
    Tool: Bash (grep)
    Preconditions: Screen files updated
    Steps:
      1. Run: grep "SkeletonCard\|SkeletonFeedCard\|SkeletonLoading" lib/presentation/screens/today_screen.dart lib/presentation/screens/meals_screen.dart
      2. Assert: At least 1 match in each file
      3. Run: flutter analyze lib/presentation/screens/
      4. Assert: No errors
    Expected Result: Both screens use skeleton loading during initial load
    Failure Indicators: No skeleton usage in screen files
    Evidence: .sisyphus/evidence/task-6-integration.txt
  ```

  **Commit**: YES (groups with Wave 2)
  - Message: `feat(motion): add skeleton/shimmer loading replacing bare spinners`
  - Files: `lib/presentation/widgets/skeleton_loading.dart`, `lib/presentation/screens/today_screen.dart`, `lib/presentation/screens/meals_screen.dart`
  - Pre-commit: `flutter analyze`

- [ ] 7. Add animated month transitions to CalendarScreen

  **What to do**:
  - Update `lib/presentation/screens/calendar_screen.dart`:
    - Add `AnimationController` for month transition (requires changing CalendarScreen to use `SingleTickerProviderStateMixin`)
    - On `_provider.goToPreviousMonth` / `_provider.goToNextMonth`:
      - Animate the calendar grid out (slide left/right + fade) then in (slide from opposite direction + fade)
      - Direction: previous month slides content right (old exits right, new enters from left), next month slides left
      - Duration: 250ms (within guardrail ≥150ms for transitions)
      - Curve: `Curves.easeOutCubic` (consistent with existing route transitions)
    - Implementation approach: Use `AnimatedSwitcher` wrapping the calendar grid, with a `ValueKey(_provider.focusedMonth)` to trigger re-animation on month change. Configure `transitionBuilder` for slide+fade.
    - Alternative: Wrap `_buildCalendarGrid` in `AnimatedSwitcher` with custom `layoutBuilder` and `transitionBuilder`
  - Add haptic feedback on month navigation buttons:
    - `goToPreviousMonth` → `HapticWrapper.trigger(HapticLevel.light)` (from Task 2)
    - `goToNextMonth` → `HapticWrapper.trigger(HapticLevel.light)`
  - Add press scale on the chevron buttons (from Task 3):
    - Wrap `IconButton` for previous/next month in `PressScale`

  **Must NOT do**:
  - Do not change the `NeverScrollableScrollPhysics` on the grid — it must stay non-scrollable
  - Do not add swipe gesture for month navigation (out of scope — only button-triggered)
  - Do not change the grid layout (7-column, aspect ratio 1.0)
  - Duration must be ≥150ms per guardrail

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: Animation choreography — coordinating slide direction with navigation intent
  - **Skills**: [`flutter-expert`]
    - `flutter-expert`: AnimatedSwitcher patterns, SlideTransition direction control
  - **Skills Evaluated but Omitted**:
    - `mobile-touch`: No custom gesture handling needed

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 5, 6, 8, 9)
  - **Blocks**: Task 10
  - **Blocked By**: Tasks 2, 3 (needs HapticWrapper and PressScale)

  **References**:

  **Pattern References**:
  - `lib/presentation/screens/calendar_screen.dart:82-110` — `_buildCalendarHeader` with chevron buttons (where haptics/press scale go)
  - `lib/presentation/screens/calendar_screen.dart:142-170` — `_buildCalendarGrid` (what gets wrapped in AnimatedSwitcher)
  - `lib/presentation/screens/calendar_screen.dart:70-78` — body Column layout showing grid placement
  - `lib/config/routes.dart:24-38` — Existing slide+fade transition pattern (model for consistency)

  **API/Type References**:
  - `AnimatedSwitcher` — widget that cross-fades between old and new child when key changes
  - `SlideTransition` — for directional month slide
  - `ValueKey<DateTime>` — to trigger AnimatedSwitcher rebuild on month change

  **WHY Each Reference Matters**:
  - `_buildCalendarHeader` lines 87-106 show the two `IconButton` widgets that need PressScale and haptic wrapping
  - `routes.dart` transition pattern establishes the visual language — month transitions should feel consistent with route transitions
  - `_buildCalendarGrid` is the target for AnimatedSwitcher wrapping

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Verify animated month transition exists
    Tool: Bash (grep + flutter analyze)
    Preconditions: Calendar screen updated
    Steps:
      1. Run: grep "AnimatedSwitcher" lib/presentation/screens/calendar_screen.dart
      2. Assert: At least 1 match
      3. Run: grep "SlideTransition\|FadeTransition" lib/presentation/screens/calendar_screen.dart
      4. Assert: At least 1 match (transition animation present)
      5. Run: flutter analyze lib/presentation/screens/calendar_screen.dart
      6. Assert: No errors
    Expected Result: Calendar grid wrapped in AnimatedSwitcher with slide+fade transition
    Failure Indicators: No AnimatedSwitcher, no transition widgets
    Evidence: .sisyphus/evidence/task-7-month-transition.txt

  Scenario: Verify haptics and press scale on month buttons
    Tool: Bash (grep)
    Preconditions: Calendar screen updated
    Steps:
      1. Run: grep "HapticLevel\|HapticWrapper\|haptic" lib/presentation/screens/calendar_screen.dart
      2. Assert: At least 2 matches (previous + next button)
      3. Run: grep "PressScale" lib/presentation/screens/calendar_screen.dart
      4. Assert: At least 1 match
    Expected Result: Month navigation buttons have haptic feedback and press scale
    Failure Indicators: No haptic or press scale integration
    Evidence: .sisyphus/evidence/task-7-haptics.txt
  ```

  **Commit**: YES (groups with Wave 2)
  - Message: `feat(motion): add animated month slide transitions to CalendarScreen`
  - Files: `lib/presentation/screens/calendar_screen.dart`
  - Pre-commit: `flutter analyze`

- [ ] 8. Add swipe-to-delete on MealsScreen feed cards

  **What to do**:
  - Update `lib/presentation/screens/meals_screen.dart`:
    - Wrap each `MealHistoryCard` in a `Dismissible` widget:
      - `key: ValueKey(meal.id)` (each meal has a unique id)
      - `direction: DismissDirection.endToStart` (swipe left to reveal delete)
      - `confirmDismiss`: Show confirmation dialog (localized: "Delete this meal?")
      - `onDismissed`: Call provider delete method
      - `background`: Red background with delete icon aligned right
    - Add haptic feedback at swipe threshold:
      - When `Dismissible` reaches dismiss threshold → `HapticWrapper.trigger(HapticLevel.medium)`
      - On actual delete confirmation → `HapticWrapper.trigger(HapticLevel.heavy)`
    - Add `AnimatedList`-style removal animation (or rely on Dismissible's built-in slide-out)
  - Check: `MealsProvider` must have a delete method. Look at existing `_provider.clearMeal` patterns in today_screen.dart. If meals_provider doesn't have delete, add `deleteMeal(int mealId)` method that:
    - Calls `MealRepository.delete(mealId)`
    - Removes from local meal list
    - Calls `notifyListeners()`
  - The delete confirmation dialog should be localized — check if `l10n.deleteMeal` / `l10n.deleteMealConfirmation` exist. If not, add ARB entries.

  **Must NOT do**:
  - Do not add swipe-to-delete to `TodayScreen` meal slots (they're not feed cards, they're edit forms)
  - Do not add swipe-to-delete to `DayDetailScreen` (same reason as today)
  - Do not remove the existing `onTap` → ModalBottomSheet behavior on cards
  - Swipe direction must be endToStart only (left swipe = delete, consistent with iOS/Android conventions)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Touches meals_screen + potentially meals_provider + ARB files, needs careful state management
  - **Skills**: [`flutter-expert`]
    - `flutter-expert`: Dismissible widget, provider state updates
  - **Skills Evaluated but Omitted**:
    - `mobile-touch`: Dismissible handles gestures natively
    - `flutter-internationalization`: Only needed if adding new ARB strings (simple addition)

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 5, 6, 7, 9)
  - **Blocks**: Task 10
  - **Blocked By**: Task 2 (needs HapticWrapper for swipe threshold haptic)

  **References**:

  **Pattern References**:
  - `lib/presentation/screens/meals_screen.dart:413-424` — `_onMealTap` showing current card interaction (preserve this)
  - `lib/presentation/screens/meals_screen.dart:387-407` — `_buildFeedItems` showing feed item structure
  - `lib/presentation/screens/today_screen.dart:538-562` — `_showClearConfirmation` dialog pattern (model for delete confirmation)
  - `lib/presentation/providers/meals_provider.dart` — Check for existing delete/remove methods
  - `lib/data/repositories/meal_repository.dart` — Check for existing `delete` method
  - `lib/data/models/meal.dart` — Meal model (verify `id` field exists for Dismissible key)

  **API/Type References**:
  - `Dismissible` — built-in Flutter widget for swipe-to-dismiss
  - `DismissDirection.endToStart` — left-swipe direction

  **External References**:
  - `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb` — for new "delete meal" localization strings if needed

  **WHY Each Reference Matters**:
  - `_onMealTap` must be preserved — swipe-to-delete is an additional gesture, not a replacement
  - `_showClearConfirmation` dialog is the existing confirmation pattern — delete confirmation should match this style
  - `meal.dart` model's `id` field is needed for `ValueKey` in Dismissible

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Verify Dismissible wrapping on feed cards
    Tool: Bash (grep + flutter analyze)
    Preconditions: Meals screen updated
    Steps:
      1. Run: grep "Dismissible" lib/presentation/screens/meals_screen.dart
      2. Assert: At least 1 match
      3. Run: grep "endToStart" lib/presentation/screens/meals_screen.dart
      4. Assert: At least 1 match (correct swipe direction)
      5. Run: grep "confirmDismiss" lib/presentation/screens/meals_screen.dart
      6. Assert: At least 1 match (confirmation before delete)
      7. Run: flutter analyze lib/presentation/screens/meals_screen.dart
      8. Assert: No errors
    Expected Result: Feed cards wrapped in Dismissible with left-swipe delete + confirmation
    Failure Indicators: No Dismissible, wrong direction, no confirmation
    Evidence: .sisyphus/evidence/task-8-swipe-delete.txt

  Scenario: Verify haptic feedback on swipe
    Tool: Bash (grep)
    Preconditions: Haptic integration done
    Steps:
      1. Run: grep "HapticLevel.medium\|HapticLevel.heavy" lib/presentation/screens/meals_screen.dart
      2. Assert: At least 2 matches (threshold + delete confirmation haptics)
    Expected Result: Haptic feedback fires at swipe threshold and on delete
    Failure Indicators: No haptic calls
    Evidence: .sisyphus/evidence/task-8-haptics.txt
  ```

  **Commit**: YES (groups with Wave 2)
  - Message: `feat(meals): add swipe-to-delete on feed cards with haptic feedback`
  - Files: `lib/presentation/screens/meals_screen.dart`, potentially `lib/presentation/providers/meals_provider.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`
  - Pre-commit: `flutter analyze`

- [ ] 9. Add Hero transition on DayDetailScreen meal photos

  **What to do**:
  - Update `lib/presentation/screens/calendar_screen.dart`:
    - Find where meal images are displayed in the selected day summary section
    - Wrap meal image widgets with `Hero(tag: 'meal-photo-${meal.id}', child: ...)`
    - The tag must be unique per meal — use meal ID
  - Update `lib/presentation/screens/day_detail_screen.dart`:
    - In the `MealSlotWidget` usage or photo display, wrap the meal photo with matching `Hero(tag: 'meal-photo-${meal.id}', child: ...)`
    - DayDetailScreen is navigated to via `context.go('/calendar/day/${date}')` — this IS a route push, so Hero works natively
  - Check: `MealSlotWidget` in `lib/presentation/widgets/meal_slot.dart` — does it display the image? If so, the Hero tag needs to be added there, parameterized by meal ID
  - Alternative approach: If the calendar screen doesn't show meal photos in its day summary, apply Hero to the **day cell** → **day detail** transition instead (e.g., the date number or rating indicator)

  **Must NOT do**:
  - Do not add Hero to ModalBottomSheet in MealsScreen (doesn't support Hero — decided in interview)
  - Do not wrap non-image elements in Hero unless photos aren't visible in calendar
  - Do not change the GoRouter route configuration
  - Do not add Hero to the ShellRoute transitions (they use `CustomTransitionPage` which doesn't support Hero natively across shell boundaries)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Requires understanding navigation flow and finding matching Hero tag points across screens
  - **Skills**: [`flutter-expert`]
    - `flutter-expert`: Hero widget, GoRouter navigation, Hero across route transitions
  - **Skills Evaluated but Omitted**:
    - `visual-engineering`: Hero is behavior, not visual design

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 5, 6, 7, 8)
  - **Blocks**: Task 10
  - **Blocked By**: None (no Wave 1 dependency)

  **References**:

  **Pattern References**:
  - `lib/config/routes.dart:56-64` — DayDetailScreen route (route push, not ShellRoute — Hero works here)
  - `lib/presentation/screens/calendar_screen.dart:70-78` — CalendarScreen body with `_buildSelectedDaySummary`
  - `lib/presentation/screens/day_detail_screen.dart:236-265` — ListView builder where MealSlotWidgets are created
  - `lib/presentation/widgets/meal_slot.dart:77-97` — Photo display section in MealSlotWidget (potential Hero wrap point)
  - `lib/data/models/meal.dart` — Meal model `id` field for unique Hero tag

  **API/Type References**:
  - `Hero` widget — requires matching `tag` on source and destination screens
  - `Hero.flightShuttleBuilder` — optional custom animation during flight (default is fine for photos)

  **WHY Each Reference Matters**:
  - `routes.dart:56-64` confirms DayDetailScreen is a top-level route (not inside ShellRoute), so Hero animation will work
  - Calendar screen's `_buildSelectedDaySummary` is where the source Hero widget goes (if it shows photos)
  - `meal_slot.dart` photo section is where the destination Hero widget goes in DayDetailScreen

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Verify Hero widgets exist on both sides of transition
    Tool: Bash (grep + flutter analyze)
    Preconditions: Both screens updated
    Steps:
      1. Run: grep "Hero" lib/presentation/screens/calendar_screen.dart lib/presentation/screens/day_detail_screen.dart lib/presentation/widgets/meal_slot.dart
      2. Assert: At least 1 match on source screen (calendar) and destination screen (day_detail or meal_slot)
      3. Run: grep "meal-photo" lib/presentation/screens/calendar_screen.dart lib/presentation/screens/day_detail_screen.dart lib/presentation/widgets/meal_slot.dart
      4. Assert: Matching tag pattern on both sides
      5. Run: flutter analyze lib/presentation/
      6. Assert: No errors
    Expected Result: Hero tags match between calendar and day detail screens
    Failure Indicators: Hero on only one side, mismatched tags
    Evidence: .sisyphus/evidence/task-9-hero.txt

  Scenario: Verify Hero not added to ModalBottomSheet path
    Tool: Bash (grep)
    Preconditions: Implementation complete
    Steps:
      1. Run: grep "Hero" lib/presentation/screens/meals_screen.dart
      2. Assert: 0 matches (no Hero on ModalBottomSheet path)
    Expected Result: Hero NOT added to MealsScreen (interview decision)
    Failure Indicators: Hero widget in meals_screen.dart
    Evidence: .sisyphus/evidence/task-9-no-hero-meals.txt
  ```

  **Commit**: YES (groups with Wave 2)
  - Message: `feat(motion): add Hero photo transition on DayDetailScreen navigation`
  - Files: `lib/presentation/screens/calendar_screen.dart`, `lib/presentation/screens/day_detail_screen.dart`, potentially `lib/presentation/widgets/meal_slot.dart`
  - Pre-commit: `flutter analyze`

- [ ] 10. Integrate haptics + press scale into all screens and widgets

  **What to do**:
  This is the integration task — wire HapticWrapper (Task 2) and PressScale (Task 3) into every interactive element across all screens.

  **Haptic integration map (from agreed 5-tier mapping):**
  - `lightImpact`:
    - Tab switches in `MainScaffold` NavigationBar (`lib/config/routes.dart:92`)
    - Rating button tap in `DayRatingWidget` (from Task 4)
  - `mediumImpact`:
    - Description save confirmation in `MealSlotWidget` (`meal_slot.dart`)
    - Water/exercise save in `DailyMetricsWidget` (from Task 4)
  - `heavyImpact`:
    - Clear meal confirmation in `today_screen.dart:538-562` and `day_detail_screen.dart:624-653`
  - `selectionClick`:
    - Calendar day cell tap in `calendar_screen.dart` (day selection)
    - Meal slot photo/action selection in `meal_slot.dart`
  - `error`:
    - Error state display in `today_screen.dart:509-536` and `day_detail_screen.dart:599-622`
    - Provider error notifications

  **Press scale integration:**
  - Wrap `MealHistoryCard` InkWell with `PressScale` in `meals_screen.dart` (or modify `MealHistoryCard` itself)
  - Wrap rating option buttons in `DayRatingWidget` with `PressScale`
  - Wrap calendar day cells with `PressScale` in `calendar_screen.dart`
  - Wrap meal slot action buttons (camera, gallery, delete) in `meal_slot.dart` with `PressScale`
  - Do NOT wrap the NavigationBar items (Material 3 handles its own press feedback)

  **Files to modify:**
  - `lib/config/routes.dart` — add haptic on NavigationBar destination tap
  - `lib/presentation/widgets/day_rating_widget.dart` — add haptic + press scale on rating buttons
  - `lib/presentation/widgets/daily_metrics_widget.dart` — add haptic on save
  - `lib/presentation/widgets/meal_slot.dart` — add haptic + press scale on action buttons
  - `lib/presentation/widgets/meal_history_card.dart` — add press scale on card
  - `lib/presentation/screens/today_screen.dart` — add haptic on clear meal confirmation
  - `lib/presentation/screens/day_detail_screen.dart` — add haptic on clear meal confirmation
  - `lib/presentation/screens/calendar_screen.dart` — add haptic + press scale on day cells

  **Must NOT do**:
  - Do not replace InkWell with PressScale — PressScale wraps around the existing widget
  - Do not add haptics to non-interactive elements (text, containers, spacers)
  - Do not add press scale to NavigationBar (it has its own Material 3 feedback)
  - Do not modify ShellRoute transition timing (260ms/220ms easeOutCubic must stay)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Touches 8+ files, systematic integration requiring understanding of every interactive element
  - **Skills**: [`flutter-expert`]
    - `flutter-expert`: Widget composition, Material 3 conventions
  - **Skills Evaluated but Omitted**:
    - `mobile-touch`: Could help but task is mechanical integration, not gesture design
    - `visual-engineering`: No visual changes, only behavioral additions

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Task 11)
  - **Parallel Group**: Wave 3 (with Task 11)
  - **Blocks**: Task 12
  - **Blocked By**: Tasks 2, 3, 4, 5 (needs all infrastructure + extracted widgets)

  **References**:

  **Pattern References**:
  - `lib/presentation/widgets/haptic_feedback_wrapper.dart` — HapticWrapper and HapticLevel (from Task 2)
  - `lib/presentation/widgets/press_scale.dart` — PressScale widget (from Task 3)
  - `lib/config/routes.dart:92` — NavigationBar onDestinationSelected
  - `lib/presentation/screens/today_screen.dart:538-562` — Clear meal confirmation dialog (heavy haptic)
  - `lib/presentation/screens/day_detail_screen.dart:624-653` — Clear meal confirmation dialog (heavy haptic)
  - `lib/presentation/widgets/meal_slot.dart:56-98` — Action buttons in header
  - `lib/presentation/widgets/meal_history_card.dart:23` — InkWell to wrap with PressScale

  **WHY Each Reference Matters**:
  - Each reference is a specific integration point — the executor needs to find each interactive element and wrap/add haptic call
  - `routes.dart:92` is the NavigationBar — add haptic in `onDestinationSelected` callback
  - Confirmation dialogs (`_showClearConfirmation`) fire heavy haptic after user confirms

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Verify haptic feedback coverage across all screens
    Tool: Bash (grep)
    Preconditions: All integration done
    Steps:
      1. Run: grep -l "HapticLevel\|HapticWrapper\|haptic_feedback_wrapper" lib/presentation/screens/*.dart lib/presentation/widgets/*.dart lib/config/routes.dart
      2. Assert: At least 7 files contain haptic imports/usage (4 screens + meal_slot + meal_history_card + routes)
      3. Run: grep -c "HapticLevel" lib/presentation/screens/today_screen.dart
      4. Assert: At least 1 (clear meal heavy haptic)
      5. Run: grep -c "HapticLevel" lib/presentation/screens/calendar_screen.dart
      6. Assert: At least 1 (day selection haptic)
    Expected Result: Every screen and interactive widget has haptic feedback
    Failure Indicators: Any screen file missing haptic imports
    Evidence: .sisyphus/evidence/task-10-haptic-coverage.txt

  Scenario: Verify press scale on key interactive elements
    Tool: Bash (grep)
    Preconditions: All integration done
    Steps:
      1. Run: grep -l "PressScale\|press_scale" lib/presentation/widgets/*.dart lib/presentation/screens/calendar_screen.dart
      2. Assert: At least 3 files (meal_history_card + day_rating_widget + calendar_screen or meal_slot)
      3. Run: flutter analyze lib/
      4. Assert: No errors
    Expected Result: Press scale on cards, rating buttons, and calendar cells
    Failure Indicators: Missing PressScale in key widgets
    Evidence: .sisyphus/evidence/task-10-press-scale.txt
  ```

  **Commit**: YES
  - Message: `feat(motion): integrate haptics and press scale across all screens`
  - Files: All listed above
  - Pre-commit: `flutter analyze`

- [ ] 11. Error/success animation polish

  **What to do**:
  - Add shake animation on error states:
    - In error display widgets (today_screen `_buildErrorWidget`, day_detail_screen `_buildErrorWidget`):
      - Wrap error icon in a horizontal shake animation (3 cycles, 8px amplitude, 300ms)
      - Trigger haptic `HapticLevel.error` when error widget appears
    - Pattern: Use `AnimationController` with `Tween<Offset>(begin: Offset(-0.02, 0), end: Offset(0.02, 0))` and `repeat(reverse: true, count: 3)` or `TweenSequence` for dampened shake

  - Add checkmark animation on save success:
    - In `MealSlotWidget` (`meal_slot.dart`): the existing `AnimatedSwitcher(duration: 180ms)` on `isSavingDescription` shows a spinner. Enhance:
      - After save completes (spinner disappears), briefly show a green checkmark icon with scale-in animation (200ms, `Curves.easeOutBack`)
      - Use `AnimatedSwitcher` with 3 states: idle → spinner → checkmark → idle
      - Haptic `HapticLevel.medium` on checkmark appearance

  - Add subtle bounce on successful water goal achievement:
    - In `DailyMetricsWidget` (from Task 4): when `isWaterGoalMet` becomes true, animate the "Goal met" badge with a scale bounce (1.0 → 1.15 → 1.0, 300ms)

  **Must NOT do**:
  - Do not add error animations to providers — keep it in widgets only
  - Shake amplitude must be subtle (≤10px) — not cartoonish
  - Do not add sound effects (out of scope)
  - Error animation duration ≤400ms per guardrail

  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
    - Reason: Animation choreography — timing, easing, visual feedback design
  - **Skills**: [`flutter-expert`]
    - `flutter-expert`: TweenSequence, AnimatedSwitcher multi-state patterns

  **Parallelization**:
  - **Can Run In Parallel**: YES (with Task 10)
  - **Parallel Group**: Wave 3 (with Task 10)
  - **Blocks**: Task 12
  - **Blocked By**: Task 2 (needs HapticWrapper for error haptic)

  **References**:

  **Pattern References**:
  - `lib/presentation/screens/today_screen.dart:509-536` — `_buildErrorWidget` (shake animation target)
  - `lib/presentation/screens/day_detail_screen.dart:599-622` — `_buildErrorWidget` (shake animation target)
  - `lib/presentation/widgets/meal_slot.dart` — `isSavingDescription` + `AnimatedSwitcher` (enhance with checkmark)
  - `lib/presentation/widgets/daily_metrics_widget.dart` — Goal met badge (bounce animation target, from Task 4)

  **API/Type References**:
  - `TweenSequence<Offset>` — for dampened shake (progressively smaller oscillations)
  - `AnimatedSwitcher` — already used for spinner, extend to 3-state (idle/spinner/checkmark)
  - `Curves.easeOutBack` — overshoot for checkmark scale-in

  **WHY Each Reference Matters**:
  - `_buildErrorWidget` in both screens is where the error icon needs shake wrapping
  - `meal_slot.dart` already uses `AnimatedSwitcher` — extend it rather than replacing it
  - Goal met badge is the "✓ Goal met" container in DailyMetricsWidget

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Verify error shake animation exists
    Tool: Bash (grep + flutter analyze)
    Preconditions: Error widgets updated
    Steps:
      1. Run: grep -E "shake|TweenSequence|Offset\(-0" lib/presentation/screens/today_screen.dart lib/presentation/screens/day_detail_screen.dart
      2. Assert: At least 1 match in each file (shake animation present)
      3. Run: flutter analyze lib/presentation/
      4. Assert: No errors
    Expected Result: Error widgets have horizontal shake animation
    Failure Indicators: No shake-related code in error widgets
    Evidence: .sisyphus/evidence/task-11-error-shake.txt

  Scenario: Verify save success checkmark
    Tool: Bash (grep)
    Preconditions: MealSlotWidget updated
    Steps:
      1. Run: grep -E "check|Icons.check" lib/presentation/widgets/meal_slot.dart
      2. Assert: At least 1 match (checkmark icon added)
      3. Run: grep "HapticLevel.medium" lib/presentation/widgets/meal_slot.dart
      4. Assert: At least 1 match (haptic on save success)
    Expected Result: Save success shows animated checkmark with haptic
    Failure Indicators: No checkmark icon, no save haptic
    Evidence: .sisyphus/evidence/task-11-checkmark.txt
  ```

  **Commit**: YES
  - Message: `feat(motion): add error shake, save checkmark, and goal-met bounce animations`
  - Files: `lib/presentation/screens/today_screen.dart`, `lib/presentation/screens/day_detail_screen.dart`, `lib/presentation/widgets/meal_slot.dart`, `lib/presentation/widgets/daily_metrics_widget.dart`
  - Pre-commit: `flutter analyze`

- [ ] 12. Widget tests for animation behavior

  **What to do**:
  - Create `test/widgets/staggered_item_test.dart`:
    - Test that StaggeredItem creates FadeTransition + SlideTransition
    - Test that animation uses `easeOutBack` curve
    - Test stagger timing: index 0 starts at 0.0, index 1 starts at 0.12
    - Use `tester.pumpWidget` with a test AnimationController

  - Create `test/widgets/press_scale_test.dart`:
    - Test that tap-down scales to 0.96
    - Test that tap-up/cancel returns to 1.0
    - Test that onTap callback fires
    - Use `tester.startGesture` for gesture simulation

  - Create `test/widgets/day_rating_widget_test.dart`:
    - Test that 3 rating options render (Bad, Okay, Great)
    - Test that tapping a rating calls `onRatingChanged`
    - Test that selected rating shows highlighted style (AnimatedContainer)
    - Mock: provide test `AppLocalizations` or use `MaterialApp` with localization delegates

  - Create `test/widgets/swipe_to_delete_test.dart`:
    - Test Dismissible exists on meal cards
    - Test swipe direction is endToStart
    - Test confirmDismiss shows dialog
    - Use `tester.drag` for swipe simulation

  **Must NOT do**:
  - Do not test provider logic — only widget rendering and animation behavior
  - Do not test haptic feedback (HapticFeedback is a platform channel, can't test in widget tests without mocking)
  - Do not use integration tests — widget tests only (flutter_test)
  - Do not create test utilities/helpers unless needed for 3+ test files

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 4 test files, requires animation testing knowledge (pump/advance timers)
  - **Skills**: [`flutter-expert`]
    - `flutter-expert`: Widget testing patterns, tester.pump, animation advance
  - **Skills Evaluated but Omitted**:
    - `visual-engineering`: Tests are code, not visual

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 4 (sequential after Wave 3)
  - **Blocks**: Task 13
  - **Blocked By**: All tasks 1-11 (tests verify their output)

  **References**:

  **Pattern References**:
  - `test/` directory — check for existing test files and patterns (may have been created in internationalization work)
  - `lib/presentation/widgets/staggered_item.dart` — Widget under test (from Task 5)
  - `lib/presentation/widgets/press_scale.dart` — Widget under test (from Task 3)
  - `lib/presentation/widgets/day_rating_widget.dart` — Widget under test (from Task 4)

  **API/Type References**:
  - `package:flutter_test/flutter_test.dart` → `WidgetTester`, `pumpWidget`, `pump`, `startGesture`, `drag`
  - `AnimationController(vsync: TestVSync())` — test-safe vsync provider
  - `find.byType`, `find.text`, `tester.tap`, `tester.drag`

  **WHY Each Reference Matters**:
  - Existing test files (if any) establish the test pattern for this project
  - Each widget under test needs to be wrapped in `MaterialApp` with localization for `context.l10n` to work

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Verify all widget tests pass
    Tool: Bash (flutter test)
    Preconditions: All test files created
    Steps:
      1. Run: flutter test test/widgets/
      2. Assert: All tests pass, 0 failures
      3. Run: ls test/widgets/
      4. Assert: 4 test files present (staggered_item_test.dart, press_scale_test.dart, day_rating_widget_test.dart, swipe_to_delete_test.dart)
    Expected Result: All widget tests pass
    Failure Indicators: Any test failure
    Evidence: .sisyphus/evidence/task-12-widget-tests.txt

  Scenario: Verify test count is reasonable
    Tool: Bash (flutter test --reporter expanded)
    Preconditions: Tests created
    Steps:
      1. Run: flutter test test/widgets/ --reporter expanded 2>&1 | grep -c "✓"
      2. Assert: At least 12 tests total (3+ per file)
    Expected Result: Minimum 12 tests covering core animation and widget behaviors
    Failure Indicators: Fewer than 12 tests
    Evidence: .sisyphus/evidence/task-12-test-count.txt
  ```

  **Commit**: YES
  - Message: `test(widgets): add animation widget tests for staggered, press scale, rating, swipe`
  - Files: `test/widgets/staggered_item_test.dart`, `test/widgets/press_scale_test.dart`, `test/widgets/day_rating_widget_test.dart`, `test/widgets/swipe_to_delete_test.dart`
  - Pre-commit: `flutter test test/widgets/`

- [ ] 13. Final lint + analyze + format pass

  **What to do**:
  - Run `flutter analyze` on entire project — fix any warnings
  - Run `dart format .` on entire project — ensure consistent formatting
  - Run `flutter test` — ensure all tests still pass after formatting
  - Fix any issues found (unused imports, missing const, etc.)
  - Verify zero remaining duplicates:
    - `grep -rn "_buildStaggeredItem" lib/` → 0 matches
    - `grep -rn "_ratingColor" lib/presentation/screens/` → 0 matches
    - `grep -rn "_formatWater" lib/presentation/screens/` → 0 matches
    - `grep -rn "_buildDayRating" lib/presentation/screens/` → 0 matches
    - `grep -rn "_buildDailyMetrics" lib/presentation/screens/` → 0 matches

  **Must NOT do**:
  - Do not add new features
  - Do not refactor beyond fixing lint issues
  - Do not reformat files that weren't changed in this overhaul

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Mechanical cleanup — run commands, fix warnings
  - **Skills**: [`flutter-expert`]
    - `flutter-expert`: Flutter analyze output interpretation
  - **Skills Evaluated but Omitted**: None relevant

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 4 (sequential, after Task 12)
  - **Blocks**: Final Verification Wave
  - **Blocked By**: Task 12

  **References**:

  **Pattern References**:
  - All files modified in Tasks 1-12

  **Acceptance Criteria**:

  **QA Scenarios (MANDATORY):**

  ```
  Scenario: Full project health check
    Tool: Bash
    Preconditions: All implementation complete
    Steps:
      1. Run: flutter analyze
      2. Assert: "No issues found" or only pre-existing warnings
      3. Run: flutter test
      4. Assert: All tests pass
      5. Run: grep -rn "_buildStaggeredItem\|_ratingColor\|_formatWater\|_buildDayRating\|_buildDailyMetrics" lib/presentation/screens/
      6. Assert: 0 matches (all duplicates eliminated)
    Expected Result: Clean analyze, all tests pass, zero duplicates
    Failure Indicators: Analyze errors, test failures, remaining duplicates
    Evidence: .sisyphus/evidence/task-13-final-check.txt
  ```

  **Commit**: YES (if any fixes needed)
  - Message: `chore: lint, format, and final cleanup`
  - Files: Any files that needed fixing
  - Pre-commit: `flutter analyze && flutter test`

---

## Final Verification Wave (MANDATORY — after ALL implementation tasks)

> 4 review agents run in PARALLEL. ALL must APPROVE. Rejection → fix → re-run.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (grep for HapticFeedback imports in all screens, verify Hero widget in day_detail_screen, verify Dismissible in meals_screen, etc.). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in `.sisyphus/evidence/`. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `flutter analyze` + `flutter test`. Review all changed files for: unused imports, dead code, duplicated methods that should have been removed. Check AI slop: excessive comments, over-abstraction, generic variable names. Verify no `_buildStaggeredItem`, `_ratingColor`, or `_formatWater` remain as private methods in screen files.
  Output: `Analyze [PASS/FAIL] | Tests [N pass/N fail] | Dedup [CLEAN/N remaining] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high` + `flutter-expert` skill
  Build and run the app on iOS simulator. Navigate every screen. Verify: staggered list uses spring physics (bouncy feel), press scale works on cards, haptic calls exist for every interactive element, calendar month slide animates, swipe-to-delete works on meal feed, Hero photo transition works on day detail, skeleton loading shows during data fetch. Save evidence screenshots/recordings.
  Output: `Scenarios [N/N pass] | Integration [N/N] | Edge Cases [N tested] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff (git log/diff). Verify 1:1 — everything in spec was built (no missing), nothing beyond spec was built (no creep). Check "Must NOT do" compliance: no provider refactoring, no ShellRoute timing changes, no PageView removal. Detect cross-task contamination. Flag unaccounted changes.
  Output: `Tasks [N/N compliant] | Contamination [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

- **Wave 1**: `refactor(animations): extract shared animation helpers, haptic layer, and press scale widget` — animation_helpers.dart, haptic_feedback_wrapper.dart, press_scale.dart
- **Wave 2 (grouped)**: `feat(motion): add spring physics, skeleton loading, calendar transitions, swipe-to-delete, Hero` — staggered_item.dart, skeleton_loading.dart, calendar_screen.dart, meals_screen.dart, day_detail_screen.dart
- **Wave 2 (extraction)**: `refactor(widgets): extract DayRatingWidget and DailyMetricsWidget` — day_rating_widget.dart, daily_metrics_widget.dart, today_screen.dart, day_detail_screen.dart
- **Wave 3**: `feat(motion): integrate haptics and press scale across all screens, add error/success animations` — all screen files, meal_slot.dart, meal_history_card.dart
- **Wave 4**: `test(widgets): add animation widget tests` — test/widgets/*.dart
- **Final**: `chore: lint, format, analyze clean` — if any cleanup needed

---

## Success Criteria

### Verification Commands
```bash
flutter analyze          # Expected: No issues found
flutter test             # Expected: All tests pass
grep -r "HapticFeedback" lib/presentation/screens/  # Expected: matches in all 4 screen files
grep -r "_buildStaggeredItem" lib/presentation/screens/  # Expected: 0 matches (moved to shared widget)
grep -r "_ratingColor" lib/presentation/screens/  # Expected: 0 matches (moved to helpers)
grep -r "_formatWater" lib/presentation/screens/  # Expected: 0 matches (moved to helpers)
grep -r "Hero" lib/presentation/screens/day_detail_screen.dart  # Expected: at least 1 match
grep -r "Dismissible" lib/presentation/screens/meals_screen.dart  # Expected: at least 1 match
```

### Final Checklist
- [ ] All "Must Have" present
- [ ] All "Must NOT Have" absent
- [ ] All tests pass
- [ ] `flutter analyze` clean
