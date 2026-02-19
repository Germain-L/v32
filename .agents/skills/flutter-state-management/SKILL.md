---
name: flutter-state-management
description: State management patterns using Flutter's built-in ChangeNotifier and ValueListenableBuilder
license: MIT
compatibility: opencode
metadata:
  category: state-management
  framework: flutter
---

## What I Do

Provide state management patterns using only Flutter's built-in tools (ChangeNotifier, ValueListenableBuilder) without external dependencies.

## When to Use Me

Use this skill when:
- Managing meal data state across screens
- Implementing reactive UI updates
- Deciding between StatefulWidget and StatelessWidget
- Handling loading/error states
- Persisting state across app restarts

## State Management Patterns

### 1. ChangeNotifier for Business Logic

```dart
// lib/presentation/providers/meal_provider.dart
import 'package:flutter/foundation.dart';

class MealProvider extends ChangeNotifier {
  final MealRepository _repository;
  
  MealProvider(this._repository);
  
  List<Meal> _meals = [];
  bool _isLoading = false;
  String? _error;
  
  List<Meal> get meals => _meals;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> loadTodayMeals() async {
    _setLoading(true);
    try {
      _meals = await _repository.getTodayMeals();
      _error = null;
    } catch (e) {
      _error = 'Failed to load meals: $e';
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> addMeal(Meal meal) async {
    try {
      await _repository.saveMeal(meal);
      _meals.add(meal);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to save meal: $e';
      notifyListeners();
    }
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
```

### 2. ValueListenableBuilder for Reactive UI

```dart
// lib/presentation/screens/today_screen.dart
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: context.read<MealProvider>(),
      builder: (context, child) {
        final provider = context.watch<MealProvider>();
        
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (provider.error != null) {
          return ErrorWidget(message: provider.error!);
        }
        
        return MealList(meals: provider.meals);
      },
    );
  }
}

// Optimized: Only rebuild specific widgets
class MealCounter extends StatelessWidget {
  const MealCounter({super.key});
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: context.read<MealProvider>().mealCountNotifier,
      builder: (context, count, child) {
        return Badge(
          label: Text('$count'),
          child: const Icon(Icons.restaurant),
        );
      },
    );
  }
}
```

### 3. Provider Injection

```dart
// lib/app.dart
class DietApp extends StatelessWidget {
  const DietApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MealRepository>(
          create: (_) => MealRepository(Isar.getInstance()!),
        ),
        ChangeNotifierProvider(
          create: (context) => MealProvider(
            context.read<MealRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => NavigationProvider(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
      ),
    );
  }
}
```

### 4. When to Use StatefulWidget vs StatelessWidget

```dart
// StatelessWidget: Pure UI, no state
class MealCard extends StatelessWidget {
  final Meal meal;
  const MealCard({super.key, required this.meal});
  
  @override
  Widget build(BuildContext context) {
    return Card(child: Text(meal.description ?? ''));
  }
}

// StatefulWidget: Local UI state only
class PhotoCaptureButton extends StatefulWidget {
  const PhotoCaptureButton({super.key});
  
  @override
  State<PhotoCaptureButton> createState() => _PhotoCaptureButtonState();
}

class _PhotoCaptureButtonState extends State<PhotoCaptureButton> {
  bool _isCapturing = false;
  
  Future<void> _capturePhoto() async {
    setState(() => _isCapturing = true);
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(source: ImageSource.camera);
      // ...
    } finally {
      setState(() => _isCapturing = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: _isCapturing 
        ? const CircularProgressIndicator()
        : const Icon(Icons.camera_alt),
      onPressed: _isCapturing ? null : _capturePhoto,
    );
  }
}

// Provider + StatelessWidget: Business logic state
class TodayScreen extends StatelessWidget {
  // Use Provider for shared state
  @override
  Widget build(BuildContext context) {
    return Consumer<MealProvider>(
      builder: (context, provider, child) {
        return ListView.builder(
          itemCount: provider.meals.length,
          itemBuilder: (context, index) {
            return MealCard(meal: provider.meals[index]);
          },
        );
      },
    );
  }
}
```

### 5. State Persistence

```dart
// lib/presentation/providers/persistent_provider.dart
class PersistentMealProvider extends MealProvider {
  final SharedPreferences _prefs;
  
  PersistentMealProvider(super.repository, this._prefs) {
    _loadFromStorage();
  }
  
  Future<void> _loadFromStorage() async {
    final json = _prefs.getString('last_meals');
    if (json != null) {
      final List<dynamic> decoded = jsonDecode(json);
      _meals = decoded.map((m) => Meal.fromJson(m)).toList();
      notifyListeners();
    }
  }
  
  @override
  Future<void> addMeal(Meal meal) async {
    await super.addMeal(meal);
    await _saveToStorage();
  }
  
  Future<void> _saveToStorage() async {
    final json = jsonEncode(_meals.map((m) => m.toJson()).toList());
    await _prefs.setString('last_meals', json);
  }
}
```

### 6. Error State Handling

```dart
// lib/presentation/widgets/error_handler.dart
class ErrorAwareWidget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onRetry;
  
  const ErrorAwareWidget({
    super.key,
    required this.child,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return Consumer<MealProvider>(
      builder: (context, provider, _) {
        if (provider.error != null) {
          return ErrorView(
            message: provider.error!,
            onRetry: onRetry,
          );
        }
        return child;
      },
    );
  }
}
```

## Best Practices

- Keep business logic in ChangeNotifier, UI in StatelessWidget
- Use ValueListenableBuilder for granular rebuilds
- Don't notifyListeners() inside build()
- Dispose providers when no longer needed
- Use Selectors to listen to specific fields only
- Keep providers scoped to where they're needed
- Use FutureBuilder/StreamBuilder for async data
- Avoid deep widget tree rebuilds