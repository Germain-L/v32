// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Régime';

  @override
  String get navToday => 'Aujourd\'hui';

  @override
  String get navMeals => 'Repas';

  @override
  String get navCalendar => 'Calendrier';

  @override
  String get todayTitle => 'Repas du jour';

  @override
  String get mealHistoryTitle => 'Historique des repas';

  @override
  String get calendarTitle => 'Calendrier';

  @override
  String get dayDetailTitle => 'Détails du jour';

  @override
  String get howWasYourDay => 'Comment s\'est passée votre journée ?';

  @override
  String get ratingBad => 'Mauvaise';

  @override
  String get ratingOkay => 'Correcte';

  @override
  String get ratingGreat => 'Excellente';

  @override
  String get ratingNotSet => 'Non évaluée';

  @override
  String get ratingLogged => 'Journée évaluée';

  @override
  String get dayRatingSubtitleToday => 'Appuyez pour évaluer aujourd\'hui';

  @override
  String get dayRatingSubtitleDay => 'Appuyez pour évaluer ce jour';

  @override
  String get dailyMetrics => 'Métriques quotidiennes';

  @override
  String get goalMet => 'Objectif atteint';

  @override
  String get waterLabel => 'Eau';

  @override
  String get exerciseLabel => 'Exercice';

  @override
  String get waterGoal => 'Objectif : 2L';

  @override
  String get notLogged => 'Non enregistré';

  @override
  String get waterHintText => 'Saisissez la quantité en ml';

  @override
  String get exerciseHintText => 'Saisissez les détails de l\'exercice';

  @override
  String get dailyMetricsSubtitleToday =>
      'Suivez vos progrès pour aujourd\'hui';

  @override
  String get dailyMetricsSubtitleDay => 'Consultez les métriques pour ce jour';

  @override
  String waterAmount(String amount) {
    return '$amount ml';
  }

  @override
  String get waterUnit => 'ml';

  @override
  String get breakfast => 'Petit-déjeuner';

  @override
  String get lunch => 'Déjeuner';

  @override
  String get afternoonSnack => 'Goûter';

  @override
  String get dinner => 'Dîner';

  @override
  String get camera => 'Appareil photo';

  @override
  String get gallery => 'Galerie';

  @override
  String get replacePhoto => 'Remplacer la photo';

  @override
  String get deletePhoto => 'Supprimer la photo';

  @override
  String get imageNotFound => 'Image introuvable';

  @override
  String get addDescriptionHint => 'Ajoutez une description...';

  @override
  String get clearMeal => 'Effacer le repas';

  @override
  String clearMealConfirmation(String slotName) {
    return 'Êtes-vous sûr de vouloir effacer $slotName ?';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get clear => 'Effacer';

  @override
  String get noMealsYet => 'Aucun repas encore';

  @override
  String get noMealsYetSubtitle => 'Commencez par ajouter votre premier repas';

  @override
  String get noMealsLogged => 'Aucun repas enregistré';

  @override
  String get noMealsLoggedSubtitle => 'Aucun repas enregistré pour ce jour';

  @override
  String get failedToLoadMeals => 'Échec du chargement des repas';

  @override
  String get failedToLoadCalendar => 'Échec du chargement du calendrier';

  @override
  String get unknownError => 'Une erreur inconnue s\'est produite';

  @override
  String get retry => 'Réessayer';

  @override
  String get noDescription => 'Aucune description';

  @override
  String recordedAt(String time) {
    return 'Enregistré à $time';
  }

  @override
  String get clearMealTooltip => 'Effacer ce repas';

  @override
  String waterAmountWithGoal(String amount) {
    return '$amount / 2000 ml';
  }

  @override
  String get waterDash => '—';

  @override
  String get exerciseYes => 'Oui';

  @override
  String get exerciseNo => 'Non';

  @override
  String get exerciseDash => '—';

  @override
  String get goalMetSuffix => 'atteint';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get jumpToToday => 'Aller à aujourd\'hui';

  @override
  String get errorLoadMeals => 'Échec du chargement des repas';

  @override
  String get errorLoadDayRating =>
      'Échec du chargement de l\'évaluation de la journée';

  @override
  String get errorLoadDailyMetrics =>
      'Échec du chargement des métriques quotidiennes';

  @override
  String get errorInvalidDayRating =>
      'Évaluation de journée invalide sélectionnée';

  @override
  String get errorSaveDayRating =>
      'Échec de l\'enregistrement de l\'évaluation';

  @override
  String get errorSaveImage => 'Échec de l\'enregistrement de l\'image';

  @override
  String get errorCapturePhoto => 'Échec de la capture de la photo';

  @override
  String get errorPickImage => 'Échec de la sélection de l\'image';

  @override
  String get errorSaveMeal => 'Échec de l\'enregistrement du repas';

  @override
  String get errorDeletePhoto => 'Échec de la suppression de la photo';

  @override
  String get errorClearMeal => 'Échec de l\'effacement du repas';

  @override
  String get errorSaveDailyMetrics =>
      'Échec de l\'enregistrement des métriques';

  @override
  String get errorLoadCalendar =>
      'Échec du chargement des données du calendrier';
}
