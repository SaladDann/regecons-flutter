import 'package:sqflite/sqflite.dart';
import '../../../models/gestion_obras/usuario_obra.dart';

class UsuarioObraDao {
  final Database db;

  UsuarioObraDao(this.db);

  // ASIGNAR usuario a obra
  Future<int> insert(UsuarioObra usuarioObra) async {
    return await db.insert('usuario_obra', usuarioObra.toMap());
  }

  // ELIMINAR asignación de usuario a obra
  Future<int> delete(int idUsuario, int idObra) async {
    return await db.delete(
      'usuario_obra',
      where: 'id_usuario = ? AND id_obra = ?',
      whereArgs: [idUsuario, idObra],
    );
  }

  // OBTENER gestion_obras de un usuario
  Future<List<int>> getObrasByUsuario(int idUsuario) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'usuario_obra',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );

    return List.generate(maps.length, (i) => maps[i]['id_obra'] as int);
  }

  // OBTENER usuarios de una obra
  Future<List<int>> getUsuariosByObra(int idObra) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'usuario_obra',
      where: 'id_obra = ?',
      whereArgs: [idObra],
    );

    return List.generate(maps.length, (i) => maps[i]['id_usuario'] as int);
  }

  // VERIFICAR si usuario tiene acceso a obra
  Future<bool> tieneAcceso(int idUsuario, int idObra) async {
    final result = await db.rawQuery('''
      SELECT COUNT(*) FROM usuario_obra 
      WHERE id_usuario = ? AND id_obra = ?
    ''', [idUsuario, idObra]);

    return Sqflite.firstIntValue(result) != 0;
  }

  // ELIMINAR todas las asignaciones de una obra
  Future<int> deleteByObra(int idObra) async {
    return await db.delete(
      'usuario_obra',
      where: 'id_obra = ?',
      whereArgs: [idObra],
    );
  }

  // ELIMINAR todas las asignaciones de un usuario
  Future<int> deleteByUsuario(int idUsuario) async {
    return await db.delete(
      'usuario_obra',
      where: 'id_usuario = ?',
      whereArgs: [idUsuario],
    );
  }
}