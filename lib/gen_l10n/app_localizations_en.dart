// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Diet';

  @override
  String get navToday => 'Today';

  @override
  String get navMeals => 'Meals';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navWorkouts => 'Workouts';

  @override
  String get navSettings => 'Settings';

  @override
  String get todayTitle => 'Today\'s Meals';

  @override
  String get mealHistoryTitle => 'Meal History';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get dayDetailTitle => 'Day Details';

  @override
  String get checkinTitle => 'Daily Check-in';

  @override
  String get workoutsTitle => 'Workouts';

  @override
  String get bodyMetricsTitle => 'Body Metrics';

  @override
  String get screenTimeTitle => 'Screen Time';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get howWasYourDay => 'How was your day?';

  @override
  String get ratingBad => 'Bad';

  @override
  String get ratingOkay => 'Okay';

  @override
  String get ratingGreat => 'Great';

  @override
  String get ratingNotSet => 'Not rated';

  @override
  String get ratingLogged => 'Day rated';

  @override
  String get dayRatingSubtitleToday => 'Tap to rate today';

  @override
  String get dayRatingSubtitleDay => 'Tap to rate this day';

  @override
  String get dailyMetrics => 'Daily Metrics';

  @override
  String get goalMet => 'Goal met';

  @override
  String get waterLabel => 'Water';

  @override
  String get exerciseLabel => 'Exercise';

  @override
  String get waterGoal => 'Goal: 2L';

  @override
  String get notLogged => 'Not logged';

  @override
  String get waterHintText => 'Enter amount in ml';

  @override
  String get exerciseHintText => 'Enter exercise details';

  @override
  String get dailyMetricsSubtitleToday => 'Track your progress for today';

  @override
  String get dailyMetricsSubtitleDay => 'View metrics for this day';

  @override
  String waterAmount(String amount) {
    return '$amount ml';
  }

  @override
  String get waterUnit => 'ml';

  @override
  String get breakfast => 'Breakfast';

  @override
  String get lunch => 'Lunch';

  @override
  String get afternoonSnack => 'Afternoon Snack';

  @override
  String get dinner => 'Dinner';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get replacePhoto => 'Replace Photo';

  @override
  String get deletePhoto => 'Delete Photo';

  @override
  String get imageNotFound => 'Image not found';

  @override
  String get addDescriptionHint => 'Add a description...';

  @override
  String get clearMeal => 'Clear Meal';

  @override
  String clearMealConfirmation(String slotName) {
    return 'Are you sure you want to clear $slotName?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get clear => 'Clear';

  @override
  String get noMealsYet => 'No meals yet';

  @override
  String get noMealsYetSubtitle => 'Start by adding your first meal';

  @override
  String get noMealsLogged => 'No meals logged';

  @override
  String get noMealsLoggedSubtitle => 'No meals recorded for this day';

  @override
  String get failedToLoadMeals => 'Failed to load meals';

  @override
  String get failedToLoadCalendar => 'Failed to load calendar';

  @override
  String get unknownError => 'An unknown error occurred';

  @override
  String get retry => 'Retry';

  @override
  String get noDescription => 'No description';

  @override
  String recordedAt(String time) {
    return 'Recorded at $time';
  }

  @override
  String get clearMealTooltip => 'Clear this meal';

  @override
  String waterAmountWithGoal(String amount) {
    return '$amount / 2000 ml';
  }

  @override
  String get waterDash => '—';

  @override
  String get exerciseYes => 'Yes';

  @override
  String get exerciseNo => 'No';

  @override
  String get exerciseDash => '—';

  @override
  String get goalMetSuffix => 'met';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get jumpToToday => 'Jump to Today';

  @override
  String get errorLoadMeals => 'Failed to load meals';

  @override
  String get errorLoadDayRating => 'Failed to load day rating';

  @override
  String get errorLoadDailyMetrics => 'Failed to load daily metrics';

  @override
  String get errorInvalidDayRating => 'Invalid day rating selected';

  @override
  String get errorSaveDayRating => 'Failed to save day rating';

  @override
  String get errorSaveImage => 'Failed to save image';

  @override
  String get errorCapturePhoto => 'Failed to capture photo';

  @override
  String get errorPickImage => 'Failed to pick image';

  @override
  String get errorSaveMeal => 'Failed to save meal';

  @override
  String get errorDeletePhoto => 'Failed to delete photo';

  @override
  String get errorClearMeal => 'Failed to clear meal';

  @override
  String get errorSaveDailyMetrics => 'Failed to save daily metrics';

  @override
  String get errorLoadCalendar => 'Failed to load calendar data';

  @override
  String get checkinMood => 'Mood';

  @override
  String get checkinEnergy => 'Energy';

  @override
  String get checkinFocus => 'Focus';

  @override
  String get checkinStress => 'Stress';

  @override
  String get checkinSleep => 'Sleep';

  @override
  String get checkinSleepHours => 'Hours';

  @override
  String checkinSleepHoursValue(String hours) {
    return '${hours}h';
  }

  @override
  String get checkinSleepQuality => 'Quality';

  @override
  String get checkinNotes => 'Notes';

  @override
  String get checkinNotesHint => 'How are you feeling today?';

  @override
  String get checkinSave => 'Save Check-in';

  @override
  String get checkinSaved => 'Check-in saved';

  @override
  String get checkinVeryLow => 'Very Low';

  @override
  String get checkinLow => 'Low';

  @override
  String get checkinMedium => 'Medium';

  @override
  String get checkinHigh => 'High';

  @override
  String get checkinVeryHigh => 'Very High';

  @override
  String get errorLoadCheckin => 'Failed to load check-in';

  @override
  String get errorSaveCheckin => 'Failed to save check-in';

  @override
  String get workoutAdd => 'Add Workout';

  @override
  String get workoutType => 'Type';

  @override
  String get workoutDuration => 'Duration';

  @override
  String get workoutDurationUnit => 'min';

  @override
  String get workoutDistance => 'Distance';

  @override
  String get workoutDistanceUnit => 'm';

  @override
  String get workoutCaloriesLabel => 'Calories';

  @override
  String workoutCalories(String cal) {
    return '$cal cal';
  }

  @override
  String workoutHeartRate(String bpm) {
    return '$bpm bpm';
  }

  @override
  String get workoutDate => 'Date';

  @override
  String get workoutNotes => 'Notes';

  @override
  String get workoutSave => 'Save Workout';

  @override
  String get workoutDelete => 'Delete Workout';

  @override
  String get workoutDeleteConfirmation =>
      'Are you sure you want to delete this workout?';

  @override
  String get workoutsEmpty => 'No workouts yet';

  @override
  String get workoutsEmptySubtitle =>
      'Add your first workout using the button below';

  @override
  String get errorLoadWorkouts => 'Failed to load workouts';

  @override
  String get errorSaveWorkout => 'Failed to save workout';

  @override
  String get errorDeleteWorkout => 'Failed to delete workout';

  @override
  String get bodyMetricsCurrentWeight => 'Current Weight';

  @override
  String bodyMetricsWeightKg(String weight) {
    return '$weight kg';
  }

  @override
  String bodyMetricsBodyFat(String percent) {
    return '$percent% fat';
  }

  @override
  String bodyMetricsWeightLost(String kg) {
    return '-$kg kg this week';
  }

  @override
  String bodyMetricsWeightGained(String kg) {
    return '+$kg kg this week';
  }

  @override
  String get bodyMetricAdd => 'Add Measurement';

  @override
  String get bodyMetricWeightLabel => 'Weight';

  @override
  String get bodyMetricWeightUnit => 'kg';

  @override
  String get bodyMetricBodyFatLabel => 'Body Fat %';

  @override
  String get bodyMetricBodyFatUnit => '%';

  @override
  String get bodyMetricDate => 'Date';

  @override
  String get bodyMetricNotes => 'Notes';

  @override
  String get bodyMetricSave => 'Save Measurement';

  @override
  String get bodyMetricEnterValue => 'Please enter a weight or body fat value';

  @override
  String get bodyMetricDelete => 'Delete Measurement';

  @override
  String get bodyMetricDeleteConfirmation =>
      'Are you sure you want to delete this measurement?';

  @override
  String get bodyMetricsEmpty => 'No measurements yet';

  @override
  String get bodyMetricsEmptySubtitle =>
      'Add your first weight measurement using the button below';

  @override
  String get errorLoadBodyMetrics => 'Failed to load body metrics';

  @override
  String get errorSaveBodyMetric => 'Failed to save body metric';

  @override
  String get errorDeleteBodyMetric => 'Failed to delete body metric';

  @override
  String get screenTimeTotal => 'Total Screen Time';

  @override
  String screenTimePickups(String count) {
    return '$count pickups';
  }

  @override
  String get screenTimeApps => 'Apps';

  @override
  String get screenTimeNoData => 'No screen time data';

  @override
  String get screenTimeNoDataSubtitle =>
      'Screen time data will appear here once tracking is enabled';

  @override
  String get errorLoadScreenTime => 'Failed to load screen time';

  @override
  String get hydrationTitle => 'Hydration';

  @override
  String hydrationTotal(String amount) {
    return '$amount ml';
  }

  @override
  String get hydrationAdd250ml => '+250ml';

  @override
  String get hydrationAdd500ml => '+500ml';

  @override
  String get hydrationRecent => 'Recent';

  @override
  String get settingsConnections => 'Connections';

  @override
  String get settingsStrava => 'Strava';

  @override
  String get settingsConnected => 'Connected';

  @override
  String get settingsNotConnected => 'Not connected';

  @override
  String get settingsStravaDisconnect => 'Disconnect Strava';

  @override
  String get settingsStravaDisconnectConfirm =>
      'Are you sure you want to disconnect your Strava account?';

  @override
  String get settingsDisconnect => 'Disconnect';

  @override
  String get settingsStravaDisconnected => 'Strava disconnected';

  @override
  String get settingsStravaConnected => 'Strava connected successfully';

  @override
  String get settingsStravaComingSoon => 'Strava integration coming soon';

  @override
  String get settingsTracking => 'Tracking';

  @override
  String get settingsScreenTime => 'Screen Time Monitoring';

  @override
  String get settingsScreenTimeDescription => 'Track your daily phone usage';

  @override
  String get settingsSync => 'Sync';

  @override
  String get settingsSyncStatus => 'Sync Status';

  @override
  String get settingsSynced => 'Synced';

  @override
  String settingsLastSync(String time) {
    return 'Last synced: $time';
  }

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAppVersion => 'App Version';

  @override
  String get settingsBuiltWith => 'Built With';

  @override
  String get settingsMadeBy => 'Made By';

  @override
  String get todaySectionWorkouts => 'Today\'s Workouts';

  @override
  String get todaySectionWorkoutsEmpty => 'No workouts today';

  @override
  String get todaySectionWorkoutsAdd => 'Add Workout';

  @override
  String get todaySectionHydration => 'Hydration';

  @override
  String get todaySectionBodyMetrics => 'Body Metrics';

  @override
  String get todaySectionBodyMetricsEmpty => 'No recent measurements';

  @override
  String get todaySectionCheckin => 'Daily Check-in';

  @override
  String get todayCheckinMood => 'Mood';

  @override
  String get todayCheckinEnergy => 'Energy';

  @override
  String get todayCheckinComplete => 'Complete Check-in';

  @override
  String get todayQuickAdd => 'Quick Add';
}
