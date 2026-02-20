# Internationalization (i18n) — Flutter Diet App

## TL;DR

> **Quick Summary**: Add full internationalization to the diet tracker app using Flutter's official `flutter gen-l10n` with ARB files. Localize all ~85 UI strings, replace 4+ duplicated manual date formatting functions with `intl DateFormat`, and support English (base) + French.
> 
> **Deliverables**:
> - i18n infrastructure (l10n.yaml, ARB files, localization delegates)
> - English template ARB with ~85 keys + French translation ARB
> - `context.l10n` convenience extension
> - `MealSlot.localizedName()` extension method
> - `DateFormatter` utility class replacing all manual date arrays
> - All screens/widgets/providers updated to use localized strings
> - Zero hardcoded user-facing strings remaining in codebase
> 
> **Estimated Effort**: Medium
> **Parallel Execution**: YES — 4 waves
> **Critical Path**: Task 1 → Task 2 → Task 3 → Tasks 4-6 (parallel) → Task 7 → Task 8

---

## Context

### Original Request
Add internationalization for the app's UI strings (not user-generated content like meal descriptions). Support English and French.

### Interview Summary
**Key Discussions**:
- **Languages**: English (base/template) + French — decided by user
- **Error messages**: Yes, localize all provider error messages shown to users — decided by user
- **MealSlot approach**: Extension method `localizedName(AppLocalizations l10n)` rather than modifying the enum — decided by user
- **Date formatting**: Replace all manual month/weekday arrays with `intl DateFormat` — massive duplication cleanup
- **Scope**: UI strings only, user-generated content (meal descriptions, exercise notes) stays as-is

**Research Findings**:
- `intl: ^0.20.2` already in pubspec.yaml but completely unused — zero imports anywhere
- `flutter_localizations` SDK dependency missing — must be added
- Manual month/weekday arrays duplicated in 4+ files (today_screen, day_detail_screen, calendar_screen, meals_provider)
- `_formatWater()` helper duplicated in 3 files
- `MealSlot.displayName` used across 7 files — central localization touchpoint
- ~80+ unique translatable strings cataloged across all presentation files

### Metis Review
**Identified Gaps** (addressed):
- Provider error messages need l10n but providers don't have `BuildContext` — resolved: pass l10n parameter or use error keys with late resolution in UI
- Day rating/metrics subtitles differ between today_screen ("today overall") and day_detail_screen ("this day overall") — resolved: separate ARB keys for each variant
- `getFormattedDateGroup()` in MealsProvider uses 'Today'/'Yesterday' strings — resolved: accept `AppLocalizations` parameter

---

## Work Objectives

### Core Objective
Add complete i18n infrastructure and localize every user-facing string in the Flutter diet tracking app for English and French, eliminating all hardcoded string duplication.

### Concrete Deliverables
- `l10n.yaml` configuration file
- `lib/l10n/app_en.arb` — English template (~85 keys)
- `lib/l10n/app_fr.arb` — French translations (~85 keys)
- `lib/utils/l10n_helper.dart` — `context.l10n` extension
- `lib/utils/meal_slot_localization.dart` — `MealSlot.localizedName()` extension
- `lib/utils/date_formatter.dart` — Locale-aware date formatting utility
- Updated `pubspec.yaml`, `lib/app.dart`, all screens/widgets/providers

### Definition of Done
- [ ] `flutter gen-l10n` completes without errors
- [ ] `flutter analyze` passes with zero errors
- [ ] `flutter test` passes (all 11 existing tests)
- [ ] `grep -rn "'" lib/presentation/ lib/config/routes.dart` shows zero hardcoded user-facing English strings
- [ ] App launches in English and French correctly

### Must Have
- All ~85 user-facing strings in ARB files with proper metadata annotations
- French translations for all keys
- ICU message format for interpolated strings (e.g., clear meal confirmation with slot name)
- Locale-aware date/time formatting via `intl DateFormat`
- `context.l10n` convenience extension for terse access
- `MealSlot.localizedName(l10n)` extension replacing direct `displayName` usage
- Provider error messages localized

### Must NOT Have (Guardrails)
- Do NOT localize user-generated content (meal descriptions, exercise text input)
- Do NOT add language selection UI (system locale detection only)
- Do NOT add more than 2 languages (EN + FR only)
- Do NOT modify database schema or data layer (except MealSlot extension)
- Do NOT add unnecessary packages — use only `flutter_localizations` SDK + existing `intl`
- Do NOT create barrel files or restructure existing directories
- Do NOT add excessive comments or documentation to ARB files beyond `@key` descriptions
- Do NOT use `Intl.message()` directly — use `flutter gen-l10n` ARB approach only
- Do NOT remove `MealSlot.displayName` getter — keep for backward compatibility, add `localizedName()` alongside

---

## Verification Strategy

> **ZERO HUMAN INTERVENTION** — ALL verification is agent-executed. No exceptions.

### Test Decision
- **Infrastructure exists**: YES (11 test files in `test/`)
- **Automated tests**: Tests-after — verify existing tests still pass, no new test files required for i18n strings
- **Framework**: `flutter test` (built-in)

### QA Policy
Every task MUST include agent-executed QA scenarios.
Evidence saved to `.sisyphus/evidence/task-{N}-{scenario-slug}.{ext}`.

- **Build verification**: `flutter gen-l10n` + `flutter analyze` + `flutter test`
- **String verification**: `grep` for remaining hardcoded English strings
- **Format verification**: `dart format --set-exit-if-changed`

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Foundation — infrastructure setup, SEQUENTIAL within wave):
├── Task 1: pubspec.yaml + l10n.yaml + generate flag [quick]
├── Task 2: ARB files (EN template + FR translations) [writing]
└── Task 3: App root config + l10n helper + run gen-l10n [quick]

Wave 2 (Utility layer — can start after Wave 1, PARALLEL):
├── Task 4: MealSlot localization extension [quick]
├── Task 5: DateFormatter utility class [quick]
└── Task 6: Localize provider error messages [unspecified-high]

Wave 3 (UI layer — replace all hardcoded strings, PARALLEL):
├── Task 7: Localize today_screen.dart [unspecified-high]
├── Task 8: Localize meals_screen.dart + meals_provider.dart [unspecified-high]
├── Task 9: Localize calendar_screen.dart [unspecified-high]
├── Task 10: Localize day_detail_screen.dart [unspecified-high]
└── Task 11: Localize widgets (meal_slot.dart, meal_history_card.dart) + routes.dart [unspecified-high]

Wave 4 (Verification):
├── Task 12: Full build + test + string audit [deep]

Wave FINAL (After ALL tasks — independent review, 4 parallel):
├── Task F1: Plan compliance audit (oracle)
├── Task F2: Code quality review (unspecified-high)
├── Task F3: Real manual QA (unspecified-high)
└── Task F4: Scope fidelity check (deep)

Critical Path: Task 1 → Task 2 → Task 3 → Task 7 (heaviest screen) → Task 12 → F1-F4
Parallel Speedup: ~50% faster than sequential (Waves 2 and 3 fully parallel)
Max Concurrent: 5 (Wave 3)
```

### Dependency Matrix

| Task | Depends On | Blocks |
|------|-----------|--------|
| 1 | — | 2, 3 |
| 2 | 1 | 3 |
| 3 | 1, 2 | 4, 5, 6, 7, 8, 9, 10, 11 |
| 4 | 3 | 7, 8, 9, 10, 11 |
| 5 | 3 | 7, 8, 9, 10, 11 |
| 6 | 3 | 12 |
| 7 | 3, 4, 5 | 12 |
| 8 | 3, 4, 5 | 12 |
| 9 | 3, 4, 5 | 12 |
| 10 | 3, 4, 5 | 12 |
| 11 | 3, 4, 5 | 12 |
| 12 | 6, 7, 8, 9, 10, 11 | F1-F4 |
| F1-F4 | 12 | — |

### Agent Dispatch Summary

- **Wave 1**: 3 tasks — T1 → `quick`, T2 → `writing`, T3 → `quick`
- **Wave 2**: 3 tasks — T4 → `quick`, T5 → `quick`, T6 → `unspecified-high`
- **Wave 3**: 5 tasks — T7-T10 → `unspecified-high`, T11 → `unspecified-high`
- **Wave 4**: 1 task — T12 → `deep`
- **FINAL**: 4 tasks — F1 → `oracle`, F2 → `unspecified-high`, F3 → `unspecified-high`, F4 → `deep`

---

## TODOs

- [x] 1. Infrastructure Setup — pubspec.yaml + l10n.yaml + generate flag

  **What to do**:
  - Add `flutter_localizations` SDK dependency to `pubspec.yaml` under `dependencies`:
    ```yaml
    flutter_localizations:
      sdk: flutter
    ```
  - Add `generate: true` under the `flutter:` section in `pubspec.yaml` (after `uses-material-design: true`)
  - Create `l10n.yaml` in project root with:
    ```yaml
    arb-dir: lib/l10n
    template-arb-file: app_en.arb
    output-localization-file: app_localizations.dart
    ```
  - Run `flutter pub get` to install new dependency

  **Must NOT do**:
  - Do NOT add any packages beyond `flutter_localizations` SDK
  - Do NOT modify any Dart source files in this task
  - Do NOT add `output-dir` to l10n.yaml — use Flutter's default location

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Simple config file edits — 2 files, minimal logic
  - **Skills**: [`flutter-localization`]
    - `flutter-localization`: Provides exact l10n.yaml and pubspec.yaml patterns
  - **Skills Evaluated but Omitted**:
    - None — this is purely config work

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 1 — Sequential (T1 → T2 → T3)
  - **Blocks**: Task 2, Task 3
  - **Blocked By**: None (can start immediately)

  **References**:

  **Pattern References**:
  - `pubspec.yaml:1-40` — Current dependency list; add `flutter_localizations` SDK dep after line 28 (after `flutter: sdk: flutter`), add `generate: true` after line 74 (`uses-material-design: true`)

  **External References**:
  - `.agents/skills/flutter-localization/SKILL.md:27-47` — Exact pubspec.yaml and l10n.yaml configuration patterns

  **WHY Each Reference Matters**:
  - `pubspec.yaml` — Must add dependency in correct location (SDK deps go under `dependencies`, not `dev_dependencies`)
  - Skill file — Provides the exact l10n.yaml format that works with `flutter gen-l10n`

  **Acceptance Criteria**:
  - [ ] `flutter pub get` completes without errors
  - [ ] `l10n.yaml` exists in project root with correct config
  - [ ] `pubspec.yaml` contains `flutter_localizations: sdk: flutter` under dependencies
  - [ ] `pubspec.yaml` contains `generate: true` under `flutter:` section

  **QA Scenarios**:

  ```
  Scenario: Verify pub get succeeds with new dependency
    Tool: Bash
    Preconditions: Working Flutter environment
    Steps:
      1. Run `flutter pub get` in project root
      2. Check exit code is 0
      3. Run `grep -n "flutter_localizations" pubspec.yaml` — expect match
      4. Run `grep -n "generate: true" pubspec.yaml` — expect match
      5. Run `cat l10n.yaml` — expect arb-dir, template-arb-file, output-localization-file keys
    Expected Result: All 3 config entries present, pub get succeeds
    Failure Indicators: pub get fails, missing config entries
    Evidence: .sisyphus/evidence/task-1-pub-get.txt

  Scenario: Verify l10n.yaml format is valid
    Tool: Bash
    Preconditions: l10n.yaml exists
    Steps:
      1. Run `cat l10n.yaml`
      2. Verify `arb-dir: lib/l10n` is present
      3. Verify `template-arb-file: app_en.arb` is present
      4. Verify `output-localization-file: app_localizations.dart` is present
      5. Verify file does NOT contain `output-dir` key
    Expected Result: 3 expected keys present, no output-dir
    Failure Indicators: Missing keys or extra output-dir directive
    Evidence: .sisyphus/evidence/task-1-l10n-yaml.txt
  ```

  **Commit**: YES (groups with Tasks 2, 3)
  - Message: `feat(i18n): add localization infrastructure with EN+FR ARB files`
  - Files: `pubspec.yaml`, `l10n.yaml`
  - Pre-commit: `flutter pub get`

- [x] 2. Create ARB Files — English template + French translations

  **What to do**:
  - Create directory `lib/l10n/`
  - Create `lib/l10n/app_en.arb` as the template file with ALL of the following keys (organized by category). Every key MUST have a `@key` metadata entry with `description`. Use ICU message format for interpolated strings:

    **Navigation (3 keys)**: `navToday`, `navMeals`, `navCalendar`
    **Screen titles (4 keys)**: `todayTitle`, `mealHistoryTitle`, `calendarTitle`, `dayDetailTitle`
    **Day rating (8 keys)**: `howWasYourDay`, `ratingBad`, `ratingOkay`, `ratingGreat`, `ratingNotSet`, `ratingLogged`, `dayRatingSubtitleToday` ("Tap the mood that matches today overall."), `dayRatingSubtitleDay` ("Tap the mood that matches this day overall.")
    **Daily metrics (12 keys)**: `dailyMetrics`, `goalMet`, `waterLabel`, `exerciseLabel`, `waterGoal` ("Goal: 1.5 L"), `notLogged`, `waterHintText` ("0.0"), `exerciseHintText` ("Optional: walk, gym, yoga"), `dailyMetricsSubtitleToday` ("Log water and exercise for today."), `dailyMetricsSubtitleDay` ("Log water and exercise for this day."), `waterAmount` ("{amount} L" — with placeholder), `waterUnit` ("L")
    **Meal slots (4 keys)**: `breakfast`, `lunch`, `afternoonSnack`, `dinner`
    **Photo actions (5 keys)**: `camera`, `gallery`, `replacePhoto`, `deletePhoto`, `imageNotFound`
    **Description (1 key)**: `addDescriptionHint` ("Add a description (optional)...")
    **Dialogs (4 keys)**: `clearMeal`, `clearMealConfirmation` ("Are you sure you want to clear {slotName}?" — ICU placeholder), `cancel`, `clear`
    **Empty states (4 keys)**: `noMealsYet`, `noMealsYetSubtitle` ("Start tracking your meals in the Today tab"), `noMealsLogged`, `noMealsLoggedSubtitle` ("Select another date or add meals from Today tab")
    **Error states (4 keys)**: `failedToLoadMeals`, `failedToLoadCalendar`, `unknownError`, `retry`
    **Meal preview (3 keys)**: `noDescription`, `recordedAt` ("Recorded at {time}" — ICU placeholder), `clearMealTooltip`
    **Metrics display (7 keys)**: `waterAmountWithGoal` ("{amount} L (goal met)" — ICU), `waterDash` ("—"), `exerciseYes` ("Yes"), `exerciseNo` ("No"), `exerciseDash` ("—"), `goalMetSuffix` ("(goal met)")
    **Date/time (3 keys)**: `today`, `yesterday`, `jumpToToday`
    **Provider errors (13 keys)**: `errorLoadMeals`, `errorLoadDayRating`, `errorLoadDailyMetrics`, `errorInvalidDayRating`, `errorSaveDayRating`, `errorSaveImage`, `errorCapturePhoto`, `errorPickImage`, `errorSaveMeal`, `errorDeletePhoto`, `errorClearMeal`, `errorSaveDailyMetrics`, `errorLoadCalendar`
    **App (1 key)**: `appTitle` ("Diet Tracker")

  - Create `lib/l10n/app_fr.arb` with French translations for ALL keys. Use natural French — not machine translation. Key examples:
    - `navToday` → "Aujourd'hui"
    - `navMeals` → "Repas"
    - `navCalendar` → "Calendrier"
    - `breakfast` → "Petit-déjeuner"
    - `lunch` → "Déjeuner"
    - `afternoonSnack` → "Goûter"
    - `dinner` → "Dîner"
    - `howWasYourDay` → "Comment s'est passée votre journée ?"
    - `ratingBad` → "Mal"
    - `ratingOkay` → "Correct"
    - `ratingGreat` → "Super"
    - `clearMealConfirmation` → "Êtes-vous sûr de vouloir effacer {slotName} ?"
    - `retry` → "Réessayer"
    - Error keys: use French equivalents (e.g., "Échec du chargement des repas")
    - All other keys: provide natural idiomatic French

  **Must NOT do**:
  - Do NOT use machine-translation quality — use natural French
  - Do NOT skip `@key` metadata descriptions on the English template
  - Do NOT add keys not listed above — keep it to the ~76 keys specified
  - Do NOT add plural forms unless explicitly needed (none are currently needed)

  **Recommended Agent Profile**:
  - **Category**: `writing`
    - Reason: Creating structured translation files requires attention to natural language quality
  - **Skills**: [`flutter-localization`]
    - `flutter-localization`: ARB file format and ICU message syntax patterns
  - **Skills Evaluated but Omitted**:
    - None

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 1 — Sequential (after Task 1)
  - **Blocks**: Task 3
  - **Blocked By**: Task 1

  **References**:

  **Pattern References**:
  - `.agents/skills/flutter-localization/SKILL.md:49-107` — ARB file structure with `@@locale`, key naming, and metadata patterns
  - `.sisyphus/plans/internationalization.md` (this file) — "What to do" section above has the complete key inventory

  **Source References** (strings extracted from these files):
  - `lib/config/routes.dart:96-107` — Navigation labels: 'Today', 'Meals', 'Calendar'
  - `lib/presentation/screens/today_screen.dart` — Day rating strings (L95, L185-188, L209, L217), daily metrics strings (L331, L349, L375, L410, L437), dialog strings (L523, L534, L539-542), format helpers (L554-584)
  - `lib/presentation/screens/meals_screen.dart` — History strings (L62, L107, L127, L149, L157, L250, L272-275, L292, L443, L471, L497)
  - `lib/presentation/screens/calendar_screen.dart` — Calendar strings (L45, L107, L341, L366, L375, L385-388, L395, L472, L540, L548, L570, L579, L590)
  - `lib/presentation/screens/day_detail_screen.dart` — Day detail strings (L53, L65, L335, L468, L631, L641-653)
  - `lib/presentation/widgets/meal_slot.dart` — Widget strings (L66, L77, L132, L152, L158, L188, L199, L280)
  - `lib/data/models/meal.dart:4-15` — MealSlot display names
  - `lib/presentation/providers/today_provider.dart:79-467` — All error message strings

  **WHY Each Reference Matters**:
  - Source files contain the exact English strings that must become ARB values — executor should cross-reference to ensure nothing is missed

  **Acceptance Criteria**:
  - [ ] `lib/l10n/app_en.arb` exists with `@@locale: "en"` and ~76 keys
  - [ ] `lib/l10n/app_fr.arb` exists with `@@locale: "fr"` and identical key set
  - [ ] Every key in EN has a `@key` metadata entry with `description`
  - [ ] `clearMealConfirmation` uses ICU placeholder syntax: `{slotName}`
  - [ ] `recordedAt` uses ICU placeholder syntax: `{time}`
  - [ ] `waterAmount` uses ICU placeholder syntax: `{amount}`
  - [ ] All FR translations are natural French (not literal word-for-word)
  - [ ] Valid JSON — both files parse without errors

  **QA Scenarios**:

  ```
  Scenario: Verify ARB files are valid JSON with correct structure
    Tool: Bash
    Preconditions: ARB files created
    Steps:
      1. Run `python3 -c "import json; d=json.load(open('lib/l10n/app_en.arb')); print(f'EN keys: {len([k for k in d if not k.startswith(\"@\")])}')"` — expect ~76 keys
      2. Run `python3 -c "import json; d=json.load(open('lib/l10n/app_fr.arb')); print(f'FR keys: {len([k for k in d if not k.startswith(\"@\")])}')"` — expect same count
      3. Run `python3 -c "import json; en=json.load(open('lib/l10n/app_en.arb')); fr=json.load(open('lib/l10n/app_fr.arb')); en_keys=set(k for k in en if not k.startswith('@')); fr_keys=set(k for k in fr if not k.startswith('@')); missing=en_keys-fr_keys; extra=fr_keys-en_keys; print(f'Missing in FR: {missing}'); print(f'Extra in FR: {extra}')"` — expect both empty sets
    Expected Result: Both files valid JSON, identical key sets, ~76 non-metadata keys each
    Failure Indicators: JSON parse error, mismatched keys, significantly fewer keys than expected
    Evidence: .sisyphus/evidence/task-2-arb-validation.txt

  Scenario: Verify ICU placeholders in interpolated strings
    Tool: Bash
    Preconditions: ARB files created
    Steps:
      1. Run `grep "slotName" lib/l10n/app_en.arb` — expect `{slotName}` in clearMealConfirmation
      2. Run `grep "slotName" lib/l10n/app_fr.arb` — expect `{slotName}` in French translation
      3. Run `grep '"time"' lib/l10n/app_en.arb` — expect `{time}` placeholder in recordedAt
      4. Run `grep '"amount"' lib/l10n/app_en.arb` — expect `{amount}` placeholder in waterAmount
    Expected Result: All interpolated strings use `{placeholder}` ICU syntax
    Failure Indicators: Missing placeholders, wrong syntax (e.g., `$variable` instead of `{variable}`)
    Evidence: .sisyphus/evidence/task-2-icu-placeholders.txt
  ```

  **Commit**: YES (groups with Tasks 1, 3)
  - Message: `feat(i18n): add localization infrastructure with EN+FR ARB files`
  - Files: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`
  - Pre-commit: JSON validation

- [x] 3. Configure App Root + l10n Helper + Run gen-l10n

  **What to do**:
  - Run `flutter gen-l10n` to generate localization files from ARB
  - Update `lib/app.dart` to add localization delegates and supported locales to `MaterialApp.router`:
    ```dart
    import 'package:flutter_localizations/flutter_localizations.dart';
    import 'package:flutter_gen/gen_l10n/app_localizations.dart';
    
    // In MaterialApp.router, add:
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('en'),
      Locale('fr'),
    ],
    ```
  - Create `lib/utils/l10n_helper.dart` with the `context.l10n` extension:
    ```dart
    import 'package:flutter/widgets.dart';
    import 'package:flutter_gen/gen_l10n/app_localizations.dart';
    
    extension L10nHelper on BuildContext {
      AppLocalizations get l10n => AppLocalizations.of(this)!;
    }
    ```
  - Verify `flutter gen-l10n` output exists and app compiles

  **Must NOT do**:
  - Do NOT add `localeResolutionCallback` — Flutter's default resolution is sufficient for EN+FR
  - Do NOT change the router config or theme in `app.dart`
  - Do NOT create the `lib/utils/` directory if it doesn't exist — check first, create if needed

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Small edits to 1 existing file + 1 new helper file + running a command
  - **Skills**: [`flutter-localization`]
    - `flutter-localization`: Exact MaterialApp localization delegate setup and l10n helper pattern
  - **Skills Evaluated but Omitted**:
    - `flutter-routing`: Not relevant — we're not changing routes, just adding delegates to MaterialApp

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 1 — Sequential (after Task 2)
  - **Blocks**: Tasks 4, 5, 6, 7, 8, 9, 10, 11
  - **Blocked By**: Task 1, Task 2

  **References**:

  **Pattern References**:
  - `lib/app.dart:1-18` — Current `MaterialApp.router` setup at line 10. Add `localizationsDelegates` and `supportedLocales` properties alongside existing `title`, `theme`, `darkTheme`, `routerConfig`
  - `.agents/skills/flutter-localization/SKILL.md:110-147` — MaterialApp localization delegate configuration pattern
  - `.agents/skills/flutter-localization/SKILL.md:299-323` — `context.l10n` extension helper pattern

  **WHY Each Reference Matters**:
  - `app.dart` — Must know exact current structure to add delegates without breaking router setup
  - Skill file — Provides correct import paths for generated files and delegate list

  **Acceptance Criteria**:
  - [ ] `flutter gen-l10n` completes without errors
  - [ ] Generated `app_localizations.dart` exists (check with `find .dart_tool -name "app_localizations.dart"` or the import resolves)
  - [ ] `lib/app.dart` imports `flutter_localizations` and `app_localizations`
  - [ ] `lib/app.dart` has `localizationsDelegates` with 4 delegates
  - [ ] `lib/app.dart` has `supportedLocales` with `Locale('en')` and `Locale('fr')`
  - [ ] `lib/utils/l10n_helper.dart` exists with `context.l10n` extension
  - [ ] `flutter analyze` passes

  **QA Scenarios**:

  ```
  Scenario: Verify gen-l10n and analyze pass
    Tool: Bash
    Preconditions: Tasks 1-2 completed (pubspec, l10n.yaml, ARB files exist)
    Steps:
      1. Run `flutter gen-l10n` — expect exit code 0
      2. Run `flutter analyze` — expect "No issues found!"
      3. Run `grep "localizationsDelegates" lib/app.dart` — expect match
      4. Run `grep "supportedLocales" lib/app.dart` — expect match
      5. Run `grep "context.l10n" lib/utils/l10n_helper.dart` — expect match
    Expected Result: gen-l10n succeeds, analyze clean, all config present
    Failure Indicators: gen-l10n errors, analyze warnings about missing delegates
    Evidence: .sisyphus/evidence/task-3-gen-l10n.txt

  Scenario: Verify l10n helper extension compiles
    Tool: Bash
    Preconditions: l10n_helper.dart created
    Steps:
      1. Run `flutter analyze lib/utils/l10n_helper.dart` — expect no errors
      2. Verify file imports `package:flutter_gen/gen_l10n/app_localizations.dart`
    Expected Result: Helper compiles, correct import path
    Failure Indicators: Import resolution failure, type errors
    Evidence: .sisyphus/evidence/task-3-helper-compile.txt
  ```

  **Commit**: YES (groups with Tasks 1, 2)
  - Message: `feat(i18n): add localization infrastructure with EN+FR ARB files`
  - Files: `lib/app.dart`, `lib/utils/l10n_helper.dart`
  - Pre-commit: `flutter gen-l10n && flutter analyze`

- [ ] 4. MealSlot Localization Extension

  **What to do**:
  - Create `lib/utils/meal_slot_localization.dart` with an extension on `MealSlot`:
    ```dart
    import 'package:flutter_gen/gen_l10n/app_localizations.dart';
    import '../data/models/meal.dart';
    
    extension MealSlotLocalization on MealSlot {
      String localizedName(AppLocalizations l10n) {
        switch (this) {
          case MealSlot.breakfast: return l10n.breakfast;
          case MealSlot.lunch: return l10n.lunch;
          case MealSlot.afternoonSnack: return l10n.afternoonSnack;
          case MealSlot.dinner: return l10n.dinner;
        }
      }
    }
    ```
  - Do NOT modify `lib/data/models/meal.dart` — keep existing `displayName` getter for backward compatibility
  - This extension will be imported by all screens/widgets that currently use `slot.displayName`

  **Must NOT do**:
  - Do NOT remove `MealSlotExtension.displayName` from `meal.dart`
  - Do NOT modify the `Meal` class or `MealSlot` enum
  - Do NOT add any UI changes — this is utility code only

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single small file creation, no complexity
  - **Skills**: [`flutter-localization`]
    - `flutter-localization`: Exact MealSlot localization extension pattern
  - **Skills Evaluated but Omitted**:
    - `flutter-state-management`: Not relevant — no state logic

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 5, 6)
  - **Blocks**: Tasks 7, 8, 9, 10, 11
  - **Blocked By**: Task 3

  **References**:

  **Pattern References**:
  - `lib/data/models/meal.dart:1-16` — `MealSlot` enum definition (line 1) and existing `MealSlotExtension.displayName` (lines 3-15). The new extension follows the same switch pattern but takes `AppLocalizations` parameter
  - `.agents/skills/flutter-localization/SKILL.md:149-184` — Exact `MealSlotLocalization` extension pattern with usage example

  **WHY Each Reference Matters**:
  - `meal.dart` — Must match the exact `MealSlot` enum values: `breakfast`, `lunch`, `afternoonSnack`, `dinner`
  - Skill file — Provides the proven extension pattern with correct import paths

  **Acceptance Criteria**:
  - [ ] `lib/utils/meal_slot_localization.dart` exists
  - [ ] Extension has `localizedName(AppLocalizations l10n)` method
  - [ ] Covers all 4 MealSlot values
  - [ ] `flutter analyze lib/utils/meal_slot_localization.dart` passes

  **QA Scenarios**:

  ```
  Scenario: Verify extension compiles and covers all enum values
    Tool: Bash
    Preconditions: Task 3 completed (gen-l10n ran, AppLocalizations exists)
    Steps:
      1. Run `flutter analyze lib/utils/meal_slot_localization.dart` — expect no errors
      2. Run `grep -c "MealSlot\." lib/utils/meal_slot_localization.dart` — expect 4 (one per enum value)
      3. Run `grep "localizedName" lib/utils/meal_slot_localization.dart` — expect method signature
    Expected Result: Clean analysis, all 4 enum values covered
    Failure Indicators: Missing enum case, analyze errors
    Evidence: .sisyphus/evidence/task-4-meal-slot-ext.txt
  ```

  **Commit**: YES (groups with Task 5)
  - Message: `feat(i18n): add MealSlot localization extension and DateFormatter utility`
  - Files: `lib/utils/meal_slot_localization.dart`
  - Pre-commit: `flutter analyze`

- [ ] 5. DateFormatter Utility Class

  **What to do**:
  - Create `lib/utils/date_formatter.dart` with a `DateFormatter` class that uses `intl DateFormat`:
    ```dart
    import 'package:intl/intl.dart';
    
    class DateFormatter {
      final String locale;
      DateFormatter(this.locale);
      
      /// "Wednesday, January 15" — for today_screen, day_detail_screen headers
      String formatFullDate(DateTime date) => DateFormat.EEEE(locale).add_yMMMMd().format(date);
      // Or: DateFormat('EEEE, MMMM d', locale).format(date)
      
      /// "January 2025" — for calendar month headers
      String formatMonthYear(DateTime date) => DateFormat.yMMMM(locale).format(date);
      
      /// "14:30" or locale-appropriate time — for meal timestamps
      String formatTime(DateTime date) => DateFormat.Hm(locale).format(date);
      
      /// "January 15" — for date groups in meal history (non-today/yesterday)
      String formatShortDate(DateTime date) => DateFormat.MMMd(locale).format(date);
      
      /// "Monday" — for weekday name in recent date groups
      String formatWeekday(DateTime date) => DateFormat.EEEE(locale).format(date);
    }
    ```
  - Also add a `BuildContext` extension for easy access:
    ```dart
    extension DateFormattingContext on BuildContext {
      DateFormatter get dateFormatter {
        final locale = Localizations.localeOf(this).toString();
        return DateFormatter(locale);
      }
    }
    ```
  - This replaces ALL manual month/weekday arrays currently duplicated in:
    - `today_screen.dart:_formatDate()` (lines 554-579)
    - `day_detail_screen.dart:_formatDate()` (lines 108-134)
    - `calendar_screen.dart:_formatMonthYear()` (lines 622-638), `_formatSelectedDate()` (lines 640-664), `_formatTime()` (lines 673-676)
    - `meals_screen.dart:_formatDateTime()` (lines 508-511)
    - `meal_history_card.dart:_formatTime()` (lines 159-163)
    - `meals_provider.dart:_getMonthName()` (lines 131-147)

  **Must NOT do**:
  - Do NOT modify any screen files in this task — just create the utility
  - Do NOT add calendar weekday header generation here (that goes in Task 9)
  - Do NOT use `Intl.message()` — use `DateFormat` only

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single utility file, straightforward DateFormat usage
  - **Skills**: [`flutter-localization`]
    - `flutter-localization`: DateFormatter patterns and locale-aware formatting
  - **Skills Evaluated but Omitted**:
    - None

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 6)
  - **Blocks**: Tasks 7, 8, 9, 10, 11
  - **Blocked By**: Task 3

  **References**:

  **Pattern References**:
  - `.agents/skills/flutter-localization/SKILL.md:187-259` — Complete `DateFormatter` class with locale parameter, `formatDate`, `formatTime`, `formatRelative`, and `BuildContext` extension
  - `lib/presentation/screens/today_screen.dart:554-579` — Current manual `_formatDate()` implementation with hardcoded month/weekday arrays — this is what gets replaced
  - `lib/presentation/screens/calendar_screen.dart:622-638` — `_formatMonthYear()` with hardcoded month array
  - `lib/presentation/screens/calendar_screen.dart:640-664` — `_formatSelectedDate()` with hardcoded arrays
  - `lib/presentation/screens/calendar_screen.dart:673-676` — Manual `_formatTime()` with zero-padding
  - `lib/presentation/providers/meals_provider.dart:131-147` — `_getMonthName()` with hardcoded array

  **WHY Each Reference Matters**:
  - Skill file — Provides the proven DateFormatter pattern
  - Screen files — Show the exact date formats being replaced so the utility produces equivalent output (e.g., "Wednesday, January 15" not "January 15, 2025")

  **Acceptance Criteria**:
  - [ ] `lib/utils/date_formatter.dart` exists
  - [ ] Has `formatFullDate`, `formatMonthYear`, `formatTime`, `formatShortDate`, `formatWeekday` methods
  - [ ] All methods accept `DateTime` and use `intl DateFormat` with locale
  - [ ] `BuildContext` extension `dateFormatter` is provided
  - [ ] `flutter analyze lib/utils/date_formatter.dart` passes

  **QA Scenarios**:

  ```
  Scenario: Verify DateFormatter compiles and has required methods
    Tool: Bash
    Preconditions: intl package available (already in pubspec)
    Steps:
      1. Run `flutter analyze lib/utils/date_formatter.dart` — expect no errors
      2. Run `grep "formatFullDate\|formatMonthYear\|formatTime\|formatShortDate\|formatWeekday" lib/utils/date_formatter.dart` — expect 5 matches
      3. Run `grep "DateFormat" lib/utils/date_formatter.dart` — expect multiple matches (one per method)
      4. Run `grep "dateFormatter" lib/utils/date_formatter.dart` — expect BuildContext extension
    Expected Result: All 5 formatting methods present, using intl DateFormat
    Failure Indicators: Missing methods, not using intl, analyze errors
    Evidence: .sisyphus/evidence/task-5-date-formatter.txt
  ```

  **Commit**: YES (groups with Task 4)
  - Message: `feat(i18n): add MealSlot localization extension and DateFormatter utility`
  - Files: `lib/utils/date_formatter.dart`
  - Pre-commit: `flutter analyze`

- [ ] 6. Localize Provider Error Messages

  **What to do**:
  - Update error messages in providers to use localization keys. Since providers don't have `BuildContext`, use one of two approaches:
    - **Approach A (recommended)**: Store error keys/enum values in providers, resolve to localized strings in the UI layer when displaying errors
    - **Approach B**: Accept `AppLocalizations` as parameter in methods that set errors
  - For simplicity and minimum disruption, use **Approach A**: Change error string fields to store a structured error that the UI can localize. The simplest version: keep error strings as-is in providers (they serve as error identifiers), and localize them in the UI widgets where they're displayed.
  - Actually, the SIMPLEST approach with minimum changes: just make the error messages use l10n in the UI. The providers already set `_error = 'Failed to load meals: $e'`. Instead of changing providers, change how UI displays the error:
    - In screens that show `provider.error`, replace the raw error display with localized versions
    - Map provider error strings to l10n keys in the screen using a helper or switch
  - **HOWEVER**, for cleaner architecture: update providers to accept l10n and use localized error strings. Since `loadTodayMeals()` etc. are called from `initState` or `addListener` where context IS available, pass `AppLocalizations` to provider methods:
    - Change `loadTodayMeals()` → `loadTodayMeals(AppLocalizations l10n)` and use `l10n.errorLoadMeals`
    - Apply same pattern to ALL provider methods that set `_error`
  - Files to modify:
    - `lib/presentation/providers/today_provider.dart` — ~12 error strings
    - `lib/presentation/providers/day_detail_provider.dart` — same ~12 error strings
    - `lib/presentation/providers/meals_provider.dart` — 1 error string + `getFormattedDateGroup()` to accept `AppLocalizations` for 'Today'/'Yesterday'
    - `lib/presentation/providers/calendar_provider.dart` — 1 error string

  **Must NOT do**:
  - Do NOT change the public API shape of providers beyond adding optional `AppLocalizations` parameters
  - Do NOT modify screen files to pass l10n — that happens in Tasks 7-10
  - Do NOT remove the `$e` exception detail from error messages — append it for debugging: `'${l10n.errorLoadMeals}: $e'`

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Touches 4 provider files with careful API changes, needs to understand call chains
  - **Skills**: [`flutter-localization`, `flutter-state-management`]
    - `flutter-localization`: Error localization patterns
    - `flutter-state-management`: ChangeNotifier patterns, understanding provider lifecycle
  - **Skills Evaluated but Omitted**:
    - `flutter-performance`: Not relevant — no performance concern

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 2 (with Tasks 4, 5)
  - **Blocks**: Task 12
  - **Blocked By**: Task 3

  **References**:

  **Pattern References**:
  - `lib/presentation/providers/today_provider.dart:79-467` — All error message assignments. Pattern: `_error = 'Failed to X: $e'; notifyListeners();`. Lines: 79, 89, 104, 133, 141, 166, 173, 199, 207, 330, 374, 401, 467
  - `lib/presentation/providers/meals_provider.dart:81` — `_error = 'Failed to load meals: $e'`
  - `lib/presentation/providers/meals_provider.dart:105-147` — `getFormattedDateGroup()` with hardcoded 'Today'/'Yesterday'/weekday strings and `_getMonthName()` helper

  **API/Type References**:
  - `lib/presentation/providers/today_provider.dart` — `loadTodayMeals()`, `loadDayRating()`, `loadDailyMetrics()`, `saveDayRating()`, `capturePhoto()`, `pickImage()`, `saveMeal()`, `deletePhoto()`, `clearMeal()`, `saveDailyMetrics()` — these all need l10n parameter

  **WHY Each Reference Matters**:
  - `today_provider.dart` — Has the most error strings (~12), establishes the pattern for all other providers
  - `meals_provider.dart` — Has both error string AND `getFormattedDateGroup()` which uses 'Today'/'Yesterday' — must update both

  **Acceptance Criteria**:
  - [ ] All provider methods that set `_error` accept `AppLocalizations` parameter (or equivalent)
  - [ ] Error messages use l10n keys: `l10n.errorLoadMeals`, `l10n.errorSaveMeal`, etc.
  - [ ] Exception detail `$e` is preserved in error messages for debugging
  - [ ] `getFormattedDateGroup()` in meals_provider accepts `AppLocalizations` and uses `l10n.today`, `l10n.yesterday`
  - [ ] `flutter analyze` passes on all modified provider files

  **QA Scenarios**:

  ```
  Scenario: Verify providers accept l10n and use localized error keys
    Tool: Bash
    Preconditions: Tasks 1-3 completed
    Steps:
      1. Run `flutter analyze lib/presentation/providers/` — expect no errors
      2. Run `grep -c "AppLocalizations" lib/presentation/providers/today_provider.dart` — expect > 0
      3. Run `grep "l10n.error" lib/presentation/providers/today_provider.dart` — expect multiple matches
      4. Run `grep "l10n.today\|l10n.yesterday" lib/presentation/providers/meals_provider.dart` — expect matches
      5. Run `grep "'Failed to" lib/presentation/providers/today_provider.dart` — expect 0 matches (all replaced)
    Expected Result: All hardcoded error strings replaced with l10n calls, analyze clean
    Failure Indicators: Remaining hardcoded error strings, analyze errors
    Evidence: .sisyphus/evidence/task-6-provider-errors.txt

  Scenario: Verify exception details preserved in error messages
    Tool: Bash
    Preconditions: Provider files updated
    Steps:
      1. Run `grep '\$e' lib/presentation/providers/today_provider.dart` — expect multiple matches (exception detail kept)
      2. Verify pattern is like `'${l10n.errorLoadMeals}: $e'` not just `l10n.errorLoadMeals`
    Expected Result: Every error assignment includes `: $e` suffix for debugging
    Failure Indicators: Missing exception details in error messages
    Evidence: .sisyphus/evidence/task-6-error-details.txt
  ```

  **Commit**: YES
  - Message: `feat(i18n): localize provider error messages`
  - Files: `lib/presentation/providers/today_provider.dart`, `lib/presentation/providers/day_detail_provider.dart`, `lib/presentation/providers/meals_provider.dart`, `lib/presentation/providers/calendar_provider.dart`
  - Pre-commit: `flutter analyze`

- [ ] 7. Localize today_screen.dart

  **What to do**:
  - Import `l10n_helper.dart`, `meal_slot_localization.dart`, `date_formatter.dart`
  - Replace ALL hardcoded strings with `context.l10n.*` calls:
    - `'Today'` (L95) → `context.l10n.todayTitle`
    - `'How was your day?'` (L209) → `context.l10n.howWasYourDay`
    - `'Not set'` (L217) → `context.l10n.ratingNotSet`
    - `'Logged'` (L217) → `context.l10n.ratingLogged`
    - `'Tap the mood that matches today overall.'` → `context.l10n.dayRatingSubtitleToday`
    - `'Bad'` / `'Okay'` / `'Great'` (L185-188) → `context.l10n.ratingBad` / `.ratingOkay` / `.ratingGreat`
    - `'Daily Metrics'` (L331) → `context.l10n.dailyMetrics`
    - `'Goal met'` (L349) → `context.l10n.goalMet`
    - `'Log water and exercise for today.'` → `context.l10n.dailyMetricsSubtitleToday`
    - `'Water'` (L375) → `context.l10n.waterLabel`
    - `'0.0'` hint (L) → `context.l10n.waterHintText`
    - `'Goal: 1.5 L'` (L410) → `context.l10n.waterGoal`
    - `'Not logged'` (L305) → `context.l10n.notLogged`
    - `'Exercise'` (L437) → `context.l10n.exerciseLabel`
    - `'Optional: walk, gym, yoga'` → `context.l10n.exerciseHintText`
    - `'Retry'` (L523) → `context.l10n.retry`
    - `'Clear Meal'` (L534) → `context.l10n.clearMeal`
    - `'Are you sure you want to clear ${slot.displayName}?'` → `context.l10n.clearMealConfirmation(slot.localizedName(context.l10n))`
    - `'Cancel'` (L539) → `context.l10n.cancel`
    - `'Clear'` (L542) → `context.l10n.clear`
  - Replace `slot.displayName` → `slot.localizedName(context.l10n)` everywhere in this file
  - Replace `_formatDate()` method (L554-579) with `context.dateFormatter.formatFullDate(date)` — DELETE the manual month/weekday arrays
  - Replace `_formatWater()` helper (L582-584) with `context.l10n.waterAmount(amount)` or equivalent
  - Update calls to provider methods to pass `context.l10n` where needed (if provider API changed in Task 6)
  - Remove `const` from widgets that now use l10n (dynamic strings can't be const)

  **Must NOT do**:
  - Do NOT change widget layout, animations, or styling
  - Do NOT refactor widget tree structure
  - Do NOT touch provider logic beyond passing l10n parameter
  - Do NOT localize user-entered description text

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Largest screen file (585 lines), most string replacements (~25+), needs careful line-by-line work
  - **Skills**: [`flutter-localization`]
    - `flutter-localization`: String replacement patterns, context.l10n usage
  - **Skills Evaluated but Omitted**:
    - `flutter-state-management`: Provider changes already done in Task 6
    - `flutter-performance`: No performance impact from string lookups

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 8, 9, 10, 11)
  - **Blocks**: Task 12
  - **Blocked By**: Tasks 3, 4, 5

  **References**:

  **Pattern References**:
  - `lib/presentation/screens/today_screen.dart:1-585` — Full file. Key sections: AppBar title (L95), day rating section (L185-220), daily metrics section (L331-470), format helpers (L554-584), dialog (L534-542)
  - `lib/utils/l10n_helper.dart` — `context.l10n` extension (created in Task 3)
  - `lib/utils/meal_slot_localization.dart` — `slot.localizedName(l10n)` (created in Task 4)
  - `lib/utils/date_formatter.dart` — `context.dateFormatter.formatFullDate()` (created in Task 5)

  **WHY Each Reference Matters**:
  - `today_screen.dart` — The primary file being modified. Executor must read it fully to find every hardcoded string
  - Utility files — Must import and use them correctly

  **Acceptance Criteria**:
  - [ ] Zero hardcoded user-facing English strings remaining
  - [ ] `_formatDate()` method deleted (replaced by DateFormatter)
  - [ ] `_formatWater()` method deleted or replaced with l10n call
  - [ ] All `slot.displayName` replaced with `slot.localizedName(context.l10n)`
  - [ ] `flutter analyze lib/presentation/screens/today_screen.dart` passes

  **QA Scenarios**:

  ```
  Scenario: Verify no hardcoded English strings remain
    Tool: Bash
    Preconditions: All replacements done
    Steps:
      1. Run `flutter analyze lib/presentation/screens/today_screen.dart` — expect no errors
      2. Run `grep -n "'Today'\|'How was\|'Bad'\|'Okay'\|'Great'\|'Daily Metrics'\|'Goal met'\|'Water'\|'Exercise'\|'Retry'\|'Clear Meal'\|'Cancel'\|'Clear'\|'Not set'\|'Logged'\|'Not logged'" lib/presentation/screens/today_screen.dart` — expect 0 matches
      3. Run `grep -n "displayName" lib/presentation/screens/today_screen.dart` — expect 0 matches (all replaced with localizedName)
      4. Run `grep -n "_formatDate\|_months\|_weekdays" lib/presentation/screens/today_screen.dart` — expect 0 matches (manual arrays deleted)
    Expected Result: All strings localized, manual date formatting removed
    Failure Indicators: Any hardcoded strings remaining, displayName still used
    Evidence: .sisyphus/evidence/task-7-today-screen.txt
  ```

  **Commit**: YES (groups with Tasks 8-11)
  - Message: `feat(i18n): replace all hardcoded strings in screens, widgets, and routes`
  - Files: `lib/presentation/screens/today_screen.dart`
  - Pre-commit: `flutter analyze`

- [ ] 8. Localize meals_screen.dart + meals_provider.dart

  **What to do**:
  - Import `l10n_helper.dart`, `meal_slot_localization.dart`, `date_formatter.dart`
  - Replace ALL hardcoded strings in `meals_screen.dart`:
    - `'Meal History'` (L62) → `context.l10n.mealHistoryTitle`
    - `'Failed to load meals'` (L107) → `context.l10n.failedToLoadMeals`
    - `'Retry'` (L127) → `context.l10n.retry`
    - `'No meals yet'` (L149) → `context.l10n.noMealsYet`
    - `'Start tracking your meals in the Today tab'` (L157) → `context.l10n.noMealsYetSubtitle`
    - `'No description'` (L471, L497) → `context.l10n.noDescription`
    - `'Recorded at ${...}'` (L443) → `context.l10n.recordedAt(formattedTime)`
    - `'Water: —'` / `'Water: X L'` / `'(goal met)'` (L272-275) → use l10n keys
    - `'Exercise: Yes/No'` (L250, L292) → `context.l10n.exerciseYes` / `.exerciseNo`
  - Replace `slot.displayName` → `slot.localizedName(context.l10n)`
  - Replace `_formatWater()` (L515-516) with l10n call
  - Replace `_formatDateTime()` (L508-511) with `context.dateFormatter.formatTime(date)`
  - Update calls to `provider.getFormattedDateGroup()` (L375) to pass `context.l10n`
  - In `meals_provider.dart`: Update `getFormattedDateGroup()` to use `DateFormatter` for weekday names and month-day format instead of hardcoded arrays (already updated signature in Task 6). Delete `_getMonthName()` helper (L131-147)

  **Must NOT do**:
  - Do NOT change infinite scroll logic or pagination behavior
  - Do NOT modify the meal card layout structure

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Two files to modify, date group formatting logic needs careful migration
  - **Skills**: [`flutter-localization`]
    - `flutter-localization`: String replacement and date formatting patterns
  - **Skills Evaluated but Omitted**:
    - `flutter-state-management`: Provider signature already changed in Task 6

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 7, 9, 10, 11)
  - **Blocks**: Task 12
  - **Blocked By**: Tasks 3, 4, 5

  **References**:

  **Pattern References**:
  - `lib/presentation/screens/meals_screen.dart:1-517` — Full file. Key sections: AppBar (L62), error state (L107-127), empty state (L149-157), meal preview strings (L250-292, L443-497), format helpers (L508-516)
  - `lib/presentation/providers/meals_provider.dart:105-147` — `getFormattedDateGroup()` with 'Today'/'Yesterday'/weekday arrays and `_getMonthName()` helper

  **WHY Each Reference Matters**:
  - `meals_screen.dart` — Primary file, all hardcoded strings must be found and replaced
  - `meals_provider.dart` — `getFormattedDateGroup()` logic must switch from manual arrays to `DateFormatter` while keeping the same relative date behavior (today/yesterday/this week/older)

  **Acceptance Criteria**:
  - [ ] Zero hardcoded user-facing English strings in `meals_screen.dart`
  - [ ] `_formatWater()` and `_formatDateTime()` deleted or replaced
  - [ ] `_getMonthName()` deleted from `meals_provider.dart`
  - [ ] `getFormattedDateGroup()` uses `DateFormatter` + l10n for 'Today'/'Yesterday'
  - [ ] `flutter analyze` passes on both files

  **QA Scenarios**:

  ```
  Scenario: Verify meals screen and provider are fully localized
    Tool: Bash
    Preconditions: All replacements done
    Steps:
      1. Run `flutter analyze lib/presentation/screens/meals_screen.dart lib/presentation/providers/meals_provider.dart` — expect no errors
      2. Run `grep -n "'Meal History'\|'Failed to load'\|'Retry'\|'No meals'\|'No description'\|'Recorded at'\|'Water:'\|'Exercise:'" lib/presentation/screens/meals_screen.dart` — expect 0 matches
      3. Run `grep -n "_getMonthName\|_months" lib/presentation/providers/meals_provider.dart` — expect 0 matches
      4. Run `grep -n "'Today'\|'Yesterday'" lib/presentation/providers/meals_provider.dart` — expect 0 matches
    Expected Result: All strings localized, manual date helpers removed
    Failure Indicators: Any remaining hardcoded strings
    Evidence: .sisyphus/evidence/task-8-meals.txt
  ```

  **Commit**: YES (groups with Tasks 7, 9-11)
  - Message: `feat(i18n): replace all hardcoded strings in screens, widgets, and routes`
  - Files: `lib/presentation/screens/meals_screen.dart`, `lib/presentation/providers/meals_provider.dart`
  - Pre-commit: `flutter analyze`

- [ ] 9. Localize calendar_screen.dart

  **What to do**:
  - Import `l10n_helper.dart`, `meal_slot_localization.dart`, `date_formatter.dart`
  - Replace ALL hardcoded strings:
    - `'Calendar'` (L45) → `context.l10n.calendarTitle`
    - `'Daily Metrics'` (L366) → `context.l10n.dailyMetrics`
    - `'Goal met'` (L375) → `context.l10n.goalMet`
    - `'Water: —'` / `'Water: X L (goal met)'` (L385-388) → l10n keys
    - `'Exercise: Yes/No/—'` (L341, L395) → l10n keys
    - `'No meals logged'` (L540) → `context.l10n.noMealsLogged`
    - `'Select another date or add meals from Today tab'` (L548) → `context.l10n.noMealsLoggedSubtitle`
    - `'Failed to load calendar'` (L570) → `context.l10n.failedToLoadCalendar`
    - `'Unknown error'` (L579) → `context.l10n.unknownError`
    - `'Retry'` (L590) → `context.l10n.retry`
    - `'No description'` (L472) → `context.l10n.noDescription`
  - Replace weekday labels `['M','T','W','T','F','S','S']` (L107) with locale-derived labels:
    ```dart
    // Generate from intl DateFormat
    final weekdayLabels = List.generate(7, (i) {
      final date = DateTime(2024, 1, 1 + i); // Monday = Jan 1 2024
      return DateFormat.E(Localizations.localeOf(context).toString())
          .format(date)[0].toUpperCase();
    });
    ```
  - Replace `slot.displayName` → `slot.localizedName(context.l10n)`
  - Replace `_formatMonthYear()` (L622-638) with `context.dateFormatter.formatMonthYear(date)` — DELETE manual month arrays
  - Replace `_formatSelectedDate()` (L640-664) with `context.dateFormatter.formatFullDate(date)` — DELETE manual arrays
  - Replace `_formatTime()` (L673-676) with `context.dateFormatter.formatTime(date)`
  - Replace `_formatWater()` (L679-681) with l10n call

  **Must NOT do**:
  - Do NOT change calendar grid layout or dot indicators
  - Do NOT modify date selection logic
  - Do NOT change the calendar navigation behavior

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Large file (701 lines), complex date formatting, weekday label generation needs care
  - **Skills**: [`flutter-localization`]
    - `flutter-localization`: Date formatting and locale-aware weekday generation
  - **Skills Evaluated but Omitted**:
    - `flutter-performance`: Calendar rendering not affected by string changes

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 7, 8, 10, 11)
  - **Blocks**: Task 12
  - **Blocked By**: Tasks 3, 4, 5

  **References**:

  **Pattern References**:
  - `lib/presentation/screens/calendar_screen.dart:1-701` — Full file. Key sections: AppBar (L45), weekday headers (L107), metrics section (L341-395), empty state (L540-548), error state (L570-590), format helpers (L622-681)

  **WHY Each Reference Matters**:
  - `calendar_screen.dart` — All 4 manual format methods must be found and replaced with DateFormatter equivalents
  - Weekday labels are the trickiest part — must generate from locale, not hardcode single letters

  **Acceptance Criteria**:
  - [ ] Zero hardcoded user-facing English strings remaining
  - [ ] Weekday headers generated from locale (not hardcoded `['M','T','W','T','F','S','S']`)
  - [ ] ALL 4 format helpers deleted: `_formatMonthYear`, `_formatSelectedDate`, `_formatTime`, `_formatWater`
  - [ ] `flutter analyze lib/presentation/screens/calendar_screen.dart` passes

  **QA Scenarios**:

  ```
  Scenario: Verify calendar screen fully localized
    Tool: Bash
    Preconditions: All replacements done
    Steps:
      1. Run `flutter analyze lib/presentation/screens/calendar_screen.dart` — expect no errors
      2. Run `grep -n "'Calendar'\|'Daily Metrics'\|'Goal met'\|'Water:'\|'Exercise:'\|'No meals'\|'Failed to load'\|'Unknown error'\|'Retry'\|'No description'" lib/presentation/screens/calendar_screen.dart` — expect 0 matches
      3. Run `grep -n "'M','T','W'" lib/presentation/screens/calendar_screen.dart` — expect 0 matches (hardcoded weekday array removed)
      4. Run `grep -n "_formatMonthYear\|_formatSelectedDate\|_formatTime\|_formatWater\|_months\|_weekdays" lib/presentation/screens/calendar_screen.dart` — expect 0 matches (manual helpers deleted)
    Expected Result: All strings localized, all manual format helpers removed
    Failure Indicators: Any remaining hardcoded strings or format helpers
    Evidence: .sisyphus/evidence/task-9-calendar.txt
  ```

  **Commit**: YES (groups with Tasks 7, 8, 10, 11)
  - Message: `feat(i18n): replace all hardcoded strings in screens, widgets, and routes`
  - Files: `lib/presentation/screens/calendar_screen.dart`
  - Pre-commit: `flutter analyze`

- [ ] 10. Localize day_detail_screen.dart

  **What to do**:
  - Import `l10n_helper.dart`, `meal_slot_localization.dart`, `date_formatter.dart`
  - Replace ALL hardcoded strings:
    - `'Day Detail'` (L53) → `context.l10n.dayDetailTitle`
    - `'Jump to today'` (L65) → `context.l10n.jumpToToday`
    - Day rating section — same strings as today_screen but use `dayRatingSubtitleDay` ("this day overall") instead of `dayRatingSubtitleToday`
    - Daily metrics section — same strings but use `dailyMetricsSubtitleDay` ("for this day") instead of `dailyMetricsSubtitleToday`
    - `'Retry'` (L631) → `context.l10n.retry`
    - `'Clear Meal'` / dialog strings (L641-653) → same l10n keys as today_screen
  - Replace `slot.displayName` → `slot.localizedName(context.l10n)`
  - Replace `_formatDate()` (L108-134) with `context.dateFormatter.formatFullDate(date)` — DELETE manual arrays
  - Replace `_formatWater()` (L589-591) with l10n call
  - Update calls to provider methods to pass `context.l10n` where needed

  **Must NOT do**:
  - Do NOT change swipe navigation logic
  - Do NOT modify day detail provider beyond what Task 6 already did
  - Do NOT use `dayRatingSubtitleToday` — this screen uses the "this day" variants

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Large file (661 lines), similar to today_screen but with subtle string differences
  - **Skills**: [`flutter-localization`]
    - `flutter-localization`: String replacement patterns
  - **Skills Evaluated but Omitted**:
    - None

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 7, 8, 9, 11)
  - **Blocks**: Task 12
  - **Blocked By**: Tasks 3, 4, 5

  **References**:

  **Pattern References**:
  - `lib/presentation/screens/day_detail_screen.dart:1-661` — Full file. Key sections: AppBar (L53), jump to today tooltip (L65), day rating (similar to today_screen but subtitle differs at L335), daily metrics (subtitle differs at L468), format helpers (L108-134, L589-591), dialog (L641-653)
  - Task 7 output — Follow the same replacement pattern used for today_screen.dart

  **WHY Each Reference Matters**:
  - `day_detail_screen.dart` — Must use the "this day" variants of subtitle keys, not "today" variants. The subtle difference is critical.
  - Task 7 — Establishes the pattern to follow consistently

  **Acceptance Criteria**:
  - [ ] Zero hardcoded user-facing English strings remaining
  - [ ] Uses `dayRatingSubtitleDay` (NOT `dayRatingSubtitleToday`)
  - [ ] Uses `dailyMetricsSubtitleDay` (NOT `dailyMetricsSubtitleToday`)
  - [ ] `_formatDate()` and `_formatWater()` deleted
  - [ ] `flutter analyze lib/presentation/screens/day_detail_screen.dart` passes

  **QA Scenarios**:

  ```
  Scenario: Verify day detail screen fully localized with correct variants
    Tool: Bash
    Preconditions: All replacements done
    Steps:
      1. Run `flutter analyze lib/presentation/screens/day_detail_screen.dart` — expect no errors
      2. Run `grep -n "'Day Detail'\|'Jump to today'\|'Retry'\|'Clear Meal'\|'Cancel'\|'Clear'" lib/presentation/screens/day_detail_screen.dart` — expect 0 matches
      3. Run `grep -n "_formatDate\|_formatWater\|_months\|_weekdays" lib/presentation/screens/day_detail_screen.dart` — expect 0 matches
      4. Run `grep "dayRatingSubtitleToday\|dailyMetricsSubtitleToday" lib/presentation/screens/day_detail_screen.dart` — expect 0 matches (should use Day variants, not Today)
      5. Run `grep "dayRatingSubtitleDay\|dailyMetricsSubtitleDay" lib/presentation/screens/day_detail_screen.dart` — expect matches
    Expected Result: All localized, correct Day variants used (not Today)
    Failure Indicators: Wrong subtitle variant, remaining hardcoded strings
    Evidence: .sisyphus/evidence/task-10-day-detail.txt
  ```

  **Commit**: YES (groups with Tasks 7-9, 11)
  - Message: `feat(i18n): replace all hardcoded strings in screens, widgets, and routes`
  - Files: `lib/presentation/screens/day_detail_screen.dart`
  - Pre-commit: `flutter analyze`

- [ ] 11. Localize Widgets (meal_slot.dart, meal_history_card.dart) + routes.dart

  **What to do**:
  - **`lib/presentation/widgets/meal_slot.dart`**:
    - Import `l10n_helper.dart`, `meal_slot_localization.dart`
    - Replace `slot.displayName` (L66) → `slot.localizedName(context.l10n)`
    - `'Clear meal'` tooltip (L77) → `context.l10n.clearMealTooltip`
    - `'Camera'` (L188) → `context.l10n.camera`
    - `'Gallery'` (L199) → `context.l10n.gallery`
    - `'Image not found'` (L132) → `context.l10n.imageNotFound`
    - `'Replace photo'` tooltip (L152) → `context.l10n.replacePhoto`
    - `'Delete photo'` tooltip (L158) → `context.l10n.deletePhoto`
    - `'Add a description (optional)...'` hint (L280) → `context.l10n.addDescriptionHint`
  
  - **`lib/presentation/widgets/meal_history_card.dart`**:
    - Import `l10n_helper.dart`, `meal_slot_localization.dart`, `date_formatter.dart`
    - Replace `meal.slot.displayName` (L52) → `meal.slot.localizedName(context.l10n)`
    - Replace `_formatTime()` (L159-163) with `context.dateFormatter.formatTime(date)` — DELETE manual method

  - **`lib/config/routes.dart`**:
    - Import `l10n_helper.dart`
    - Remove `const` from the `destinations` list (l10n strings can't be const)
    - Replace navigation labels:
      - `'Today'` (L96) → `context.l10n.navToday`
      - `'Meals'` (L101) → `context.l10n.navMeals`
      - `'Calendar'` (L106) → `context.l10n.navCalendar`
    - Note: `MainScaffold` is a `StatelessWidget` with `build(BuildContext context)` — context is available

  **Must NOT do**:
  - Do NOT change widget APIs or constructor signatures
  - Do NOT restructure the navigation bar or routing logic
  - Do NOT add l10n to the `GoRoute` path strings (those are URL paths, not user-facing)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: 3 files to modify, routes.dart needs const removal which requires care
  - **Skills**: [`flutter-localization`]
    - `flutter-localization`: Widget localization and context.l10n patterns
  - **Skills Evaluated but Omitted**:
    - `flutter-routing`: Routes aren't changing, just nav labels

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 7, 8, 9, 10)
  - **Blocks**: Task 12
  - **Blocked By**: Tasks 3, 4, 5

  **References**:

  **Pattern References**:
  - `lib/presentation/widgets/meal_slot.dart:1-327` — Full file. Strings at L66, L77, L132, L152, L158, L188, L199, L280
  - `lib/presentation/widgets/meal_history_card.dart:1-164` — Full file. `meal.slot.displayName` at L52, `_formatTime()` at L159-163
  - `lib/config/routes.dart:78-111` — `MainScaffold` widget. `const` destinations list at L92, labels at L96/L101/L106

  **WHY Each Reference Matters**:
  - `meal_slot.dart` — Has 8 hardcoded strings, most are tooltips/labels
  - `meal_history_card.dart` — Small file but has `displayName` and manual time format
  - `routes.dart` — `const` keyword on destinations list must be removed since l10n strings are runtime values

  **Acceptance Criteria**:
  - [ ] Zero hardcoded user-facing English strings in all 3 files
  - [ ] `const` removed from `destinations` list in routes.dart
  - [ ] `_formatTime()` deleted from meal_history_card.dart
  - [ ] All `displayName` → `localizedName(context.l10n)` in both widgets
  - [ ] `flutter analyze` passes on all 3 files

  **QA Scenarios**:

  ```
  Scenario: Verify widgets and routes fully localized
    Tool: Bash
    Preconditions: All replacements done
    Steps:
      1. Run `flutter analyze lib/presentation/widgets/meal_slot.dart lib/presentation/widgets/meal_history_card.dart lib/config/routes.dart` — expect no errors
      2. Run `grep -n "'Camera'\|'Gallery'\|'Image not found'\|'Replace photo'\|'Delete photo'\|'Add a description'\|'Clear meal'" lib/presentation/widgets/meal_slot.dart` — expect 0 matches
      3. Run `grep -n "displayName" lib/presentation/widgets/meal_slot.dart lib/presentation/widgets/meal_history_card.dart` — expect 0 matches
      4. Run `grep -n "'Today'\|'Meals'\|'Calendar'" lib/config/routes.dart` — expect 0 matches
      5. Run `grep -n "const \[" lib/config/routes.dart` — verify destinations list is NOT const
      6. Run `grep -n "_formatTime" lib/presentation/widgets/meal_history_card.dart` — expect 0 matches
    Expected Result: All 3 files clean of hardcoded strings
    Failure Indicators: Remaining hardcoded strings, const still on destinations
    Evidence: .sisyphus/evidence/task-11-widgets-routes.txt
  ```

  **Commit**: YES (groups with Tasks 7-10)
  - Message: `feat(i18n): replace all hardcoded strings in screens, widgets, and routes`
  - Files: `lib/presentation/widgets/meal_slot.dart`, `lib/presentation/widgets/meal_history_card.dart`, `lib/config/routes.dart`
  - Pre-commit: `flutter analyze`

- [ ] 12. Full Build + Test + String Audit

  **What to do**:
  - Run `flutter gen-l10n` to regenerate localization files (catches any new/changed ARB keys)
  - Run `flutter analyze` — must pass with zero errors
  - Run `flutter test` — all 11 existing tests must pass
  - Run `dart format --set-exit-if-changed .` — formatting must be clean
  - Run comprehensive string audit:
    ```bash
    # Find any remaining hardcoded user-facing strings in presentation layer
    grep -rn "'" lib/presentation/ lib/config/routes.dart --include="*.dart" | \
      grep -v "import\|//\|Icons\.\|Curves\.\|'date'\|'slot'\|'id'\|'description'\|'imagePath'\|'/today\|'/meals\|'/calendar\|'Manrope'\|key:\|'en'\|'fr'\|package:" 
    ```
  - Verify EN and FR ARB files have identical key sets (no missing translations)
  - If any issues found: fix them in the appropriate files
  - Run `flutter gen-l10n && flutter analyze && flutter test` again after any fixes

  **Must NOT do**:
  - Do NOT add new features or change behavior
  - Do NOT modify tests to make them pass — fix the source code instead
  - Do NOT skip the string audit — this is the critical final check

  **Recommended Agent Profile**:
  - **Category**: `deep`
    - Reason: Comprehensive verification across entire codebase, requires thorough analysis and fixing
  - **Skills**: [`flutter-localization`]
    - `flutter-localization`: Understanding of what constitutes a "hardcoded string" vs legitimate code
  - **Skills Evaluated but Omitted**:
    - `flutter-testing`: No new tests being written

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 4 — Sequential (after all Wave 3 tasks)
  - **Blocks**: F1-F4
  - **Blocked By**: Tasks 6, 7, 8, 9, 10, 11

  **References**:

  **Pattern References**:
  - All files modified in Tasks 1-11
  - `test/` directory — All 11 existing test files

  **WHY Each Reference Matters**:
  - Modified files — Need to verify no regressions introduced
  - Test files — May need minor adjustments if tests reference hardcoded strings or MealSlot.displayName

  **Acceptance Criteria**:
  - [ ] `flutter gen-l10n` — exit code 0
  - [ ] `flutter analyze` — "No issues found!"
  - [ ] `flutter test` — all tests pass
  - [ ] `dart format --set-exit-if-changed .` — exit code 0
  - [ ] String audit finds zero remaining hardcoded user-facing English strings
  - [ ] EN and FR ARB files have identical key sets

  **QA Scenarios**:

  ```
  Scenario: Full build and test pipeline passes
    Tool: Bash
    Preconditions: All Tasks 1-11 completed
    Steps:
      1. Run `flutter gen-l10n` — expect exit code 0
      2. Run `flutter analyze` — expect "No issues found!"
      3. Run `flutter test` — expect all tests pass
      4. Run `dart format --set-exit-if-changed .` — expect exit code 0
    Expected Result: All 4 commands pass cleanly
    Failure Indicators: Any non-zero exit code
    Evidence: .sisyphus/evidence/task-12-build-pipeline.txt

  Scenario: Comprehensive string audit finds zero hardcoded strings
    Tool: Bash
    Preconditions: All Tasks 1-11 completed
    Steps:
      1. Run string audit grep command (see "What to do" above)
      2. Run `python3 -c "import json; en=json.load(open('lib/l10n/app_en.arb')); fr=json.load(open('lib/l10n/app_fr.arb')); en_keys=set(k for k in en if not k.startswith('@')); fr_keys=set(k for k in fr if not k.startswith('@')); missing=en_keys-fr_keys; extra=fr_keys-en_keys; print(f'Missing in FR: {missing}'); print(f'Extra in FR: {extra}'); assert not missing and not extra, 'Key mismatch!'"` — expect both empty, no assertion error
    Expected Result: Zero hardcoded strings found, ARB key sets match perfectly
    Failure Indicators: Any grep matches, key set mismatch
    Evidence: .sisyphus/evidence/task-12-string-audit.txt
  ```

  **Commit**: YES (verification only, commit if fixes were needed)
  - Message: `chore(i18n): verify build, tests, and zero remaining hardcoded strings`
  - Files: Any files fixed during audit
  - Pre-commit: `flutter gen-l10n && flutter analyze && flutter test`

---

## Final Verification Wave

> 4 review agents run in PARALLEL. ALL must APPROVE. Rejection → fix → re-run.

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read the plan end-to-end. For each "Must Have": verify implementation exists (read file, run command). For each "Must NOT Have": search codebase for forbidden patterns — reject with file:line if found. Check evidence files exist in `.sisyphus/evidence/`. Compare deliverables against plan.
  Output: `Must Have [N/N] | Must NOT Have [N/N] | Tasks [N/N] | VERDICT: APPROVE/REJECT`

- [ ] F2. **Code Quality Review** — `unspecified-high`
  Run `flutter analyze` + `dart format --set-exit-if-changed .` + `flutter test`. Review all changed files for: unused imports, inconsistent l10n access patterns, missing `context.l10n` usage (direct `AppLocalizations.of(context)!` calls). Check for hardcoded English strings that were missed. Verify ARB files have consistent key ordering between EN and FR.
  Output: `Analyze [PASS/FAIL] | Format [PASS/FAIL] | Tests [N pass/N fail] | Files [N clean/N issues] | VERDICT`

- [ ] F3. **Real Manual QA** — `unspecified-high`
  Run `flutter gen-l10n` and verify generated files. Grep entire `lib/presentation/` and `lib/config/routes.dart` for remaining hardcoded English strings (exclude imports, variable names, route paths). Verify all ARB keys are actually used in code. Verify EN and FR ARB files have identical key sets. Check ICU message syntax is valid.
  Output: `Gen-l10n [PASS/FAIL] | Remaining strings [N found] | Unused keys [N] | Key parity [PASS/FAIL] | VERDICT`

- [ ] F4. **Scope Fidelity Check** — `deep`
  For each task: read "What to do", read actual diff (`git log`/`diff`). Verify 1:1 — everything in spec was built (no missing), nothing beyond spec was built (no creep). Check "Must NOT do" compliance: no user content localized, no language selector UI, no extra languages, no database changes, no new packages beyond `flutter_localizations`. Flag unaccounted changes.
  Output: `Tasks [N/N compliant] | Scope [CLEAN/N issues] | Unaccounted [CLEAN/N files] | VERDICT`

---

## Commit Strategy

| After Task(s) | Commit Message | Key Files |
|---------------|---------------|-----------|
| 1-3 | `feat(i18n): add localization infrastructure with EN+FR ARB files` | `pubspec.yaml`, `l10n.yaml`, `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`, `lib/app.dart`, `lib/utils/l10n_helper.dart` |
| 4-5 | `feat(i18n): add MealSlot localization extension and DateFormatter utility` | `lib/utils/meal_slot_localization.dart`, `lib/utils/date_formatter.dart` |
| 6 | `feat(i18n): localize provider error messages` | `lib/presentation/providers/*.dart` |
| 7-11 | `feat(i18n): replace all hardcoded strings in screens, widgets, and routes` | `lib/presentation/screens/*.dart`, `lib/presentation/widgets/*.dart`, `lib/config/routes.dart` |
| 12 | `chore(i18n): verify build, tests, and zero remaining hardcoded strings` | — (verification only) |

---

## Success Criteria

### Verification Commands
```bash
flutter gen-l10n          # Expected: generates lib/generated/app_localizations.dart without errors
flutter analyze           # Expected: No issues found!
flutter test              # Expected: All 11 tests passing
grep -rn "'[A-Z]" lib/presentation/ lib/config/routes.dart --include="*.dart" | grep -v "import\|//\|Icons\.\|Curves\.\|'date'\|'slot'\|'id'\|'description'\|'imagePath'\|'/today\|'/meals\|'/calendar\|'Manrope'"  # Expected: no output (zero hardcoded user-facing strings)
```

### Final Checklist
- [ ] All "Must Have" present (ARB files, extensions, delegates, all strings localized)
- [ ] All "Must NOT Have" absent (no user content localized, no language selector, no extra packages)
- [ ] `flutter gen-l10n` succeeds
- [ ] `flutter analyze` passes
- [ ] `flutter test` passes (11 tests)
- [ ] EN and FR ARB files have identical key sets
- [ ] All manual date formatting arrays eliminated (replaced by `intl DateFormat`)
