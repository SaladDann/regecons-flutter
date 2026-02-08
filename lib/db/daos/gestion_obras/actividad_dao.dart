import 'package:sqflite/sqflite.dart';
import '../../../models/gestion_obras/actividad.dart';

class ActividadDao {
  final Database db;

  ActividadDao(this.db);

  // INSERTAR una nueva actividad
  Future<int> insert(Actividad actividad) async {
    return await db.insert('actividades', actividad.toMap());
  }

  // ACTUALIZAR una actividad existente
  Future<int> update(Actividad actividad) async {
    return await db.update(
      'actividades',
      actividad.toMap(),
      where: 'id_actividad = ?',
      whereArgs: [actividad.idActividad],
    );
  }

  // ELIMINAR una actividad por ID
  Future<int> delete(int idActividad) async {
    return await db.delete(
      'actividades',
      where: 'id_actividad = ?',
      whereArgs: [idActividad],
    );
  }

  // OBTENER todas las actividades
  Future<List<Actividad>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query('actividades');
    return List.generate(maps.length, (i) => Actividad.fromMap(maps[i]));
  }

  // OBTENER actividad por ID
  Future<Actividad?> getById(int idActividad) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'actividades',
      where: 'id_actividad = ?',
      whereArgs: [idActividad],
    );
    if (maps.isNotEmpty) {
      return Actividad.fromMap(maps.first);
    }
    return null;
  }

  // OBTENER actividades por obra
  Future<List<Actividad>> getByObra(int idObra) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'actividades',
      where: 'id_obra = ?',
      whereArgs: [idObra],
    );
    return List.generate(maps.length, (i) => Actividad.fromMap(maps[i]));
  }

  // OBTENER actividades por estado
  Future<List<Actividad>> getByEstado(String estado) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'actividades',
      where: 'estado = ?',
      whereArgs: [estado],
      orderBy: 'id_obra',
    );
    return List.generate(maps.length, (i) => Actividad.fromMap(maps[i]));
  }

  // OBTENER actividades por obra y estado
  Future<List<Actividad>> getByObraAndEstado(int idObra, String estado) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'actividades',
      where: 'id_obra = ? AND estado = ?',
      whereArgs: [idObra, estado],
    );
    return List.generate(maps.length, (i) => Actividad.fromMap(maps[i]));
  }

  // CONTAR actividades por obra
  Future<int> countByObra(int idObra) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM actividades WHERE id_obra = ?',
      [idObra],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // CONTAR actividades por estado
  Future<int> countByEstado(String estado) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM actividades WHERE estado = ?',
      [estado],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ACTUALIZAR estado de una actividad
  Future<int> updateEstado(int idActividad, String estado) async {
    return await db.update(
      'actividades',
      {'estado': estado},
      where: 'id_actividad = ?',
      whereArgs: [idActividad],
    );
  }

  // BUSCAR actividades por nombre o descripción
  Future<List<Actividad>> search(String query) async {
    final searchTerm = '%$query%';
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM actividades 
      WHERE nombre LIKE ? 
      OR descripcion LIKE ?
      ORDER BY id_obra
    ''', [searchTerm, searchTerm]);

    return List.generate(maps.length, (i) => Actividad.fromMap(maps[i]));
  }

  // BUSCAR actividades por obra y texto
  Future<List<Actividad>> searchByObra(int idObra, String query) async {
    final searchTerm = '%$query%';
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM actividades 
      WHERE id_obra = ? 
      AND (nombre LIKE ? OR descripcion LIKE ?)
      ORDER BY id_actividad
    ''', [idObra, searchTerm, searchTerm]);

    return List.generate(maps.length, (i) => Actividad.fromMap(maps[i]));
  }

  // OBTENER actividades próximas a vencer (con fecha estimada)
  Future<List<Actividad>> getProximasAVencer({int dias = 7}) async {
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM actividades 
      WHERE estado = 'PENDIENTE' OR estado = 'EN_PROGRESO'
      ORDER BY id_obra
      LIMIT 20
    ''');

    return List.generate(maps.length, (i) => Actividad.fromMap(maps[i]));
  }

  // OBTENER estadísticas de actividades (solo conteo de avances)
  Future<Map<String, dynamic>> getEstadisticasByObra(int idObra) async {
    final total = await db.rawQuery(
      'SELECT COUNT(*) FROM actividades WHERE id_obra = ?',
      [idObra],
    );
    final completadas = await db.rawQuery(
      'SELECT COUNT(*) FROM actividades WHERE id_obra = ? AND estado = ?',
      [idObra, 'COMPLETADA'],
    );
    final enProgreso = await db.rawQuery(
      'SELECT COUNT(*) FROM actividades WHERE id_obra = ? AND estado = ?',
      [idObra, 'EN_PROGRESO'],
    );
    final registrados = await db.rawQuery(
      'SELECT COUNT(*) FROM avances WHERE id_actividad IN (SELECT id_actividad FROM actividades WHERE id_obra = ?)',
      [idObra],
    );

    return {
      'total': Sqflite.firstIntValue(total) ?? 0,
      'registrados': Sqflite.firstIntValue(registrados) ?? 0,
      'en_proceso': Sqflite.firstIntValue(enProgreso) ?? 0,
      'finalizados': Sqflite.firstIntValue(completadas) ?? 0,
    };
  }

}

