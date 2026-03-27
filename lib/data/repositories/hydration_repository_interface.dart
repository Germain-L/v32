import '../models/hydration.dart';

abstract class HydrationRepository {
  Future<Hydration> saveHydration(Hydration hydration);
  Future<Hydration?> getHydrationById(int id);
  Future<List<Hydration>> getHydrationsForDate(DateTime date);
  Future<void> deleteHydration(int id);
  Stream<List<Hydration>> watchTodayHydrations();
  Future<List<Hydration>> getHydrationsForDateRange(
      DateTime start, DateTime end);
  Future<List<Hydration>> getHydrationsBefore(DateTime date,
      {int limit = 20});
  Future<List<Hydration>> getPendingSyncHydrations();
  Future<void> updateServerId(int localId, int serverId);
  Future<int> getTotalHydrationForDate(DateTime date);
}
