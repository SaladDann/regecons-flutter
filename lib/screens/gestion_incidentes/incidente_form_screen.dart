import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/gestion_incidentes/incidente.dart';
import '../../models/gestion_obras/obra.dart';
import '../../services/gestion_incidentes/incidente_service.dart';

class IncidenteFormScreen extends StatefulWidget {
  final Obra obra;
  final Incidente? incidente;

  const IncidenteFormScreen({
    super.key,
    required this.obra,
    this.incidente,
  });

  @override
  State<IncidenteFormScreen> createState() => _IncidenteFormScreenState();
}

class _IncidenteFormScreenState extends State<IncidenteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final IncidenteService _service = IncidenteService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _descripcionCtrl = TextEditingController();

  late String _tipo;
  late String _severidad;
  late DateTime _fechaEvento;
  String? _rutaFotoTemporal;
  late List<String> _evidencias;

  final Map<String, dynamic> _configTipos = {
    'ACCIDENTE': {'icon': Icons.emergency, 'color': Colors.redAccent},
    'INCIDENTE': {'icon': Icons.warning_rounded, 'color': Colors.orange},
    'CONDICION_INSEGURA': {'icon': Icons.construction, 'color': Colors.amber},
    'ACTO_INSEGURO': {'icon': Icons.person_off, 'color': Colors.yellow},
    'FALLA_EQUIPO': {'icon': Icons.settings_suggest, 'color': Colors.blueAccent},
    'DERRAME_MATERIAL': {'icon': Icons.opacity, 'color': Colors.cyan},
    'OTRO': {'icon': Icons.more_horiz, 'color': Colors.grey},
  };

  @override
  void initState() {
    super.initState();
    final incidente = widget.incidente;
    _tipo = incidente?.tipo ?? 'INCIDENTE';
    _severidad = incidente?.severidad ?? 'BAJA';
    _descripcionCtrl.text = incidente?.descripcion ?? '';
    _fechaEvento = incidente?.fechaEvento ?? DateTime.now();
    _evidencias = List.from(incidente?.evidenciasFoto ?? []);
    if (_evidencias.isNotEmpty) _rutaFotoTemporal = _evidencias.first;
  }

  bool get _esEdicion => widget.incidente != null;

  Future<void> _gestionarCaptura() async {
    final ImageSource? fuente = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1A1D2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("EVIDENCIA FOTOGRÁFICA",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSourceBtn(Icons.camera_alt_rounded, "CÁMARA", ImageSource.camera, Colors.orange),
                  _buildSourceBtn(Icons.photo_library_rounded, "GALERÍA", ImageSource.gallery, Colors.blue),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (fuente != null) {
      final XFile? photo = await _picker.pickImage(source: fuente, imageQuality: 70);
      if (photo != null) {
        setState(() {
          _rutaFotoTemporal = photo.path;
          if (_evidencias.isEmpty) _evidencias.add(photo.path); else _evidencias[0] = photo.path;
        });
      }
    }
  }

  Widget _buildSourceBtn(IconData icon, String label, ImageSource source, Color color) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, source),
      child: Column(
        children: [
          CircleAvatar(radius: 30, backgroundColor: color.withOpacity(0.15), child: Icon(icon, color: color, size: 30)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final incidente = Incidente(
      idReporte: widget.incidente?.idReporte,
      idObra: widget.obra.idObra!,
      idUsuario: widget.incidente?.idUsuario ?? 1,
      tipo: _tipo,
      severidad: _severidad,
      descripcion: _descripcionCtrl.text.trim(),
      fechaEvento: _fechaEvento,
      estado: widget.incidente?.estado ?? 'REPORTADO',
      evidenciasFoto: _evidencias,
    );

    try {
      await _service.guardarIncidente(obra: widget.obra, incidente: incidente);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  void dispose() {
    _descripcionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F111A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A1D2E),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _esEdicion ? 'EDITAR REPORTE' : 'NUEVO REPORTE',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderObra(),
              const SizedBox(height: 25),
              _buildLabel('CATEGORÍA DEL INCIDENTE'),
              _buildTipoDropdown(),
              const SizedBox(height: 25),
              _buildLabel('NIVEL DE SEVERIDAD'),
              _buildSeveridadChips(),
              const SizedBox(height: 25),
              _buildLabel('DESCRIPCIÓN DE LOS HECHOS'),
              _buildDescriptionField(),
              const SizedBox(height: 25),
              _buildLabel('EVIDENCIA VISUAL'),
              _buildFotoBox(),
              const SizedBox(height: 35),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 4),
    child: Text(text, style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
  );

  Widget _buildHeaderObra() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10)
    ),
    child: Row(
      children: [
        const Icon(Icons.location_city, color: Colors.orange, size: 20),
        const SizedBox(width: 12),
        Expanded(
            child: Text(
                widget.obra.nombre,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
            )
        ),
      ],
    ),
  );

  Widget _buildTipoDropdown() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: const Color(0xFF1A1D2E), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
    child: DropdownButtonHideUnderline(
      child: DropdownButtonFormField<String>(
        value: _tipo,
        dropdownColor: const Color(0xFF1A1D2E),
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(border: InputBorder.none),
        items: _configTipos.entries.map((e) => DropdownMenuItem(
          value: e.key,
          child: Row(children: [Icon(e.value['icon'], color: e.value['color'], size: 20), const SizedBox(width: 10), Text(e.key)]),
        )).toList(),
        onChanged: (v) => setState(() => _tipo = v!),
      ),
    ),
  );

  Widget _buildSeveridadChips() {
    final sevColors = {'BAJA': Colors.green, 'MEDIA': Colors.yellow, 'ALTA': Colors.orange, 'CRITICA': Colors.red};
    return Row(
      children: sevColors.entries.map((entry) {
        bool isSelected = _severidad == entry.key;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _severidad = entry.key),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? entry.value : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? entry.value : Colors.white24),
              ),
              child: Center(
                child: Text(entry.key,
                    style: TextStyle(color: isSelected ? Colors.black : Colors.white60, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDescriptionField() => TextFormField(
    controller: _descripcionCtrl, // SOLUCIÓN: Usa el controller
    maxLines: 3,
    style: const TextStyle(color: Colors.white, fontSize: 14),
    decoration: InputDecoration(
      filled: true,
      fillColor: const Color(0xFF1A1D2E),
      hintText: "Escriba aquí...",
      hintStyle: const TextStyle(color: Colors.white24),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orange)),
    ),
    validator: (v) => (v == null || v.trim().isEmpty) ? 'La descripción es obligatoria' : null, // SOLUCIÓN: Agrega validador
  );

  Widget _buildFotoBox() {
    return GestureDetector(
      onTap: _gestionarCaptura,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D2E),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _rutaFotoTemporal != null ? Colors.orange : Colors.white10, width: 2),
        ),
        child: _rutaFotoTemporal == null
            ? const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: Colors.orange, size: 35),
            SizedBox(height: 10),
            Text('AÑADIR FOTO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        )
            : ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _rutaFotoTemporal!.startsWith('http')
                  ? Image.network(_rutaFotoTemporal!, fit: BoxFit.cover)
                  : Image.file(File(_rutaFotoTemporal!), fit: BoxFit.cover),
              Positioned(
                right: 10, top: 10,
                child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _gestionarCaptura)
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() => SizedBox(
    width: double.infinity,
    height: 60,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _guardar,
      child: Text(_esEdicion ? 'ACTUALIZAR' : 'GUARDAR REPORTE',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
    ),
  );
}