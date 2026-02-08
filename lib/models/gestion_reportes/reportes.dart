import '../gestion_obras/obra.dart';
import '../gestion_obras/actividad.dart';
import '../gestion_incidentes/incidente.dart';
import '../gestion_obras/avance.dart';

class ReporteObraModel {
  final Obra obra;
  final double porcentajeAvance;
  final double avanceSemanal;
  final int totalActividades;
  final List<Actividad> actividades;
  final int totalIncidentes;
  final List<Incidente> incidentes;
  final int riesgosActivos;
  final DateTime fechaGeneracion;
  final String responsable;

  // --- NUEVOS CAMPOS PARA REPORTE COMPLETO ---
  final double totalHorasTrabajadas;
  final List<Avance> ultimosAvances;

  ReporteObraModel({
    required this.obra,
    required this.porcentajeAvance,
    this.avanceSemanal = 0.0,
    required this.totalActividades,
    required this.actividades,
    required this.totalIncidentes,
    required this.incidentes,
    required this.riesgosActivos,
    required this.fechaGeneracion,
    required this.responsable,

    this.totalHorasTrabajadas = 0.0,
    this.ultimosAvances = const [],
  });
}