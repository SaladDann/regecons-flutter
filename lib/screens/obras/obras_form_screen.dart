import 'package:flutter/material.dart';
import '../../models/obra.dart';
import '../../services/obra_service.dart';

class ObraFormScreen extends StatefulWidget {
  final Obra? obra;
  const ObraFormScreen({super.key, this.obra});

  @override
  State<ObraFormScreen> createState() => _ObraFormScreenState();
}

class _ObraFormScreenState extends State<ObraFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _obraService = ObraService();

  late TextEditingController nombreCtrl;
  late TextEditingController descripcionCtrl;
  late TextEditingController clienteCtrl;
  late TextEditingController direccionCtrl;
  late TextEditingController presupuestoCtrl;

  DateTime? fechaInicio;
  DateTime? fechaFin;
  String estado = 'PLANIFICADA';

  bool get esEdicion => widget.obra != null;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final o = widget.obra;
    nombreCtrl = TextEditingController(text: o?.nombre ?? '');
    descripcionCtrl = TextEditingController(text: o?.descripcion ?? '');
    clienteCtrl = TextEditingController(text: o?.cliente ?? '');
    direccionCtrl = TextEditingController(text: o?.direccion ?? '');
    presupuestoCtrl = TextEditingController(text: o?.presupuesto?.toString() ?? '');
    fechaInicio = o?.fechaInicio;
    fechaFin = o?.fechaFin;
    estado = o?.estado ?? 'PLANIFICADA';
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    descripcionCtrl.dispose();
    clienteCtrl.dispose();
    direccionCtrl.dispose();
    presupuestoCtrl.dispose();
    super.dispose();
  }

  // --- LÓGICA DE DIÁLOGOS Y GUARDADO ---

  void _mostrarConfirmacionCancelar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181B35),
        title: const Text('¿Descartar cambios?', style: TextStyle(color: Colors.white)),
        content: const Text('Los datos no guardados se perderán.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CONTINUAR EDITANDO', style: TextStyle(color: Colors.orange)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cierra el diálogo
              Navigator.pop(context); // Sale de la pantalla
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DESCARTAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    // Validación lógica de fechas
    if (fechaInicio != null && fechaFin != null && fechaFin!.isBefore(fechaInicio!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha fin no puede ser anterior a la de inicio'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _guardando = true);
    final obra = Obra(
      idObra: widget.obra?.idObra,
      nombre: nombreCtrl.text.trim(),
      descripcion: descripcionCtrl.text.trim(),
      cliente: clienteCtrl.text.trim(),
      direccion: direccionCtrl.text.trim(),
      presupuesto: double.tryParse(presupuestoCtrl.text),
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      estado: estado,
      porcentajeAvance: widget.obra?.porcentajeAvance ?? 0,
    );

    try {
      esEdicion ? await _obraService.actualizarObra(obra) : await _obraService.crearObra(obra);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(esEdicion ? 'Obra actualizada correctamente' : 'Obra registrada correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        // NOTA: No cerramos la pantalla (Navigator.pop) para que el usuario decida cuándo salir
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _pickFecha(bool inicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Colors.orange, onPrimary: Colors.white, surface: Color(0xFF181B35)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => inicio ? fechaInicio = picked : fechaFin = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF181B35).withOpacity(0.8),
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(esEdicion ? 'Editar Obra' : 'Nueva Obra'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _mostrarConfirmacionCancelar,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/login_bg.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.55)),
          ),
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _input(nombreCtrl, 'Nombre de la Obra', requerido: true),
                  _input(descripcionCtrl, 'Descripción', multilinea: true),
                  _input(clienteCtrl, 'Cliente'),
                  _input(direccionCtrl, 'Dirección'),
                  _input(presupuestoCtrl, 'Presupuesto', numero: true),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _fechaBtn('Inicio', fechaInicio, () => _pickFecha(true), Icons.calendar_today),
                      const SizedBox(width: 12),
                      _fechaBtn('Fin', fechaFin, () => _pickFecha(false), Icons.event_available),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: estado,
                    dropdownColor: const Color(0xFF181B35),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'PLANIFICADA', child: Text('PLANIFICADA')),
                      DropdownMenuItem(value: 'ACTIVA', child: Text('ACTIVA')),
                      DropdownMenuItem(value: 'SUSPENDIDA', child: Text('SUSPENDIDA')),
                      DropdownMenuItem(value: 'FINALIZADA', child: Text('FINALIZADA')),
                    ],
                    onChanged: (v) => setState(() => estado = v!),
                    decoration: _decor('Estado'),
                  ),
                  const SizedBox(height: 30),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE ESTILO ---

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _mostrarConfirmacionCancelar,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.black26,
            ),
            child: const Text('CANCELAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _guardando ? null : _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _guardando
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(esEdicion ? 'ACTUALIZAR' : 'REGISTRAR', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _input(TextEditingController c, String label, {bool requerido = false, bool multilinea = false, bool numero = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        maxLines: multilinea ? 3 : 1,
        keyboardType: numero ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        validator: requerido ? (v) => v == null || v.isEmpty ? 'Requerido' : null : null,
        decoration: _decor(label).copyWith(
          prefixIcon: numero ? const Icon(Icons.attach_money, color: Colors.greenAccent) : null,
        ),
      ),
    );
  }

  InputDecoration _decor(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    filled: true,
    fillColor: const Color(0xFF181B35).withOpacity(0.7),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.white30),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.orange, width: 2),
    ),
  );

  Widget _fechaBtn(String label, DateTime? fecha, VoidCallback onTap, IconData icon) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF181B35).withOpacity(0.7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white30),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  fecha == null ? label : "${fecha.day}/${fecha.month}/${fecha.year}",
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
