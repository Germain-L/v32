---
name: flutter-routing
description: GoRouter configuration and navigation patterns for Flutter apps
license: MIT
compatibility: opencode
metadata:
  category: navigation
  framework: flutter
---

## What I Do

Provide go_router patterns for declarative navigation, deep linking, and type-safe routing.

## When to Use Me

Use this skill when:
- Setting up go_router for the first time
- Configuring deep links for meal detail views
- Implementing tab-based navigation
- Creating type-safe routes with parameters
- Handling authentication redirects

## GoRouter Patterns

### 1. Basic Configuration

```dart
// lib/config/routes.dart
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainShell(),
      routes: [
        GoRoute(
          path: 'today',
          builder: (context, state) => const TodayScreen(),
        ),
        GoRoute(
          path: 'meals',
          builder: (context, state) => const MealsScreen(),
        ),
        GoRoute(
          path: 'calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/meal/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return MealDetailScreen(mealId: id);
      },
    ),
  ],
);
```

### 2. Shell Route for Bottom Navigation

```dart
// lib/presentation/screens/main_shell.dart
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  
  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
    
    switch (index) {
      case 0:
        context.go('/today');
        break;
      case 1:
        context.go('/meals');
        break;
      case 2:
        context.go('/calendar');
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          TodayScreen(),
          MealsScreen(),
          CalendarScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Today'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Meals'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
        ],
      ),
    );
  }
}
```

### 3. Navigation Helpers

```dart
// lib/utils/navigation.dart
extension GoRouterNavigation on BuildContext {
  void goToday() => go('/today');
  void goMeals() => go('/meals');
  void goCalendar() => go('/calendar');
  void goMealDetail(int id) => go('/meal/$id');
  
  // With query parameters
  void goMealsForDate(DateTime date) => go(
    '/meals',
    extra: {'date': date},
  );
}

// Usage in widgets
ElevatedButton(
  onPressed: () => context.goMealDetail(meal.id),
  child: const Text('View Details'),
)
```

### 4. Deep Linking Setup

```dart
// Android: android/app/src/main/AndroidManifest.xml
<activity android:name=".MainActivity">
  <intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="diet" android:host="meal" />
  </intent-filter>
</activity>

// iOS: ios/Runner/Info.plist
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>diet</string>
    </array>
  </dict>
</array>

// Router with deep link support
final router = GoRouter(
  routes: [...],
  // Handle deep links
  redirect: (context, state) {
    final uri = state.uri;
    if (uri.scheme == 'diet') {
      if (uri.host == 'meal' && uri.pathSegments.isNotEmpty) {
        return '/meal/${uri.pathSegments.first}';
      }
    }
    return null;
  },
);
```

### 5. Route Guards

```dart
// Redirect unauthenticated users
final router = GoRouter(
  routes: [...],
  redirect: (context, state) {
    final isAuthenticated = context.read<AuthProvider>().isAuthenticated;
    final isLoggingIn = state.uri.path == '/login';
    
    if (!isAuthenticated && !isLoggingIn) {
      return '/login';
    }
    if (isAuthenticated && isLoggingIn) {
      return '/';
    }
    return null;
  },
);
```

### 6. Passing Complex Objects

```dart
// Using extra parameter for objects
void goToMealEdit(Meal meal) {
  context.push('/meal/edit', extra: meal);
}

// Retrieving in screen
class MealEditScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final meal = GoRouterState.of(context).extra as Meal?;
    // ...
  }
}
```

## Best Practices

- Use pathParameters for IDs and simple values
- Use extra for complex objects that shouldn't be in URL
- Keep routes flat when possible (avoid deep nesting)
- Use redirect for authentication and onboarding flows
- Test deep links on both platforms
- Use go() for replace, push() for stack navigation
- Handle back button with WillPopScope or PopScope
- Keep route definitions in a single location