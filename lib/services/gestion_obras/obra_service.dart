import 'package:regcons/db/app_db.dart';
import 'package:regcons/services/gestion_obras/usuario_obra_service.dart';
import '../../db/daos/gestion_obras/avance_dao.dart';
import '../../db/daos/gestion_obras/obra_dao.dart';
import '../../models/gestion_obras/obra.dart';
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

  // --- CRUD BÁSICO ---

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

  // --- CONSULTAS CON CÁLCULO DINÁMICO ---

  Future<List<Obra>> obtenerTodasObras() async {
    await _initialize();
    final obras = await _obraDao.getAll();

    // Inyectamos el porcentaje calculado desde el DAO a cada obra
    for (var obra in obras) {
      if (obra.idObra != null) {
        obra.porcentajeAvance = await _obraDao.calcularPorcentajeAvance(obra.idObra!);
      }
    }
    return obras;
  }

  Future<List<Obra>> obtenerObrasActivas() async {
    await _initialize();
    final obras = await _obraDao.getActivas();

    for (var obra in obras) {
      if (obra.idObra != null) {
        obra.porcentajeAvance = await _obraDao.calcularPorcentajeAvance(obra.idObra!);
      }
    }
    return obras;
  }

  Future<Obra?> obtenerObraPorId(int idObra) async {
    await _initialize();
    final obra = await _obraDao.getById(idObra);
    if (obra != null && obra.idObra != null) {
      obra.porcentajeAvance = await _obraDao.calcularPorcentajeAvance(obra.idObra!);
    }
    return obra;
  }

  Future<List<Obra>> obtenerObrasConDetalles() async {
    return await obtenerTodasObras();
  }

  // --- ESTADÍSTICAS Y OTROS ---
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

  Future<Map<String, dynamic>> obtenerObraCompleta(int idObra) async {
    await _initialize();

    final obra = await _obraDao.getById(idObra);
    if (obra == null) throw Exception('Obra no encontrada');

    final actividadesService = ActividadService();
    final avancesService = AvanceService();

    final actividades = await actividadesService.obtenerActividadesPorObra(idObra);
    final resumen = await actividadesService.obtenerResumenObra(idObra);
    final reporteAvances = await avancesService.generarReporteAvances(idObra: idObra);

    double avance = (resumen['porcentaje_avance'] as num?)?.toDouble() ?? 0.0;
    obra.porcentajeAvance = await _obraDao.calcularPorcentajeAvance(idObra);


    return {
      'obra': obra,
      'actividades': actividades,
      'resumen': resumen,
      'reporte_avances': reporteAvances,
      'porcentaje_avance': obra.porcentajeAvance,
      'total_actividades': actividades.length,
    };
  }

  Future<void> eliminarObraCompleta(int idObra) async {
    await _initialize();
    final actividadService = ActividadService();
    final actividades = await actividadService.obtenerActividadesPorObra(idObra);

    for (var actividad in actividades) {
      if (actividad.idActividad != null) {
        final avanceDao = AvanceDao(await AppDatabase().database);
        await avanceDao.deleteByActividad(actividad.idActividad!);
        await actividadService.eliminarActividad(actividad.idActividad!);
      }
    }

    try {
      final usuarioObraService = UsuarioObraService();
      await usuarioObraService.eliminarTodosUsuariosDeObra(idObra);
    } catch (_) {}

    await _obraDao.delete(idObra);
  }

  // Método unificado para calcular el avance
  Future<double> calcularPorcentajeAvance(int idObra) async {
    await _initialize();
    // Usamos el DAO directamente, es más rápido y menos propenso a errores de nulos
    return await _obraDao.calcularPorcentajeAvance(idObra);
  }
}
