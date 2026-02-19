# Flutter Development Rules

## Project Overview
This is a Flutter application for diet/food tracking using:
- **Database**: Isar (NoSQL database for Flutter)
- **Routing**: go_router
- **State Management**: TBD (recommend Riverpod or Bloc)
- **Localization**: intl package
- **Image Handling**: image_picker and image packages

## Architecture Guidelines

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── app.dart                  # Root widget
├── config/                   # App configuration
│   ├── routes.dart          # GoRouter configuration
│   └── theme.dart           # Theme configuration
├── data/                     # Data layer
│   ├── models/              # Isar entity models
│   ├── repositories/        # Data repositories
│   └── services/            # Data services
├── presentation/             # UI layer
│   ├── screens/             # App screens
│   ├── widgets/             # Reusable widgets
│   └── providers/           # State management
└── utils/                    # Utilities
    ├── constants.dart
    ├── extensions.dart
    └── helpers.dart
```

### State Management Rules
1. Use **Riverpod** or **Bloc** for state management
2. Keep business logic out of widgets
3. Use immutable state classes
4. Implement proper loading/error states

### Database Rules (Isar)
1. Annotate all model classes with `@collection`
2. Use proper index annotations for query optimization
3. Implement toJson/fromJson for serialization
4. Handle database migrations properly

### Widget Guidelines
1. Keep widgets small and focused (single responsibility)
2. Use `const` constructors where possible
3. Extract reusable widgets into separate files
4. Implement proper responsive design
5. Support both light and dark themes

### Code Quality
1. Run `flutter analyze` before committing
2. Run `flutter format` to ensure consistent formatting
3. Write widget tests for custom widgets
4. Keep code coverage above 80%

### Performance Guidelines
1. Minimize widget rebuilds using const constructors
2. Use `ListView.builder` for long lists
3. Implement lazy loading for images
4. Cache expensive computations
5. Use `RepaintBoundary` for complex widgets that don't change often

### Naming Conventions
- Files: snake_case (e.g., `home_screen.dart`)
- Classes: PascalCase (e.g., `HomeScreen`)
- Variables/Functions: camelCase (e.g., `userName`, `getData()`)
- Constants: UPPER_SNAKE_CASE or camelCase with `k` prefix
- Private members: Leading underscore (e.g., `_privateVar`)

### Dependencies
- Always use `flutter pub add` to add dependencies
- Keep dependencies up to date
- Pin critical dependencies to specific versions
- Prefer official Flutter packages over third-party when possible

### Navigation
- Use `go_router` for all navigation
- Define all routes in a single configuration
- Use type-safe routes with code generation when possible
- Implement deep linking support

### Error Handling
1. Use `try-catch` blocks for async operations
2. Implement proper error boundaries
3. Show user-friendly error messages
4. Log errors for debugging

### Accessibility
1. Ensure proper contrast ratios
2. Add semantic labels to all interactive widgets
3. Support screen readers
4. Implement proper focus management

## MCP Tools Usage

When working on this project, you can use these MCP tools:

1. **pubdev** - Search for packages on pub.dev:
   ```
   Search for state management packages using pubdev
   ```

2. **git** - Git operations (already integrated with OpenCode)

3. **memory** - Store project context and decisions persistently

## Common Commands

```bash
# Run the app
flutter run

# Run tests
flutter test

# Build for production
flutter build ios
flutter build android
flutter build web

# Generate code (for Isar)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch for code generation
flutter pub run build_runner watch

# Analyze code
flutter analyze

# Format code
flutter format .

# Clean build artifacts
flutter clean && flutter pub get
```

## Best Practices

### Do's
- Use the latest stable Flutter SDK
- Follow Material Design 3 guidelines
- Implement proper error handling
- Write comprehensive tests
- Use proper localization
- Implement proper logging
- Use dependency injection

### Don'ts
- Don't use global state
- Don't block the UI thread
- Don't ignore analyzer warnings
- Don't hardcode values (use constants)
- Don't create widget trees deeper than 5-6 levels

## Testing

### Unit Tests
- Test business logic
- Mock dependencies
- Test edge cases

### Widget Tests
- Test UI components in isolation
- Verify user interactions
- Test different screen sizes

### Integration Tests
- Test complete user flows
- Use `integration_test` package
- Run on real devices before release

## Security
1. Never commit API keys or secrets
2. Use environment variables for configuration
3. Implement proper data validation
4. Use secure storage for sensitive data
5. Implement proper authentication flows

## Resources
- [Flutter Documentation](https://docs.flutter.dev)
- [Dart Style Guide](https://dart.dev/effective-dart)
- [Material Design 3](https://m3.material.io/)
- [Flutter Best Practices](https://docs.flutter.dev/perf/best-practices)
