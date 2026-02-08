import 'package:sqflite/sqflite.dart';
import '../../../models/gestion_obras/avance.dart';

class AvanceDao {
  final Database db;

  AvanceDao(this.db);

  // INSERTAR un nuevo avance
  Future<int> insert(Avance avance) async {
    return await db.insert('avances', avance.toMap());
  }

  // ACTUALIZAR un avance existente
  Future<int> update(Avance avance) async {
    return await db.update(
      'avances',
      avance.toMap(),
      where: 'id_avance = ?',
      whereArgs: [avance.idAvance],
    );
  }

  // ELIMINAR un avance por ID
  Future<int> delete(int idAvance) async {
    return await db.delete(
      'avances',
      where: 'id_avance = ?',
      whereArgs: [idAvance],
    );
  }

  // OBTENER todos los avances
  Future<List<Avance>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query(
      'avances',
      orderBy: 'fecha DESC',
    );
    return List.generate(maps.length, (i) => Avance.fromMap(maps[i]));
  }

  // OBTENER avance por ID
  Future<Avance?> getById(int idAvance) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'avances',
      where: 'id_avance = ?',
      whereArgs: [idAvance],
    );
    if (maps.isNotEmpty) {
      return Avance.fromMap(maps.first);
    }
    return null;
  }

  // OBTENER avances por actividad
  Future<List<Avance>> getByActividad(int idActividad) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'avances',
      where: 'id_actividad = ?',
      whereArgs: [idActividad],
      orderBy: 'fecha DESC',
    );
    return List.generate(maps.length, (i) => Avance.fromMap(maps[i]));
  }

  // OBTENER avances por obra
  Future<List<Avance>> getByObra(int idObra) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'avances',
      where: 'id_obra = ?',
      whereArgs: [idObra],
      orderBy: 'fecha DESC',
    );
    return List.generate(maps.length, (i) => Avance.fromMap(maps[i]));
  }


  // OBTENER avances por rango de fechas
  Future<List<Avance>> getByFechaRange(DateTime start, DateTime end) async {
    final startMillis = start.millisecondsSinceEpoch;
    final endMillis = end.millisecondsSinceEpoch;

    final List<Map<String, dynamic>> maps = await db.query(
      'avances',
      where: 'fecha >= ? AND fecha <= ?',
      whereArgs: [startMillis, endMillis],
      orderBy: 'fecha DESC',
    );
    return List.generate(maps.length, (i) => Avance.fromMap(maps[i]));
  }

  // OBTENER avances por estado
  Future<List<Avance>> getByEstado(String estado) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'avances',
      where: 'estado = ?',
      whereArgs: [estado],
      orderBy: 'fecha DESC',
    );
    return List.generate(maps.length, (i) => Avance.fromMap(maps[i]));
  }

  // CONTAR avances por actividad
  Future<int> countByActividad(int idActividad) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM avances WHERE id_actividad = ?',
      [idActividad],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // CONTAR avances por obra
  Future<int> countByObra(int idObra) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM avances WHERE id_obra = ?',
      [idObra],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }


  // CONTAR total de horas trabajadas por actividad
  Future<double> sumHorasByActividad(int idActividad) async {
    final result = await db.rawQuery('''
      SELECT SUM(horas_trabajadas) as total_horas
      FROM avances
      WHERE id_actividad = ? AND horas_trabajadas IS NOT NULL
    ''', [idActividad]);

    if (result.isNotEmpty && result.first['total_horas'] != null) {
      return (result.first['total_horas'] as num).toDouble();
    }
    return 0.0;
  }

  // OBTENER último avance por actividad
  Future<Avance?> getUltimoByActividad(int idActividad) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'avances',
      where: 'id_actividad = ?',
      whereArgs: [idActividad],
      orderBy: 'fecha DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Avance.fromMap(maps.first);
    }
    return null;
  }

  // ACTUALIZAR estado de un avance
  Future<int> updateEstado(int idAvance, String estado) async {
    return await db.update(
      'avances',
      {'estado': estado},
      where: 'id_avance = ?',
      whereArgs: [idAvance],
    );
  }

  // ELIMINAR todos los avances de una actividad
  Future<int> deleteByActividad(int idActividad) async {
    return await db.delete(
      'avances',
      where: 'id_actividad = ?',
      whereArgs: [idActividad],
    );
  }

  // BUSCAR avances por texto en descripción
  Future<List<Avance>> search(String query) async {
    final searchTerm = '%$query%';
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT * FROM avances 
      WHERE descripcion LIKE ? 
      OR estado LIKE ?
      ORDER BY fecha DESC
    ''', [searchTerm, searchTerm]);

    return List.generate(maps.length, (i) => Avance.fromMap(maps[i]));
  }

  // OBTENER estadísticas de avances
  Future<Map<String, dynamic>> getEstadisticas() async {
    final total = await db.rawQuery('SELECT COUNT(*) FROM avances');
    final finalizados = await db.rawQuery(
      'SELECT COUNT(*) FROM avances WHERE estado = ?',
      ['FINALIZADO'],
    );
    final enProceso = await db.rawQuery(
      'SELECT COUNT(*) FROM avances WHERE estado = ?',
      const ['EN_PROCESO'],
    );
    final pendientes = await db.rawQuery(
      'SELECT COUNT(*) FROM avances WHERE estado = ?',
      ['PENDIENTE'],
    );

    return {
      'total': Sqflite.firstIntValue(total) ?? 0,
      'finalizados': Sqflite.firstIntValue(finalizados) ?? 0,
      'en_proceso': Sqflite.firstIntValue(enProceso) ?? 0,
      'pendientes': Sqflite.firstIntValue(pendientes) ?? 0,
    };
  }

}