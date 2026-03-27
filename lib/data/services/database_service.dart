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
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  @visibleForTesting
  static Future<void> useInMemoryDatabaseForTesting() async {
    _database = await openDatabase(
      inMemoryDatabasePath,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE meals(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        slot TEXT NOT NULL,
        date INTEGER NOT NULL,
        description TEXT,
        imagePath TEXT,
        updated_at INTEGER NOT NULL,
        pending_sync INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('CREATE INDEX idx_date ON meals(date)');
    await db.execute('CREATE INDEX idx_slot ON meals(slot)');
    await db.execute('CREATE INDEX idx_server_id ON meals(server_id)');
    await db.execute('CREATE INDEX idx_pending_sync ON meals(pending_sync)');

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

    // Create sync_metadata table for tracking last sync timestamp
    await db.execute('''
      CREATE TABLE sync_metadata(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Create workouts table
    await db.execute('''
      CREATE TABLE workouts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        type TEXT NOT NULL,
        date INTEGER NOT NULL,
        duration_seconds INTEGER,
        distance_meters REAL,
        calories INTEGER,
        heart_rate_avg INTEGER,
        heart_rate_max INTEGER,
        notes TEXT,
        source TEXT NOT NULL,
        source_id TEXT,
        strava_data TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        pending_sync INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_workouts_date ON workouts(date)');
    await db.execute('CREATE INDEX idx_workouts_type ON workouts(type)');
    await db.execute('CREATE INDEX idx_workouts_server_id ON workouts(server_id)');
    await db.execute('CREATE INDEX idx_workouts_pending_sync ON workouts(pending_sync)');

    // Create body_metrics table
    await db.execute('''
      CREATE TABLE body_metrics(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        date INTEGER NOT NULL,
        weight REAL,
        body_fat REAL,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        pending_sync INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_body_metrics_date ON body_metrics(date)');
    await db.execute('CREATE INDEX idx_body_metrics_server_id ON body_metrics(server_id)');
    await db.execute('CREATE INDEX idx_body_metrics_pending_sync ON body_metrics(pending_sync)');

    // Create daily_checkins table
    await db.execute('''
      CREATE TABLE daily_checkins(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        date INTEGER NOT NULL,
        mood INTEGER,
        energy INTEGER,
        focus INTEGER,
        stress INTEGER,
        sleep_hours REAL,
        sleep_quality INTEGER,
        notes TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        pending_sync INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_daily_checkins_date ON daily_checkins(date)');
    await db.execute('CREATE INDEX idx_daily_checkins_server_id ON daily_checkins(server_id)');
    await db.execute('CREATE INDEX idx_daily_checkins_pending_sync ON daily_checkins(pending_sync)');

    // Create screen_times table
    await db.execute('''
      CREATE TABLE screen_times(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        date INTEGER NOT NULL,
        total_ms INTEGER NOT NULL,
        pickups INTEGER,
        created_at INTEGER NOT NULL,
        pending_sync INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_screen_times_date ON screen_times(date)');
    await db.execute('CREATE INDEX idx_screen_times_server_id ON screen_times(server_id)');
    await db.execute('CREATE INDEX idx_screen_times_pending_sync ON screen_times(pending_sync)');

    // Create screen_time_apps table
    await db.execute('''
      CREATE TABLE screen_time_apps(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        screen_time_id INTEGER NOT NULL,
        package_name TEXT NOT NULL,
        app_name TEXT NOT NULL,
        duration_ms INTEGER NOT NULL,
        FOREIGN KEY (screen_time_id) REFERENCES screen_times(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_screen_time_apps_screen_time_id ON screen_time_apps(screen_time_id)');
    await db.execute('CREATE INDEX idx_screen_time_apps_package_name ON screen_time_apps(package_name)');

    // Create hydrations table
    await db.execute('''
      CREATE TABLE hydrations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER,
        date INTEGER NOT NULL,
        amount_ml INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        pending_sync INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('CREATE INDEX idx_hydrations_date ON hydrations(date)');
    await db.execute('CREATE INDEX idx_hydrations_server_id ON hydrations(server_id)');
    await db.execute('CREATE INDEX idx_hydrations_pending_sync ON hydrations(pending_sync)');
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
    if (oldVersion < 6) {
      // Add remote-first sync columns
      await db.execute('ALTER TABLE meals ADD COLUMN server_id INTEGER');
      await db.execute('ALTER TABLE meals ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0');
      await db.execute('ALTER TABLE meals ADD COLUMN pending_sync INTEGER NOT NULL DEFAULT 0');

      // Create indexes for new columns
      await db.execute('CREATE INDEX idx_server_id ON meals(server_id)');
      await db.execute('CREATE INDEX idx_pending_sync ON meals(pending_sync)');

      // Create sync_metadata table
      await db.execute('''
        CREATE TABLE sync_metadata(
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');

      // Set updated_at for existing meals
      await db.execute('UPDATE meals SET updated_at = date WHERE updated_at = 0');
    }
    if (oldVersion < 7) {
      // Add new tables for Sprint 2

      // Create workouts table
      await db.execute('''
        CREATE TABLE workouts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id INTEGER,
          type TEXT NOT NULL,
          date INTEGER NOT NULL,
          duration_seconds INTEGER,
          distance_meters REAL,
          calories INTEGER,
          heart_rate_avg INTEGER,
          heart_rate_max INTEGER,
          notes TEXT,
          source TEXT NOT NULL,
          source_id TEXT,
          strava_data TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          pending_sync INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('CREATE INDEX idx_workouts_date ON workouts(date)');
      await db.execute('CREATE INDEX idx_workouts_type ON workouts(type)');
      await db.execute('CREATE INDEX idx_workouts_server_id ON workouts(server_id)');
      await db.execute('CREATE INDEX idx_workouts_pending_sync ON workouts(pending_sync)');

      // Create body_metrics table
      await db.execute('''
        CREATE TABLE body_metrics(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id INTEGER,
          date INTEGER NOT NULL,
          weight REAL,
          body_fat REAL,
          notes TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          pending_sync INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('CREATE INDEX idx_body_metrics_date ON body_metrics(date)');
      await db.execute('CREATE INDEX idx_body_metrics_server_id ON body_metrics(server_id)');
      await db.execute('CREATE INDEX idx_body_metrics_pending_sync ON body_metrics(pending_sync)');

      // Create daily_checkins table
      await db.execute('''
        CREATE TABLE daily_checkins(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id INTEGER,
          date INTEGER NOT NULL,
          mood INTEGER,
          energy INTEGER,
          focus INTEGER,
          stress INTEGER,
          sleep_hours REAL,
          sleep_quality INTEGER,
          notes TEXT,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          pending_sync INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('CREATE INDEX idx_daily_checkins_date ON daily_checkins(date)');
      await db.execute('CREATE INDEX idx_daily_checkins_server_id ON daily_checkins(server_id)');
      await db.execute('CREATE INDEX idx_daily_checkins_pending_sync ON daily_checkins(pending_sync)');

      // Create screen_times table
      await db.execute('''
        CREATE TABLE screen_times(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id INTEGER,
          date INTEGER NOT NULL,
          total_ms INTEGER NOT NULL,
          pickups INTEGER,
          created_at INTEGER NOT NULL,
          pending_sync INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('CREATE INDEX idx_screen_times_date ON screen_times(date)');
      await db.execute('CREATE INDEX idx_screen_times_server_id ON screen_times(server_id)');
      await db.execute('CREATE INDEX idx_screen_times_pending_sync ON screen_times(pending_sync)');

      // Create screen_time_apps table
      await db.execute('''
        CREATE TABLE screen_time_apps(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id INTEGER,
          screen_time_id INTEGER NOT NULL,
          package_name TEXT NOT NULL,
          app_name TEXT NOT NULL,
          duration_ms INTEGER NOT NULL,
          FOREIGN KEY (screen_time_id) REFERENCES screen_times(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX idx_screen_time_apps_screen_time_id ON screen_time_apps(screen_time_id)');
      await db.execute('CREATE INDEX idx_screen_time_apps_package_name ON screen_time_apps(package_name)');

      // Create hydrations table
      await db.execute('''
        CREATE TABLE hydrations(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          server_id INTEGER,
          date INTEGER NOT NULL,
          amount_ml INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          pending_sync INTEGER NOT NULL DEFAULT 0
        )
      ''');
      await db.execute('CREATE INDEX idx_hydrations_date ON hydrations(date)');
      await db.execute('CREATE INDEX idx_hydrations_server_id ON hydrations(server_id)');
      await db.execute('CREATE INDEX idx_hydrations_pending_sync ON hydrations(pending_sync)');
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
