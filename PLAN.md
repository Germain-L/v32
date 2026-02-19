# Diet App - Development Plan

A smooth, optimized, no-bloat Flutter app for tracking daily meals locally.

## 1. Core Objectives
- **Local-Only**: No backend, no cloud sync. All data stays on the device.
- **Visual-First**: Easy photo capture for every meal.
- **Smooth UX**: Fast navigation, minimal loading states, high performance.
- **Minimalist Design**: No feature bloat, focused purely on the nutritionist's requirements.

## 2. Tech Stack
- **Framework**: Flutter (Material 3)
- **Database**: `sqflite` - Official Flutter plugin for SQLite, zero native lib issues.
- **Image Handling**: `image_picker` (capture), `path_provider` (file storage), `image` (compression/optimization).
- **State Management**: `ChangeNotifier` + `ValueListenableBuilder` (Built-in, low overhead).
- **Navigation**: `go_router` (Declarative, deep-link ready).
- **Icons**: `lucide_icons` or standard Material Icons.

### Database Migration Note
Migrated from Isar to sqflite to avoid:
- 16KB page size alignment issues with Android 15
- Build configuration hacks in pub-cache
- Deprecated/unmaintained library (last update April 2023)

All existing functionality preserved with SQLite as the backing store.

## 3. Data Model
### Meal
- `id`: int (autoincrement)
- `slot`: Enum (Breakfast, Lunch, Afternoon Snack, Dinner)
- `date`: DateTime (stored as timestamp)
- `description`: String?
- `imagePath`: String? (Path to local file storage)

## 4. Architecture
- **Data Layer**: Isar services for CRUD operations on Meals.
- **Storage Layer**: File system management for meal images.
- **UI Layer**:
    - **Today Tab**: Interactive list of 4 fixed slots for the current day.
    - **Meals Tab**: Infinite scroll back through history.
    - **Calendar Tab**: High-level view of compliance/entries with date selection.

## 5. Implementation Roadmap

### Phase 1: Foundation (Migrated to sqflite)
- [x] Initialize project and add dependencies.
- [x] Set up database schemas and services (migrated from Isar → sqflite).
- [x] Implement Image Storage service (saving images to app documents directory).
- [x] Configure `go_router` and main tab scaffold.

### Migration: Isar → sqflite
- [x] Add sqflite dependency, remove isar/isar_flutter_libs/isar_generator
- [x] Create SQLite database helper (database creation, migrations)
- [x] Recreate Meal model without Isar annotations (plain Dart class)
- [x] Create Meal table schema with proper indexes
- [x] Rewrite MealRepository with sqflite queries
- [x] Update all imports across the codebase
- [x] Delete Isar-generated files (meal.g.dart)
- [x] Clean build and verify no warnings
- [x] Test CRUD operations

### Phase 2: Today Tab (Input)
- [x] Create `MealSlot` component (Photo placeholder + Text input).
- [x] Implement photo capture logic.
- [x] Auto-save on input change.
- [x] Debounce auto-save to avoid repeated writes.

### Phase 3: Meals Tab (History)
- [x] Implement infinite scroll logic using repository pagination.
- [x] Design compact meal cards for the feed.
- [x] Logic for "up until current time" display.

### Phase 4: Calendar Tab
- [x] Integrate a lightweight calendar widget.
- [x] Connect calendar selection to a daily view summary.

### Phase 5: Optimization & Polish
- [x] Image compression to keep app size low.
- [x] Smooth transitions between tabs.
- [x] Final UI/UX pass for "premium" feel (shadows, typography).

## 6. Development Workflow

### Tracking Progress
We use a two-tier tracking system:

1. **PLAN.md** - Persistent progress tracking
   - Check off completed roadmap items here
   - Serves as the single source of truth for overall progress
   - Update immediately after completing tasks

2. **TODO Tool** - Session-based work tracking
   - Use for active tasks during development sessions
   - Clear when session ends
   - Tracks granular subtasks within roadmap phases

### Development Process
1. Create TODOs for current session's tasks
2. Mark complete in PLAN.md after finishing each phase
3. Update this section if workflow changes

## 7. Migration Strategy: Isar → sqflite

### Why sqflite?
- **Official plugin**: Maintained by the Flutter team
- **No native build issues**: Pure Dart/SQLite, no 16KB alignment problems
- **Stable API**: Well-documented, battle-tested
- **Zero workarounds**: No pub-cache patches required

### Technical Approach

#### 1. Data Model Changes
```dart
// From: Isar annotations + code generation
@collection
class Meal { ... }

// To: Plain Dart class
class Meal {
  final int? id;  // Auto-increment from SQLite
  final MealSlot slot;
  final DateTime date;
  final String? description;
  final String? imagePath;
  
  Meal({...});
  
  // Add toMap/fromMap for serialization
}
```

#### 2. Database Schema
```sql
CREATE TABLE meals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  slot TEXT NOT NULL,
  date INTEGER NOT NULL,
  description TEXT,
  imagePath TEXT
);

CREATE INDEX idx_date ON meals(date);
CREATE INDEX idx_slot ON meals(slot);
```

#### 3. API Surface (Keep It Identical)
The MealRepository public API should remain unchanged:
- `saveMeal(Meal meal)` → Future<Meal>
- `saveMeals(List<Meal> meals)` → Future<void>
- `getMealById(int id)` → Future<Meal?>
- `deleteMeal(int id)` → Future<void>
- `watchTodayMeals()` → Stream<List<Meal>>
- `getMealsForDate(DateTime date)` → Future<List<Meal>>
- `getMealsBefore(DateTime date, {int limit})` → Future<List<Meal>>
- `getMealsForMonth(int year, int month)` → Future<List<Meal>>
- `hasMealsForDate(DateTime date)` → Future<bool>

This ensures zero changes needed in UI layer.

#### 4. Query Mapping
| Isar Query | sqflite Equivalent |
|------------|-------------------|
| `filter().dateBetween(start, end)` | `WHERE date BETWEEN ? AND ?` |
| `filter().dateLessThan(date)` | `WHERE date < ?` |
| `sortByDate()` | `ORDER BY date ASC` |
| `sortByDateDesc()` | `ORDER BY date DESC` |
| `limit(n)` | `LIMIT ?` |
| `watch(fireImmediately: true)` | Custom Stream implementation |

#### 5. Stream Implementation
Since sqflite doesn't have built-in reactive queries like Isar:
- Create a `DatabaseWatcher` singleton
- Use `StreamController<List<Meal>>` for reactive streams
- Notify watchers after every write operation
- Close streams properly when not needed

#### 6. Migration Checklist (All Completed ✓)
- [x] Remove isar, isar_flutter_libs, isar_generator from pubspec.yaml
- [x] Add sqflite and path dependencies
- [x] Delete lib/data/models/meal.g.dart
- [x] Rewrite lib/data/models/meal.dart (plain class)
- [x] Create lib/data/services/database_service.dart (sqflite wrapper)
- [x] Rewrite lib/data/repositories/meal_repository.dart
- [x] Run `flutter clean && flutter pub get`
- [x] Verify no 16KB warnings in build
- [x] Test all repository methods
