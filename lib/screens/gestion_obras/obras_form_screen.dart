import 'package:flutter/material.dart';
import '../../models/gestion_obras/obra.dart';
import '../../services/gestion_obras/obra_service.dart';

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

  // --- MEJORA UX: Notificaciones estandarizadas ---
  void _notificar(String msj, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msj, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: error ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _mostrarConfirmacionCancelar() {
    // Si no hay cambios, salimos directamente (Mejora UX: ahorro de clics)
    if (!_hayCambios()) {
      Navigator.pop(context);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181B35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('¿Descartar cambios?', style: TextStyle(color: Colors.white)),
        content: const Text('Tienes cambios sin guardar que se perderán.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('SEGUIR EDITANDO', style: TextStyle(color: Colors.orange)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cierra diálogo
              Navigator.pop(context); // Sale de pantalla
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('DESCARTAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  bool _hayCambios() {
    final o = widget.obra;
    if (nombreCtrl.text != (o?.nombre ?? '')) return true;
    if (descripcionCtrl.text != (o?.descripcion ?? '')) return true;
    if (estado != (o?.estado ?? 'PLANIFICADA')) return true;
    return false; // Simplificado para el ejemplo
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    if (fechaInicio != null && fechaFin != null && fechaFin!.isBefore(fechaInicio!)) {
      _notificar('La fecha fin no puede ser anterior al inicio', error: true);
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
        _notificar(esEdicion ? 'Obra actualizada' : 'Obra registrada');
        // MEJORA UX: Cerramos automáticamente al tener éxito
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _notificar('Error: $e', error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _pickFecha(bool inicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (inicio ? fechaInicio : fechaFin) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: Colors.orange,
              onPrimary: Colors.white,
              surface: Color(0xFF181B35)
          ),
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
        backgroundColor: const Color(0xFF181B35).withOpacity(0.9),
        elevation: 0,
        centerTitle: true,
        foregroundColor: Colors.white,
        title: Text(esEdicion ? 'Editar Obra' : 'Nueva Obra',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.close), // UX: Icono X para cerrar formularios
          onPressed: _mostrarConfirmacionCancelar,
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: Image.asset('assets/images/login_bg.png', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.black.withOpacity(0.65))),
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _seccionTitulo('Información General'),
                  _input(nombreCtrl, 'Nombre de la Obra', icon: Icons.business, requerido: true),
                  _input(descripcionCtrl, 'Descripción', icon: Icons.notes, multilinea: true),

                  _seccionTitulo('Detalles de Contacto'),
                  _input(clienteCtrl, 'Cliente', icon: Icons.person_outline),
                  _input(direccionCtrl, 'Dirección', icon: Icons.location_on_outlined),

                  _seccionTitulo('Presupuesto y Tiempos'),
                  _input(presupuestoCtrl, 'Presupuesto total', icon: Icons.monetization_on_outlined, numero: true),

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
                    onChanged: (v) => setState(() => estado = v!),
                    decoration: _decor('Estado', Icons.info_outline),
                    items: ['PLANIFICADA', 'ACTIVA', 'SUSPENDIDA', 'FINALIZADA']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  ),
                  const SizedBox(height: 40),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _seccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 12, left: 4),
      child: Text(titulo.toUpperCase(),
          style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _guardando ? null : _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: _guardando
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(esEdicion ? 'GUARDAR CAMBIOS' : 'REGISTRAR OBRA',
                style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _mostrarConfirmacionCancelar,
          child: const Text('CANCELAR', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _input(TextEditingController c, String label, {required IconData icon, bool requerido = false, bool multilinea = false, bool numero = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        maxLines: multilinea ? 3 : 1,
        keyboardType: numero ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        validator: requerido ? (v) => v == null || v.isEmpty ? 'Campo requerido' : null : null,
        decoration: _decor(label, icon),
      ),
    );
  }

  InputDecoration _decor(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: Colors.orange, size: 20),
    labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
    filled: true,
    fillColor: const Color(0xFF181B35).withOpacity(0.6),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.white10),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.orange, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
  );

  Widget _fechaBtn(String label, DateTime? fecha, VoidCallback onTap, IconData icon) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF181B35).withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.orange, size: 18),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  fecha == null ? label : "${fecha.day}/${fecha.month}/${fecha.year}",
                  style: TextStyle(color: fecha == null ? Colors.white60 : Colors.white, fontSize: 13),
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
