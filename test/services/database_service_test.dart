import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:v32/data/services/database_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseService.resetForTesting();
  });

  test('useInMemoryDatabaseForTesting initializes schema', () async {
    await DatabaseService.resetForTesting();
    await DatabaseService.useInMemoryDatabaseForTesting();
    final db = await DatabaseService.database;
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='meals'",
    );
    expect(result, isNotEmpty);
  });

  test('notifyChange emits on dbChanges stream', () async {
    await DatabaseService.resetForTesting();
    await DatabaseService.useInMemoryDatabaseForTesting();
    final iterator = StreamIterator(DatabaseService.dbChanges);

    final moveNextFuture = iterator.moveNext();
    await DatabaseService.notifyChange();

    expect(await moveNextFuture, isTrue);
    await iterator.cancel();
  });

  test('close completes dbChanges stream', () async {
    await DatabaseService.resetForTesting();
    await DatabaseService.useInMemoryDatabaseForTesting();
    final done = Completer<void>();
    DatabaseService.dbChanges.listen((_) {}, onDone: () => done.complete());

    await DatabaseService.close(closeStreams: true);

    await done.future;
  });

  test('watchTable only emits for matching table', () async {
    await DatabaseService.resetForTesting();
    await DatabaseService.useInMemoryDatabaseForTesting();
    final iterator = StreamIterator(DatabaseService.watchTable('meals'));

    final moveNextFuture = iterator.moveNext();
    await DatabaseService.notifyChange(table: 'daily_metrics');

    final didEmit = await moveNextFuture.timeout(
      const Duration(milliseconds: 50),
      onTimeout: () => false,
    );
    expect(didEmit, isFalse);
    await iterator.cancel();
  });
}
