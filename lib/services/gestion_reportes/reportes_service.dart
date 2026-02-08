import '../../db/app_db.dart';
import '../../db/daos/gestion_incidentes/incidente_dao.dart';
import '../../db/daos/gestion_obras/actividad_dao.dart';
import '../../db/daos/gestion_obras/avance_dao.dart';
import '../../db/daos/gestion_obras/obra_dao.dart';
import '../../models/gestion_obras/avance.dart';
import '../../models/gestion_reportes/reportes.dart';

class ReporteService {
  final AppDatabase _db = AppDatabase();
  final IncidenteDao _incidenteDao = IncidenteDao();

  Future<ReporteObraModel> generarDataReporte(int idObra, String responsable) async {
    // 1. Obtener la instancia de la base de datos
    final dbClient = await _db.database;

    // 2. Inicializar DAOs con la conexión activa
    final obraDao = ObraDao(dbClient);
    final actividadDao = ActividadDao(dbClient);
    final avanceDao = AvanceDao(dbClient);

    // 3. Obtener datos maestros de la Obra (ID, Presupuesto, Cliente)
    final obra = await obraDao.getById(idObra);
    if (obra == null) throw Exception('No se encontró la obra con ID: $idObra');

    // 4. Calcular el avance físico basado en actividades finalizadas
    final porcentajeAvance = await obraDao.calcularPorcentajeAvance(idObra);

    // 5. Obtener actividades y sus estadísticas
    final statsAct = await actividadDao.getEstadisticasByObra(idObra);
    final listaActividades = await actividadDao.getByObra(idObra);

    // 6. Obtener Avances de Campo y sumar Horas Trabajadas (HH)
    final List<Avance> todosLosAvances = await avanceDao.getByObra(idObra);

    // Suma manual de las horas registradas (aquí se capturan tus 3.0h)
    double acumuladoHoras = 0;
    for (var avance in todosLosAvances) {
      acumuladoHoras += (avance.horasTrabajadas ?? 0.0);
    }

    // 7. Obtener lista completa de incidentes (Accidentes, Derrames, etc.)
    final incidentes = await _incidenteDao.listarPorObra(idObra);

    // Filtrar riesgos críticos (Severidad ALTA o CRÍTICA)
    final riesgosCriticos = await _incidenteDao.listarConFiltros(
      idObra: idObra,
      severidad: 'ALTA',
    );

    // 8. Retornar el modelo listo para el PDF Service
    return ReporteObraModel(
      obra: obra,
      porcentajeAvance: porcentajeAvance,
      totalActividades: statsAct['total'] ?? 0,
      actividades: listaActividades,
      totalIncidentes: incidentes.length,
      incidentes: incidentes,
      riesgosActivos: riesgosCriticos.length,
      fechaGeneracion: DateTime.now(),
      responsable: responsable,
      totalHorasTrabajadas: acumuladoHoras,
      ultimosAvances: todosLosAvances,
      avanceSemanal: _calcularAvance7D(todosLosAvances),
    );
  }

  /// Calcula el avance de los últimos 7 días basado en la cantidad de registros
  double _calcularAvance7D(List<Avance> avances) {
    if (avances.isEmpty) return 0.0;
    final hace7Dias = DateTime.now().subtract(const Duration(days: 7));
    final recientes = avances.where((a) => a.fecha.isAfter(hace7Dias)).length;
    return (recientes / avances.length) * 100;
  }
}