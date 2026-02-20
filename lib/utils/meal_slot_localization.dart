import '../data/models/meal.dart';
import '../gen_l10n/app_localizations.dart';

extension MealSlotLocalization on MealSlot {
  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case MealSlot.breakfast:
        return l10n.breakfast;
      case MealSlot.lunch:
        return l10n.lunch;
      case MealSlot.afternoonSnack:
        return l10n.afternoonSnack;
      case MealSlot.dinner:
        return l10n.dinner;
    }
  }
}
