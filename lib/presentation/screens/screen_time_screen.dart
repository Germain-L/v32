import 'package:flutter/material.dart';
import '../../data/models/screen_time.dart';
import '../../data/repositories/screen_time_repository_interface.dart';
import '../../data/repositories/repository_factory.dart';
import '../../gen_l10n/app_localizations.dart';
import '../../utils/date_formatter.dart';
import '../../utils/l10n_helper.dart';
import '../widgets/haptic_feedback_wrapper.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/staggered_item.dart';

class ScreenTimeScreen extends StatefulWidget {
  const ScreenTimeScreen({super.key});

  @override
  State<ScreenTimeScreen> createState() => _ScreenTimeScreenState();
}

class _ScreenTimeScreenState extends State<ScreenTimeScreen>
    with SingleTickerProviderStateMixin {
  late final ScreenTimeRepository _repository;
  late final AnimationController _listController;

  ScreenTime? _screenTime;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = RepositoryFactory().getScreenTimeRepository();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _loadScreenTime();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _loadScreenTime() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final screenTime = await _repository.getScreenTimeForDate(_selectedDate);
      _screenTime = screenTime;
      _isLoading = false;
      _listController.forward(from: 0);
      setState(() {});
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = context.l10n.errorLoadScreenTime;
      });
    }
  }

  void _previousDay() {
    HapticFeedbackUtil.trigger(HapticLevel.light);
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadScreenTime();
  }

  void _nextDay() {
    HapticFeedbackUtil.trigger(HapticLevel.light);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    if (_selectedDate.isBefore(tomorrow)) {
      setState(() {
        _selectedDate = _selectedDate.add(const Duration(days: 1));
      });
      _loadScreenTime();
    }
  }

  void _goToToday() {
    HapticFeedbackUtil.trigger(HapticLevel.light);
    setState(() {
      _selectedDate = DateTime.now();
    });
    _loadScreenTime();
  }

  String _formatDuration(int ms) {
    final hours = ms ~/ 3600000;
    final minutes = (ms % 3600000) ~/ 60000;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.screenTimeTitle),
      ),
      body: _buildBody(theme, l10n),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n) {
    return Column(
      children: [
        // Date navigation
        _buildDateNav(theme, l10n),
        
        // Content
        Expanded(
          child: _buildContent(theme, l10n),
        ),
      ],
    );
  }

  Widget _buildDateNav(ThemeData theme, AppLocalizations l10n) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousDay,
          ),
          GestureDetector(
            onTap: _goToToday,
            child: Column(
              children: [
                Text(
                  _isToday
                      ? l10n.today
                      : context.dateFormatter.formatFullDate(_selectedDate),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!_isToday)
                  Text(
                    l10n.jumpToToday,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _isToday ? null : _nextDay,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, AppLocalizations l10n) {
    if (_isLoading) {
      return SkeletonLoading(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SkeletonCard(),
            SizedBox(height: 12),
            SkeletonCard(),
            SizedBox(height: 12),
            SkeletonCard(),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadScreenTime,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_screenTime == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.phone_android_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.screenTimeNoData,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.screenTimeNoDataSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final apps = _screenTime!.apps
      ..sort((a, b) => b.durationMs.compareTo(a.durationMs));

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: apps.length + 2, // +1 for summary, +1 for pickups
      itemBuilder: (context, index) {
        if (index == 0) {
          return StaggeredItem(
            index: 0,
            animationController: _listController,
            child: _SummaryCard(
              totalMs: _screenTime!.totalMs,
              pickups: _screenTime!.pickups,
              formatDuration: _formatDuration,
            ),
          );
        }

        if (index == 1) {
          return StaggeredItem(
            index: 1,
            animationController: _listController,
            child: _SectionHeader(title: l10n.screenTimeApps),
          );
        }

        final app = apps[index - 2];
        final percentage = _screenTime!.totalMs > 0
            ? (app.durationMs / _screenTime!.totalMs * 100)
            : 0.0;

        return StaggeredItem(
          index: index,
          animationController: _listController,
          child: _AppCard(
            app: app,
            percentage: percentage,
            formatDuration: _formatDuration,
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int totalMs;
  final int? pickups;
  final String Function(int) formatDuration;

  const _SummaryCard({
    required this.totalMs,
    required this.pickups,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              l10n.screenTimeTotal,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              formatDuration(totalMs),
              style: theme.textTheme.displaySmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (pickups != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.screenTimePickups(pickups.toString()),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  final ScreenTimeApp app;
  final double percentage;
  final String Function(int) formatDuration;

  const _AppCard({
    required this.app,
    required this.percentage,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.apps,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app.appName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        formatDuration(app.durationMs),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: colorScheme.surfaceContainerHighest,
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
