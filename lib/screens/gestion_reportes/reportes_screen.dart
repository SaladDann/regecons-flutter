import 'package:flutter/material.dart';
import '../../db/app_db.dart';
import '../../db/daos/gestion_obras/obra_dao.dart';
import '../../models/gestion_obras/obra.dart';
import '../../models/gestion_reportes/reportes.dart';
import '../../services/gestion_reportes/reporte_pdf_service.dart';
import '../../services/gestion_reportes/reportes_service.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  _ReportesScreenState createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final AppDatabase _db = AppDatabase();
  final ReporteService _reporteService = ReporteService();
  final ReportePdfService _pdfService = ReportePdfService();

  List<Obra> _obrasDisponibles = [];
  Obra? _obraSeleccionada;
  ReporteObraModel? _reporteActual;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargarObras();
  }

  /// Carga la lista de obras activas al iniciar
  Future<void> _cargarObras() async {
    setState(() => _cargando = true);
    try {
      final dbClient = await _db.database;
      final obraDao = ObraDao(dbClient);
      final lista = await obraDao.getActivas();

      if (lista.isNotEmpty) {
        setState(() {
          _obrasDisponibles = lista;
          _obraSeleccionada = lista.first;
        });
        await _generarDataReporte();
      }
    } catch (e) {
      _showError("Error al cargar obras: $e");
    } finally {
      setState(() => _cargando = false);
    }
  }

  /// Usa el ReporteService para obtener toda la data procesada (HH, Incidentes, etc.)
  Future<void> _generarDataReporte() async {
    if (_obraSeleccionada == null) return;

    setState(() => _cargando = true);
    try {
      // Llamamos al servicio unificado
      final data = await _reporteService.generarDataReporte(
        _obraSeleccionada!.idObra!,
        "Admin RegCons", // Aquí podrías pasar el nombre del usuario logueado
      );

      setState(() {
        _reporteActual = data;
      });
    } catch (e) {
      _showError("Error al procesar datos: $e");
    } finally {
      setState(() => _cargando = false);
    }
  }

  /// Llama al PDF Service corregido
  void _exportarPDF() async {
    if (_reporteActual == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Generando documento PDF..."),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      // Ahora enviamos el modelo directo, sin mapas manuales
      await _pdfService.exportarPdf(_reporteActual!);
    } catch (e) {
      _showError("Error al exportar PDF: $e");
    }
  }

  void _showError(String msg) {
    debugPrint(msg);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        title: const Text("Reportes de Control", style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: const Color(0xFF1A1D2E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.orange),
            onPressed: _reporteActual == null ? null : _exportarPDF,
          )
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _obrasDisponibles.isEmpty
          ? const Center(child: Text("No hay obras activas", style: TextStyle(color: Colors.white54)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("OBRA BAJO ANALISIS"),
            _buildFiltroObra(),
            const SizedBox(height: 25),
            if (_reporteActual != null) ...[
              _buildHeaderInfo(),
              const SizedBox(height: 25),
              _buildMetricasClave(),
              const SizedBox(height: 25),
              _buildSeccionProgreso(),
              const SizedBox(height: 25),
              _buildSeccionSeguridad(),
              const SizedBox(height: 25),
              _buildLabel("DETALLE DE ACTIVIDADES"),
              _buildResumenActividades(),
            ]
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE APOYO ---

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4),
    child: Text(text,
        style: const TextStyle(
            color: Colors.orange,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1)),
  );

  Widget _buildFiltroObra() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Obra>(
          isExpanded: true,
          dropdownColor: const Color(0xFF1A1D2E),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          value: _obraSeleccionada,
          items: _obrasDisponibles
              .map((o) => DropdownMenuItem(value: o, child: Text(o.nombre)))
              .toList(),
          onChanged: (val) {
            setState(() {
              _obraSeleccionada = val;
              _reporteActual = null; // Reset para mostrar carga
            });
            _generarDataReporte();
          },
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.orange.withOpacity(0.2))),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Colors.orange,
            child: Icon(Icons.business_center, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_reporteActual!.obra.nombre,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("Cliente: ${_reporteActual!.obra.cliente ?? 'No registrado'}",
                    style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricasClave() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _kpiCard("Actividades", "${_reporteActual!.totalActividades}", Icons.checklist, Colors.blueAccent),
        _kpiCard("Horas Hombre", "${_reporteActual!.totalHorasTrabajadas}h", Icons.timer, Colors.cyanAccent),
        _kpiCard("Incidentes", "${_reporteActual!.totalIncidentes}", Icons.warning_amber, Colors.redAccent),
        _kpiCard("Riesgos Altas", "${_reporteActual!.riesgosActivos}", Icons.gpp_maybe, Colors.orangeAccent),
      ],
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.white38), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSeccionProgreso() {
    double progreso = (_reporteActual!.porcentajeAvance / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("AVANCE DE OBRA",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
              Text("${_reporteActual!.porcentajeAvance.toStringAsFixed(1)}%",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: progreso,
            minHeight: 8,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(progreso > 0.7 ? Colors.greenAccent : Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionSeguridad() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.redAccent.withOpacity(0.1))),
      child: Row(
        children: [
          const Icon(Icons.shield, color: Colors.redAccent, size: 30),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("SEGURIDAD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("${_reporteActual!.totalIncidentes} Incidentes registrados",
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildResumenActividades() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _reporteActual!.actividades.length,
      itemBuilder: (context, index) {
        final act = _reporteActual!.actividades[index];
        return Card(
          color: const Color(0xFF1A1D2E),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(act.nombre, style: const TextStyle(color: Colors.white, fontSize: 13)),
            subtitle: Text(act.estado, style: const TextStyle(color: Colors.orange, fontSize: 11)),
            trailing: Text("${act.porcentajeCompletado}%", style: const TextStyle(color: Colors.white38)),
          ),
        );
      },
    );
  }
}