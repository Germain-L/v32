import '../models/screen_time.dart';

abstract class ScreenTimeRepository {
  Future<ScreenTime> saveScreenTime(ScreenTime screenTime);
  Future<ScreenTime?> getScreenTimeById(int id);
  Future<ScreenTime?> getScreenTimeForDate(DateTime date);
  Future<void> deleteScreenTime(int id);
  Stream<List<ScreenTime>> watchRecentScreenTimes({int limit = 30});
  Future<List<ScreenTime>> getScreenTimesForDateRange(
      DateTime start, DateTime end);
  Future<List<ScreenTime>> getScreenTimesBefore(DateTime date,
      {int limit = 20});
  Future<List<ScreenTime>> getPendingSyncScreenTimes();
  Future<void> updateServerId(int localId, int serverId);
  Future<void> saveScreenTimeApps(int screenTimeId, List<ScreenTimeApp> apps);
  Future<List<ScreenTimeApp>> getScreenTimeApps(int screenTimeId);
}
