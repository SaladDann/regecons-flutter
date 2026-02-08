import '../../db/daos/gestion_incidentes/incidente_dao.dart';
import '../../models/gestion_incidentes/incidente.dart';
import '../../models/gestion_obras/obra.dart';

class IncidenteService {
  final IncidenteDao _dao = IncidenteDao();

  // =========================
  // CREAR INCIDENTE
  // =========================
  Future<int> crearIncidente({
    required Obra obra,
    required Incidente incidente,
  }) async {
    _validarIncidente(obra, incidente);

    // Regla: obra finalizada -> solo lectura
    if (obra.estado == 'FINALIZADA') {
      throw Exception(
        'No se pueden registrar incidentes en una obra finalizada',
      );
    }

    return await _dao.insertarIncidente(incidente);
  }

  // =========================
  // ACTUALIZAR INCIDENTE
  // =========================
  Future<int> actualizarIncidente({
    required Obra obra,
    required Incidente incidente,
  }) async {
    if (incidente.idReporte == null) {
      throw Exception('El incidente no existe');
    }

    _validarIncidente(obra, incidente);

    if (obra.estado == 'FINALIZADA') {
      throw Exception(
        'No se pueden modificar incidentes de una obra finalizada',
      );
    }

    return await _dao.actualizarIncidente(incidente);
  }

  // =========================
  // GUARDAR (CREAR / EDITAR)
  // =========================
  Future<int> guardarIncidente({
    required Obra obra,
    required Incidente incidente,
  }) async {
    if (incidente.idReporte == null) {
      return await crearIncidente(
        obra: obra,
        incidente: incidente,
      );
    } else {
      return await actualizarIncidente(
        obra: obra,
        incidente: incidente,
      );
    }
  }

  // =========================
  // ELIMINAR
  // =========================
  Future<void> eliminarIncidente({
    required Obra obra,
    required int idReporte,
  }) async {
    if (obra.estado == 'FINALIZADA') {
      throw Exception(
        'No se pueden eliminar incidentes de una obra finalizada',
      );
    }

    await _dao.eliminarIncidente(idReporte);
  }

  // =========================
  // LISTADOS
  // =========================
  Future<List<Incidente>> listarPorObra(int idObra) {
    return _dao.listarPorObra(idObra);
  }

  Future<List<Incidente>> listarConFiltros({
    required int idObra,
    String? tipo,
    String? severidad,
    String? estado,
    String? textoBusqueda,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) {
    return _dao.listarConFiltros(
      idObra: idObra,
      tipo: tipo,
      severidad: severidad,
      estado: estado,
      textoBusqueda: textoBusqueda,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
  }

  // =========================
  // CAMBIO DE ESTADO
  // =========================
  Future<void> cambiarEstado({
    required Obra obra,
    required int idReporte,
    required String nuevoEstado,
  }) async {
    const estadosValidos = [
      'REPORTADO',
      'EN_ANALISIS',
      'RESUELTO',
      'CERRADO',
    ];

    if (!estadosValidos.contains(nuevoEstado)) {
      throw Exception('Estado no válido');
    }

    if (obra.estado == 'FINALIZADA') {
      throw Exception(
        'No se pueden cambiar estados en una obra finalizada',
      );
    }

    await _dao.actualizarEstado(idReporte, nuevoEstado);
  }

  // =========================
  // VALIDACIONES DE NEGOCIO
  // =========================
  void _validarIncidente(Obra obra, Incidente incidente) {
    if (incidente.descripcion.trim().isEmpty) {
      throw Exception('La descripción es obligatoria');
    }

    // CORREGIDO: Permite todos los tipos que muestra la UI
    if (!['ACCIDENTE', 'INCIDENTE', 'CONDICION_INSEGURA',
      'ACTO_INSEGURO', 'FALLA_EQUIPO', 'DERRAME_MATERIAL', 'OTRO']
        .contains(incidente.tipo)) {
      throw Exception('Tipo de incidente inválido');
    }

    if (!['BAJA', 'MEDIA', 'ALTA', 'CRITICA']
        .contains(incidente.severidad)) {
      throw Exception('Nivel de severidad inválido');
    }

    if (incidente.idObra != obra.idObra) {
      throw Exception(
        'El incidente no pertenece a la obra seleccionada',
      );
    }
  }
}
