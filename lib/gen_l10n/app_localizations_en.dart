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
  String get todayTitle => 'Today\'s Meals';

  @override
  String get mealHistoryTitle => 'Meal History';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get dayDetailTitle => 'Day Details';

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
}
