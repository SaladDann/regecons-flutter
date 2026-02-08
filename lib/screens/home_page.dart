import 'package:flutter/material.dart';
import 'package:regcons/screens/gestion_incidentes/reportes_incidentes_screen.dart';
import 'package:regcons/screens/gestion_reportes/reportes_screen.dart';
import '../models/gestion_obras/obra.dart';
import '../services/gestion_obras/obra_service.dart';
import 'gestion_obras/obra_detalle_screen.dart';
import 'gestion_obras/obras_screen.dart';
import 'news_page.dart';
import 'configuraciones_screen.dart';

class HomePage extends StatefulWidget {
  final String nombreUsuario;
  const HomePage({super.key, required this.nombreUsuario});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2;
  final ObraService _obraService = ObraService();
  Obra? _obraSeleccionada;
  List<Obra> _obrasActivas = [];
  bool _isLoading = true;

  static const List<String> _titles = [
    'Ajustes',
    'Noticias',
    'Inicio',
    'Incidentes',
    'Reportes'
  ];

  @override
  void initState() {
    super.initState();
    _cargarObrasActivas();
  }

  Future<void> _cargarObrasActivas() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final obras = await _obraService.obtenerObrasActivas();
      if (!mounted) return;
      setState(() {
        _obrasActivas = obras;
        if (_obrasActivas.isNotEmpty) {
          _obraSeleccionada = _obraSeleccionada != null
              ? _obrasActivas.firstWhere((o) => o.idObra == _obraSeleccionada!.idObra, orElse: () => _obrasActivas.first)
              : _obrasActivas.first;
        } else {
          _obraSeleccionada = null;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _irADetalleObra() {
    if (_obraSeleccionada?.idObra != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ObraDetalleScreen(idObra: _obraSeleccionada!.idObra!),
        ),
      ).then((_) => _cargarObrasActivas());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10121D),
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF181B35).withOpacity(0.8),
        title: Text(_titles[_selectedIndex], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        // El botón de sincronizar ahora solo aparece si el índice es 2 (Home)
        actions: _selectedIndex == 2 ? [IconButton(onPressed: _cargarObrasActivas, icon: const Icon(Icons.sync, color: Colors.orange))] : null,
      ),
      body: Stack(
        children: [
          Positioned.fill(
              child: Image.asset(
                  'assets/images/tapiz_bg.png',
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(0.25)
              )
          ),
          SafeArea(
              bottom: false,
              child: _buildContent()
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0: return const ConfiguracionesScreen();
      case 1: return const NewsPage();
      case 2: return _buildHomeContent();
      case 3: if (_obraSeleccionada == null) {
        return const Center(
          child: Text(
            'Seleccione una obra activa',
            style: TextStyle(color: Colors.white70),
          ),
        );
      }
      return IncidentesScreen(obra: _obraSeleccionada!);
      case 4: if (_obraSeleccionada == null || _obraSeleccionada!.idObra == null) {
        return const Center(
            child: Text('Seleccione una obra para generar reportes',
                style: TextStyle(color: Colors.white70))
        );
      }
      return ReportesScreen();

      default: return const SizedBox();
    }
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: Colors.orange.withOpacity(0.2), child: const Icon(Icons.person, color: Colors.orange)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Panel de Control', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(widget.nombreUsuario, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildActiveWorkCard(),

          const SizedBox(height: 24),
          const Text('CONTROL OPERATIVO', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),


          _buildGridAcciones(),

          const SizedBox(height: 24),
          const Text('RESUMEN DE PROYECTOS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 24),
          _buildResumenEstadistico(),
        ],
      ),
    );
  }

  Widget _buildActiveWorkCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF181B35).withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.construction, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Text('OBRA EN SEGUIMIENTO', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w900, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 16),
                _isLoading ? const LinearProgressIndicator(color: Colors.orange) : _buildDropdownObras(),
                if (_obraSeleccionada != null) ...[
                  const SizedBox(height: 20),
                  _buildProgresoVisual(),
                ],
              ],
            ),
          ),
          if (_obraSeleccionada != null)
            InkWell(
              onTap: _irADetalleObra,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.trending_up_rounded, color: Colors.orange, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'VER AVANCES Y ACTIVIDADES',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownObras() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Obra>(
          value: _obraSeleccionada,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E2130),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.orange),
          items: _obrasActivas.map((o) => DropdownMenuItem(
              value: o,
              child: Text(o.nombre, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))
          )).toList(),
          onChanged: (v) => setState(() => _obraSeleccionada = v),
        ),
      ),
    );
  }

  Widget _buildProgresoVisual() {
    final porc = _obraSeleccionada!.porcentajeAvance ?? 0.0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Nivel de Avance', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13)),
            Text('${porc.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (porc / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            color: Colors.orange,
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildGridAcciones() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: [
        _buildActionCard(
            icon: Icons.business_center_outlined,
            label: 'Gestionar\nObras',
            color: Colors.blueAccent,
            onTap: () => Navigator.push(
                context, MaterialPageRoute(
                builder: (context) => const ObrasScreen()
            )).then((_) => _cargarObrasActivas())
        ),
        _buildActionCard(
            icon: Icons.report_problem_outlined,
            label: 'Nuevo\nIncidente',
            color: Colors.redAccent,
            onTap: () => setState(() => _selectedIndex = 3)),
        _buildActionCard(
            icon: Icons.analytics_outlined,
            label: 'Reportes\nPDF',
            color: Colors.purpleAccent,
            onTap: () => setState(() => _selectedIndex = 4)),
      ],
    );
  }

  Widget _buildActionCard({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF181B35).withOpacity(0.85),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenEstadistico() {
    return FutureBuilder<Map<String, int>>(
      future: _obraService.getEstadisticas(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {'total': 0, 'activas': 0, 'finalizadas': 0};
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF181B35).withOpacity(0.85),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statCircle('Total Obras', stats['total'].toString(), Colors.blue),
              _statCircle('Activas', stats['activas'].toString(), Colors.orange),
              _statCircle('Finalizadas', stats['finalizadas'].toString(), Colors.green),
            ],
          ),
        );
      },
    );
  }

  Widget _statCircle(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFF181B35).withOpacity(0.92),
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.white30,
      elevation: 0,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      items: const [

        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
        BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'Noticias'),

        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Inicio'),

        BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Incidentes'),
        BottomNavigationBarItem(icon: Icon(Icons.assessment), label: 'Reportes'),
      ],
    );
  }
}