# Multi-Images Remediation Plan

> **For Sisyphus:** Use subagent-driven-development with fresh subagent per task.

**Goal:** Fix compile-time errors and complete the partially implemented multi-image per meal feature.

**Current State:** Partially implemented with 23+ compile-time errors. Core infrastructure exists but providers and UI still use single-image logic.

**Architecture:** Keep relational `meal_images` table with `meal_id` foreign key. Store images in `meal_images/{meal_id}/` directories.

**Tech Stack:** Flutter, sqflite, image_picker, path_provider

---

## TL;DR

> **Problem:** Multi-image migration started but incomplete. 23+ compile errors from removed `imagePath`/`hasImage` fields still referenced in providers/widgets.
> 
> **Deliverables:** Fixed compile errors, working multi-image support end-to-end
> - Meal extension for backward compatibility during transition
> - Fixed database service (syntax + schema)
> - Updated providers to use MealImageRepository
> - Working multi-image UI in MealSlot and MealHistoryCard
> - Tests passing
> 
> **Estimated Effort:** Medium (8-10 tasks)
> **Parallel Execution:** YES - 3 waves
> **Critical Path:** Wave 1 (compile fixes) → Wave 2 (provider integration) → Wave 3 (UI polish + tests)

---

## Context

### Original Request
Complete the multi-image per meal feature. Existing plan was marked complete but implementation is in a transitional state with compile errors and missing integrations.

### Gap Analysis Summary

**What EXISTS:**
- `MealImage` model with toMap/fromMap
- `MealImageRepository` with CRUD operations
- `meal_images` table in database (v5 migration)
- `ImageStorageService` with compression, file handling
- `ImageMigrationService` skeleton
- `MealHistoryCard` widget designed for multi-images

**What's BROKEN (23+ compile-time errors):**

| Error Category | Count | Files Affected |
|----------------|-------|----------------|
| Missing Meal.imagePath/hasImage | 16 | today_provider.dart, day_detail_provider.dart, calendar_screen.dart, meals_screen.dart, meal_slot.dart |
| Repository interface mismatches | 4 | calendar_screen.dart, day_detail_screen.dart, today_screen.dart, meals_screen.dart |
| Missing required parameters | 1 | meals_screen.dart |
| Database syntax errors | 2 | database_service.dart, image_migration_service.dart |

**Integration GAPS:**
- Providers save to `meals.imagePath` instead of `meal_images` table
- Providers don't load images from `MealImageRepository`
- `MealSlotWidget` doesn't support multi-image UI
- No tests for `MealImage` model or repository
- Missing fake implementations for testing

---

## Work Objectives

### Core Objective
Fix all compile-time errors and complete the multi-image per meal feature so users can add, view, and delete multiple images per meal.

### Concrete Deliverables
- [x] `MealImageExtension` on Meal model for transition compatibility
- [x] Fixed `database_service.dart` syntax and schema
- [x] Updated `today_provider.dart` using `MealImageRepository`
- [x] Updated `day_detail_provider.dart` using `MealImageRepository`
- [x] Fixed repository instantiation in all screens
- [x] Working multi-image UI in `meal_slot.dart`
- [x] Pass images to `MealHistoryCard` in `meals_screen.dart`
- [x] Tests for `MealImage` model and repository
- [x] Fake implementations for provider testing
- [ ] Fixed `database_service.dart` syntax and schema
- [ ] Updated `today_provider.dart` using `MealImageRepository`
- [ ] Updated `day_detail_provider.dart` using `MealImageRepository`
- [ ] Fixed repository instantiation in all screens
- [ ] Working multi-image UI in `meal_slot.dart`
- [ ] Pass images to `MealHistoryCard` in `meals_screen.dart`
- [ ] Tests for `MealImage` model and repository
- [ ] Fake implementations for provider testing

### Definition of Done
```bash
flutter analyze  # 0 issues found
flutter test     # All tests passing
```

### Must Have
- Zero compile-time errors
- Working image picker with multi-select
- Images persist in database and filesystem
- UI displays multiple images per meal

### Must NOT Have (Guardrails)
- Don't modify the core `Meal` model (use extension instead)
- Don't break existing meal functionality
- Don't add features beyond multi-image support

---

## Verification Strategy

### Test Decision
- **Infrastructure exists**: YES
- **Automated tests**: Tests-after
- **Framework**: flutter_test

### QA Policy
Every task includes agent-executed QA scenarios verified via:
- `flutter analyze` for compile errors
- `flutter test` for test results
- Code review for implementation correctness

---

## Execution Strategy

### Wave 1: Fix Compile-Time Errors (Foundation)
Must complete in order - these are blocking.

```
Wave 1 (Sequential — compile blockers):
├── Task 1: Fix database_service.dart syntax errors [quick]
├── Task 2: Create MealImageExtension for compatibility [quick]
├── Task 3: Fix ImageMigrationService imagesDirectory reference [quick]
└── Task 4: Fix repository instantiation in screens [quick]

Critical Path: Task 1 → Task 2 → Task 3 → Task 4
```

### Wave 2: Provider Integration (Core Logic)
Can be done in parallel after Wave 1.

```
Wave 2 (Parallel — provider updates):
├── Task 5: Update today_provider.dart for multi-images [unspecified-high]
├── Task 6: Update day_detail_provider.dart for multi-images [unspecified-high]
└── Task 7: Fix meals_screen.dart image passing [quick]

Can run in parallel after Wave 1 complete
```

### Wave 3: UI + Tests (Polish)
Can be done in parallel after Wave 2.

```
Wave 3 (Parallel — UI and testing):
├── Task 8: Update meal_slot.dart for multi-image UI [visual-engineering]
├── Task 9: Add MealImage model tests [quick]
├── Task 10: Add MealImageRepository tests [unspecified-high]
├── Task 11: Create fake implementations for testing [quick]
└── Task 12: Run full test suite and fix any issues [unspecified-high]

Can run in parallel after Wave 2 complete
```

### Wave FINAL: Verification
All tasks complete → Run verification.

```
Wave FINAL (Verification):
├── Task F1: Final flutter analyze check [quick]
└── Task F2: Final flutter test check [quick]
```

---

## TODOs



- [x] 1. Fix database_service.dart syntax errors

  **What to do**:
  - Fix unclosed bracket at line 173 in `lib/data/services/database_service.dart`
  - Remove `imagePath TEXT` column from meals table schema (line 61)
  - The meals table should NOT have imagePath since we're using meal_images table
  
  **Must NOT do**:
  - Don't remove the meal_images table creation
  - Don't change the foreign key constraints
  
  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: `flutter-expert`
    - Needed for Flutter/Dart syntax and sqflite patterns
  
  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 1 (Sequential)
  - **Blocks**: Tasks 2, 3, 4, 5, 6, 7
  - **Blocked By**: None (can start immediately)
  
  **References**:
  - `lib/data/services/database_service.dart:61` - meals table schema with imagePath to remove
  - `lib/data/services/database_service.dart:173` - syntax error location
  - `lib/data/services/database_service.dart:160-180` - _onUpgrade migration block
  
  **Acceptance Criteria**:
  - [ ] `flutter analyze lib/data/services/database_service.dart` shows no errors
  - [ ] Meals table schema no longer includes imagePath column
  - [ ] Database version remains at 5
  
  **QA Scenarios**:
  ```
  Scenario: Database service compiles without errors
    Tool: Bash
    Steps:
      1. Run: flutter analyze lib/data/services/database_service.dart
    Expected Result: No issues found
    Evidence: .sisyphus/evidence/task-1-analyze-pass.txt
  
  Scenario: Meals table schema correct
    Tool: Read
    Steps:
      1. Read lib/data/services/database_service.dart
      2. Verify CREATE TABLE meals does NOT include imagePath
      3. Verify CREATE TABLE meal_images still exists
    Expected Result: imagePath removed from meals, meal_images table intact
    Evidence: .sisyphus/evidence/task-1-schema-check.txt
  ```
  
  **Commit**: YES
  - Message: `fix: remove imagePath from meals table and fix syntax error`
  - Files: `lib/data/services/database_service.dart`

- [x] 2. Create MealImageExtension for backward compatibility

  **What to do**:
  - Create `lib/data/models/meal_extension.dart`
  - Add extension on Meal with `imagePath` and `hasImage` getters
  - These should query `MealImageRepository` to get the first image for a meal
  - This provides backward compatibility during the transition
  
  **Must NOT do**:
  - Don't modify the Meal model directly
  - Don't add setters (extension getters should be read-only)
  
  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: `flutter-expert`
    - Needed for Dart extension syntax and repository patterns
  
  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 1 (Sequential)
  - **Blocks**: Tasks 3, 4, 5, 6, 7
  - **Blocked By**: Task 1
  
  **References**:
  - `lib/data/models/meal.dart` - Meal model structure
  - `lib/data/models/meal_image.dart` - MealImage model
  - `lib/data/repositories/meal_image_repository.dart` - Repository to query
  
  **Acceptance Criteria**:
  - [ ] Extension file created with `imagePath` and `hasImage` getters
  - [ ] `flutter analyze lib/data/models/meal_extension.dart` shows no errors
  
  **QA Scenarios**:
  ```
  Scenario: Extension compiles and provides getters
    Tool: Bash
    Steps:
      1. Create lib/data/models/meal_extension.dart
      2. Run: flutter analyze lib/data/models/meal_extension.dart
    Expected Result: No issues found
    Evidence: .sisyphus/evidence/task-2-extension-created.txt
  ```
  
  **Commit**: YES
  - Message: `feat: add MealImageExtension for backward compatibility`
  - Files: `lib/data/models/meal_extension.dart`

- [x] 3. Fix ImageMigrationService imagesDirectory reference

  **What to do**:
  - Fix `lib/data/services/image_migration_service.dart` line 29
  - Change `ImageStorageService.imagesDirectory` to use the correct getter
  - Check ImageStorageService for the actual directory getter name
  
  **Must NOT do**:
  - Don't change migration logic, just fix the reference
  
  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: `flutter-expert`
    - Needed to understand ImageStorageService API
  
  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 1 (Sequential)
  - **Blocks**: Tasks 4, 5, 6, 7
  - **Blocked By**: Tasks 1, 2
  
  **References**:
  - `lib/data/services/image_migration_service.dart:29` - Error location
  - `lib/data/services/image_storage_service.dart` - Find correct getter
  
  **Acceptance Criteria**:
  - [ ] `flutter analyze lib/data/services/image_migration_service.dart` shows no errors
  
  **QA Scenarios**:
  ```
  Scenario: Migration service compiles
    Tool: Bash
    Steps:
      1. Run: flutter analyze lib/data/services/image_migration_service.dart
    Expected Result: No issues found
    Evidence: .sisyphus/evidence/task-3-migration-fixed.txt
  ```
  
  **Commit**: YES
  - Message: `fix: correct ImageStorageService directory reference in migration`
  - Files: `lib/data/services/image_migration_service.dart`

- [x] 4. Fix repository instantiation in screens

  **What to do**:
  - Fix repository instantiation errors in 4 screen files
  - `calendar_screen.dart:30` - Interface assignment issue
  - `day_detail_screen.dart:143` - Repository parameter issue
  - `today_screen.dart:46` - Repository parameter issue
  - `meals_screen.dart:41` - Positional vs named parameter issue
  
  **Must NOT do**:
  - Don't change repository interfaces, just fix the instantiation
  
  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: `flutter-expert`
    - Needed for repository pattern and dependency injection
  
  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 1 (Sequential)
  - **Blocks**: Tasks 5, 6, 7
  - **Blocked By**: Tasks 1, 2, 3
  
  **References**:
  - `lib/data/repositories/meal_repository_interface.dart` - Interface definitions
  - `lib/data/repositories/meal_repository.dart` - Concrete implementations
  - `lib/presentation/screens/calendar_screen.dart:30` - Error location
  - `lib/presentation/screens/day_detail_screen.dart:143` - Error location
  - `lib/presentation/screens/today_screen.dart:46` - Error location
  - `lib/presentation/screens/meals_screen.dart:41` - Error location
  
  **Acceptance Criteria**:
  - [ ] All 4 screen files compile without errors
  - [ ] `flutter analyze` on each screen file shows no repository-related errors
  
  **QA Scenarios**:
  ```
  Scenario: All screens compile
    Tool: Bash
    Steps:
      1. Run: flutter analyze lib/presentation/screens/calendar_screen.dart
      2. Run: flutter analyze lib/presentation/screens/day_detail_screen.dart
      3. Run: flutter analyze lib/presentation/screens/today_screen.dart
      4. Run: flutter analyze lib/presentation/screens/meals_screen.dart
    Expected Result: No issues found in any screen
    Evidence: .sisyphus/evidence/task-4-screens-compiled.txt
  ```
  
  **Commit**: YES
  - Message: `fix: correct repository instantiation in all screens`
  - Files: `lib/presentation/screens/calendar_screen.dart`, `lib/presentation/screens/day_detail_screen.dart`, `lib/presentation/screens/today_screen.dart`, `lib/presentation/screens/meals_screen.dart`

- [x] 5. Update today_provider.dart for multi-images

  **What to do**:
  - Update `lib/presentation/providers/today_provider.dart` to use MealImageRepository
  - Replace single-image save logic with multi-image support
  - Load images for each meal using MealImageRepository.getImagesForMeal()
  - Update pickImage method to use multi-select and save multiple images
  - Remove references to meal.imagePath for saving (keep for reading via extension)
  
  **Must NOT do**:
  - Don't break existing meal loading/saving logic
  - Don't remove the Meal model usage, just add image handling
  
  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: `flutter-expert`
    - Needed for provider patterns and state management
  
  **Parallelization**:
  - **Can Run In Parallel**: YES (after Wave 1)
  - **Parallel Group**: Wave 2
  - **Blocks**: None
  - **Blocked By**: Tasks 1, 2, 3, 4 (Wave 1 complete)
  
  **References**:
  - `lib/presentation/providers/today_provider.dart` - File to modify
  - `lib/data/repositories/meal_image_repository.dart` - Repository to use
  - `lib/data/models/meal_extension.dart` - Extension from Task 2
  - `lib/presentation/providers/day_detail_provider.dart` - Similar pattern to follow
  
  **Acceptance Criteria**:
  - [ ] `flutter analyze lib/presentation/providers/today_provider.dart` shows no errors
  - [ ] Provider loads images from MealImageRepository
  - [ ] Provider saves images to MealImageRepository
  
  **QA Scenarios**:
  ```
  Scenario: TodayProvider compiles with multi-image support
    Tool: Bash
    Steps:
      1. Run: flutter analyze lib/presentation/providers/today_provider.dart
    Expected Result: No issues found
    Evidence: .sisyphus/evidence/task-5-today-provider.txt
  ```
  
  **Commit**: YES
  - Message: `feat: update TodayProvider for multi-image support`
  - Files: `lib/presentation/providers/today_provider.dart`

- [x] 6. Update day_detail_provider.dart for multi-images

  **What to do**:
  - Update `lib/presentation/providers/day_detail_provider.dart` to use MealImageRepository
  - Same changes as today_provider.dart but for day detail view
  - Load images for meals on the selected day
  - Update image picking to support multi-select
  
  **Must NOT do**:
  - Don't duplicate logic unnecessarily - extract shared patterns if possible
  
  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: `flutter-expert`
    - Needed for provider patterns
  
  **Parallelization**:
  - **Can Run In Parallel**: YES (after Wave 1, parallel with Task 5)
  - **Parallel Group**: Wave 2
  - **Blocks**: None
  - **Blocked By**: Tasks 1, 2, 3, 4 (Wave 1 complete)
  
  **References**:
  - `lib/presentation/providers/day_detail_provider.dart` - File to modify
  - `lib/presentation/providers/today_provider.dart` - Pattern from Task 5
  
  **Acceptance Criteria**:
  - [ ] `flutter analyze lib/presentation/providers/day_detail_provider.dart` shows no errors
  - [ ] Provider loads and saves images correctly
  
  **QA Scenarios**:
  ```
  Scenario: DayDetailProvider compiles with multi-image support
    Tool: Bash
    Steps:
      1. Run: flutter analyze lib/presentation/providers/day_detail_provider.dart
    Expected Result: No issues found
    Evidence: .sisyphus/evidence/task-6-daydetail-provider.txt
  ```
  
  **Commit**: YES
  - Message: `feat: update DayDetailProvider for multi-image support`
  - Files: `lib/presentation/providers/day_detail_provider.dart`

- [x] 7. Fix meals_screen.dart image passing

  **What to do**:
  - Fix `lib/presentation/screens/meals_screen.dart:283`
  - MealHistoryCard requires `images` parameter but not provided
  - Load images for each meal before passing to MealHistoryCard
  - May need to modify how meals are loaded to include images
  
  **Must NOT do**:
  - Don't change MealHistoryCard widget (it's already correct)
  
  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: `flutter-expert`
  
  **Parallelization**:
  - **Can Run In Parallel**: YES (after Wave 1, parallel with Tasks 5, 6)
  - **Parallel Group**: Wave 2
  - **Blocks**: None
  - **Blocked By**: Tasks 1, 2, 3, 4 (Wave 1 complete)
  
  **References**:
  - `lib/presentation/screens/meals_screen.dart:283` - Error location
  - `lib/presentation/widgets/meal_history_card.dart` - Widget interface
  - `lib/data/repositories/meal_image_repository.dart` - To load images
  
  **Acceptance Criteria**:
  - [ ] `flutter analyze lib/presentation/screens/meals_screen.dart` shows no errors
  - [ ] Images are loaded and passed to MealHistoryCard
  
  **QA Scenarios**:
  ```
  Scenario: MealsScreen compiles and passes images
    Tool: Bash
    Steps:
      1. Run: flutter analyze lib/presentation/screens/meals_screen.dart
    Expected Result: No issues found
    Evidence: .sisyphus/evidence/task-7-meals-screen.txt
  ```
  
  **Commit**: YES
  - Message: `fix: pass images to MealHistoryCard in meals screen`
  - Files: `lib/presentation/screens/meals_screen.dart`

- [x] 8. Update meal_slot.dart for multi-image UI

  **What to do**:
  - Update `lib/presentation/widgets/meal_slot.dart` to support multiple images
  - Replace single image display with horizontal scrollable list of thumbnails
  - Add ability to add/remove individual images
  - Tap to open full-screen gallery view
  
  **Must NOT do**:
  - Don't break the meal slot's core meal editing functionality
  
  **Recommended Agent Profile**:
  - **Category**: `visual-engineering`
  - **Skills**: `flutter-expert`
    - Needed for Flutter widget development and image handling
  
  **Parallelization**:
  - **Can Run In Parallel**: YES (after Wave 2)
  - **Parallel Group**: Wave 3
  - **Blocks**: None
  - **Blocked By**: Tasks 5, 6, 7 (Wave 2 complete)
  
  **References**:
  - `lib/presentation/widgets/meal_slot.dart` - File to modify
  - `lib/presentation/widgets/image_gallery_view.dart` - For full-screen view
  - `lib/data/repositories/meal_image_repository.dart` - For image operations
  
  **Acceptance Criteria**:
  - [ ] MealSlot displays multiple images as thumbnails
  - [ ] Can add new images via multi-select picker
  - [ ] Can remove individual images
  - [ ] Tap opens gallery view
  
  **QA Scenarios**:
  ```
  Scenario: MealSlot displays multi-image UI
    Tool: Bash
    Steps:
      1. Run: flutter analyze lib/presentation/widgets/meal_slot.dart
    Expected Result: No issues found
    Evidence: .sisyphus/evidence/task-8-mealslot-analyze.txt
  ```
  
  **Commit**: YES
  - Message: `feat: update MealSlot for multi-image display and management`
  - Files: `lib/presentation/widgets/meal_slot.dart`

- [x] 9. Add MealImage model tests

  **What to do**:
  - Create `test/data/models/meal_image_test.dart`
  - Test MealImage.toMap() and MealImage.fromMap() round-trip
  - Test edge cases (null id, special characters in path)
  
  **Must NOT do**:
  - Don't test MealImageRepository here (that's Task 10)
  
  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: `flutter-expert`
  
  **Parallelization**:
  - **Can Run In Parallel**: YES (after Wave 2)
  - **Parallel Group**: Wave 3
  - **Blocks**: None
  - **Blocked By**: None (can start anytime)
  
  **References**:
  - `lib/data/models/meal_image.dart` - Model to test
  - `test/data/meal_model_test.dart` - Example test pattern
  
  **Acceptance Criteria**:
  - [ ] Test file created with toMap/fromMap tests
  - [ ] Tests pass: `flutter test test/data/models/meal_image_test.dart`
  
  **QA Scenarios**:
  ```
  Scenario: MealImage model tests pass
    Tool: Bash
    Steps:
      1. Run: flutter test test/data/models/meal_image_test.dart
    Expected Result: All tests pass
    Evidence: .sisyphus/evidence/task-9-mealimage-tests.txt
  ```
  
  **Commit**: YES
  - Message: `test: add MealImage model tests`
  - Files: `test/data/models/meal_image_test.dart`

- [x] 10. Add MealImageRepository tests

  **What to do**:
  - Create `test/data/repositories/meal_image_repository_test.dart`
  - Test CRUD operations: getImagesForMeal, addImage, deleteImage, deleteAllImagesForMeal
  - Use in-memory SQLite database for testing
  
  **Must NOT do**:
  - Don't test against real filesystem (use temp directory)
  
  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: `flutter-expert`
  
  **Parallelization**:
  - **Can Run In Parallel**: YES (after Wave 2)
  - **Parallel Group**: Wave 3
  - **Blocks**: None
  - **Blocked By**: None (can start anytime)
  
  **References**:
  - `lib/data/repositories/meal_image_repository.dart` - Repository to test
  - `test/data/repositories/` - Look for existing repository test patterns
  
  **Acceptance Criteria**:
  - [ ] Test file created with CRUD tests
  - [ ] Tests pass: `flutter test test/data/repositories/meal_image_repository_test.dart`
  
  **QA Scenarios**:
  ```
  Scenario: MealImageRepository tests pass
    Tool: Bash
    Steps:
      1. Run: flutter test test/data/repositories/meal_image_repository_test.dart
    Expected Result: All tests pass
    Evidence: .sisyphus/evidence/task-10-repository-tests.txt
  ```
  
  **Commit**: YES
  - Message: `test: add MealImageRepository tests`
  - Files: `test/data/repositories/meal_image_repository_test.dart`

- [x] 11. Create fake implementations for testing

  **What to do**:
  - Create `test/fakes/fake_meal_image_repository.dart`
  - Create `test/fakes/fake_image_storage_service.dart` (if needed)
  - These fakes should implement the same interfaces for use in provider tests
  
  **Must NOT do**:
  - Don't make fakes too complex - just in-memory storage
  
  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: `flutter-expert`
  
  **Parallelization**:
  - **Can Run In Parallel**: YES (after Wave 2)
  - **Parallel Group**: Wave 3
  - **Blocks**: None
  - **Blocked By**: None (can start anytime)
  
  **References**:
  - `test/fakes/fake_meal_repository.dart` - Example fake pattern
  - `lib/data/repositories/meal_image_repository.dart` - Interface to fake
  
  **Acceptance Criteria**:
  - [ ] Fake implementations created in test/fakes/
  - [ ] Fakes can be used in provider tests
  
  **QA Scenarios**:
  ```
  Scenario: Fake implementations compile
    Tool: Bash
    Steps:
      1. Run: flutter analyze test/fakes/fake_meal_image_repository.dart
    Expected Result: No issues found
    Evidence: .sisyphus/evidence/task-11-fakes-created.txt
  ```
  
  **Commit**: YES
  - Message: `test: add fake implementations for MealImageRepository`
  - Files: `test/fakes/fake_meal_image_repository.dart`

- [x] 12. Run full test suite and fix any issues

  **What to do**:
  - Run `flutter test` to check all tests
  - Fix any failing tests caused by the changes
  - Run `flutter analyze` to catch any remaining issues
  - Fix any remaining compile errors
  
  **Must NOT do**:
  - Don't skip failing tests - fix the underlying issue
  
  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: `flutter-expert`
  
  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 3 (Final task)
  - **Blocks**: Final verification
  - **Blocked By**: Tasks 8, 9, 10, 11 (Wave 3 tasks)
  
  **References**:
  - All files modified in previous tasks
  
  **Acceptance Criteria**:
  - [ ] `flutter test` passes all tests
  - [ ] `flutter analyze` shows no issues
  
  **QA Scenarios**:
  ```
  Scenario: Full test suite passes
    Tool: Bash
    Steps:
      1. Run: flutter test
      2. Run: flutter analyze
    Expected Result: All tests pass, no analyzer issues
    Evidence: .sisyphus/evidence/task-12-full-suite.txt
  ```
  
  **Commit**: YES
  - Message: `chore: fix remaining test failures and analyzer issues`
  - Files: Any files needing fixes

---

## Final Verification Wave

> Run after ALL implementation tasks complete

- [x] F1. Final flutter analyze check

  **What to do**:
  - Run `flutter analyze` on the entire project
  - Verify zero analyzer issues
  - Fix any remaining issues

  **Acceptance Criteria**:
  - [ ] `flutter analyze` shows 0 issues

  **QA Scenarios**:
  ```
  Scenario: No analyzer issues
    Tool: Bash
    Steps:
      1. Run: flutter analyze
    Expected Result: No issues found
    Evidence: .sisyphus/evidence/final-analyze.txt
  ```

  **Commit**: NO (verification only)

- [x] F2. Final flutter test check

  **What to do**:
  - Run `flutter test` to verify all tests pass
  - Fix any remaining test failures

  **Acceptance Criteria**:
  - [ ] `flutter test` shows all tests passing

  **QA Scenarios**:
  ```
  Scenario: All tests pass
    Tool: Bash
    Steps:
      1. Run: flutter test
    Expected Result: All tests pass
    Evidence: .sisyphus/evidence/final-tests.txt
  ```

  **Commit**: NO (verification only)

---

## Commit Strategy

Each task includes its own commit with:
- Type prefix: `fix:` for bug fixes, `feat:` for features, `test:` for tests, `chore:` for maintenance
- Descriptive message explaining the change
- All relevant files included

## Success Criteria

### Verification Commands
```bash
# Should show 0 issues
flutter analyze

# Should show all tests passing
flutter test
```

### Final Checklist
- [ ] All 23+ original compile errors fixed
- [ ] MealImageExtension provides backward compatibility
- [ ] Providers use MealImageRepository for multi-image operations
- [ ] UI displays multiple images per meal
- [ ] Tests added for MealImage model and repository
- [ ] All tests passing
- [ ] No analyzer warnings or errors