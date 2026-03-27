// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Diet';

  @override
  String get navToday => 'Aujourd\'hui';

  @override
  String get navMeals => 'Repas';

  @override
  String get navCalendar => 'Calendrier';

  @override
  String get navWorkouts => 'Exercices';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get todayTitle => 'Repas du jour';

  @override
  String get mealHistoryTitle => 'Historique des repas';

  @override
  String get calendarTitle => 'Calendrier';

  @override
  String get dayDetailTitle => 'Détails du jour';

  @override
  String get checkinTitle => 'Check-in quotidien';

  @override
  String get workoutsTitle => 'Exercices';

  @override
  String get bodyMetricsTitle => 'Métriques corporelles';

  @override
  String get screenTimeTitle => 'Temps d\'écran';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get howWasYourDay => 'Comment s\'est passée votre journée ?';

  @override
  String get ratingBad => 'Mauvaise';

  @override
  String get ratingOkay => 'Moyenne';

  @override
  String get ratingGreat => 'Super';

  @override
  String get ratingNotSet => 'Non notée';

  @override
  String get ratingLogged => 'Journée notée';

  @override
  String get dayRatingSubtitleToday => 'Appuyez pour noter aujourd\'hui';

  @override
  String get dayRatingSubtitleDay => 'Appuyez pour noter cette journée';

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
  String get waterHintText => 'Entrez la quantité en ml';

  @override
  String get exerciseHintText => 'Entrez les détails de l\'exercice';

  @override
  String get dailyMetricsSubtitleToday =>
      'Suivez vos progrès pour aujourd\'hui';

  @override
  String get dailyMetricsSubtitleDay => 'Voir les métriques pour ce jour';

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
  String get afternoonSnack => 'Collation';

  @override
  String get dinner => 'Dîner';

  @override
  String get camera => 'Caméra';

  @override
  String get gallery => 'Galerie';

  @override
  String get replacePhoto => 'Remplacer la photo';

  @override
  String get deletePhoto => 'Supprimer la photo';

  @override
  String get imageNotFound => 'Image non trouvée';

  @override
  String get addDescriptionHint => 'Ajouter une description...';

  @override
  String get clearMeal => 'Effacer le repas';

  @override
  String clearMealConfirmation(String slotName) {
    return 'Voulez-vous vraiment effacer $slotName ?';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get clear => 'Effacer';

  @override
  String get noMealsYet => 'Pas encore de repas';

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
  String get noDescription => 'Pas de description';

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
  String get errorLoadDayRating => 'Échec du chargement de la note du jour';

  @override
  String get errorLoadDailyMetrics => 'Échec du chargement des métriques';

  @override
  String get errorInvalidDayRating => 'Note du jour invalide';

  @override
  String get errorSaveDayRating => 'Échec de l\'enregistrement de la note';

  @override
  String get errorSaveImage => 'Échec de l\'enregistrement de l\'image';

  @override
  String get errorCapturePhoto => 'Échec de la capture photo';

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

  @override
  String get checkinMood => 'Humeur';

  @override
  String get checkinEnergy => 'Énergie';

  @override
  String get checkinFocus => 'Concentration';

  @override
  String get checkinStress => 'Stress';

  @override
  String get checkinSleep => 'Sommeil';

  @override
  String get checkinSleepHours => 'Heures';

  @override
  String checkinSleepHoursValue(String hours) {
    return '${hours}h';
  }

  @override
  String get checkinSleepQuality => 'Qualité';

  @override
  String get checkinNotes => 'Notes';

  @override
  String get checkinNotesHint => 'Comment vous sentez-vous aujourd\'hui ?';

  @override
  String get checkinSave => 'Enregistrer le check-in';

  @override
  String get checkinSaved => 'Check-in enregistré';

  @override
  String get checkinVeryLow => 'Très bas';

  @override
  String get checkinLow => 'Bas';

  @override
  String get checkinMedium => 'Moyen';

  @override
  String get checkinHigh => 'Élevé';

  @override
  String get checkinVeryHigh => 'Très élevé';

  @override
  String get errorLoadCheckin => 'Échec du chargement du check-in';

  @override
  String get errorSaveCheckin => 'Échec de l\'enregistrement du check-in';

  @override
  String get workoutAdd => 'Ajouter un exercice';

  @override
  String get workoutType => 'Type';

  @override
  String get workoutDuration => 'Durée';

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
  String get workoutSave => 'Enregistrer l\'exercice';

  @override
  String get workoutDelete => 'Supprimer l\'exercice';

  @override
  String get workoutDeleteConfirmation =>
      'Voulez-vous vraiment supprimer cet exercice ?';

  @override
  String get workoutsEmpty => 'Pas encore d\'exercices';

  @override
  String get workoutsEmptySubtitle =>
      'Ajoutez votre premier exercice avec le bouton ci-dessous';

  @override
  String get errorLoadWorkouts => 'Échec du chargement des exercices';

  @override
  String get errorSaveWorkout => 'Échec de l\'enregistrement de l\'exercice';

  @override
  String get errorDeleteWorkout => 'Échec de la suppression de l\'exercice';

  @override
  String get bodyMetricsCurrentWeight => 'Poids actuel';

  @override
  String bodyMetricsWeightKg(String weight) {
    return '$weight kg';
  }

  @override
  String bodyMetricsBodyFat(String percent) {
    return '$percent% gras';
  }

  @override
  String bodyMetricsWeightLost(String kg) {
    return '-$kg kg cette semaine';
  }

  @override
  String bodyMetricsWeightGained(String kg) {
    return '+$kg kg cette semaine';
  }

  @override
  String get bodyMetricAdd => 'Ajouter une mesure';

  @override
  String get bodyMetricWeightLabel => 'Poids';

  @override
  String get bodyMetricWeightUnit => 'kg';

  @override
  String get bodyMetricBodyFatLabel => 'Graisse corporelle %';

  @override
  String get bodyMetricBodyFatUnit => '%';

  @override
  String get bodyMetricDate => 'Date';

  @override
  String get bodyMetricNotes => 'Notes';

  @override
  String get bodyMetricSave => 'Enregistrer la mesure';

  @override
  String get bodyMetricEnterValue =>
      'Veuillez entrer un poids ou un pourcentage de graisse';

  @override
  String get bodyMetricDelete => 'Supprimer la mesure';

  @override
  String get bodyMetricDeleteConfirmation =>
      'Voulez-vous vraiment supprimer cette mesure ?';

  @override
  String get bodyMetricsEmpty => 'Pas encore de mesures';

  @override
  String get bodyMetricsEmptySubtitle =>
      'Ajoutez votre première mesure de poids avec le bouton ci-dessous';

  @override
  String get errorLoadBodyMetrics =>
      'Échec du chargement des métriques corporelles';

  @override
  String get errorSaveBodyMetric => 'Échec de l\'enregistrement de la mesure';

  @override
  String get errorDeleteBodyMetric => 'Échec de la suppression de la mesure';

  @override
  String get screenTimeTotal => 'Temps d\'écran total';

  @override
  String screenTimePickups(String count) {
    return '$count consultations';
  }

  @override
  String get screenTimeApps => 'Applications';

  @override
  String get screenTimeNoData => 'Pas de données de temps d\'écran';

  @override
  String get screenTimeNoDataSubtitle =>
      'Les données de temps d\'écran apparaîtront ici une fois le suivi activé';

  @override
  String get errorLoadScreenTime => 'Échec du chargement du temps d\'écran';

  @override
  String get hydrationTitle => 'Hydratation';

  @override
  String hydrationTotal(String amount) {
    return '$amount ml';
  }

  @override
  String get hydrationAdd250ml => '+250ml';

  @override
  String get hydrationAdd500ml => '+500ml';

  @override
  String get hydrationRecent => 'Récent';

  @override
  String get settingsConnections => 'Connexions';

  @override
  String get settingsStrava => 'Strava';

  @override
  String get settingsConnected => 'Connecté';

  @override
  String get settingsNotConnected => 'Non connecté';

  @override
  String get settingsStravaDisconnect => 'Déconnecter Strava';

  @override
  String get settingsStravaDisconnectConfirm =>
      'Voulez-vous vraiment déconnecter votre compte Strava ?';

  @override
  String get settingsDisconnect => 'Déconnecter';

  @override
  String get settingsStravaDisconnected => 'Strava déconnecté';

  @override
  String get settingsStravaConnected => 'Strava connecté avec succès';

  @override
  String get settingsStravaComingSoon =>
      'Intégration Strava bientôt disponible';

  @override
  String get settingsTracking => 'Suivi';

  @override
  String get settingsScreenTime => 'Surveillance du temps d\'écran';

  @override
  String get settingsScreenTimeDescription =>
      'Suivez votre utilisation quotidienne du téléphone';

  @override
  String get settingsScreenTimePermissionTitle => 'Accès au temps d\'écran';

  @override
  String get settingsScreenTimePermissionMessage =>
      'Pour suivre votre temps d\'écran, v32 a besoin d\'accéder à vos données d\'utilisation des applications. Vous serez redirigé vers les réglages Android pour accorder cette permission.';

  @override
  String get settingsScreenTimeOpenSettings => 'Ouvrir les réglages';

  @override
  String get settingsScreenTimePermissionGranted =>
      'Accès au temps d\'écran activé';

  @override
  String get settingsScreenTimeOpen => 'Ouvrir le temps d\'écran';

  @override
  String get settingsScreenTimeOpenDescription =>
      'Voir le détail du temps d\'écran du jour';

  @override
  String get settingsSync => 'Synchronisation';

  @override
  String get settingsSyncStatus => 'État de la synchronisation';

  @override
  String get settingsSynced => 'Synchronisé';

  @override
  String settingsLastSync(String time) {
    return 'Dernière sync : $time';
  }

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsAppVersion => 'Version de l\'application';

  @override
  String get settingsBuiltWith => 'Créé avec';

  @override
  String get settingsMadeBy => 'Créé par';

  @override
  String get todaySectionWorkouts => 'Exercices du jour';

  @override
  String get todaySectionWorkoutsEmpty => 'Pas d\'exercice aujourd\'hui';

  @override
  String get todaySectionWorkoutsAdd => 'Ajouter un exercice';

  @override
  String get todaySectionHydration => 'Hydratation';

  @override
  String get todaySectionBodyMetrics => 'Métriques corporelles';

  @override
  String get todaySectionBodyMetricsEmpty => 'Pas de mesures récentes';

  @override
  String get todaySectionCheckin => 'Check-in quotidien';

  @override
  String get todayCheckinMood => 'Humeur';

  @override
  String get todayCheckinEnergy => 'Énergie';

  @override
  String get todayCheckinComplete => 'Compléter le check-in';

  @override
  String get todayQuickAdd => 'Ajout rapide';
}
