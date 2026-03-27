import '../models/daily_checkin.dart';

abstract class DailyCheckinRepository {
  Future<DailyCheckin> saveDailyCheckin(DailyCheckin dailyCheckin);
  Future<DailyCheckin?> getDailyCheckinById(int id);
  Future<DailyCheckin?> getDailyCheckinForDate(DateTime date);
  Future<void> deleteDailyCheckin(int id);
  Stream<List<DailyCheckin>> watchRecentDailyCheckins({int limit = 30});
  Future<List<DailyCheckin>> getDailyCheckinsForDateRange(
      DateTime start, DateTime end);
  Future<List<DailyCheckin>> getDailyCheckinsBefore(DateTime date,
      {int limit = 20});
  Future<List<DailyCheckin>> getPendingSyncDailyCheckins();
  Future<void> updateServerId(int localId, int serverId);
}
