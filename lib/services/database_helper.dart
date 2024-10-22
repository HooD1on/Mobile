// lib/services/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/history_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('history.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      imagePath TEXT,
      result TEXT,
      dateTime TEXT
    )
    ''');
  }

  Future<int> insert(History history) async {
    final db = await instance.database;
    return await db.insert('history', history.toMap());
  }

  Future<List<History>> getAllHistories() async {
    final db = await instance.database;
    final maps = await db.query('history', orderBy: 'dateTime DESC');
    return List.generate(maps.length, (i) => History.fromMap(maps[i]));
  }

  Future<void> delete(int id) async {
    final db = await instance.database;
    await db.delete('history', where: 'id = ?', whereArgs: [id]);
  }
}