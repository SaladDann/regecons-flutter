import 'package:flutter/material.dart';
import '../../models/obra.dart';
import '../../services/obra_service.dart';
import 'actividad_form_screen.dart';
import '../../models/actividad.dart';

class ObraDetalleScreen extends StatefulWidget {
  final int idObra;

  const ObraDetalleScreen({super.key, required this.idObra});

  @override
  State<ObraDetalleScreen> createState() => _ObraDetalleScreenState();
}

class _ObraDetalleScreenState extends State<ObraDetalleScreen>
    with SingleTickerProviderStateMixin {
  final _obraService = ObraService();

  late TabController _tabController;
  bool _cargando = true;

  Obra? obra;
  Map<String, dynamic>? resumen;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Solo RESUMEN y ACTIVIDADES
    _tabController.addListener(() {
      if (mounted) setState(() {}); // Actualiza header según tab
    });
    _cargarObra();
  }

  Future<void> _cargarObra() async {
    setState(() => _cargando = true);
    final data = await _obraService.obtenerObraCompleta(widget.idObra);
    setState(() {
      obra = data['obra'] as Obra;
      resumen = data;
      _cargando = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF181B35).withOpacity(0.9),
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          obra?.nombre ?? 'Detalle de Obra',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.orange,
          indicatorWeight: 3,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'RESUMEN', icon: Icon(Icons.analytics_outlined, size: 20)),
            Tab(text: 'ACTIVIDADES', icon: Icon(Icons.list_alt_outlined, size: 20)),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final ok = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActividadFormScreen(idObra: widget.idObra),
            ),
          );
          if (ok == true) _cargarObra();
        },
      )
          : null,
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.6)),
          ),
          SafeArea(
            child: Column(
              children: [
                _headerObra(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _tabResumen(),
                      _tabActividades(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================
  Widget _headerObra() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF181B35).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  obra!.nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: obra!.estadoColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  obra!.estado,
                  style: TextStyle(
                    color: obra!.estadoColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (_tabController.index == 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (obra!.porcentajeAvance ?? 0) / 100,
                minHeight: 8,
                color: Colors.orange,
                backgroundColor: Colors.white12,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progreso General',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
                Text(
                  '${obra!.porcentajeAvance?.toStringAsFixed(1) ?? '0'}%',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ================= TABS =================
  Widget _tabResumen() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _itemResumen('Total actividades', resumen!['total_actividades'].toString(), Icons.assignment),
        _itemResumen('Avance calculado', '${resumen!['porcentaje_avance']} %', Icons.pie_chart),
        _itemResumen('Cliente', obra?.cliente ?? 'N/A', Icons.person),
      ],
    );
  }

  // Tab Actividades con avances fusionados
  Widget _tabActividades() {
    final List<Actividad> actividades =
    (resumen?['actividades'] as List<Actividad>? ?? []);

    if (actividades.isEmpty) {
      return const Center(
        child: Text(
          'No hay actividades registradas',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: actividades.length,
      itemBuilder: (_, i) {
        final actividad = actividades[i];

        return ExpansionTile(
          backgroundColor: const Color(0xFF181B35).withOpacity(0.85),
          collapsedBackgroundColor: const Color(0xFF181B35).withOpacity(0.6),
          title: Text(
            actividad.nombre,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Estado: ${actividad.estado}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.orange),
                  onPressed: () {
                    // agregar avance
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () async {
                    final ok = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ActividadFormScreen(
                          idObra: widget.idObra,
                          actividad: actividad,
                        ),
                      ),
                    );

                    if (ok == true) {
                      _cargarObra(); // refresca datos
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    // eliminar actividad
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }


  Widget _itemResumen(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF181B35).withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 24),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}


