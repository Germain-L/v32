import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/today_screen.dart';
import '../presentation/screens/meals_screen.dart';
import '../presentation/screens/calendar_screen.dart';
import '../presentation/screens/day_detail_screen.dart';
import '../presentation/screens/checkin_screen.dart';
import '../presentation/screens/workouts_screen.dart';
import '../presentation/screens/body_metrics_screen.dart';
import '../presentation/screens/screen_time_screen.dart';
import '../presentation/screens/settings_screen.dart';
import '../presentation/widgets/haptic_feedback_wrapper.dart';
import '../utils/l10n_helper.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/today',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      pageBuilder: (context, state, child) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: MainScaffold(child: child),
          transitionDuration: const Duration(milliseconds: 260),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            final slide = Tween<Offset>(
              begin: const Offset(0.02, 0.02),
              end: Offset.zero,
            ).animate(fade);

            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
        );
      },
      routes: [
        GoRoute(
          path: '/today',
          builder: (context, state) => const TodayScreen(),
        ),
        GoRoute(
          path: '/meals',
          builder: (context, state) => const MealsScreen(),
        ),
        GoRoute(
          path: '/workouts',
          builder: (context, state) => const WorkoutsScreen(),
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/calendar/day/:date',
      builder: (context, state) {
        final dateParam = state.pathParameters['date'];
        return DayDetailScreen(
          initialDate: _parseDateParam(dateParam) ?? DateTime.now(),
        );
      },
    ),
    GoRoute(
      path: '/checkin',
      builder: (context, state) => const CheckinScreen(),
    ),
    GoRoute(
      path: '/body-metrics',
      builder: (context, state) => const BodyMetricsScreen(),
    ),
    GoRoute(
      path: '/screen-time',
      builder: (context, state) => const ScreenTimeScreen(),
    ),
  ],
);

DateTime? _parseDateParam(String? value) {
  if (value == null) return null;
  final parts = value.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(location),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: context.l10n.navToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.restaurant_outlined),
            selectedIcon: const Icon(Icons.restaurant),
            label: context.l10n.navMeals,
          ),
          NavigationDestination(
            icon: const Icon(Icons.fitness_center_outlined),
            selectedIcon: const Icon(Icons.fitness_center),
            label: context.l10n.navWorkouts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: context.l10n.navCalendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: context.l10n.navSettings,
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/meals')) return 1;
    if (location.startsWith('/workouts')) return 2;
    if (location.startsWith('/calendar')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    HapticFeedbackUtil.trigger(HapticLevel.light);
    switch (index) {
      case 0:
        context.go('/today');
        break;
      case 1:
        context.go('/meals');
        break;
      case 2:
        context.go('/workouts');
        break;
      case 3:
        context.go('/calendar');
        break;
      case 4:
        context.go('/settings');
        break;
    }
  }
}
