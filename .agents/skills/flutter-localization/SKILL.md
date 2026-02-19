---
name: flutter-localization
description: Internationalization and localization patterns using the intl package
license: MIT
compatibility: opencode
metadata:
  category: localization
  framework: flutter
---

## What I Do

Provide localization patterns for Flutter apps using the intl package, including date formatting, translations, and locale support.

## When to Use Me

Use this skill when:
- Setting up app internationalization
- Formatting dates for different locales
- Translating meal slot names
- Supporting multiple languages
- Localizing date pickers and UI elements

## Localization Patterns

### 1. Setup intl Package

```dart
// pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.2

flutter:
  generate: true
```

```dart
// l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-dir: lib/generated
```

### 2. Create ARB Files

```json
// lib/l10n/app_en.arb
{
  "@@locale": "en",
  "appTitle": "Diet Tracker",
  "@appTitle": {
    "description": "The app title"
  },
  
  "breakfast": "Breakfast",
  "lunch": "Lunch",
  "afternoonSnack": "Afternoon Snack",
  "dinner": "Dinner",
  
  "today": "Today",
  "meals": "Meals",
  "calendar": "Calendar",
  
  "addPhoto": "Add Photo",
  "addDescription": "Add a description...",
  
  "mealAdded": "Meal added successfully",
  "mealUpdated": "Meal updated",
  "mealDeleted": "Meal deleted",
  
  "noMealsToday": "No meals recorded today",
  "noMealsHistory": "No meals in history",
  
  "dateFormat": "MMMM d, yyyy",
  "timeFormat": "h:mm a",
  "dateTimeFormat": "MMMM d, yyyy 'at' h:mm a"
}
```

```json
// lib/l10n/app_pt.arb
{
  "@@locale": "pt",
  "appTitle": "Rastreador de Dieta",
  "breakfast": "Café da Manhã",
  "lunch": "Almoço",
  "afternoonSnack": "Lanche da Tarde",
  "dinner": "Jantar",
  "today": "Hoje",
  "meals": "Refeições",
  "calendar": "Calendário",
  "addPhoto": "Adicionar Foto",
  "addDescription": "Adicione uma descrição...",
  "mealAdded": "Refeição adicionada com sucesso",
  "mealUpdated": "Refeição atualizada",
  "mealDeleted": "Refeição excluída",
  "noMealsToday": "Nenhuma refeição registrada hoje",
  "noMealsHistory": "Nenhuma refeição no histórico",
  "dateFormat": "d 'de' MMMM 'de' yyyy",
  "timeFormat": "HH:mm",
  "dateTimeFormat": "d 'de' MMMM 'de' yyyy 'às' HH:mm"
}
```

### 3. Configure App Localization

```dart
// lib/app.dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DietApp extends StatelessWidget {
  const DietApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('pt'),
        Locale('es'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        // Fall back to English if locale not supported
        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return const Locale('en');
      },
      home: const MainScreen(),
    );
  }
}
```

### 4. Meal Slot Localization

```dart
// lib/utils/meal_slot_localization.dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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

// Usage in widgets
class MealSlotWidget extends StatelessWidget {
  final MealSlot slot;
  
  const MealSlotWidget({super.key, required this.slot});
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Chip(
      label: Text(slot.localizedName(l10n)),
    );
  }
}
```

### 5. Date Formatting

```dart
// lib/utils/date_formatter.dart
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DateFormatter {
  final String locale;
  
  DateFormatter(this.locale);
  
  String formatDate(DateTime date) {
    return DateFormat.yMMMMd(locale).format(date);
  }
  
  String formatTime(DateTime date) {
    return DateFormat.jm(locale).format(date);
  }
  
  String formatDateTime(DateTime date) {
    return DateFormat.yMMMMd(locale).add_jm().format(date);
  }
  
  String formatShortDate(DateTime date) {
    return DateFormat.MMMd(locale).format(date);
  }
  
  String formatWeekday(DateTime date) {
    return DateFormat.EEEE(locale).format(date);
  }
  
  String formatRelative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateDay).inDays;
    
    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return DateFormat.EEEE(locale).format(date);
    } else {
      return formatDate(date);
    }
  }
}

// Usage with context
extension DateFormatting on BuildContext {
  String formatDate(DateTime date) {
    final locale = Localizations.localeOf(this).toString();
    return DateFormatter(locale).formatDate(date);
  }
  
  String formatRelative(DateTime date) {
    final locale = Localizations.localeOf(this).toString();
    final formatter = DateFormatter(locale);
    
    // Check if it's today/yesterday in current locale
    final l10n = AppLocalizations.of(this)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    final difference = today.difference(dateDay).inDays;
    
    if (difference == 0) return l10n.today;
    
    return formatter.formatRelative(date);
  }
}
```

### 6. Localized Date Picker

```dart
// lib/presentation/widgets/localized_date_picker.dart
Future<DateTime?> showLocalizedDatePicker(
  BuildContext context, {
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final locale = Localizations.localeOf(context);
  
  return showDatePicker(
    context: context,
    initialDate: initialDate ?? DateTime.now(),
    firstDate: firstDate ?? DateTime(2000),
    lastDate: lastDate ?? DateTime(2100),
    locale: locale,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          // Ensure proper localization
          appBarTheme: Theme.of(context).appBarTheme,
        ),
        child: child!,
      );
    },
  );
}

// Usage
final selectedDate = await showLocalizedDatePicker(
  context,
  initialDate: DateTime.now(),
);
```

### 7. Translation Helper

```dart
// lib/utils/l10n_helper.dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension L10nHelper on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

// Usage throughout the app
class MealListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.meals),
      ),
      body: meals.isEmpty
        ? Center(child: Text(context.l10n.noMealsHistory))
        : ListView(...),
    );
  }
}
```

## Best Practices

- Always provide context to translation keys
- Use placeholder values for dynamic content: "mealCount": "{count} meals"
- Test date formatting with different locales
- Support RTL languages if targeting those markets
- Use localeResolutionCallback for fallback handling
- Keep ARB files organized and well-documented
- Use DateFormat for consistent date/time display
- Generate localization files with `flutter gen-l10n`
- Provide complete translations for all supported languages
- Consider using select statements for pluralization: "mealCount": "{count, plural, =0{No meals} =1{1 meal} other{{count} meals}}"