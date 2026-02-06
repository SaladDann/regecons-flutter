import 'package:regcons/db/app_db.dart';
import 'package:regcons/services/usuario_obra_service.dart';

import '../db/daos/avance_dao.dart';
import '../db/daos/obra_dao.dart';
import '../models/obra.dart';
import 'actividad_service.dart';
import 'avance_service.dart';

class ObraService {
  late ObraDao _obraDao;
  bool _inicializado = false;

  Future<void> _initialize() async {
    if (!_inicializado) {
      final db = await AppDatabase().database;
      _obraDao = ObraDao(db);
      _inicializado = true;
    }
  }

  Future<int> crearObra(Obra obra) async {
    await _initialize();
    return await _obraDao.insert(obra);
  }

  Future<int> actualizarObra(Obra obra) async {
    await _initialize();
    return await _obraDao.update(obra);
  }

  Future<int> eliminarObra(int idObra) async {
    await _initialize();
    return await _obraDao.delete(idObra);
  }

  Future<List<Obra>> obtenerTodasObras() async {
    await _initialize();
    return await _obraDao.getAll();
  }

  Future<List<Obra>> obtenerObrasActivas() async {
    await _initialize();
    final obras = await _obraDao.getActivas();

    // Calcular porcentaje de avance para cada obra
    for (var obra in obras) {
      if (obra.idObra != null) {
        final porcentaje = await _obraDao.calcularPorcentajeAvance(
          obra.idObra!,
        );
        obra.porcentajeAvance = porcentaje;
      }
    }

    return obras;
  }

  Future<Obra?> obtenerObraPorId(int idObra) async {
    await _initialize();
    final obra = await _obraDao.getById(idObra);
    if (obra != null && obra.idObra != null) {
      final porcentaje = await _obraDao.calcularPorcentajeAvance(obra.idObra!);
      obra.porcentajeAvance = porcentaje;
    }
    return obra;
  }

  Future<List<String>> getEstadosDisponibles() async {
    return ['PLANIFICADA', 'ACTIVA', 'SUSPENDIDA', 'FINALIZADA'];
  }

  Future<Map<String, int>> getEstadisticas() async {
    await _initialize();
    final todas = await _obraDao.getAll();

    return {
      'total': todas.length,
      'activas': todas.where((o) => o.estado == 'ACTIVA').length,
      'planificadas': todas.where((o) => o.estado == 'PLANIFICADA').length,
      'finalizadas': todas.where((o) => o.estado == 'FINALIZADA').length,
    };
  }

  // OBTENER obras con actividades y avances
  Future<List<Obra>> obtenerObrasConDetalles() async {
    await _initialize();

    final obras = await _obraDao.getAll();

    for (var obra in obras) {
      if (obra.idObra != null) {
        final actividadesService = ActividadService();
        final resumen = await actividadesService.obtenerResumenObra(obra.idObra!);

        obra.porcentajeAvance = resumen['porcentaje_avance'] as double;
      }
    }

    return obras;
  }

  // OBTENER obra completa con todas sus relaciones
  Future<Map<String, dynamic>> obtenerObraCompleta(int idObra) async {
    await _initialize();

    final obra = await _obraDao.getById(idObra);
    if (obra == null) {
      throw Exception('Obra no encontrada');
    }

    final actividadesService = ActividadService();
    final avancesService = AvanceService();

    final actividades = await actividadesService.obtenerActividadesPorObra(idObra);
    final resumen = await actividadesService.obtenerResumenObra(idObra);
    final reporteAvances = await avancesService.generarReporteAvances(idObra: idObra);

    return {
      'obra': obra,
      'actividades': actividades,
      'resumen': resumen,
      'reporte_avances': reporteAvances,
      'porcentaje_avance': resumen['porcentaje_avance'],
      'total_actividades': actividades.length,
    };
  }

  // ELIMINAR obra con todas sus relaciones
  Future<void> eliminarObraCompleta(int idObra) async {
    await _initialize();

    // Obtener todas las actividades de la obra
    final actividadService = ActividadService();
    final actividades = await actividadService.obtenerActividadesPorObra(idObra);

    // Para cada actividad, eliminar sus avances primero
    for (var actividad in actividades) {
      if (actividad.idActividad != null) {
        final avanceDao = AvanceDao(await AppDatabase().database);
        await avanceDao.deleteByActividad(actividad.idActividad!);
      }
    }

    // Eliminar todas las actividades
    for (var actividad in actividades) {
      if (actividad.idActividad != null) {
        await actividadService.eliminarActividad(actividad.idActividad!);
      }
    }

    // Eliminar relaciones usuario_obra si existen
    try {
      final usuarioObraService = UsuarioObraService();
      await usuarioObraService.eliminarTodosUsuariosDeObra(idObra);
    } catch (_) {

    }

    // eliminar la obra
    await _obraDao.delete(idObra);
  }

  Future<double> calcularPorcentajeAvance(int idObra) async {
    await _initialize();

    final actividadService = ActividadService();
    final resumen = await actividadService.obtenerResumenObra(idObra);

    // devolver porcentaje dinámico
    return resumen['porcentaje_avance'] as double? ?? 0.0;
  }
}
