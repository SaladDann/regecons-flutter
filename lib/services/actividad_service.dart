import '../db/app_db.dart';
import '../db/daos/actividad_dao.dart';
import '../db/daos/avance_dao.dart';
import '../db/daos/obra_dao.dart';
import '../models/actividad.dart';

class ActividadService {
  late ActividadDao _actividadDao;
  late AvanceDao _avanceDao;
  late ObraDao _obraDao;
  bool _inicializado = false;

  Future<void> _initialize() async {
    if (!_inicializado) {
      final db = await AppDatabase().database;
      _actividadDao = ActividadDao(db);
      _avanceDao = AvanceDao(db);
      _obraDao = ObraDao(db);
      _inicializado = true;
    }
  }

  // CREAR actividad
  Future<Actividad> crearActividad({
    required int idObra,
    required String nombre,
    String? descripcion,
  }) async {
    await _initialize();
    final obra = await _obraDao.getById(idObra);
    if (obra == null) throw Exception('La obra no existe');

    final nuevaActividad = Actividad(
      idObra: idObra,
      nombre: nombre,
      descripcion: descripcion,
      estado: 'PENDIENTE',
    );

    final id = await _actividadDao.insert(nuevaActividad);
    nuevaActividad.idActividad = id;
    return nuevaActividad;
  }

  // ACTUALIZAR actividad
  Future<Actividad> actualizarActividad(Actividad actividad) async {
    await _initialize();
    if (actividad.idActividad == null) throw Exception('La actividad no tiene ID');

    final errores = actividad.validar();
    if (errores.isNotEmpty) throw Exception(errores.join(', '));

    await _actividadDao.update(actividad);
    return actividad;
  }

  // ELIMINAR actividad
  Future<void> eliminarActividad(int idActividad) async {
    await _initialize();
    final actividad = await _actividadDao.getById(idActividad);
    if (actividad == null) throw Exception('La actividad no existe');

    await _avanceDao.deleteByActividad(idActividad);
    await _actividadDao.delete(idActividad);
  }

  // OBTENER actividades por obra
  Future<List<Actividad>> obtenerActividadesPorObra(int idObra) async {
    await _initialize();
    return await _actividadDao.getByObra(idObra);
  }

  // CAMBIAR estado de una actividad
  Future<void> cambiarEstadoActividad(int idActividad, String nuevoEstado) async {
    await _initialize();

    const estadosValidos = ['PENDIENTE', 'EN_PROGRESO', 'COMPLETADA', 'ATRASADA'];
    if (!estadosValidos.contains(nuevoEstado)) {
      throw Exception('Estado no válido: $nuevoEstado');
    }

    await _actividadDao.updateEstado(idActividad, nuevoEstado);
  }

  // CALCULAR porcentaje de avance de obra (basado en actividades completadas)
  Future<double> calcularPorcentajeAvanceObra(int idObra) async {
    await _initialize();
    return await _actividadDao.calcularPorcentajeAvanceObra(idObra);
  }

  // ESTADÍSTICAS por obra
  Future<Map<String, dynamic>> obtenerEstadisticasPorObra(int idObra) async {
    await _initialize();
    return await _actividadDao.getEstadisticasByObra(idObra);
  }

  // OBTENER resumen completo de obra
  Future<Map<String, dynamic>> obtenerResumenObra(int idObra) async {
    await _initialize();

    final actividades = await obtenerActividadesPorObra(idObra);
    final porcentajeAvance = await calcularPorcentajeAvanceObra(idObra);
    final estadisticas = await obtenerEstadisticasPorObra(idObra);

    // Tomar últimos 5 avances (opcional)
    final avancesRecientes = await _avanceDao.getByObra(idObra);
    avancesRecientes.sort((a, b) => b.fecha.compareTo(a.fecha));
    final ultimosAvances = avancesRecientes.take(5).toList();

    return {
      'actividades': actividades,
      'porcentaje_avance': porcentajeAvance,
      'estadisticas': estadisticas,
      'ultimos_avances': ultimosAvances,
      'total_actividades': actividades.length,
    };
  }
}
