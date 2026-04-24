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
      version: 7,
      onCreate: (db, version) async {
        await _createBirthdaysTable(db);
        await _createUserSessionTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try { await _createUserSessionTable(db); } catch (_) {}
        }
        // Repair any broken intermediate migration — safe to run always
        await _ensureColumn(db, 'user_session', 'profile_completed',
            'INTEGER NOT NULL DEFAULT 0');
        await _ensureColumn(db, 'birthdays', 'is_self',
            'INTEGER NOT NULL DEFAULT 0');
        await _ensureColumn(db, 'birthdays', 'owner_user_id', 'INTEGER');
        await _ensureColumn(db, 'birthdays', 'backend_birthday_id', 'INTEGER');
      },
    );
  }

  Future<void> _ensureColumn(
      Database db, String table, String column, String definition) async {
    final info = await db.rawQuery('PRAGMA table_info($table)');
    final exists = info.any((row) => row['name'] == column);
    if (!exists) {
      await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  Future<void> _createBirthdaysTable(Database db) => db.execute('''
      CREATE TABLE birthdays (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_user_id INTEGER NOT NULL,
        backend_birthday_id INTEGER,
        name TEXT NOT NULL,
        birth_day INTEGER NOT NULL,
        birth_month INTEGER NOT NULL,
        birth_year INTEGER,
        gender TEXT,
        notes TEXT,
        interests TEXT,
        is_self INTEGER NOT NULL DEFAULT 0,
        notify_days_before INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

  Future<void> _createUserSessionTable(Database db) => db.execute('''
      CREATE TABLE user_session (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        firebase_uid TEXT NOT NULL,
        laravel_user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        photo_b64 TEXT,
        laravel_token TEXT NOT NULL,
        profile_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

  // ── Birthdays ────────────────────────────────────────────

  Future<int> insertBirthday(
    Birthday b, {
    required int ownerUserId,
  }) async {
    final data = b.toMap()..['owner_user_id'] = ownerUserId;
    return (await db).insert('birthdays', data);
  }

  Future<List<Birthday>> getAllBirthdays({
    required int ownerUserId,
  }) async {
    final rows = await (await db).query(
      'birthdays',
      where: 'owner_user_id = ?',
      whereArgs: [ownerUserId],
      orderBy: 'is_self DESC, birth_month, birth_day',
    );
    return rows.map(Birthday.fromMap).toList();
  }

  Future<Birthday?> getSelfBirthday({
    required int ownerUserId,
  }) async {
    final rows = await (await db).query(
      'birthdays',
      where: 'is_self = 1 AND owner_user_id = ?',
      whereArgs: [ownerUserId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Birthday.fromMap(rows.first);
  }

  Future<int> updateBirthday(
    Birthday b, {
    required int ownerUserId,
  }) async =>
      (await db).update(
        'birthdays',
        b.toMap(),
        where: 'id = ? AND owner_user_id = ?',
        whereArgs: [b.id, ownerUserId],
      );

  Future<int> deleteBirthday(
    int id, {
    required int ownerUserId,
  }) async =>
      (await db).delete(
        'birthdays',
        where: 'id = ? AND owner_user_id = ?',
        whereArgs: [id, ownerUserId],
      );
}
