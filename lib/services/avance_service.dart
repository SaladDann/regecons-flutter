import '../db/app_db.dart';
import '../db/daos/avance_dao.dart';
import '../db/daos/actividad_dao.dart';
import '../models/avance.dart';
import '../models/actividad.dart';

class AvanceService {
  late AvanceDao _avanceDao;
  late ActividadDao _actividadDao;
  bool _inicializado = false;

  Future<void> _initialize() async {
    if (!_inicializado) {
      final db = await AppDatabase().database;
      _avanceDao = AvanceDao(db);
      _actividadDao = ActividadDao(db);
      _inicializado = true;
    }
  }

  // CREAR un nuevo avance
  Future<Avance> crearAvance({
    required int idActividad,
    required int idUsuario,
    required DateTime fecha,
    required double porcentajeEjecutado,
    required double horasTrabajadas,
    String? descripcion,
    String? evidenciaFoto,
    String estado = 'REGISTRADO',
  }) async {
    await _initialize();

    final actividad = await _actividadDao.getById(idActividad);
    if (actividad == null) throw Exception('La actividad no existe');

    final nuevoAvance = Avance(
      idActividad: idActividad,
      idUsuario: idUsuario,
      fecha: fecha,
      porcentajeEjecutado: porcentajeEjecutado,
      horasTrabajadas: horasTrabajadas, // puede ser null si no se pasa
      descripcion: descripcion,
      evidenciaFoto: evidenciaFoto,
      estado: estado,
    );

    final id = await _avanceDao.insert(nuevoAvance);
    nuevoAvance.idAvance = id;

    return nuevoAvance;
  }

  // ACTUALIZAR un avance existente
  Future<Avance> actualizarAvance(Avance avance) async {
    await _initialize();
    if (avance.idAvance == null) throw Exception('El avance no tiene ID');
    await _avanceDao.update(avance);
    return avance;
  }

  // ELIMINAR un avance
  Future<void> eliminarAvance(int idAvance) async {
    await _initialize();
    final avance = await _avanceDao.getById(idAvance);
    if (avance == null) throw Exception('El avance no existe');
    await _avanceDao.delete(idAvance);
  }

  // OBTENER avances por actividad
  Future<List<Avance>> obtenerAvancesPorActividad(int idActividad) async {
    await _initialize();
    return await _avanceDao.getByActividad(idActividad);
  }

  // OBTENER avances por usuario
  Future<List<Avance>> obtenerAvancesPorUsuario(int idUsuario) async {
    await _initialize();
    return await _avanceDao.getByUsuario(idUsuario);
  }

  // OBTENER avances por obra
  Future<List<Avance>> obtenerAvancesPorObra(int idObra) async {
    await _initialize();
    return await _avanceDao.getByObra(idObra);
  }

  // OBTENER avances por rango de fechas
  Future<List<Avance>> obtenerAvancesPorFechaRange(DateTime inicio, DateTime fin) async {
    await _initialize();
    return await _avanceDao.getByFechaRange(inicio, fin);
  }

  // OBTENER último avance de una actividad
  Future<Avance?> obtenerUltimoAvance(int idActividad) async {
    await _initialize();
    return await _avanceDao.getUltimoByActividad(idActividad);
  }

  // CAMBIAR estado de un avance
  Future<void> cambiarEstadoAvance(int idAvance, String nuevoEstado) async {
    await _initialize();
    final estadosValidos = ['REGISTRADO', 'EN_PROCESO', 'FINALIZADO', 'CANCELADO'];
    if (!estadosValidos.contains(nuevoEstado)) throw Exception('Estado no válido: $nuevoEstado');
    await _avanceDao.updateEstado(idAvance, nuevoEstado);
  }

  // CALCULAR porcentaje promedio de avance por actividad
  Future<double> calcularPromedioPorActividad(int idActividad) async {
    await _initialize();
    return await _avanceDao.calcularPromedioPorActividad(idActividad);
  }

  // CONTAR avances por actividad
  Future<int> contarAvancesPorActividad(int idActividad) async {
    await _initialize();
    return await _avanceDao.countByActividad(idActividad);
  }

  // CONTAR avances por usuario
  Future<int> contarAvancesPorUsuario(int idUsuario) async {
    await _initialize();
    return await _avanceDao.countByUsuario(idUsuario);
  }

  // SUMAR horas trabajadas por actividad
  Future<double> sumarHorasPorActividad(int idActividad) async {
    await _initialize();
    return await _avanceDao.sumHorasByActividad(idActividad);
  }

  // ELIMINAR todos los avances de una actividad
  Future<void> eliminarAvancesPorActividad(int idActividad) async {
    await _initialize();
    await _avanceDao.deleteByActividad(idActividad);
  }

  // BUSCAR avances por texto
  Future<List<Avance>> buscarAvances(String query) async {
    await _initialize();
    return await _avanceDao.search(query);
  }

  // OBTENER estadísticas generales de avances
  Future<Map<String, dynamic>> obtenerEstadisticas() async {
    await _initialize();
    return await _avanceDao.getEstadisticas();
  }

  // OBTENER resumen de actividad (actividad + avances)
  Future<Map<String, dynamic>> obtenerResumenActividad(int idActividad) async {
    await _initialize();

    final actividad = await _actividadDao.getById(idActividad);
    if (actividad == null) throw Exception('La actividad no existe');

    final avances = await _avanceDao.getByActividad(idActividad);
    final promedio = await _avanceDao.calcularPromedioPorActividad(idActividad);
    actividad.porcentajeCompletado = promedio;

    final totalHoras = avances.fold<double>(
      0,
          (sum, a) => sum + (a.horasTrabajadas ?? 0),
    );

    return {
      'actividad': actividad,
      'avances': avances,
      'porcentaje_completado': promedio,
      'total_avances': avances.length,
      'total_horas': totalHoras,
    };
  }

  // GENERAR reporte de avances
  Future<Map<String, dynamic>> generarReporteAvances({
    int? idObra,
    int? idUsuario,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    await _initialize();

    List<Avance> avances;

    if (idObra != null) {
      avances = await _avanceDao.getByObra(idObra);
    } else if (idUsuario != null) {
      avances = await _avanceDao.getByUsuario(idUsuario);
    } else if (fechaInicio != null && fechaFin != null) {
      avances = await _avanceDao.getByFechaRange(fechaInicio, fechaFin);
    } else {
      avances = await _avanceDao.getAll();
    }

    // Calcular estadísticas del reporte
    double totalHoras = 0;
    double porcentajePromedio = 0;

    for (var avance in avances) {
      totalHoras += avance.horasTrabajadas ?? 0;
      porcentajePromedio += avance.porcentajeEjecutado;
    }

    if (avances.isNotEmpty) {
      porcentajePromedio /= avances.length;
    }

    return {
      'total_avances': avances.length,
      'total_horas': totalHoras,
      'porcentaje_promedio': porcentajePromedio,
      'periodo': fechaInicio != null && fechaFin != null
          ? '${fechaInicio.toIso8601String()} - ${fechaFin.toIso8601String()}'
          : 'Todos',
      'avances': avances,
    };
  }
}




