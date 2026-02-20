import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static Database? _database;
  static StreamController<void> _dbChangeController =
      StreamController<void>.broadcast();

  static Stream<void> get dbChanges => _dbChangeController.stream;

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
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

  static Future<void> notifyChange() async {
    if (_dbChangeController.isClosed) return;
    _dbChangeController.add(null);
  }

  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    await _dbChangeController.close();
  }

  @visibleForTesting
  static Future<void> resetForTesting() async {
    await close();
    _dbChangeController = StreamController<void>.broadcast();
  }
}
