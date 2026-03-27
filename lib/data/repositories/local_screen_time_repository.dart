import 'dart:async';

import '../models/screen_time.dart';
import '../services/database_service.dart';
import '../services/screen_time_service.dart';
import 'screen_time_repository_interface.dart';

class LocalScreenTimeRepository implements ScreenTimeRepository {
  LocalScreenTimeRepository({
    ScreenTimeService? screenTimeService,
  }) : _screenTimeService = screenTimeService ?? ScreenTimeService();

  final ScreenTimeService _screenTimeService;

  @override
  Future<ScreenTime> saveScreenTime(ScreenTime screenTime) async {
    final db = await DatabaseService.database;
    late ScreenTime savedScreenTime;

    if (screenTime.id == null) {
      final id =
          await db.insert('screen_times', screenTime.toMap()..remove('id'));
      await DatabaseService.notifyChange(table: 'screen_times');
      savedScreenTime = screenTime.copyWith(id: id);
    } else {
      await db.update(
        'screen_times',
        screenTime.toMap(),
        where: 'id = ?',
        whereArgs: [screenTime.id],
      );
      savedScreenTime = screenTime;
    }

    if (screenTime.apps.isNotEmpty && savedScreenTime.id != null) {
      final apps = screenTime.apps
          .map(
            (app) => app.copyWith(screenTimeId: savedScreenTime.id!),
          )
          .toList(growable: false);
      await saveScreenTimeApps(savedScreenTime.id!, apps);
      savedScreenTime = savedScreenTime.copyWith(apps: apps);
    }

    await DatabaseService.notifyChange(table: 'screen_times');
    return savedScreenTime;
  }

  Future<void> saveScreenTimes(List<ScreenTime> screenTimes) async {
    final db = await DatabaseService.database;
    final batch = db.batch();

    for (final screenTime in screenTimes) {
      if (screenTime.id == null) {
        batch.insert('screen_times', screenTime.toMap()..remove('id'));
      } else {
        batch.update(
          'screen_times',
          screenTime.toMap(),
          where: 'id = ?',
          whereArgs: [screenTime.id],
        );
      }
    }

    await batch.commit(noResult: true);
    await DatabaseService.notifyChange(table: 'screen_times');
  }

  @override
  Future<ScreenTime?> getScreenTimeById(int id) async {
    final db = await DatabaseService.database;
    final maps =
        await db.query('screen_times', where: 'id = ?', whereArgs: [id]);

    if (maps.isEmpty) return null;
    return _hydrateScreenTime(ScreenTime.fromMap(maps.first));
  }

  @override
  Future<ScreenTime?> getScreenTimeForDate(DateTime date) async {
    final db = await DatabaseService.database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final maps = await db.query(
      'screen_times',
      where: 'date >= ? AND date < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch
      ],
      orderBy: 'date DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return _hydrateScreenTime(ScreenTime.fromMap(maps.first));
  }

  @override
  Future<void> deleteScreenTime(int id) async {
    final db = await DatabaseService.database;
    await db.delete('screen_times', where: 'id = ?', whereArgs: [id]);
    await DatabaseService.notifyChange(table: 'screen_times');
  }

  @override
  Stream<List<ScreenTime>> watchRecentScreenTimes({int limit = 30}) async* {
    Future<List<ScreenTime>> load() async {
      final db = await DatabaseService.database;
      final maps = await db.query(
        'screen_times',
        orderBy: 'date DESC',
        limit: limit,
      );
      return _hydrateScreenTimes(
        maps.map((map) => ScreenTime.fromMap(map)).toList(),
      );
    }

    yield await load();

    await for (final _ in DatabaseService.watchTable('screen_times')) {
      yield await load();
    }
  }

  @override
  Future<List<ScreenTime>> getScreenTimesForDateRange(
      DateTime start, DateTime end) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'screen_times',
      where: 'date >= ? AND date < ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'date ASC',
    );

    return _hydrateScreenTimes(
      maps.map((map) => ScreenTime.fromMap(map)).toList(),
    );
  }

  @override
  Future<List<ScreenTime>> getScreenTimesBefore(DateTime date,
      {int limit = 20}) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'screen_times',
      where: 'date < ?',
      whereArgs: [date.millisecondsSinceEpoch],
      orderBy: 'date DESC',
      limit: limit,
    );

    return _hydrateScreenTimes(
      maps.map((map) => ScreenTime.fromMap(map)).toList(),
    );
  }

  @override
  Future<List<ScreenTime>> getPendingSyncScreenTimes() async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'screen_times',
      where: 'pending_sync = ?',
      whereArgs: [1],
      orderBy: 'created_at ASC',
    );

    return _hydrateScreenTimes(
      maps.map((map) => ScreenTime.fromMap(map)).toList(),
    );
  }

  @override
  Future<void> updateServerId(int localId, int serverId) async {
    final db = await DatabaseService.database;
    await db.update(
      'screen_times',
      {'server_id': serverId, 'pending_sync': 0},
      where: 'id = ?',
      whereArgs: [localId],
    );
    await DatabaseService.notifyChange(table: 'screen_times');
  }

  @override
  Future<void> saveScreenTimeApps(
      int screenTimeId, List<ScreenTimeApp> apps) async {
    final db = await DatabaseService.database;

    // Delete existing apps for this screen time
    await db.delete(
      'screen_time_apps',
      where: 'screen_time_id = ?',
      whereArgs: [screenTimeId],
    );

    // Insert new apps
    final batch = db.batch();
    for (final app in apps) {
      batch.insert(
        'screen_time_apps',
        app.copyWith(screenTimeId: screenTimeId).toMap()..remove('id'),
      );
    }
    await batch.commit(noResult: true);
    await DatabaseService.notifyChange(table: 'screen_time_apps');
  }

  @override
  Future<List<ScreenTimeApp>> getScreenTimeApps(int screenTimeId) async {
    final db = await DatabaseService.database;
    final maps = await db.query(
      'screen_time_apps',
      where: 'screen_time_id = ?',
      whereArgs: [screenTimeId],
      orderBy: 'duration_ms DESC',
    );

    return maps.map((map) => ScreenTimeApp.fromMap(map)).toList();
  }

  Future<ScreenTime?> syncFromNative(DateTime date) async {
    final data = await _screenTimeService.getScreenTimeForDate(
      year: date.year,
      month: date.month,
      day: date.day,
    );

    if (data == null) {
      return null;
    }

    final existing = await getScreenTimeForDate(date);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final pickups = _readNullableInt(data['pickups']);
    final apps = _parseApps(data['apps'], existing?.id);

    if (existing != null &&
        existing.totalMs == _readInt(data['totalMs']) &&
        existing.pickups == pickups &&
        _sameApps(existing.apps, apps)) {
      return existing;
    }

    final saved = await saveScreenTime(
      ScreenTime(
        id: existing?.id,
        serverId: existing?.serverId,
        date: normalizedDate,
        totalMs: _readInt(data['totalMs']),
        pickups: pickups,
        createdAt: existing?.createdAt,
        pendingSync: true,
      ),
    );

    if (saved.id == null) {
      return saved;
    }

    final appsWithScreenTimeId = apps
        .map((app) => app.copyWith(screenTimeId: saved.id!))
        .toList(growable: false);
    await saveScreenTimeApps(saved.id!, appsWithScreenTimeId);

    return saved.copyWith(apps: appsWithScreenTimeId);
  }

  Future<ScreenTime> _hydrateScreenTime(ScreenTime screenTime) async {
    if (screenTime.id == null) {
      return screenTime;
    }

    final apps = await getScreenTimeApps(screenTime.id!);
    return screenTime.copyWith(apps: List.unmodifiable(apps));
  }

  Future<List<ScreenTime>> _hydrateScreenTimes(List<ScreenTime> screenTimes) {
    return Future.wait(
      screenTimes.map(_hydrateScreenTime),
    );
  }

  List<ScreenTimeApp> _parseApps(dynamic rawApps, int? screenTimeId) {
    final apps = rawApps as List<dynamic>? ?? const <dynamic>[];
    return apps
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (app) => ScreenTimeApp(
            screenTimeId: screenTimeId ?? 0,
            packageName: app['packageName'] as String? ?? '',
            appName: app['appName'] as String? ??
                app['packageName'] as String? ??
                '',
            durationMs: _readInt(app['durationMs']),
          ),
        )
        .where((app) => app.packageName.isNotEmpty)
        .toList(growable: false);
  }

  bool _sameApps(List<ScreenTimeApp> left, List<ScreenTimeApp> right) {
    if (left.length != right.length) {
      return false;
    }

    for (var i = 0; i < left.length; i++) {
      final leftApp = left[i];
      final rightApp = right[i];
      if (leftApp.packageName != rightApp.packageName ||
          leftApp.appName != rightApp.appName ||
          leftApp.durationMs != rightApp.durationMs) {
        return false;
      }
    }

    return true;
  }

  int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return 0;
  }

  int? _readNullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    return _readInt(value);
  }
}
