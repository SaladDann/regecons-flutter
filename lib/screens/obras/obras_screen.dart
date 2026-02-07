import 'package:flutter/material.dart';
import '../../../services/obra_service.dart';
import '../../../models/obra.dart';
import 'obra_detalle_screen.dart';
import 'obras_form_screen.dart';
import '../widgets/obra_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/loading_widget.dart';

class ObrasScreen extends StatefulWidget {
  const ObrasScreen({super.key});

  @override
  State<ObrasScreen> createState() => _ObrasScreenState();
}

class _ObrasScreenState extends State<ObrasScreen> {
  final ObraService _obraService = ObraService();

  List<Obra> _todasObras = [];
  List<Obra> _obrasFiltradas = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _showOnlyActive = false;

  @override
  void initState() {
    super.initState();
    _cargarObras();
  }

  Future<void> _cargarObras() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final obras = await _obraService.obtenerObrasConDetalles();

      if (!mounted) return;
      setState(() {
        _todasObras = obras;
        _aplicarFiltros();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _mostrarError('Error al cargar las obras: ${e.toString()}');
    }
  }

  void _aplicarFiltros() {
    List<Obra> filtradas = _todasObras;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtradas = filtradas.where((obra) {
        return obra.nombre.toLowerCase().contains(query) ||
            (obra.descripcion?.toLowerCase().contains(query) ?? false) ||
            (obra.cliente?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    if (_showOnlyActive) {
      filtradas = filtradas.where((obra) => obra.estado == 'ACTIVA').toList();
    }

    setState(() => _obrasFiltradas = filtradas);
  }

  void _onSearch(String query) {
    setState(() => _searchQuery = query);
    _aplicarFiltros();
  }

  void _toggleFilterActive() {
    setState(() => _showOnlyActive = !_showOnlyActive);
    _aplicarFiltros();
  }

  void _navegarAFormularioObra({Obra? obra}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ObraFormScreen(obra: obra),
      ),
    ).then((_) => _cargarObras());
  }

  void _verDetallesObra(Obra obra) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ObraDetalleScreen(
          idObra: obra.idObra!,
        ),
      ),
    ).then((_) => _cargarObras());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10121D),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: const Color(0xFF181B35),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.orange, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Gestión de Obras',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withOpacity(0.3))
            ),
            child: Center(
              child: Text(
                '${_obrasFiltradas.length}',
                style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: const Color(0xFF181B35),
            child: SearchBarWidget(
              hintText: 'Buscar nombre o cliente...',
              onSearch: _onSearch,
              onClear: () => _onSearch(''),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('SOLO ACTIVAS'),
                  selected: _showOnlyActive,
                  onSelected: (_) => _toggleFilterActive(),
                  backgroundColor: const Color(0xFF1E2130),
                  selectedColor: Colors.orange.withOpacity(0.2),
                  checkmarkColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _showOnlyActive ? Colors.orange : Colors.white60),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Actualizar lista',
                  onPressed: _cargarObras,
                  icon: const Icon(Icons.sync, color: Colors.blueAccent),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: Colors.orange,
              backgroundColor: const Color(0xFF181B35),
              onRefresh: _cargarObras,
              child: _buildObrasList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navegarAFormularioObra(),
        backgroundColor: Colors.orange,
        elevation: 4,
        icon: const Icon(Icons.add_business_rounded, color: Colors.white),
        label: const Text('NUEVA OBRA',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildObrasList() {
    if (_isLoading && _todasObras.isEmpty) {
      return const LoadingWidget(message: 'Cargando proyectos...');
    }

    if (_obrasFiltradas.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: _InternalEmptyState(
            title: _searchQuery.isEmpty ? 'No hay obras' : 'Sin coincidencias',
            message: _searchQuery.isEmpty
                ? 'Aún no has registrado ninguna obra en el sistema.'
                : 'No encontramos nada que coincida con tu búsqueda.',
            icon: _searchQuery.isEmpty ? Icons.inbox : Icons.search_off,
            actionText: _searchQuery.isEmpty ? 'CREAR PRIMERA OBRA' : 'LIMPIAR FILTROS',

          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
      itemCount: _obrasFiltradas.length,
      itemBuilder: (context, index) {
        final obra = _obrasFiltradas[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: ObraCard(
            obra: obra,
            onEditar: () => _navegarAFormularioObra(obra: obra),
            onFinalizar: obra.estado == 'FINALIZADA' ? null : () => _finalizarObra(obra),
            onEliminar: () => _mostrarConfirmacionEliminar(obra),
            onTap: () => _verDetallesObra(obra),
          ),
        );
      },
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _mostrarConfirmacionEliminar(Obra obra) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181B35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('¿Eliminar Obra?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Se eliminará "${obra.nombre}" y todos sus datos relacionados de forma permanente.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarObra(obra);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarObra(Obra obra) async {
    if (obra.idObra == null) return;
    try {
      await _obraService.eliminarObraCompleta(obra.idObra!);
      setState(() {
        _todasObras.removeWhere((o) => o.idObra == obra.idObra);
        _aplicarFiltros();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${obra.nombre}" eliminada con éxito'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      _mostrarError('Error al eliminar: $e');
    }
  }

  Future<void> _finalizarObra(Obra obra) async {
    if (obra.idObra == null) return;
    try {
      final obraActualizada = Obra(
        idObra: obra.idObra,
        nombre: obra.nombre,
        descripcion: obra.descripcion,
        direccion: obra.direccion,
        cliente: obra.cliente,
        fechaInicio: obra.fechaInicio,
        fechaFin: obra.fechaFin,
        presupuesto: obra.presupuesto,
        estado: 'FINALIZADA',
        porcentajeAvance: 100.0,
      );

      await _obraService.actualizarObra(obraActualizada);
      await _cargarObras();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Obra marcada como FINALIZADA'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      _mostrarError('Error al finalizar: $e');
    }
  }
}

// COMPONENTE EMPTY STATE INTEGRADO
class _InternalEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  //final VoidCallback onAction;
  final String actionText;

  const _InternalEmptyState({
    required this.title,
    required this.message,
    required this.icon,
    //required this.onAction,
    required this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: Colors.orange),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70)),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontSize: 14, color: Colors.white54, height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 24),

          ],
        ),
      ),
    );
  }
}
