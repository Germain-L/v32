import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/screen_time_service.dart';
import '../../data/services/screen_time_settings_service.dart';
import '../../data/services/strava_auth_service.dart';
import '../../utils/l10n_helper.dart';
import '../widgets/haptic_feedback_wrapper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  final ScreenTimeService _screenTimeService = ScreenTimeService();
  final ScreenTimeSettingsService _screenTimeSettingsService =
      ScreenTimeSettingsService();

  bool _stravaConnected = false;
  bool _screenTimeEnabled = false;
  bool _isScreenTimeLoading = true;
  bool _awaitingScreenTimePermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadScreenTimePreference();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingScreenTimePermission) {
      _handleScreenTimePermissionReturn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          // Connections section
          _SectionHeader(title: l10n.settingsConnections),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.directions_run,
                title: l10n.settingsStrava,
                subtitle: _stravaConnected
                    ? l10n.settingsConnected
                    : l10n.settingsNotConnected,
                trailing: _stravaConnected
                    ? Icon(
                        Icons.check_circle,
                        color: colorScheme.primary,
                      )
                    : null,
                onTap: () => _connectStrava(),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tracking section
          _SectionHeader(title: l10n.settingsTracking),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.phone_android,
                title: l10n.settingsScreenTime,
                subtitle: l10n.settingsScreenTimeDescription,
                trailing: Switch(
                  value: _screenTimeEnabled,
                  onChanged:
                      _screenTimeService.isSupported && !_isScreenTimeLoading
                          ? _onScreenTimeToggle
                          : null,
                ),
              ),
              _SettingsTile(
                icon: Icons.bar_chart_rounded,
                title: l10n.settingsScreenTimeOpen,
                subtitle: l10n.settingsScreenTimeOpenDescription,
                trailing: const Icon(Icons.chevron_right),
                onTap: _screenTimeEnabled ? _openScreenTime : null,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sync status section
          _SectionHeader(title: l10n.settingsSync),
          const _SyncStatusCard(),

          const SizedBox(height: 16),

          // About section
          _SectionHeader(title: l10n.settingsAbout),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: l10n.settingsAppVersion,
                subtitle: '2.0.1',
              ),
              _SettingsTile(
                icon: Icons.code,
                title: l10n.settingsBuiltWith,
                subtitle: 'Flutter & Material 3',
              ),
              _SettingsTile(
                icon: Icons.favorite_outline,
                title: l10n.settingsMadeBy,
                subtitle: 'Clanker 🦞',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _connectStrava() async {
    HapticFeedbackUtil.trigger(HapticLevel.light);

    if (_stravaConnected) {
      // Show disconnect confirmation
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.settingsStravaDisconnect),
          content: Text(context.l10n.settingsStravaDisconnectConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.settingsDisconnect),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          await StravaAuthService().logout();
          setState(() => _stravaConnected = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.settingsStravaDisconnected),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          // Not implemented yet
        }
      }
    } else {
      try {
        final success = await StravaAuthService().login();
        if (success) {
          setState(() => _stravaConnected = true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.l10n.settingsStravaConnected),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        // Not implemented yet - show placeholder message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.settingsStravaComingSoon),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _loadScreenTimePreference() async {
    final isEnabled = await _screenTimeSettingsService.isScreenTimeEnabled();
    final hasPermission =
        isEnabled ? await _screenTimeService.hasPermission() : false;

    if (isEnabled && !hasPermission) {
      await _screenTimeSettingsService.setScreenTimeEnabled(false);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _screenTimeEnabled = isEnabled && hasPermission;
      _isScreenTimeLoading = false;
    });
  }

  Future<void> _onScreenTimeToggle(bool enabled) async {
    HapticFeedbackUtil.trigger(HapticLevel.light);

    if (!enabled) {
      await _screenTimeSettingsService.setScreenTimeEnabled(false);
      if (!mounted) {
        return;
      }

      setState(() {
        _screenTimeEnabled = false;
      });
      return;
    }

    final hasPermission = await _screenTimeService.hasPermission();
    if (hasPermission) {
      await _screenTimeSettingsService.setScreenTimeEnabled(true);
      if (!mounted) {
        return;
      }

      setState(() {
        _screenTimeEnabled = true;
      });
      return;
    }

    if (!mounted) {
      return;
    }

    final shouldOpenSettings = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(context.l10n.settingsScreenTimePermissionTitle),
            content: Text(
              context.l10n.settingsScreenTimePermissionMessage,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(context.l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(context.l10n.settingsScreenTimeOpenSettings),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldOpenSettings) {
      return;
    }

    setState(() {
      _awaitingScreenTimePermission = true;
    });
    await _screenTimeService.requestPermission();
  }

  Future<void> _handleScreenTimePermissionReturn() async {
    final hasPermission = await _screenTimeService.hasPermission();
    await _screenTimeSettingsService.setScreenTimeEnabled(hasPermission);

    if (!mounted) {
      return;
    }

    setState(() {
      _awaitingScreenTimePermission = false;
      _screenTimeEnabled = hasPermission;
    });

    if (hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.settingsScreenTimePermissionGranted),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openScreenTime() {
    HapticFeedbackUtil.trigger(HapticLevel.light);
    context.push('/screen-time');
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                indent: 56,
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = context.l10n;

    // Note: In a real app, this would watch a provider
    // For now, we'll just show a placeholder
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_done_outlined,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsSyncStatus,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.settingsSynced,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.settingsLastSync('Just now'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
