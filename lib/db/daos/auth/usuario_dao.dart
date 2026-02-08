import 'package:sqflite/sqflite.dart';
import '../../../models/auth/usuario.dart';

class UsuarioDao {
  final Database db;

  UsuarioDao(this.db);

  Future<int> insert(Usuario usuario) async {
    return await db.insert('usuarios', usuario.toMap());
  }

  Future<Usuario?> getByUsername(String username) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'usuarios',
      where: 'username = ?',
      whereArgs: [username],
    );

    if (maps.isNotEmpty) {
      return Usuario.fromMap(maps.first);
    }
    return null;
  }

  Future<Usuario?> getByEmail(String email) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return Usuario.fromMap(maps.first);
    }
    return null;
  }

  Future<bool> exists(String username) async {
    final count = await db.rawQuery(
      'SELECT COUNT(*) FROM usuarios WHERE username = ?',
      [username],
    );
    return Sqflite.firstIntValue(count) != 0;
  }

  Future<void> updateLastPasswordChange(int userId, DateTime fecha) async {
    await db.update(
      'usuarios',
      {'fecha_ultimo_cambio_password': fecha.millisecondsSinceEpoch},
      where: 'id_usuario = ?',
      whereArgs: [userId],
    );
  }

  Future<List<Usuario>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query('usuarios');
    return List.generate(maps.length, (i) => Usuario.fromMap(maps[i]));
  }
}