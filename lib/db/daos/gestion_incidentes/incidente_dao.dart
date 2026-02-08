import 'package:sqflite/sqflite.dart';

import '../../../models/gestion_incidentes/incidente.dart';
import '../../app_db.dart';

class IncidenteDao {
  final AppDatabase _appDatabase = AppDatabase();

  // =========================
  // INSERTAR
  // =========================
  Future<int> insertarIncidente(Incidente incidente) async {
    final Database db = await _appDatabase.database;
    return await db.insert(
      'reportes_seguridad',
      incidente.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // =========================
  // ACTUALIZAR
  // =========================
  Future<int> actualizarIncidente(Incidente incidente) async {
    final Database db = await _appDatabase.database;
    return await db.update(
      'reportes_seguridad',
      incidente.toMap(),
      where: 'id_reporte = ?',
      whereArgs: [incidente.idReporte],
    );
  }

  // =========================
  // ELIMINAR
  // =========================
  Future<int> eliminarIncidente(int idReporte) async {
    final Database db = await _appDatabase.database;
    return await db.delete(
      'reportes_seguridad',
      where: 'id_reporte = ?',
      whereArgs: [idReporte],
    );
  }

  // =========================
  // OBTENER POR ID
  // =========================
  Future<Incidente?> obtenerPorId(int idReporte) async {
    final Database db = await _appDatabase.database;
    final result = await db.query(
      'reportes_seguridad',
      where: 'id_reporte = ?',
      whereArgs: [idReporte],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return Incidente.fromMap(result.first);
  }

  // =========================
  // LISTAR POR OBRA
  // =========================
  Future<List<Incidente>> listarPorObra(int idObra) async {
    final Database db = await _appDatabase.database;
    final result = await db.query(
      'reportes_seguridad',
      where: 'id_obra = ?',
      whereArgs: [idObra],
      orderBy: 'fecha_evento DESC',
    );

    return result.map((e) => Incidente.fromMap(e)).toList();
  }

  // =========================
  // LISTAR CON FILTROS
  // =========================
  Future<List<Incidente>> listarConFiltros({
    required int idObra,
    String? tipo,
    String? severidad,
    String? estado,
    String? textoBusqueda,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    final Database db = await _appDatabase.database;

    final List<String> where = ['id_obra = ?'];
    final List<dynamic> args = [idObra];

    if (tipo != null) {
      where.add('tipo = ?');
      args.add(tipo);
    }

    if (severidad != null) {
      where.add('severidad = ?');
      args.add(severidad);
    }

    if (estado != null) {
      where.add('estado = ?');
      args.add(estado);
    }

    if (textoBusqueda != null && textoBusqueda.isNotEmpty) {
      where.add('descripcion LIKE ?');
      args.add('%$textoBusqueda%');
    }

    if (fechaInicio != null) {
      where.add('fecha_evento >= ?');
      args.add(fechaInicio.millisecondsSinceEpoch);
    }

    if (fechaFin != null) {
      where.add('fecha_evento <= ?');
      args.add(fechaFin.millisecondsSinceEpoch);
    }

    final result = await db.query(
      'reportes_seguridad',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'fecha_evento DESC',
    );

    return result.map((e) => Incidente.fromMap(e)).toList();
  }

  // =========================
  // ACTUALIZAR ESTADO
  // =========================
  Future<int> actualizarEstado(
      int idReporte,
      String nuevoEstado,
      ) async {
    final Database db = await _appDatabase.database;
    return await db.update(
      'reportes_seguridad',
      {'estado': nuevoEstado},
      where: 'id_reporte = ?',
      whereArgs: [idReporte],
    );
  }
}
