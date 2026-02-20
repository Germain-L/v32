import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static Database? _database;
  static StreamController<void> _dbChangeController =
      StreamController<void>.broadcast();
  static StreamController<String> _tableChangeController =
      StreamController<String>.broadcast();

  static Stream<void> get dbChanges => _dbChangeController.stream;
  static Stream<String> get tableChanges => _tableChangeController.stream;

  static Future<Database> get database async {
    _ensureControllers();
    _database ??= await _initDatabase();
    return _database!;
  }

  static void _ensureControllers() {
    if (_dbChangeController.isClosed) {
      _dbChangeController = StreamController<void>.broadcast();
    }
    if (_tableChangeController.isClosed) {
      _tableChangeController = StreamController<String>.broadcast();
    }
  }

  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'diet_database.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  @visibleForTesting
  static Future<void> useInMemoryDatabaseForTesting() async {
    _database = await openDatabase(
      inMemoryDatabasePath,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE meals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        slot TEXT NOT NULL,
        date INTEGER NOT NULL,
        description TEXT,
        imagePath TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_date ON meals(date)');
    await db.execute('CREATE INDEX idx_slot ON meals(slot)');

    await db.execute('''
      CREATE TABLE day_ratings(
        date INTEGER PRIMARY KEY,
        score INTEGER NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_day_ratings_date ON day_ratings(date)');

    await db.execute('''
      CREATE TABLE daily_metrics(
        date INTEGER PRIMARY KEY,
        water_liters REAL,
        exercise_done INTEGER,
        exercise_note TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_daily_metrics_date ON daily_metrics(date)',
    );
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE day_ratings(
          date INTEGER PRIMARY KEY,
          score INTEGER NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_day_ratings_date ON day_ratings(date)',
      );
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE daily_metrics(
          date INTEGER PRIMARY KEY,
          water_liters REAL,
          exercise_done INTEGER,
          exercise_note TEXT
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_daily_metrics_date ON daily_metrics(date)',
      );
    }
  }

  static Stream<void> watchTable(String table) {
    _ensureControllers();
    return _tableChangeController.stream
        .where((name) => name == table)
        .map((_) {});
  }

  static Future<void> notifyChange({String? table}) async {
    _ensureControllers();
    if (!_dbChangeController.isClosed) {
      _dbChangeController.add(null);
    }
    if (table != null && !_tableChangeController.isClosed) {
      _tableChangeController.add(table);
    }
  }

  static Future<void> close({bool closeStreams = false}) async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    if (closeStreams) {
      await _dbChangeController.close();
      await _tableChangeController.close();
    }
  }

  @visibleForTesting
  static Future<void> resetForTesting() async {
    await close(closeStreams: true);
    _dbChangeController = StreamController<void>.broadcast();
    _tableChangeController = StreamController<String>.broadcast();
  }
}
