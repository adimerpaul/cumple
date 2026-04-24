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
      version: 2,
      onCreate: (db, version) async {
        await _createBirthdaysTable(db);
        await _createUserSessionTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createUserSessionTable(db);
        }
      },
    );
  }

  Future<void> _createBirthdaysTable(Database db) async {
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
  }

  Future<void> _createUserSessionTable(Database db) async {
    await db.execute('''
      CREATE TABLE user_session (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_uid TEXT NOT NULL,
        laravel_user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        photo_b64 TEXT,
        laravel_token TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // ── Birthdays ────────────────────────────────────────────
  Future<int> insertBirthday(Birthday b) async {
    return (await db).insert('birthdays', b.toMap());
  }

  Future<List<Birthday>> getAllBirthdays() async {
    final rows = await (await db).query('birthdays', orderBy: 'birth_month, birth_day');
    return rows.map(Birthday.fromMap).toList();
  }

  Future<int> updateBirthday(Birthday b) async {
    return (await db).update('birthdays', b.toMap(), where: 'id = ?', whereArgs: [b.id]);
  }

  Future<int> deleteBirthday(int id) async {
    return (await db).delete('birthdays', where: 'id = ?', whereArgs: [id]);
  }
}
