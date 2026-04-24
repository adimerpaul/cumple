import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/birthday.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  DatabaseHelper._();

  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'cumple.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE birthdays (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            birth_day INTEGER NOT NULL,
            birth_month INTEGER NOT NULL,
            birth_year INTEGER,
            gender TEXT,
            notes TEXT,
            interests TEXT,
            notify_days_before INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertBirthday(Birthday b) async {
    final database = await db;
    return database.insert('birthdays', b.toMap());
  }

  Future<List<Birthday>> getAllBirthdays() async {
    final database = await db;
    final rows = await database.query('birthdays', orderBy: 'birth_month, birth_day');
    return rows.map(Birthday.fromMap).toList();
  }

  Future<int> updateBirthday(Birthday b) async {
    final database = await db;
    return database.update('birthdays', b.toMap(), where: 'id = ?', whereArgs: [b.id]);
  }

  Future<int> deleteBirthday(int id) async {
    final database = await db;
    return database.delete('birthdays', where: 'id = ?', whereArgs: [id]);
  }
}
