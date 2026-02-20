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
    Locale('fr'),
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
    'that was used.',
  );
}
