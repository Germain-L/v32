# Settings Page Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a comprehensive settings page with theme toggle, tracking preferences, data export, notifications, language selection, and about section.

**Architecture:** Add `shared_preferences` for settings storage, create a `SettingsProvider` ChangeNotifier for reactive settings, add new `/settings` route to go_router, and build `SettingsScreen` with modular section widgets. All settings apply immediately without save buttons.

**Tech Stack:** Flutter, Material 3, shared_preferences, share_plus, package_info_plus, flutter_local_notifications

---

## Prerequisites

Before starting, ensure these dependencies are in `pubspec.yaml`:

```yaml
dependencies:
  shared_preferences: ^2.5.0
  share_plus: ^10.0.0
  package_info_plus: ^8.0.0
  flutter_local_notifications: ^18.0.0
  permission_handler: ^11.0.0
```

Run: `flutter pub get`

---

## Execution Strategy

### Wave 1: Foundation (Dependencies + Provider + Storage)
Tasks 1-4 run sequentially (each depends on previous).

### Wave 2: Core Settings UI (Appearance + Tracking)
Tasks 5-8 run sequentially (UI layer building on provider).

### Wave 3: Advanced Features (Data + Notifications + Language)
Tasks 9-12 run sequentially (complex features requiring Wave 2).

### Wave 4: Navigation + Polish + Tests
Tasks 13-15 run sequentially (integration and final QA).

---

## Final Verification Wave (After ALL tasks)

- [ ] **F1. Integration Test** - `unspecified-high`
  Navigate through all settings, verify each toggle/field works, check persistence after restart.
  
- [ ] **F2. Code Review** - `quick`
  Verify no `dynamic` types, proper null safety, const constructors where possible, follows existing patterns.

- [ ] **F3. Visual QA** - `visual-engineering`
  Screenshot settings screen on both light/dark themes, verify Material 3 compliance, check all sections render correctly.

---

## Success Criteria

- [ ] All settings persist across app restarts
- [ ] Theme changes apply immediately
- [ ] Water goal displays progress on Today screen
- [ ] Export JSON/CSV opens share sheet
- [ ] Language override changes app language
- [ ] Settings accessible from Today screen AppBar
- [ ] All tests pass
- [ ] No lint errors

---

## Commit Strategy

Each task includes its own commit. Commit messages follow conventional commits:
- `feat(settings): add theme mode toggle`
- `feat(settings): add water goal slider`
- `feat(settings): add meal slot name customization`
- etc.

---

## TODOs



- [ ] **Task 1: Add dependencies to pubspec.yaml**

  **What to do:** Add required packages to pubspec.yaml and run flutter pub get.

  **Must NOT do:** Don't upgrade unrelated packages, don't change version constraints unnecessarily.

  **Recommended Agent Profile:**
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization:**
  - **Can Run In Parallel**: NO (first task)
  - **Blocks**: Tasks 2-15

  **References:**
  - `pubspec.yaml` - existing dependencies section

  **Acceptance Criteria:**
  - [ ] shared_preferences: ^2.5.0 added to dependencies
  - [ ] share_plus: ^10.0.0 added to dependencies
  - [ ] package_info_plus: ^8.0.0 added to dependencies
  - [ ] flutter_local_notifications: ^18.0.0 added to dependencies
  - [ ] permission_handler: ^11.0.0 added to dependencies
  - [ ] `flutter pub get` completes without errors

  **QA Scenarios:**
  ```
  Scenario: Dependencies install correctly
    Tool: Bash
    Steps:
      1. Run: `flutter pub get`
    Expected Result: Exit code 0, no errors
    Evidence: Terminal output saved to .sisyphus/evidence/task-1-deps.txt
  ```

  **Commit**: YES
  - Message: `chore(deps): add settings page dependencies`
  - Files: `pubspec.yaml`, `pubspec.lock`

- [ ] **Task 2: Create SettingsKeys constants**

  **What to do:** Create a constants file for SharedPreferences keys to avoid string duplication.

  **Must NOT do:** Don't use the keys directly in code without referencing these constants.

  **Recommended Agent Profile:**
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization:**
  - **Can Run In Parallel**: NO (depends on Task 1)
  - **Blocked By**: Task 1
  - **Blocks**: Task 3

  **References:**
  - Pattern: `lib/utils/` for utility files
  - `lib/utils/date_formatter.dart` - example utility file

  **Acceptance Criteria:**
  - [ ] File created: `lib/utils/settings_keys.dart`
  - [ ] Constants defined:
    - `themeMode`
    - `waterGoalLiters`
    - `mealNameBreakfast`, `mealNameLunch`, `mealNameAfternoonSnack`, `mealNameDinner`
    - `reminderBreakfastEnabled`, `reminderLunchEnabled`, `reminderAfternoonSnackEnabled`, `reminderDinnerEnabled`
    - `languageOverride`

  **QA Scenarios:**
  ```
  Scenario: Constants file compiles
    Tool: Bash
    Steps:
      1. Run: `flutter analyze lib/utils/settings_keys.dart`
    Expected Result: No errors
    Evidence: Analyzer output saved
  ```

  **Commit**: YES
  - Message: `feat(settings): add SharedPreferences keys constants`
  - Files: `lib/utils/settings_keys.dart`

- [ ] **Task 3: Create SettingsProvider**

  **What to do:** Create ChangeNotifier provider that manages all settings state with SharedPreferences.

  **Must NOT do:** Don't call notifyListeners() inside async gap without mounted checks, don't expose mutable state directly.

  **Recommended Agent Profile:**
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization:**
  - **Can Run In Parallel**: NO (depends on Task 2)
  - **Blocked By**: Task 2
  - **Blocks**: Tasks 4-15

  **References:**
  - Pattern: `lib/presentation/providers/today_provider.dart` - existing provider pattern
  - Pattern: `lib/presentation/providers/meals_provider.dart` - ChangeNotifier pattern
  - `lib/utils/settings_keys.dart` - constants from Task 2

  **Implementation:**
  ```dart
  // lib/presentation/providers/settings_provider.dart
  class SettingsProvider extends ChangeNotifier {
    final SharedPreferences _prefs;
    
    // Theme
    ThemeMode get themeMode => ...
    set themeMode(ThemeMode mode) => ...
    
    // Water goal
    double get waterGoalLiters => ...
    set waterGoalLiters(double value) => ...
    
    // Meal names
    String getMealName(MealSlot slot) => ...
    void setMealName(MealSlot slot, String name) => ...
    
    // Reminders
    bool isReminderEnabled(MealSlot slot) => ...
    void setReminderEnabled(MealSlot slot, bool enabled) => ...
    
    // Language
    Locale? get languageOverride => ...
    set languageOverride(Locale? locale) => ...
    
    // Storage
    Future<void> clearAllData() => ...
  }
  ```

  **Acceptance Criteria:**
  - [ ] File created: `lib/presentation/providers/settings_provider.dart`
  - [ ] All getters return appropriate default values
  - [ ] All setters persist to SharedPreferences and call notifyListeners()
  - [ ] clearAllData() method implemented (for later use)

  **QA Scenarios:**
  ```
  Scenario: Provider initializes correctly
    Tool: Dart analysis
    Steps:
      1. Run: `flutter analyze lib/presentation/providers/settings_provider.dart`
    Expected Result: No errors, no warnings
    Evidence: Analyzer output

  Scenario: Provider can be instantiated
    Tool: Bash (quick test)
    Steps:
      1. Create temp test that instantiates SettingsProvider
      2. Run: `flutter test test/temp_settings_provider_test.dart`
    Expected Result: Test passes
    Evidence: Test output
  ```

  **Commit**: YES
  - Message: `feat(settings): add SettingsProvider for state management`
  - Files: `lib/presentation/providers/settings_provider.dart`

- [ ] **Task 4: Create SettingsService for data operations**

  **What to do:** Create service class that handles data export (JSON/CSV) and storage calculation.

  **Must NOT do:** Don't mix UI logic with data operations, don't export in UI-blocking synchronous calls.

  **Recommended Agent Profile:**
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization:**
  - **Can Run In Parallel**: NO (depends on Task 3)
  - **Blocked By**: Task 3
  - **Blocks**: Tasks 9-10

  **References:**
  - Pattern: `lib/data/services/database_service.dart` - service pattern
  - `lib/data/repositories/meal_repository.dart` - data access pattern
  - `lib/data/repositories/local_meal_repository.dart` - SQL queries

  **Implementation:**
  ```dart
  // lib/data/services/settings_service.dart
  class SettingsService {
    final DatabaseService _db;
    final ImageStorageService _imageStorage;
    
    // Export to JSON
    Future<Map<String, dynamic>> exportToJson() async { ... }
    
    // Export meals to CSV
    Future<String> exportMealsToCsv() async { ... }
    
    // Export metrics to CSV
    Future<String> exportMetricsToCsv() async { ... }
    
    // Calculate storage usage
    Future<StorageInfo> getStorageUsage() async { ... }
    
    // Clear all data
    Future<void> clearAllData() async { ... }
  }
  
  class StorageInfo {
    final int databaseBytes;
    final int imagesBytes;
    int get totalBytes => databaseBytes + imagesBytes;
    String get formattedSize => ... // "12.5 MB"
  }
  ```

  **Acceptance Criteria:**
  - [ ] File created: `lib/data/services/settings_service.dart`
  - [ ] exportToJson() returns valid structure with meals, metrics, ratings
  - [ ] exportMealsToCsv() returns CSV string with headers
  - [ ] getStorageUsage() returns actual file sizes
  - [ ] clearAllData() deletes database and images

  **QA Scenarios:**
  ```
  Scenario: Export JSON contains data
    Tool: Dart test
    Steps:
      1. Create test with sample meal
      2. Call exportToJson()
      3. Assert 'meals' array is not empty
    Expected Result: Test passes
    Evidence: Test output saved

  Scenario: CSV export has correct format
    Tool: Dart test
    Steps:
      1. Create test with sample meals
      2. Call exportMealsToCsv()
      3. Assert output contains 'date,slot,description'
    Expected Result: Test passes
    Evidence: Test output
  ```

  **Commit**: YES
  - Message: `feat(settings): add SettingsService for data export and storage`
  - Files: `lib/data/services/settings_service.dart`


- [ ] **Task 5: Create ThemeSelector widget**

  **What to do:** Build reusable widget for Light/Dark/System theme selection.

  **Must NOT do:** Don't hardcode theme values, use ThemeMode enum. Don't apply theme here - just emit selection.

  **Recommended Agent Profile:**
  - **Category**: `visual-engineering`
  - **Skills**: []

  **Parallelization:**
  - **Can Run In Parallel**: NO (depends on Task 3)
  - **Blocked By**: Task 3
  - **Blocks**: Task 8

  **References:**
  - Pattern: `lib/presentation/widgets/day_rating_widget.dart` - stateful widget pattern
  - `lib/config/theme.dart` - existing themes

  **Implementation:**
  ```dart
  // lib/presentation/widgets/theme_selector.dart
  class ThemeSelector extends StatelessWidget {
    final ThemeMode selectedMode;
    final ValueChanged<ThemeMode> onChanged;
    
    @override
    Widget build(BuildContext context) {
      // Use SegmentedButton or DropdownButton
      return SegmentedButton<ThemeMode>(
        segments: [
          ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode)),
          ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
          ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.settings)),
        ],
        selected: {selectedMode},
        onSelectionChanged: (set) => onChanged(set.first),
      );
    }
  }
  ```

  **Acceptance Criteria:**
  - [ ] File created: `lib/presentation/widgets/theme_selector.dart`
  - [ ] Widget displays three options: Light, Dark, System
  - [ ] Selected mode is visually highlighted
  - [ ] onChanged callback fires when selection changes
  - [ ] Follows Material 3 design

  **QA Scenarios:**
  ```
  Scenario: Theme selector renders correctly
    Tool: Flutter test (widget test)
    Steps:
      1. Pump widget with ThemeMode.light selected
      2. Find 'Light' text and verify it's in selected state
    Expected Result: Light button is selected
    Evidence: Screenshot or test pass output
  ```

  **Commit**: YES
  - Message: `feat(settings): add ThemeSelector widget`
  - Files: `lib/presentation/widgets/theme_selector.dart`

- [ ] **Task 6: Create WaterGoalSlider widget**

  **What to do:** Build slider widget for setting daily water intake goal (1.0L - 4.0L).

  **Must NOT do:** Don't allow values outside 1.0-4.0 range, don't use integer steps (allow 0.1L increments).

  **Recommended Agent Profile:**
  - **Category**: `visual-engineering`
  - **Skills**: []

  **Parallelization:**
  - **Can Run In Parallel**: NO (depends on Task 3)
  - **Blocked By**: Task 3
  - **Blocks**: Task 8

  **References:**
  - Pattern: `lib/presentation/widgets/daily_metrics_widget.dart` - slider/spinner patterns
  - App theme color: #2F6F5E

  **Implementation:**
  ```dart
  // lib/presentation/widgets/water_goal_slider.dart
  class WaterGoalSlider extends StatelessWidget {
    final double value; // in liters
    final ValueChanged<double> onChanged;
    static const minLiters = 1.0;
    static const maxLiters = 4.0;
    
    @override
    Widget build(BuildContext context) {
      return Column(
        children: [
          Text('${value.toStringAsFixed(1)} L'),
          Slider(
            value: value,
            min: minLiters,
            max: maxLiters,
            divisions: 30, // 0.1L steps
            onChanged: onChanged,
          ),
        ],
      );
    }
  }
  ```

  **Acceptance Criteria:**
  - [ ] File created: `lib/presentation/widgets/water_goal_slider.dart`
  - [ ] Slider ranges from 1.0L to 4.0L
  - [ ] Current value displayed above slider
  - [ ] 0.1L increments (30 divisions)
  - [ ] Uses app's primary color for active track

  **QA Scenarios:**
  ```
  Scenario: Slider updates value
    Tool: Flutter test
    Steps:
      1. Pump widget with value=2.0
      2. Drag slider to right
      3. Verify onChanged called with value > 2.0
    Expected Result: Callback receives new value
    Evidence: Test output
  ```

  **Commit**: YES
  - Message: `feat(settings): add WaterGoalSlider widget`
  - Files: `lib/presentation/widgets/water_goal_slider.dart`

- [ ] **Task 7: Create MealSlotNameEditor widget**

  **What to do:** Build expandable widget for customizing meal slot display names.

  **Must NOT do:** Don't allow empty names, don't save immediately on every keystroke (debounce or onBlur).

  **Recommended Agent Profile:**
  - **Category**: `visual-engineering`
  - **Skills**: []

  **Parallelization:**
  - **Can Run In Parallel**: NO (depends on Task 3)
  - **Blocked By**: Task 3
  - **Blocks**: Task 8

  **References:**
  - Pattern: `lib/presentation/screens/today_screen.dart` - TextField usage
  - `lib/data/models/meal.dart` - MealSlot enum

  **Implementation:**
  ```dart
  // lib/presentation/widgets/meal_slot_name_editor.dart
  class MealSlotNameEditor extends StatefulWidget {
    final Map<MealSlot, String> names;
    final ValueChanged<Map<MealSlot, String>> onChanged;
    
    @override
    Widget build(BuildContext context) {
      // ExpansionTile with 4 TextFields inside
      // One for each MealSlot
    }
  }
  ```

  **Acceptance Criteria:**
  - [ ] File created: `lib/presentation/widgets/meal_slot_name_editor.dart`
  - [ ] Shows ExpansionTile with title "Meal Names"
  - [ ] Inside: 4 TextFields with labels (Breakfast, Lunch, Afternoon Snack, Dinner)
  - [ ] Pre-filled with current custom names or defaults
  - [ ] Validates non-empty on save
  - [ ] onChanged fires when any name changes

  **QA Scenarios:**
  ```
  Scenario: Meal names can be edited
    Tool: Flutter test
    Steps:
      1. Pump widget
      2. Expand the tile
      3. Enter "Tea Time" in Afternoon Snack field
      4. Verify onChanged called with updated map
    Expected Result: Callback includes new name
    Evidence: Test output
  ```

  **Commit**: YES
  - Message: `feat(settings): add MealSlotNameEditor widget`
  - Files: `lib/presentation/widgets/meal_slot_name_editor.dart`

- [ ] **Task 8: Create AppearanceSection and TrackingSection widgets**

  **What to do:** Compose the Appearance and Tracking Preferences sections using widgets from Tasks 5-7.

  **Must NOT do:** Don't mix business logic with presentation - use SettingsProvider via context.watch().

  **Recommended Agent Profile:**
  - **Category**: `visual-engineering`
  - **Skills**: []

  **Parallelization:**
  - **Can Run In Parallel**: NO (depends on Tasks 5, 6, 7)
  - **Blocked By**: Tasks 5, 6, 7
  - **Blocks**: Task 13

  **References:**
  - `lib/presentation/widgets/theme_selector.dart` (Task 5)
  - `lib/presentation/widgets/water_goal_slider.dart` (Task 6)
  - `lib/presentation/widgets/meal_slot_name_editor.dart` (Task 7)
  - `lib/presentation/providers/settings_provider.dart` (Task 3)

  **Implementation:**
  ```dart
  // lib/presentation/widgets/settings_sections.dart
  class AppearanceSection extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      final settings = context.watch<SettingsProvider>();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Appearance', style: theme.textTheme.titleSmall),
          ListTile(
            title: Text('Theme'),
            trailing: ThemeSelector(
              selectedMode: settings.themeMode,
              onChanged: (mode) => settings.themeMode = mode,
            ),
          ),
        ],
      );
    }
  }
  
  class TrackingSection extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      final settings = context.watch<SettingsProvider>();
      return Column(...);
    }
  }
  ```

  **Acceptance Criteria:**
  - [ ] File created: `lib/presentation/widgets/settings_sections.dart`
  - [ ] AppearanceSection uses ThemeSelector widget
  - [ ] TrackingSection uses WaterGoalSlider and MealSlotNameEditor
  - [ ] Both sections use ListTile with appropriate dividers
  - [ ] Both sections read from and write to SettingsProvider

  **QA Scenarios:**
  ```
  Scenario: Sections render with provider data
    Tool: Flutter test
    Steps:
      1. Create SettingsProvider with test values
      2. Pump sections wrapped in Provider
      3. Verify widgets display correct values
    Expected Result: Theme mode and water goal display correctly
    Evidence: Test output + screenshot
  ```

  **Commit**: YES
  - Message: `feat(settings): add Appearance and Tracking section widgets`
  - Files: `lib/presentation/widgets/settings_sections.dart`


- [ ] **Task 9: Create DataManagementSection widget**

  **What to do:** Build section with Export JSON, Export CSV, View Storage, and Clear Data options.

  **Must NOT do:** Don't perform exports on main thread (use async), don't clear data without confirmation dialog.

  **Recommended Agent Profile:**
  - **Category**: `visual-engineering`
  - **Skills**: []

  **Parallelization:**
  - **Can Run In Parallel**: NO (depends on Task 4)
  - **Blocked By**: Task 4
  - **Blocks**: Task 13

  **References:**
  - `lib/data/services/settings_service.dart` (Task 4)
  - Pattern: `lib/presentation/widgets/haptic_feedback_wrapper.dart` - haptic feedback
  - `share_plus` package for sharing files

  **Implementation:**
  ```dart
  // lib/presentation/widgets/settings_sections.dart (add to existing file)
  class DataManagementSection extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return Column(
        children: [
          ListTile(
            leading: Icon(Icons.file_upload_outlined),
            title: Text('Export to JSON'),
            subtitle: Text('Backup all data'),
            onTap: () => _exportJson(context),
          ),
          ListTile(
            leading: Icon(Icons.table_chart_outlined),
            title: Text('Export to CSV'),
            subtitle: Text('For spreadsheet analysis'),
            onTap: () => _exportCsv(context),
          ),
          ListTile(
            leading: Icon(Icons.storage_outlined),
            title: Text('Storage Usage'),
            trailing: FutureBuilder<StorageInfo>(...),
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red),
            title: Text('Clear All Data', style: TextStyle(color: Colors.red)),
            onTap: () => _showClearDataDialog(context),
          ),
        ],
      );
    }
    
    void _exportJson(BuildContext context) async {
      final json = await settingsService.exportToJson();
      final jsonString = jsonEncode(json);
      // Use share_plus to share file
    }
    
    void _showClearDataDialog(BuildContext context) {
      // Show AlertDialog with confirmation
      // Require typing "DELETE" to confirm
    }
  }
  ```

  **Acceptance Criteria:**
  - [ ] Export JSON uses SettingsService.exportToJson() and share_plus
  - [ ] Export CSV generates meals and metrics CSVs
  - [ ] Storage Usage shows live calculation from SettingsService
  - [ ] Clear Data shows confirmation dialog with text input
  - [ ] Clear Data is styled with error color (red)
  - [ ] All operations show loading indicators

  **QA Scenarios:**
  ```
  Scenario: Export JSON opens share sheet
    Tool: Integration test
    Steps:
      1. Navigate to settings
      2. Tap "Export to JSON"
      3. Verify share sheet opens with valid JSON file
    Expected Result: Share sheet appears with file
    Evidence: Screenshot

  Scenario: Clear data requires confirmation
    Tool: Integration test
    Steps:
      1. Tap "Clear All Data"
      2. Verify confirmation dialog appears
      3. Type "DELETE"
      4. Confirm
      5. Verify data is cleared
    Expected Result: Dialog appears, data clears after confirmation
    Evidence: Test output
  ```

  **Commit**: YES
  - Message: `feat(settings): add DataManagement section with export and clear`
  - Files: `lib/presentation/widgets/settings_sections.dart`

- [ ] **Task 10: Create NotificationService and reminder scheduling**

  **What to do:** Implement flutter_local_notifications setup and scheduling for meal reminders.

  **Must NOT do:** Don't request notification permission aggressively (ask on first toggle), don't schedule if permission denied.

  **Recommended Agent Profile:**
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization:**
  - **Can Run In Parallel**: NO (depends on Task 3)
  - **Blocked By**: Task 3
  - **Blocks**: Task 11

  **References:**
  - `flutter_local_notifications` documentation
  - `permission_handler` for iOS notification permission
  - `lib/presentation/providers/settings_provider.dart` - reminder state

  **Implementation:**
  ```dart
  // lib/data/services/notification_service.dart
  class NotificationService {
    static final _notifications = FlutterLocalNotificationsPlugin();
    
    static Future<void> initialize() async {
      // Initialize with Android/iOS settings
    }
    
    static Future<bool> requestPermission() async {
      // iOS permission request
    }
    
    static Future<void> scheduleMealReminder(MealSlot slot, Time time) async {
      // Schedule daily repeating notification
    }
    
    static Future<void> cancelMealReminder(MealSlot slot) async {
      // Cancel scheduled notification
    }
    
    static Future<void> updateAllReminders(SettingsProvider settings) async {
      // Enable/disable based on settings
    }
  }
  ```

  **Android Configuration:**
  - Add to `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
  <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
  ```

  **iOS Configuration:**
  - Add to `ios/Runner/Info.plist`:
  ```xml
  <key>UIBackgroundModes</key>
  <array>
    <string>fetch</string>
    <string>remote-notification</string>
  </array>
  ```

  **Acceptance Criteria:**
  - [ ] File created: `lib/data/services/notification_service.dart`
  - [ ] NotificationService.initialize() called in main()
  - [ ] scheduleMealReminder creates daily repeating notification
  - [ ] cancelMealReminder removes scheduled notification
  - [ ] updateAllReminders syncs with SettingsProvider state
  - [ ] Permission handling for iOS

  **QA Scenarios:**
  ```
  Scenario: Notifications initialize without errors
    Tool: Flutter run
    Steps:
      1. Start app
      2. Check logs for initialization errors
    Expected Result: No errors, initialization success logged
    Evidence: Log output

  Scenario: Reminder can be scheduled
    Tool: Manual test on device
    Steps:
      1. Enable breakfast reminder
      2. Verify notification scheduled (check system settings)
    Expected Result: Notification appears in system notification settings
    Evidence: Screenshot of system settings
  ```

  **Commit**: YES
  - Message: `feat(settings): add NotificationService for meal reminders`
  - Files: `lib/data/services/notification_service.dart`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`

- [ ] **Task 11: Create NotificationsSection widget**

  **What to do:** Build section with toggle switches for each meal slot reminder.

  **Must NOT do:** Don't show notification permission errors inline - use a dialog, don't allow toggling if permission permanently denied.

  **Recommended Agent Profile:**
  - **Category**: `visual-engineering`
  - **Skills**: []

  **Parallelization:**
  - **Can Run In Parallel**: NO (depends on Tasks 3, 10)
  - **Blocked By**: Tasks 3, 10
  - **Blocks**: Task 13

  **References:**
  - `lib/data/services/notification_service.dart` (Task 10)
  - `lib/presentation/providers/settings_provider.dart` (Task 3)
  - `lib/data/models/meal.dart` - MealSlot enum

  **Implementation:**
  ```dart
  // lib/presentation/widgets/settings_sections.dart (add to existing)
  class NotificationsSection extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      final settings = context.watch<SettingsProvider>();
      
      return Column(
        children: [
          for (final slot in MealSlot.values)
            SwitchListTile(
              secondary: Icon(_getSlotIcon(slot)),
              title: Text(settings.getMealName(slot)),
              subtitle: Text(_getReminderTime(slot)),
              value: settings.isReminderEnabled(slot),
              onChanged: (enabled) => _onToggle(context, slot, enabled),
            ),
        ],
      );
    }
    
    void _onToggle(BuildContext context, MealSlot slot, bool enabled) async {
      if (enabled) {
        final hasPermission = await NotificationService.requestPermission();
        if (!hasPermission) {
          // Show dialog explaining how to enable in settings
          return;
        }
      }
      context.read<SettingsProvider>().setReminderEnabled(slot, enabled);
      await NotificationService.updateAllReminders(settings);
    }
    
    String _getReminderTime(MealSlot slot) {
      return switch (slot) {
        MealSlot.breakfast => '8:00 AM',
        MealSlot.lunch => '12:00 PM',
        MealSlot.afternoonSnack => '4:00 PM',
        MealSlot.dinner => '7:00 PM',
      };
    }
  }
  ```

  **Acceptance Criteria:**
  - [ ] 4 SwitchListTile entries (one per MealSlot)
  - [ ] Each shows meal name, scheduled time, and toggle
  - [ ] Toggle requests permission on first enable
  - [ ] Toggle updates SettingsProvider and NotificationService
  - [ ] Shows permission denied dialog if user denies

  **QA Scenarios:**
  ```
  Scenario: Toggle reminder on requests permission
    Tool: Device test
    Steps:
      1. Fresh install
      2. Open settings
      3. Toggle breakfast reminder ON
      4. Verify permission dialog appears
    Expected Result: iOS permission dialog shown
    Evidence: Screenshot

  Scenario: Toggle updates settings
    Tool: Widget test
    Steps:
      1. Pump with SettingsProvider
      2. Toggle switch
      3. Verify provider value changed
    Expected Result: Provider receives new value
    Evidence: Test output
  ```

  **Commit**: YES
  - Message: `feat(settings): add Notifications section with meal reminders`
  - Files: `lib/presentation/widgets/settings_sections.dart`

- [ ] **Task 12: Create LanguageSelector widget and AdvancedSection**

  **What to do:** Build language override selector and compose Advanced section.

  **Must NOT do:** Don't change locale immediately on selection (requires restart or MaterialApp rebuild), don't show languages app doesn't support.

  **Recommended Agent Profile:**
  - **Category**: `visual-engineering`
  - **Skills**: []

  **Parallelization:**
  - **Can Run In Parallel**: NO (depends on Task 3)
  - **Blocked By**: Task 3
  - **Blocks**: Task 13

  **References:**
  - `lib/gen_l10n/app_localizations.dart` - supported locales
  - `lib/main.dart` - MaterialApp locale setup
  - `lib/presentation/providers/settings_provider.dart` - language override

  **Implementation:**
  ```dart
  // lib/presentation/widgets/language_selector.dart
  class LanguageSelector extends StatelessWidget {
    final Locale? selectedLocale; // null = system default
    final ValueChanged<Locale?> onChanged;
    
    @override
    Widget build(BuildContext context) {
      return DropdownButton<Locale?>(
        value: selectedLocale,
        items: [
          DropdownMenuItem(value: null, child: Text('System Default')),
          DropdownMenuItem(value: Locale('en'), child: Text('English')),
          DropdownMenuItem(value: Locale('fr'), child: Text('Français')),
        ],
        onChanged: onChanged,
      );
    }
  }
  
  // In settings_sections.dart:
  class AdvancedSection extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      final settings = context.watch<SettingsProvider>();
      return ListTile(
        title: Text('Language'),
        trailing: LanguageSelector(
          selectedLocale: settings.languageOverride,
          onChanged: (locale) {
            settings.languageOverride = locale;
            // Show restart dialog
            _showRestartDialog(context);
          },
        ),
      );
    }
    
    void _showRestartDialog(BuildContext context) {
      showDialog(...); // "Restart required to apply changes"
    }
  }
  ```

  **Acceptance Criteria:**
  - [ ] File created: `lib/presentation/widgets/language_selector.dart`
  - [ ] Dropdown shows: System Default, English, Français
  - [ ] Selected value synced with SettingsProvider
  - [ ] On change, shows restart required dialog
  - [ ] AdvancedSection uses LanguageSelector

  **QA Scenarios:**
  ```
  Scenario: Language selector shows options
    Tool: Widget test
    Steps:
      1. Pump LanguageSelector
      2. Tap dropdown
      3. Verify 3 options visible
    Expected Result: System Default, English, Français shown
    Evidence: Test output
  ```

  **Commit**: YES
  - Message: `feat(settings): add LanguageSelector and Advanced section`
  - Files: `lib/presentation/widgets/language_selector.dart`, `lib/presentation/widgets/settings_sections.dart`


- [ ] **Task 13: Create AboutSection widget**

  **What to do:** Build About section with version, description, and licenses button.

  **Must NOT do:** Don't hardcode version number, fetch from package_info_plus. Don't add unnecessary links.

  **Recommended Agent Profile:**
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization:**
  - **Can Run In Parallel**: NO (depends on nothing new, but logical order)
  - **Blocked By**: None
  - **Blocks**: Task 14

  **References:**
  - `package_info_plus` for version info
  - `lib/config/theme.dart` - app description
  - Flutter's `showLicensePage()` function

  **Implementation:**
  ```dart
  // lib/presentation/widgets/settings_sections.dart (add to existing)
  class AboutSection extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return Column(
        children: [
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              return ListTile(
                title: Text('Version'),
                trailing: Text(snapshot.data?.version ?? '...'),
              );
            },
          ),
          ListTile(
            title: Text('About'),
            subtitle: Text('Local diet and meal tracking app'),
          ),
          ListTile(
            title: Text('View Licenses'),
            trailing: Icon(Icons.chevron_right),
            onTap: () => showLicensePage(context: context),
          ),
        ],
      );
    }
  }
  ```

  **Acceptance Criteria:**
  - [ ] Shows app version from package_info_plus
  - [ ] Shows brief app description
  - [ ] "View Licenses" opens Flutter license page
  - [ ] Follows Material 3 ListTile styling

  **QA Scenarios:**
  ```
  Scenario: Version displays correctly
    Tool: Widget test
    Steps:
      1. Pump AboutSection
      2. Wait for PackageInfo future
      3. Verify version text is shown
    Expected Result: Version number displayed (e.g., "1.0.0")
    Evidence: Test output
  ```

  **Commit**: YES
  - Message: `feat(settings): add About section with version and licenses`
  - Files: `lib/presentation/widgets/settings_sections.dart`

- [ ] **Task 14: Create SettingsScreen and integrate all sections**

  **What to do:** Build the main SettingsScreen that composes all section widgets.

  **Must NOT do:** Don't forget to wrap with Provider, don't forget AppBar with back button.

  **Recommended Agent Profile:**
  - **Category**: `visual-engineering`
  - **Skills**: []

  **Parallelization:**
  - **Can Run In Parallel**: NO (depends on Tasks 8, 9, 11, 12, 13)
  - **Blocked By**: Tasks 8, 9, 11, 12, 13
  - **Blocks**: Task 15

  **References:**
  - `lib/presentation/widgets/settings_sections.dart` - all section widgets
  - `lib/presentation/screens/today_screen.dart` - AppBar pattern
  - `lib/config/routes.dart` - route integration

  **Implementation:**
  ```dart
  // lib/presentation/screens/settings_screen.dart
  class SettingsScreen extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.settings ?? 'Settings'),
        ),
        body: ListView(
          children: [
            AppearanceSection(),
            Divider(),
            TrackingSection(),
            Divider(),
            NotificationsSection(),
            Divider(),
            DataManagementSection(),
            Divider(),
            AdvancedSection(),
            Divider(),
            AboutSection(),
          ],
        ),
      );
    }
  }
  ```

  **Acceptance Criteria:**
  - [ ] File created: `lib/presentation/screens/settings_screen.dart`
  - [ ] Scaffold with AppBar titled "Settings"
  - [ ] ListView with all sections in order
  - [ ] Dividers between sections
  - [ ] No Provider error (SettingsProvider available in context)

  **QA Scenarios:**
  ```
  Scenario: Settings screen renders all sections
    Tool: Widget test
    Steps:
      1. Pump SettingsScreen wrapped with SettingsProvider
      2. Find all section titles
      3. Verify all 6 sections present
    Expected Result: All sections found
    Evidence: Test output + screenshot
  ```

  **Commit**: YES
  - Message: `feat(settings): add SettingsScreen with all sections`
  - Files: `lib/presentation/screens/settings_screen.dart`

- [ ] **Task 15: Add settings route and integrate with app**

  **What to do:** Add /settings route to go_router and add settings button to TodayScreen AppBar.

  **Must NOT do:** Don't add settings to bottom nav (it's accessed from Today only), don't forget to provide SettingsProvider at app root.

  **Recommended Agent Profile:**
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization:**
  - **Can Run In Parallel**: NO (depends on Task 14)
  - **Blocked By**: Task 14
  - **Blocks**: Final Verification

  **References:**
  - `lib/config/routes.dart` - add new GoRoute
  - `lib/presentation/screens/today_screen.dart` - add AppBar action
  - `lib/app.dart` - add SettingsProvider to widget tree
  - `lib/main.dart` - initialize notification service

  **Implementation:**

  **1. Add route to routes.dart:**
  ```dart
  // lib/config/routes.dart
  GoRoute(
    path: '/settings',
    builder: (context, state) => const SettingsScreen(),
  ),
  ```

  **2. Add button to TodayScreen:**
  ```dart
  // lib/presentation/screens/today_screen.dart
  AppBar(
    title: Text(context.l10n.today),
    actions: [
      IconButton(
        icon: const Icon(Icons.settings_outlined),
        onPressed: () => context.push('/settings'),
        tooltip: 'Settings',
      ),
    ],
  )
  ```

  **3. Provide SettingsProvider at app root:**
  ```dart
  // lib/app.dart
  class App extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          // existing providers...
        ],
        child: MaterialApp.router(...),
      );
    }
  }
  ```

  **4. Initialize notifications in main:**
  ```dart
  // lib/main.dart
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    await NotificationService.initialize();
    runApp(App());
  }
  ```

  **Acceptance Criteria:**
  - [ ] Route '/settings' navigates to SettingsScreen
  - [ ] Settings icon appears in TodayScreen AppBar
  - [ ] SettingsProvider provided at app root
  - [ ] NotificationService initialized on app start
  - [ ] Back navigation works from settings

  **QA Scenarios:**
  ```
  Scenario: Navigate to settings from Today screen
    Tool: Integration test
    Steps:
      1. Launch app
      2. Tap settings icon in AppBar
      3. Verify SettingsScreen appears
      4. Tap back
      5. Verify back on TodayScreen
    Expected Result: Navigation works both ways
    Evidence: Test output

  Scenario: Settings persist after restart
    Tool: Manual test
    Steps:
      1. Change theme to Dark
      2. Set water goal to 3.0L
      3. Kill app
      4. Reopen app
      5. Verify settings retained
    Expected Result: Dark theme and 3.0L goal persisted
    Evidence: Screenshots
  ```

  **Commit**: YES
  - Message: `feat(settings): integrate settings with app navigation and providers`
  - Files: `lib/config/routes.dart`, `lib/presentation/screens/today_screen.dart`, `lib/app.dart`, `lib/main.dart`


- [ ] **Task 16: Add localization strings**

  **What to do:** Add English and French translations for all settings UI text.

  **Must NOT do:** Don't leave any hardcoded strings in UI, don't forget French translations.

  **Recommended Agent Profile:**
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization:**
  - **Can Run In Parallel**: NO (should be done after UI is stable)
  - **Blocked By**: Task 14
  - **Blocks**: None

  **References:**
  - `lib/l10n/app_en.arb` - English strings
  - `lib/l10n/app_fr.arb` - French strings
  - `lib/utils/l10n_helper.dart` - localization helper

  **Strings to add:**
  - settings
  - appearance
  - theme
  - themeLight
  - themeDark
  - themeSystem
  - trackingPreferences
  - waterGoal
  - mealNames
  - notifications
  - reminderBreakfast
  - reminderLunch
  - reminderAfternoonSnack
  - reminderDinner
  - dataManagement
  - exportJson
  - exportJsonSubtitle
  - exportCsv
  - exportCsvSubtitle
  - storageUsage
  - clearAllData
  - clearAllDataSubtitle
  - clearDataConfirmation
  - clearDataWarning
  - advanced
  - language
  - systemDefault
  - about
  - viewLicenses

  **Acceptance Criteria:**
  - [ ] All settings strings added to app_en.arb
  - [ ] All strings translated in app_fr.arb
  - [ ] UI uses context.l10n for all text
  - [ ] No hardcoded strings in settings widgets

  **QA Scenarios:**
  ```
  Scenario: Settings screen is localized
    Tool: Widget test
    Steps:
      1. Pump with French locale
      2. Verify all text is French
    Expected Result: "Paramètres" instead of "Settings"
    Evidence: Test output
  ```

  **Commit**: YES
  - Message: `feat(settings): add localization for settings page`
  - Files: `lib/l10n/app_en.arb`, `lib/l10n/app_fr.arb`

---

## Final Verification Wave (After ALL tasks)

> 3 review agents run in PARALLEL. ALL must APPROVE. Rejection → fix → re-run.

- [ ] **F1. Integration Test** - `unspecified-high`

  **What to verify:** End-to-end settings functionality
  
  **Test Scenarios:**
  1. Navigate to settings from Today screen
  2. Change theme (Light → Dark → System)
  3. Set water goal to 3.0L
  4. Change "Afternoon Snack" to "Tea Time"
  5. Enable breakfast reminder
  6. Export data to JSON (verify file valid)
  7. Check storage usage displays
  8. Verify all settings persist after app restart
  9. Change language to French
  10. Verify French text appears
  
  **QA Commands:**
  ```bash
  flutter test integration_test/settings_test.dart
  ```
  
  **Evidence:** Test report saved to `.sisyphus/evidence/final-integration-test.txt`

- [ ] **F2. Code Review** - `quick`

  **What to verify:** Code quality and patterns
  
  **Checklist:**
  - [ ] No `dynamic` types used
  - [ ] Proper null safety throughout
  - [ ] `const` constructors where possible
  - [ ] Follows existing provider patterns
  - [ ] No hardcoded strings (all localized)
  - [ ] Proper error handling for async operations
  - [ ] No widget rebuild issues (proper context.watch usage)
  
  **QA Commands:**
  ```bash
  flutter analyze
  flutter format --set-exit-if-changed lib/
  ```
  
  **Evidence:** Analyzer output saved

- [ ] **F3. Visual QA** - `visual-engineering`

  **What to verify:** UI/UX quality
  
  **Screenshots to capture:**
  1. Settings screen in Light theme
  2. Settings screen in Dark theme
  3. Each expanded section
  4. Export share sheet
  5. Clear data confirmation dialog
  6. Language selector dropdown
  
  **QA Check:**
  - All sections have proper spacing
  - Dividers visible but subtle
  - Destructive action (clear data) styled in error color
  - Icons align with Material 3 guidelines
  - Text readable at all sizes
  
  **Evidence:** Screenshots saved to `.sisyphus/evidence/visual-qa/`

---

## Summary of Files Created/Modified

### New Files (12):
1. `lib/utils/settings_keys.dart`
2. `lib/presentation/providers/settings_provider.dart`
3. `lib/data/services/settings_service.dart`
4. `lib/data/services/notification_service.dart`
5. `lib/presentation/widgets/theme_selector.dart`
6. `lib/presentation/widgets/water_goal_slider.dart`
7. `lib/presentation/widgets/meal_slot_name_editor.dart`
8. `lib/presentation/widgets/language_selector.dart`
9. `lib/presentation/widgets/settings_sections.dart`
10. `lib/presentation/screens/settings_screen.dart`
11. `lib/l10n/app_en.arb` (additions)
12. `lib/l10n/app_fr.arb` (additions)

### Modified Files (5):
1. `pubspec.yaml` - add dependencies
2. `lib/config/routes.dart` - add /settings route
3. `lib/presentation/screens/today_screen.dart` - add settings button
4. `lib/app.dart` - provide SettingsProvider
5. `lib/main.dart` - initialize NotificationService

### Platform Config (2):
1. `android/app/src/main/AndroidManifest.xml` - notification permissions
2. `ios/Runner/Info.plist` - background modes

**Total: 19 files**
