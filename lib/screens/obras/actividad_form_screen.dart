import 'package:flutter/material.dart';
import '../../models/actividad.dart';
import '../../services/actividad_service.dart';

class ActividadFormScreen extends StatefulWidget {
  final int idObra;
  final Actividad? actividad;

  const ActividadFormScreen({
    super.key,
    required this.idObra,
    this.actividad,
  });

  @override
  State<ActividadFormScreen> createState() => _ActividadFormScreenState();
}

class _ActividadFormScreenState extends State<ActividadFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = ActividadService();

  late TextEditingController _nombreCtrl;
  late TextEditingController _descripcionCtrl;

  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.actividad?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: widget.actividad?.descripcion ?? '');
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      if (widget.actividad == null) {
        await _service.crearActividad(
          idObra: widget.idObra,
          nombre: _nombreCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim(),
        );
      } else {
        final act = widget.actividad!.copyWith(
          nombre: _nombreCtrl.text.trim(),
          descripcion: _descripcionCtrl.text.trim(),
        );
        await _service.actualizarActividad(act);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF181B35),
        foregroundColor: Colors.white,
        title: Text(widget.actividad == null ? 'Nueva Actividad' : 'Editar Actividad'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/login_bg.png', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.65)),
          ),
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _input(_nombreCtrl, 'Nombre', Icons.assignment, required: true),
                  _input(_descripcionCtrl, 'Descripción', Icons.notes),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _guardando ? null : _guardar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: _guardando
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Guardar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(
      TextEditingController ctrl,
      String label,
      IconData icon, {
        bool required = false,
        bool isNumber = false,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.orange),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF181B35).withOpacity(0.85),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (v) {
          if (required && (v == null || v.isEmpty)) {
            return 'Campo requerido';
          }
          if (isNumber && double.tryParse(v ?? '') == null) {
            return 'Número inválido';
          }
          return null;
        },
      ),
    );
  }
}

