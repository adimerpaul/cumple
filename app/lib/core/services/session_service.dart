import '../database/database_helper.dart';
import '../../models/user_session.dart';

class SessionService {
  static final SessionService instance = SessionService._();
  SessionService._();

  Future<UserSession?> getSession() async {
    final db = await DatabaseHelper.instance.db;
    final rows = await db.query('user_session', limit: 1);
    if (rows.isEmpty) return null;
    return UserSession.fromMap(rows.first);
  }

  Future<void> saveSession(UserSession session) async {
    final db = await DatabaseHelper.instance.db;
    await db.delete('user_session');
    await db.insert('user_session', session.toMap());
  }

  Future<void> clearSession() async {
    final db = await DatabaseHelper.instance.db;
    await db.delete('user_session');
  }
}
