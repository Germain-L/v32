import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/settings_keys.dart';

class ScreenTimeSettingsService {
  static ScreenTimeSettingsService? _instance;

  factory ScreenTimeSettingsService() =>
      _instance ??= ScreenTimeSettingsService._();

  ScreenTimeSettingsService._();

  Future<bool> isScreenTimeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(SettingsKeys.screenTimeEnabled) ?? false;
  }

  Future<void> setScreenTimeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.screenTimeEnabled, enabled);
  }
}
