# Flutter Agent Guide

This repo is a Flutter app for local-only diet tracking. Keep changes small, fast, and consistent with existing patterns.

## Context Snapshot
- Framework: Flutter (Material 3)
- Database: sqflite (SQLite) with `DatabaseService`
- State: ChangeNotifier + ListenableBuilder
- Routing: go_router (ShellRoute, bottom nav)
- Images: image_picker + image (compression) + local file storage
- Fonts: google_fonts (Manrope)

## Project Structure
```
lib/
  main.dart                 # App entry point
  app.dart                  # Root widget
  config/                   # App configuration
    routes.dart             # GoRouter configuration
    theme.dart              # Theme configuration
  data/                     # Data layer
    models/                 # Domain models (plain Dart)
    repositories/           # Data repositories
    services/               # Database + storage services
  presentation/             # UI layer
    screens/                # App screens
    widgets/                # Reusable widgets
    providers/              # ChangeNotifier providers
  utils/                    # Utilities (if needed)
```

## Build / Lint / Test Commands
Use Flutter CLI; run from repo root.

- Install deps: `flutter pub get`
- Analyze (lint): `flutter analyze`
- Format: `flutter format .`
- Run app (device required): `flutter run`
- Run all tests: `flutter test`
- Run a single test file: `flutter test test/path/to/my_test.dart`
- Run a single test by name (substring match): `flutter test test/path/to/my_test.dart --name "some test name"`
- Run integration tests (if added): `flutter test integration_test`
- Build (local release):
  - `flutter build ios`
  - `flutter build android`
  - `flutter build web`

## Code Style Guidelines
Follow existing patterns in `lib/` and standard Dart style.

### Imports
- Use relative imports within `lib/` (current code does this).
- Order: `dart:` first, then `package:`, then relative imports.
- Prefer specific imports over barrel files unless already used.

### Formatting
- Use `flutter format .` before finalizing changes.
- Keep widget trees shallow; extract private helpers for chunks.
- Prefer `const` widgets and `const` constructors when possible.

### Types and Nullability
- Prefer explicit types for public APIs, fields, and function signatures.
- Use nullable types only when a value can truly be absent.
- Avoid dynamic; use `Map<String, dynamic>` where needed (e.g. SQLite maps).

### Naming Conventions
- Files: snake_case (`meal_history_card.dart`)
- Classes/Enums: PascalCase (`MealRepository`, `MealSlot`)
- Variables/Functions: camelCase (`loadTodayMeals`)
- Private members: leading underscore (`_repository`)
- Constants: lowerCamel or UPPER_SNAKE_CASE (consistent within file)

### Error Handling
- Wrap async operations in try/catch and set provider error state.
- Surface user-friendly errors in UI and allow retry.
- Avoid throwing from UI layers; use provider error fields.

### State Management
- Use ChangeNotifier in `presentation/providers/*`.
- Keep business logic in providers/repositories, not widgets.
- Expose immutable views (`List.unmodifiable`, getters).
- Guard against double-loads and concurrent saves.

### Database and Storage
- Use `DatabaseService.database` for sqflite access.
- Use repositories for queries; keep SQL in repository/service.
- Notify via `DatabaseService.notifyChange()` after writes.
- Store images in app documents directory via `ImageStorageService`.

### UI Guidelines
- Use Material 3 components; reuse theme values from `AppTheme`.
- Prefer `ColorScheme` for colors; avoid hard-coded colors.
- Add semantic labels/tooltips on interactive widgets when helpful.
- Keep animations short and purposeful (existing staggered lists).

### Testing
- Unit tests for repository/service logic where possible.
- Widget tests for custom widgets and critical flows.
- Avoid flakiness; minimize reliance on timers without fakes.

## Development Workflow
- Update `PLAN.md` when completing roadmap items.
- Keep changes minimal; do not reformat unrelated files.
- Do not commit secrets or local config.

## Notes for Agents
- There are no Cursor rules or Copilot instructions in this repo.
- Current stack uses sqflite, not Isar.
- Follow existing code style in `lib/` for new files.
