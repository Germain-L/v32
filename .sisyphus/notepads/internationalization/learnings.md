# Internationalization Learnings

## ARB File Structure

### Key Components
- `@@locale`: Defines the locale (e.g., "en", "fr")
- Translation keys: The actual strings to translate
- Metadata keys: `@keyName` with description and optional placeholders

### Placeholder Syntax (ICU Message Format)
```json
"keyName": "Hello {name}",
"@keyName": {
  "description": "Greeting with name",
  "placeholders": {
    "name": {
      "type": "String",
      "example": "John"
    }
  }
}
```

## French Translation Patterns

### Natural vs Literal Translations
- Use "Goûter" not "Collation de l'après-midi" for "Afternoon Snack"
- Use "Déjeuner" for "Lunch" (not literal translation)
- Use "Petit-déjeuner" for "Breakfast"
- Use formal register: "votre", "vouloir" not "ton", "vouloir"

### Error Message Pattern
French error messages follow pattern: "Échec du [action]..."
- "Échec du chargement des repas"
- "Échec de l'enregistrement"

### Typography
- Accents on capital letters: É, À
- Cedilla: ç
- French quotes: « » (not used here, but good to know)

## Validation Workflow

1. **JSON Validation**: Use Python's json module to parse ARB files
2. **Key Matching**: Ensure both locale files have identical key sets
3. **Flutter Integration**: Run `flutter gen-l10n` to verify integration
4. **Metadata Count**: Should match translation key count (one @key per key)

## Key Organization Strategy

Group keys by functional area:
- Navigation (navToday, navMeals, navCalendar)
- Screen titles (todayTitle, mealHistoryTitle)
- Actions (cancel, clear, retry)
- Error states (failedToLoadMeals, unknownError)
- Provider errors (errorLoadMeals, errorSaveMeal)

This makes it easier to maintain and find strings.
2026-02-20T11:58:33Z - Fixed import paths in app.dart and l10n_helper.dart to use relative imports (../gen_l10n/ instead of package:flutter_gen/)
