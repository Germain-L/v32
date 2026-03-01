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
      version: 5,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  @visibleForTesting
  static Future<void> useInMemoryDatabaseForTesting() async {
    _database = await openDatabase(
      inMemoryDatabasePath,
      version: 5,
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

    // Create meal_images table
    await db.execute('''
      CREATE TABLE meal_images(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mealId INTEGER NOT NULL,
        imagePath TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (mealId) REFERENCES meals(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_meal_images_mealId ON meal_images(mealId)');
    await db.execute('CREATE INDEX idx_meal_images_createdAt ON meal_images(createdAt)');

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

    // Create sync_queue table for pending operations
    await db.execute('''
      CREATE TABLE sync_queue(
        id TEXT PRIMARY KEY,
        entity_type TEXT NOT NULL,
        operation_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        retry_count INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_sync_queue_created_at ON sync_queue(created_at)',
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
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE sync_queue(
          id TEXT PRIMARY KEY,
          entity_type TEXT NOT NULL,
          operation_type TEXT NOT NULL,
          payload TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          retry_count INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_sync_queue_created_at ON sync_queue(created_at)',
      );
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE meal_images(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          mealId INTEGER NOT NULL,
          imagePath TEXT NOT NULL,
          createdAt INTEGER NOT NULL,
          FOREIGN KEY (mealId) REFERENCES meals(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX idx_meal_images_mealId ON meal_images(mealId)');
      await db.execute('CREATE INDEX idx_meal_images_createdAt ON meal_images(createdAt)');
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
