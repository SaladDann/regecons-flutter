import 'package:flutter/material.dart';
import '../../models/gestion_incidentes/incidente.dart';
import '../../models/gestion_obras/obra.dart';
import '../../services/gestion_incidentes/incidente_service.dart';
import 'incidente_form_screen.dart';

class IncidentesScreen extends StatefulWidget {
  final Obra obra;
  const IncidentesScreen({super.key, required this.obra});

  @override
  State<IncidentesScreen> createState() => _IncidentesScreenState();
}

class _IncidentesScreenState extends State<IncidentesScreen> {
  final IncidenteService _service = IncidenteService();
  late Future<List<Incidente>> _incidentesFuture;

  @override
  void initState() {
    super.initState();
    _cargarIncidentes();
  }

  void _cargarIncidentes() {
    setState(() {
      _incidentesFuture = _service.listarPorObra(widget.obra.idObra!);
    });
  }

  // Lógica de colores de severidad (Mantenida para coherencia visual)
  Color _getSeveridadColor(String sev) {
    switch (sev.toUpperCase()) {
      case 'CRITICA': return Colors.red;
      case 'ALTA': return Colors.orange;
      case 'MEDIA': return Colors.yellow;
      case 'BAJA': return Colors.green;
      default: return Colors.blueAccent;
    }
  }

  Color _estadoColor(String estado) {
    switch (estado.toUpperCase()) {
      case 'REPORTADO': return Colors.red;
      case 'EN_ANALISIS': return Colors.orange;
      case 'RESUELTO': return Colors.blue;
      case 'CERRADO': return Colors.green;
      default: return Colors.grey;
    }
  }

  // WIDGET DEL BADGE DE RIESGO PARA EL LISTADO
  Widget _buildRiskBadge(String severidad) {
    final color = _getSeveridadColor(severidad);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Text(
        severidad,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool esFinalizada = widget.obra.estado == 'FINALIZADA';

    return Scaffold(
      backgroundColor: const Color(0xFF10121D),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF181B35),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.obra.nombre, style: const TextStyle(fontSize: 16, color: Colors.blueAccent)),
          ],
        ),
      ),
      floatingActionButton: esFinalizada
          ? null
          : Container(
        margin: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () => _abrirFormulario(),
          backgroundColor: Colors.orange,
          elevation: 8,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('NUEVO INCIDENTE',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        onRefresh: () async => _cargarIncidentes(),
        color: Colors.orange,
        child: FutureBuilder<List<Incidente>>(
          future: _incidentesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.orange));
            }
            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }
            final incidentes = snapshot.data ?? [];
            if (incidentes.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 150),
              itemCount: incidentes.length,
              itemBuilder: (context, index) {
                final incidente = incidentes[index];
                return _buildIncidenteCard(incidente, esFinalizada);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildIncidenteCard(Incidente incidente, bool esFinalizada) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF181B35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Dismissible(
          key: Key(incidente.idReporte.toString()),
          direction: esFinalizada ? DismissDirection.none : DismissDirection.endToStart,
          confirmDismiss: (direction) => _confirmarEliminacion(incidente),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.redAccent,
            child: const Icon(Icons.delete_sweep, color: Colors.white, size: 28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 18, color: _getSeveridadColor(incidente.severidad)),
                          const SizedBox(width: 8),
                          Text(incidente.tipo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                    _buildRiskBadge(incidente.severidad),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  incidente.descripcion,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month, size: 14, color: Colors.white30),
                        const SizedBox(width: 6),
                        Text(incidente.fechaEventoFormatted, style: const TextStyle(color: Colors.white30, fontSize: 11)),
                      ],
                    ),
                    if (!esFinalizada)
                      Row(
                        children: [
                          _circleActionBtn(Icons.edit_outlined, Colors.blueAccent, () => _abrirFormulario(incidente: incidente)),
                          const SizedBox(width: 10),
                          _circleActionBtn(Icons.delete_outline, Colors.redAccent, () => _confirmarEliminacion(incidente)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String estado) {
    Color color = _estadoColor(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        estado.replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _circleActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.2))),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 70, color: Colors.white.withOpacity(0.05)),
          const SizedBox(height: 16),
          const Text('TODO EN ORDEN', style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          const Text('No hay incidentes registrados aquí.', style: TextStyle(color: Colors.white24, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(child: Text('Error: $error', style: const TextStyle(color: Colors.redAccent)));
  }

  Future<bool> _confirmarEliminacion(Incidente incidente) async {
    final bool? confirmar = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2130),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('¿Eliminar registro?', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: const Text('Esta acción eliminará el reporte de incidente de forma permanente.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR', style: TextStyle(color: Colors.white38))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ELIMINAR', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _service.eliminarIncidente(obra: widget.obra, idReporte: incidente.idReporte!);
      _cargarIncidentes();
      return true;
    }
    return false;
  }

  Future<void> _abrirFormulario({Incidente? incidente}) async {
    if (widget.obra.estado == 'FINALIZADA') return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => IncidenteFormScreen(obra: widget.obra, incidente: incidente)));
    _cargarIncidentes();
  }
}