import 'package:flutter/material.dart';
import '../../../services/obra_service.dart';
import '../../../models/obra.dart';
import 'obra_detalle_screen.dart';
import 'obras_form_screen.dart';
import '../widgets/obra_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/empty_state.dart';
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
    setState(() => _isLoading = true);
    try {
      // Obtener obras con actividades y porcentaje de avance calculado en DAO
      final obras = await _obraService.obtenerObrasConDetalles();

      setState(() {
        _todasObras = obras;
        _aplicarFiltros();
        _isLoading = false;
      });
    } catch (e) {
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF10121D),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF181B35),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.orange),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Gestión de Obras',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_obrasFiltradas.length} Total',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // BARRA DE BÚSQUEDA
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF181B35),
            child: SearchBarWidget(
              hintText: 'Buscar por nombre o cliente...',
              onSearch: _onSearch,
              onClear: () => _onSearch(''),
            ),
          ),

          // FILTROS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Solo Activas'),
                  selected: _showOnlyActive,
                  onSelected: (_) => _toggleFilterActive(),
                  backgroundColor: const Color(0xFF1E2130),
                  selectedColor: Colors.orange.withOpacity(0.2),
                  checkmarkColor: Colors.orange,
                  labelStyle: TextStyle(
                      color: _showOnlyActive ? Colors.orange : Colors.white60),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _cargarObras,
                  icon: const Icon(Icons.refresh, color: Colors.blue),
                ),
              ],
            ),
          ),

          // LISTADO DE OBRAS
          Expanded(
            child: _buildObrasList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navegarAFormularioObra(),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('NUEVA OBRA',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildObrasList() {
    if (_isLoading) return const LoadingWidget(message: 'Cargando proyectos...');

    if (_obrasFiltradas.isEmpty) {
      return EmptyStateWidget(
        title: 'Sin resultados',
        message: 'No encontramos obras con esos criterios.',
        icon: Icons.search_off,
        actionText: 'Crear Obra',
        onAction: () => _navegarAFormularioObra(),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
      itemCount: _obrasFiltradas.length,
      itemBuilder: (context, index) {
        final obra = _obrasFiltradas[index];
        return ObraCard(
          obra: obra,
          onEditar: () => _navegarAFormularioObra(obra: obra),
          onFinalizar:
          obra.estado == 'FINALIZADA' ? null : () => _finalizarObra(obra),
          onEliminar: () => _mostrarConfirmacionEliminar(obra),
          onTap: () => _verDetallesObra(obra),
        );
      },
    );
  }

  // MÉTODOS AUXILIARES
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarConfirmacionEliminar(Obra obra) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de eliminar la obra "${obra.nombre}"?\n\n'
              'Esta acción eliminará también todas las actividades y avances relacionados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _eliminarObra(obra);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarObra(Obra obra) async {
    if (obra.idObra == null) {
      _mostrarError('La obra no tiene ID válido');
      return;
    }

    try {
      await _obraService.eliminarObraCompleta(obra.idObra!);

      setState(() {
        _todasObras.removeWhere((o) => o.idObra == obra.idObra);
        _obrasFiltradas.removeWhere((o) => o.idObra == obra.idObra);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Obra "${obra.nombre}" eliminada'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _mostrarError('Error al eliminar obra: ${e.toString()}');
    }
  }

  Future<void> _finalizarObra(Obra obra) async {
    if (obra.idObra == null) {
      _mostrarError('La obra no tiene ID válido');
      return;
    }

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
        porcentajeAvance: obra.porcentajeAvance,
      );

      await _obraService.actualizarObra(obraActualizada);

      setState(() {
        final index = _todasObras.indexWhere((o) => o.idObra == obra.idObra);
        if (index != -1) _todasObras[index] = obraActualizada;

        final filtradoIndex =
        _obrasFiltradas.indexWhere((o) => o.idObra == obra.idObra);
        if (filtradoIndex != -1) _obrasFiltradas[filtradoIndex] =
            obraActualizada;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Obra finalizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _mostrarError('Error al finalizar obra: ${e.toString()}');
    }
  }
}
