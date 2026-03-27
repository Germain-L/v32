import 'package:flutter/material.dart';
import '../../data/models/body_metric.dart';
import '../../data/repositories/body_metric_repository_interface.dart';
import '../../data/repositories/repository_factory.dart';
import '../../gen_l10n/app_localizations.dart';
import '../../utils/date_formatter.dart';
import '../../utils/l10n_helper.dart';
import '../widgets/haptic_feedback_wrapper.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/staggered_item.dart';

class BodyMetricsScreen extends StatefulWidget {
  const BodyMetricsScreen({super.key});

  @override
  State<BodyMetricsScreen> createState() => _BodyMetricsScreenState();
}

class _BodyMetricsScreenState extends State<BodyMetricsScreen>
    with SingleTickerProviderStateMixin {
  late final BodyMetricRepository _repository;
  late final AnimationController _listController;

  List<BodyMetric> _metrics = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = RepositoryFactory().getBodyMetricRepository();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _loadMetrics();
  }

  @override
  void dispose() {
    _listController.dispose();
    super.dispose();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final metrics = await _repository.getBodyMetricsBefore(
        DateTime.now(),
        limit: 50,
      );
      _metrics = metrics;
      _isLoading = false;
      _listController.forward(from: 0);
      setState(() {});
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = context.l10n.errorLoadBodyMetrics;
      });
    }
  }

  Future<void> _addMetric() async {
    HapticFeedbackUtil.trigger(HapticLevel.light);
    final result = await showModalBottomSheet<BodyMetric>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const _AddMetricSheet(),
    );

    if (result != null) {
      try {
        await _repository.saveBodyMetric(result);
        await _loadMetrics();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.errorSaveBodyMetric),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteMetric(BodyMetric metric) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.bodyMetricDelete),
        content: Text(context.l10n.bodyMetricDeleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.clear),
          ),
        ],
      ),
    );

    if (confirmed == true && metric.id != null) {
      HapticFeedbackUtil.trigger(HapticLevel.heavy);
      try {
        await _repository.deleteBodyMetric(metric.id!);
        await _loadMetrics();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.errorDeleteBodyMetric),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bodyMetricsTitle),
      ),
      body: _buildBody(theme, l10n),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMetric,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n) {
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
              onPressed: _loadMetrics,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    if (_metrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.monitor_weight_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.bodyMetricsEmpty,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.bodyMetricsEmptySubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final latestMetric = _metrics.first;
    final latestWeight = latestMetric.weight;
    final previousWeight = _metrics.length > 1 ? _metrics[1].weight : null;
    final weightChange = latestWeight != null && previousWeight != null
        ? latestWeight - previousWeight
        : null;

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _metrics.length + 1, // +1 for summary card
      itemBuilder: (context, index) {
        if (index == 0) {
          return StaggeredItem(
            index: 0,
            animationController: _listController,
            child: _SummaryCard(
              latestWeight: latestWeight,
              weightChange: weightChange,
            ),
          );
        }

        final metric = _metrics[index - 1];
        return StaggeredItem(
          index: index,
          animationController: _listController,
          child: _MetricCard(
            metric: metric,
            onDelete: () => _deleteMetric(metric),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double? latestWeight;
  final double? weightChange;

  const _SummaryCard({
    required this.latestWeight,
    required this.weightChange,
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
              l10n.bodyMetricsCurrentWeight,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              latestWeight != null
                  ? l10n.bodyMetricsWeightKg(latestWeight!.toStringAsFixed(1))
                  : '--',
              style: theme.textTheme.displaySmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (weightChange != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    weightChange! < 0
                        ? Icons.trending_down
                        : weightChange! > 0
                            ? Icons.trending_up
                            : Icons.trending_flat,
                    size: 20,
                    color: weightChange! <= 0
                        ? colorScheme.primary
                        : colorScheme.tertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    weightChange! < 0
                        ? l10n.bodyMetricsWeightLost(
                            weightChange!.abs().toStringAsFixed(1))
                        : l10n.bodyMetricsWeightGained(
                            weightChange!.toStringAsFixed(1)),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: weightChange! <= 0
                          ? colorScheme.primary
                          : colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
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

class _MetricCard extends StatelessWidget {
  final BodyMetric metric;
  final VoidCallback onDelete;

  const _MetricCard({
    required this.metric,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Dismissible(
      key: ValueKey('metric_${metric.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      onUpdate: (details) {
        if (details.progress >= 0.4 && details.progress < 0.5) {
          HapticFeedbackUtil.trigger(HapticLevel.medium);
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.delete_outline,
          color: colorScheme.onError,
          size: 28,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.monitor_weight,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.dateFormatter.formatFullDate(metric.date),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (metric.weight != null)
                          Text(
                            l10n.bodyMetricsWeightKg(
                              metric.weight!.toStringAsFixed(1)),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        if (metric.weight != null && metric.bodyFat != null)
                          Text(
                            ' • ',
                            style: theme.textTheme.bodyMedium,
                          ),
                        if (metric.bodyFat != null)
                          Text(
                            l10n.bodyMetricsBodyFat(
                              metric.bodyFat!.toStringAsFixed(1)),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMetricSheet extends StatefulWidget {
  const _AddMetricSheet();

  @override
  State<_AddMetricSheet> createState() => _AddMetricSheetState();
}

class _AddMetricSheetState extends State<_AddMetricSheet> {
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _weightController.dispose();
    _bodyFatController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  void _save() {
    final weight = double.tryParse(_weightController.text);
    final bodyFat = double.tryParse(_bodyFatController.text);

    if (weight == null && bodyFat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.bodyMetricEnterValue),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final metric = BodyMetric(
      date: _date,
      weight: weight,
      bodyFat: bodyFat,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    Navigator.of(context).pop(metric);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.bodyMetricAdd,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          
          // Weight
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.bodyMetricWeightLabel,
              suffixText: l10n.bodyMetricWeightUnit,
            ),
          ),
          const SizedBox(height: 12),
          
          // Body fat (optional)
          TextField(
            controller: _bodyFatController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l10n.bodyMetricBodyFatLabel,
              suffixText: l10n.bodyMetricBodyFatUnit,
            ),
          ),
          const SizedBox(height: 12),
          
          // Date picker
          InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(12),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.bodyMetricDate,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(context.dateFormatter.formatFullDate(_date)),
                  const Icon(Icons.calendar_today, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Notes
          TextField(
            controller: _notesController,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.bodyMetricNotes,
            ),
          ),
          const SizedBox(height: 24),
          
          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: Text(l10n.bodyMetricSave),
            ),
          ),
        ],
      ),
    );
  }
}
