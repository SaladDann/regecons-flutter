import 'package:sqflite/sqflite.dart';
import '../../../models/auth/sesion.dart';

class SesionDao {
  final Database db;

  SesionDao(this.db);

  Future<int> insert(Sesion sesion) async {
    return await db.insert('sesiones', sesion.toMap());
  }

  Future<Sesion?> getActiveByToken(String token) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'sesiones',
      where: 'token = ? AND activa = 1',
      whereArgs: [token],
    );

    if (maps.isNotEmpty) {
      return Sesion.fromMap(maps.first);
    }
    return null;
  }

  Future<Sesion?> getLastActiveByUser(int userId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'sesiones',
      where: 'id_usuario = ? AND activa = 1',
      whereArgs: [userId],
      orderBy: 'fecha_creacion DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Sesion.fromMap(maps.first);
    }
    return null;
  }

  Future<void> invalidateAllUserSessions(int userId) async {
    await db.update(
      'sesiones',
      {'activa': 0},
      where: 'id_usuario = ? AND activa = 1',
      whereArgs: [userId],
    );
  }

  Future<void> invalidateSession(int sessionId) async {
    await db.update(
      'sesiones',
      {'activa': 0},
      where: 'id_sesion = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> cleanExpiredSessions() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.delete(
      'sesiones',
      where: 'fecha_expiracion < ?',
      whereArgs: [now],
    );
  }

  Future<List<Sesion>> getActiveSessions() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'sesiones',
      where: 'activa = 1',
    );
    return List.generate(maps.length, (i) => Sesion.fromMap(maps[i]));
  }
}