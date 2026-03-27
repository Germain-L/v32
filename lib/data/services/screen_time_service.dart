import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenTimeService {
  static const MethodChannel _channel =
      MethodChannel('com.germainleignel.diet/screentime');

  static ScreenTimeService? _instance;

  factory ScreenTimeService() => _instance ??= ScreenTimeService._();

  ScreenTimeService._();

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> hasPermission() async {
    if (!isSupported) {
      return false;
    }

    try {
      final result = await _channel.invokeMethod<bool>('hasPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> requestPermission() async {
    if (!isSupported) {
      return;
    }

    try {
      await _channel.invokeMethod<bool>('requestPermission');
    } on PlatformException {
      // Settings can fail to open on some devices. The UI handles the fallback.
    }
  }

  Future<Map<String, dynamic>?> getTodayScreenTime() async {
    if (!isSupported) {
      return null;
    }

    try {
      final result = await _channel
          .invokeMapMethod<Object?, Object?>('getTodayScreenTime');
      return _normalizeMap(result);
    } on PlatformException {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getScreenTimeForDate({
    required int year,
    required int month,
    required int day,
  }) async {
    if (!isSupported) {
      return null;
    }

    try {
      final result = await _channel.invokeMapMethod<Object?, Object?>(
        'getScreenTimeForDate',
        <String, int>{
          'year': year,
          'month': month,
          'day': day,
        },
      );
      return _normalizeMap(result);
    } on PlatformException {
      return null;
    }
  }

  Map<String, dynamic>? _normalizeMap(Map<Object?, Object?>? raw) {
    if (raw == null) {
      return null;
    }

    return raw.map(
      (key, value) => MapEntry(key.toString(), _normalizeValue(value)),
    );
  }

  dynamic _normalizeValue(dynamic value) {
    if (value is Map<Object?, Object?>) {
      return value.map(
        (key, nestedValue) =>
            MapEntry(key.toString(), _normalizeValue(nestedValue)),
      );
    }

    if (value is List) {
      return value.map(_normalizeValue).toList(growable: false);
    }

    return value;
  }
}
