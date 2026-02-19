import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  static Database? _database;
  static final _dbChangeController = StreamController<void>.broadcast();

  static Stream<void> get dbChanges => _dbChangeController.stream;

  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'diet_database.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
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
  }

  static Future<void> notifyChange() async {
    _dbChangeController.add(null);
  }

  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    await _dbChangeController.close();
  }
}
