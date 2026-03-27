import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// The application title displayed in the app bar
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get appTitle;

  /// Bottom navigation label for the Today tab
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// Bottom navigation label for the Meals tab
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get navMeals;

  /// Bottom navigation label for the Calendar tab
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// Bottom navigation label for the Workouts tab
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get navWorkouts;

  /// Bottom navigation label for the Settings tab
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Title displayed on the Today screen
  ///
  /// In en, this message translates to:
  /// **'Today\'s Meals'**
  String get todayTitle;

  /// Title displayed on the meal history screen
  ///
  /// In en, this message translates to:
  /// **'Meal History'**
  String get mealHistoryTitle;

  /// Title displayed on the calendar screen
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// Title displayed on the day detail screen
  ///
  /// In en, this message translates to:
  /// **'Day Details'**
  String get dayDetailTitle;

  /// Title displayed on the check-in screen
  ///
  /// In en, this message translates to:
  /// **'Daily Check-in'**
  String get checkinTitle;

  /// Title displayed on the workouts screen
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workoutsTitle;

  /// Title displayed on the body metrics screen
  ///
  /// In en, this message translates to:
  /// **'Body Metrics'**
  String get bodyMetricsTitle;

  /// Title displayed on the screen time screen
  ///
  /// In en, this message translates to:
  /// **'Screen Time'**
  String get screenTimeTitle;

  /// Title displayed on the settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Question asking user to rate their day
  ///
  /// In en, this message translates to:
  /// **'How was your day?'**
  String get howWasYourDay;

  /// Label for bad day rating option
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get ratingBad;

  /// Label for okay day rating option
  ///
  /// In en, this message translates to:
  /// **'Okay'**
  String get ratingOkay;

  /// Label for great day rating option
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get ratingGreat;

  /// Text shown when no day rating has been set
  ///
  /// In en, this message translates to:
  /// **'Not rated'**
  String get ratingNotSet;

  /// Confirmation text shown after rating is saved
  ///
  /// In en, this message translates to:
  /// **'Day rated'**
  String get ratingLogged;

  /// Subtitle prompting user to rate today
  ///
  /// In en, this message translates to:
  /// **'Tap to rate today'**
  String get dayRatingSubtitleToday;

  /// Subtitle prompting user to rate a specific day
  ///
  /// In en, this message translates to:
  /// **'Tap to rate this day'**
  String get dayRatingSubtitleDay;

  /// Section title for daily metrics (water, exercise)
  ///
  /// In en, this message translates to:
  /// **'Daily Metrics'**
  String get dailyMetrics;

  /// Text indicating a goal has been achieved
  ///
  /// In en, this message translates to:
  /// **'Goal met'**
  String get goalMet;

  /// Label for water intake metric
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get waterLabel;

  /// Label for exercise metric
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exerciseLabel;

  /// Water intake goal label
  ///
  /// In en, this message translates to:
  /// **'Goal: 2L'**
  String get waterGoal;

  /// Text shown when a metric has not been logged
  ///
  /// In en, this message translates to:
  /// **'Not logged'**
  String get notLogged;

  /// Hint text for water input field
  ///
  /// In en, this message translates to:
  /// **'Enter amount in ml'**
  String get waterHintText;

  /// Hint text for exercise input field
  ///
  /// In en, this message translates to:
  /// **'Enter exercise details'**
  String get exerciseHintText;

  /// Subtitle for today's metrics section
  ///
  /// In en, this message translates to:
  /// **'Track your progress for today'**
  String get dailyMetricsSubtitleToday;

  /// Subtitle for a specific day's metrics section
  ///
  /// In en, this message translates to:
  /// **'View metrics for this day'**
  String get dailyMetricsSubtitleDay;

  /// Water amount display with value
  ///
  /// In en, this message translates to:
  /// **'{amount} ml'**
  String waterAmount(String amount);

  /// Unit for water measurement (milliliters)
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get waterUnit;

  /// Label for breakfast meal slot
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get breakfast;

  /// Label for lunch meal slot
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get lunch;

  /// Label for afternoon snack meal slot
  ///
  /// In en, this message translates to:
  /// **'Afternoon Snack'**
  String get afternoonSnack;

  /// Label for dinner meal slot
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get dinner;

  /// Label for camera photo source option
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// Label for gallery photo source option
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// Label for replacing an existing photo
  ///
  /// In en, this message translates to:
  /// **'Replace Photo'**
  String get replacePhoto;

  /// Label for deleting a photo
  ///
  /// In en, this message translates to:
  /// **'Delete Photo'**
  String get deletePhoto;

  /// Error message when an image cannot be loaded
  ///
  /// In en, this message translates to:
  /// **'Image not found'**
  String get imageNotFound;

  /// Hint text for meal description input
  ///
  /// In en, this message translates to:
  /// **'Add a description...'**
  String get addDescriptionHint;

  /// Title for clear meal confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Clear Meal'**
  String get clearMeal;

  /// Confirmation message for clearing a meal slot
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear {slotName}?'**
  String clearMealConfirmation(String slotName);

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Clear button label to confirm clearing
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Title for empty state when no meals exist
  ///
  /// In en, this message translates to:
  /// **'No meals yet'**
  String get noMealsYet;

  /// Subtitle for empty state prompting user to add meals
  ///
  /// In en, this message translates to:
  /// **'Start by adding your first meal'**
  String get noMealsYetSubtitle;

  /// Title shown when no meals logged for selected date
  ///
  /// In en, this message translates to:
  /// **'No meals logged'**
  String get noMealsLogged;

  /// Subtitle explaining no meals exist for the selected day
  ///
  /// In en, this message translates to:
  /// **'No meals recorded for this day'**
  String get noMealsLoggedSubtitle;

  /// Error message when meals fail to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load meals'**
  String get failedToLoadMeals;

  /// Error message when calendar fails to load
  ///
  /// In en, this message translates to:
  /// **'Failed to load calendar'**
  String get failedToLoadCalendar;

  /// Generic error message for unexpected errors
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred'**
  String get unknownError;

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Text shown when a meal has no description
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get noDescription;

  /// Timestamp showing when a meal was recorded
  ///
  /// In en, this message translates to:
  /// **'Recorded at {time}'**
  String recordedAt(String time);

  /// Tooltip for clear meal action button
  ///
  /// In en, this message translates to:
  /// **'Clear this meal'**
  String get clearMealTooltip;

  /// Water amount display with goal comparison
  ///
  /// In en, this message translates to:
  /// **'{amount} / 2000 ml'**
  String waterAmountWithGoal(String amount);

  /// Dash displayed when water amount is not set
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get waterDash;

  /// Label indicating exercise was completed
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get exerciseYes;

  /// Label indicating exercise was not completed
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get exerciseNo;

  /// Dash displayed when exercise status is not set
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get exerciseDash;

  /// Suffix indicating goal has been met
  ///
  /// In en, this message translates to:
  /// **'met'**
  String get goalMetSuffix;

  /// Label for today's date
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Label for yesterday's date
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Button to navigate to today's date
  ///
  /// In en, this message translates to:
  /// **'Jump to Today'**
  String get jumpToToday;

  /// Error message when loading meals fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load meals'**
  String get errorLoadMeals;

  /// Error message when loading day rating fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load day rating'**
  String get errorLoadDayRating;

  /// Error message when loading daily metrics fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load daily metrics'**
  String get errorLoadDailyMetrics;

  /// Error message when an invalid day rating is selected
  ///
  /// In en, this message translates to:
  /// **'Invalid day rating selected'**
  String get errorInvalidDayRating;

  /// Error message when saving day rating fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save day rating'**
  String get errorSaveDayRating;

  /// Error message when saving an image fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save image'**
  String get errorSaveImage;

  /// Error message when capturing a photo fails
  ///
  /// In en, this message translates to:
  /// **'Failed to capture photo'**
  String get errorCapturePhoto;

  /// Error message when selecting an image from gallery fails
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image'**
  String get errorPickImage;

  /// Error message when saving a meal fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save meal'**
  String get errorSaveMeal;

  /// Error message when deleting a photo fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete photo'**
  String get errorDeletePhoto;

  /// Error message when clearing a meal fails
  ///
  /// In en, this message translates to:
  /// **'Failed to clear meal'**
  String get errorClearMeal;

  /// Error message when saving daily metrics fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save daily metrics'**
  String get errorSaveDailyMetrics;

  /// Error message when loading calendar data fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load calendar data'**
  String get errorLoadCalendar;

  /// Label for mood slider in check-in
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get checkinMood;

  /// Label for energy slider in check-in
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get checkinEnergy;

  /// Label for focus slider in check-in
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get checkinFocus;

  /// Label for stress slider in check-in
  ///
  /// In en, this message translates to:
  /// **'Stress'**
  String get checkinStress;

  /// Label for sleep section in check-in
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get checkinSleep;

  /// Label for sleep hours
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get checkinSleepHours;

  /// Display for sleep hours
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String checkinSleepHoursValue(String hours);

  /// Label for sleep quality
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get checkinSleepQuality;

  /// Label for notes field in check-in
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get checkinNotes;

  /// Hint text for check-in notes
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get checkinNotesHint;

  /// Button to save check-in
  ///
  /// In en, this message translates to:
  /// **'Save Check-in'**
  String get checkinSave;

  /// Confirmation message after saving check-in
  ///
  /// In en, this message translates to:
  /// **'Check-in saved'**
  String get checkinSaved;

  /// Label for lowest value on slider
  ///
  /// In en, this message translates to:
  /// **'Very Low'**
  String get checkinVeryLow;

  /// Label for low value on slider
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get checkinLow;

  /// Label for medium value on slider
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get checkinMedium;

  /// Label for high value on slider
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get checkinHigh;

  /// Label for highest value on slider
  ///
  /// In en, this message translates to:
  /// **'Very High'**
  String get checkinVeryHigh;

  /// Error message when loading check-in fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load check-in'**
  String get errorLoadCheckin;

  /// Error message when saving check-in fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save check-in'**
  String get errorSaveCheckin;

  /// Title for add workout sheet
  ///
  /// In en, this message translates to:
  /// **'Add Workout'**
  String get workoutAdd;

  /// Label for workout type
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get workoutType;

  /// Label for workout duration
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get workoutDuration;

  /// Unit for workout duration (minutes)
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get workoutDurationUnit;

  /// Label for workout distance
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get workoutDistance;

  /// Unit for workout distance (meters)
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get workoutDistanceUnit;

  /// Label for workout calories input
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get workoutCaloriesLabel;

  /// Display for workout calories
  ///
  /// In en, this message translates to:
  /// **'{cal} cal'**
  String workoutCalories(String cal);

  /// Display for workout heart rate
  ///
  /// In en, this message translates to:
  /// **'{bpm} bpm'**
  String workoutHeartRate(String bpm);

  /// Label for workout date
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get workoutDate;

  /// Label for workout notes
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get workoutNotes;

  /// Button to save workout
  ///
  /// In en, this message translates to:
  /// **'Save Workout'**
  String get workoutSave;

  /// Title for delete workout confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete Workout'**
  String get workoutDelete;

  /// Confirmation message for deleting a workout
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this workout?'**
  String get workoutDeleteConfirmation;

  /// Title for empty state when no workouts exist
  ///
  /// In en, this message translates to:
  /// **'No workouts yet'**
  String get workoutsEmpty;

  /// Subtitle for empty workouts state
  ///
  /// In en, this message translates to:
  /// **'Add your first workout using the button below'**
  String get workoutsEmptySubtitle;

  /// Error message when loading workouts fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load workouts'**
  String get errorLoadWorkouts;

  /// Error message when saving workout fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save workout'**
  String get errorSaveWorkout;

  /// Error message when deleting workout fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete workout'**
  String get errorDeleteWorkout;

  /// Label for current weight display
  ///
  /// In en, this message translates to:
  /// **'Current Weight'**
  String get bodyMetricsCurrentWeight;

  /// Display for weight in kilograms
  ///
  /// In en, this message translates to:
  /// **'{weight} kg'**
  String bodyMetricsWeightKg(String weight);

  /// Display for body fat percentage
  ///
  /// In en, this message translates to:
  /// **'{percent}% fat'**
  String bodyMetricsBodyFat(String percent);

  /// Display for weight lost
  ///
  /// In en, this message translates to:
  /// **'-{kg} kg this week'**
  String bodyMetricsWeightLost(String kg);

  /// Display for weight gained
  ///
  /// In en, this message translates to:
  /// **'+{kg} kg this week'**
  String bodyMetricsWeightGained(String kg);

  /// Title for add body metric sheet
  ///
  /// In en, this message translates to:
  /// **'Add Measurement'**
  String get bodyMetricAdd;

  /// Label for weight input
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get bodyMetricWeightLabel;

  /// Unit for weight (kilograms)
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get bodyMetricWeightUnit;

  /// Label for body fat percentage input
  ///
  /// In en, this message translates to:
  /// **'Body Fat %'**
  String get bodyMetricBodyFatLabel;

  /// Unit for body fat percentage
  ///
  /// In en, this message translates to:
  /// **'%'**
  String get bodyMetricBodyFatUnit;

  /// Label for measurement date
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get bodyMetricDate;

  /// Label for body metric notes
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get bodyMetricNotes;

  /// Button to save body metric
  ///
  /// In en, this message translates to:
  /// **'Save Measurement'**
  String get bodyMetricSave;

  /// Error when no value is entered
  ///
  /// In en, this message translates to:
  /// **'Please enter a weight or body fat value'**
  String get bodyMetricEnterValue;

  /// Title for delete body metric confirmation
  ///
  /// In en, this message translates to:
  /// **'Delete Measurement'**
  String get bodyMetricDelete;

  /// Confirmation message for deleting a body metric
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this measurement?'**
  String get bodyMetricDeleteConfirmation;

  /// Title for empty state when no body metrics exist
  ///
  /// In en, this message translates to:
  /// **'No measurements yet'**
  String get bodyMetricsEmpty;

  /// Subtitle for empty body metrics state
  ///
  /// In en, this message translates to:
  /// **'Add your first weight measurement using the button below'**
  String get bodyMetricsEmptySubtitle;

  /// Error message when loading body metrics fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load body metrics'**
  String get errorLoadBodyMetrics;

  /// Error message when saving body metric fails
  ///
  /// In en, this message translates to:
  /// **'Failed to save body metric'**
  String get errorSaveBodyMetric;

  /// Error message when deleting body metric fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete body metric'**
  String get errorDeleteBodyMetric;

  /// Label for total screen time
  ///
  /// In en, this message translates to:
  /// **'Total Screen Time'**
  String get screenTimeTotal;

  /// Display for number of pickups
  ///
  /// In en, this message translates to:
  /// **'{count} pickups'**
  String screenTimePickups(String count);

  /// Section header for apps list
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get screenTimeApps;

  /// Title for empty state when no screen time data
  ///
  /// In en, this message translates to:
  /// **'No screen time data'**
  String get screenTimeNoData;

  /// Subtitle for empty screen time state
  ///
  /// In en, this message translates to:
  /// **'Screen time data will appear here once tracking is enabled'**
  String get screenTimeNoDataSubtitle;

  /// Error message when loading screen time fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load screen time'**
  String get errorLoadScreenTime;

  /// Title for hydration widget
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get hydrationTitle;

  /// Display for total hydration
  ///
  /// In en, this message translates to:
  /// **'{amount} ml'**
  String hydrationTotal(String amount);

  /// Button to add 250ml of water
  ///
  /// In en, this message translates to:
  /// **'+250ml'**
  String get hydrationAdd250ml;

  /// Button to add 500ml of water
  ///
  /// In en, this message translates to:
  /// **'+500ml'**
  String get hydrationAdd500ml;

  /// Label for recent hydration entries
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get hydrationRecent;

  /// Section header for connected services
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get settingsConnections;

  /// Strava connection setting
  ///
  /// In en, this message translates to:
  /// **'Strava'**
  String get settingsStrava;

  /// Label when a service is connected
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get settingsConnected;

  /// Label when a service is not connected
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get settingsNotConnected;

  /// Title for disconnect Strava confirmation
  ///
  /// In en, this message translates to:
  /// **'Disconnect Strava'**
  String get settingsStravaDisconnect;

  /// Confirmation message for disconnecting Strava
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disconnect your Strava account?'**
  String get settingsStravaDisconnectConfirm;

  /// Button to disconnect a service
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get settingsDisconnect;

  /// Message when Strava is disconnected
  ///
  /// In en, this message translates to:
  /// **'Strava disconnected'**
  String get settingsStravaDisconnected;

  /// Message when Strava is connected
  ///
  /// In en, this message translates to:
  /// **'Strava connected successfully'**
  String get settingsStravaConnected;

  /// Message when Strava feature is not yet available
  ///
  /// In en, this message translates to:
  /// **'Strava integration coming soon'**
  String get settingsStravaComingSoon;

  /// Section header for tracking settings
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get settingsTracking;

  /// Screen time monitoring toggle setting
  ///
  /// In en, this message translates to:
  /// **'Screen Time Monitoring'**
  String get settingsScreenTime;

  /// Description for screen time setting
  ///
  /// In en, this message translates to:
  /// **'Track your daily phone usage'**
  String get settingsScreenTimeDescription;

  /// Dialog title shown before opening Android usage access settings
  ///
  /// In en, this message translates to:
  /// **'Screen time access'**
  String get settingsScreenTimePermissionTitle;

  /// Dialog message explaining the Android usage access permission
  ///
  /// In en, this message translates to:
  /// **'To track your screen time, v32 needs access to your app usage data. You\'ll be redirected to Android settings to grant this permission.'**
  String get settingsScreenTimePermissionMessage;

  /// Button label that opens Android usage access settings
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get settingsScreenTimeOpenSettings;

  /// Snackbar shown when Android usage access permission has been granted
  ///
  /// In en, this message translates to:
  /// **'Screen time access enabled'**
  String get settingsScreenTimePermissionGranted;

  /// Settings row label that opens the screen time screen
  ///
  /// In en, this message translates to:
  /// **'Open screen time'**
  String get settingsScreenTimeOpen;

  /// Settings row subtitle that opens the screen time screen
  ///
  /// In en, this message translates to:
  /// **'View today\'s screen time breakdown'**
  String get settingsScreenTimeOpenDescription;

  /// Section header for sync settings
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get settingsSync;

  /// Label for sync status
  ///
  /// In en, this message translates to:
  /// **'Sync Status'**
  String get settingsSyncStatus;

  /// Label when data is synced
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get settingsSynced;

  /// Display for last sync time
  ///
  /// In en, this message translates to:
  /// **'Last synced: {time}'**
  String settingsLastSync(String time);

  /// Section header for about information
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Label for app version
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get settingsAppVersion;

  /// Label for technology used
  ///
  /// In en, this message translates to:
  /// **'Built With'**
  String get settingsBuiltWith;

  /// Label for app creator
  ///
  /// In en, this message translates to:
  /// **'Made By'**
  String get settingsMadeBy;

  /// Section title for today's workouts on dashboard
  ///
  /// In en, this message translates to:
  /// **'Today\'s Workouts'**
  String get todaySectionWorkouts;

  /// Message when no workouts logged today
  ///
  /// In en, this message translates to:
  /// **'No workouts today'**
  String get todaySectionWorkoutsEmpty;

  /// Button to add workout from today screen
  ///
  /// In en, this message translates to:
  /// **'Add Workout'**
  String get todaySectionWorkoutsAdd;

  /// Section title for hydration on dashboard
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get todaySectionHydration;

  /// Section title for body metrics on dashboard
  ///
  /// In en, this message translates to:
  /// **'Body Metrics'**
  String get todaySectionBodyMetrics;

  /// Message when no body metrics available
  ///
  /// In en, this message translates to:
  /// **'No recent measurements'**
  String get todaySectionBodyMetricsEmpty;

  /// Section title for check-in on dashboard
  ///
  /// In en, this message translates to:
  /// **'Daily Check-in'**
  String get todaySectionCheckin;

  /// Quick check-in button for mood
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get todayCheckinMood;

  /// Quick check-in button for energy
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get todayCheckinEnergy;

  /// Button to complete full check-in
  ///
  /// In en, this message translates to:
  /// **'Complete Check-in'**
  String get todayCheckinComplete;

  /// Label for quick add buttons
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get todayQuickAdd;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
