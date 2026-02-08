import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../db/app_db.dart';
import '../../db/daos/gestion_obras/avance_dao.dart';
import '../../models/gestion_obras/avance.dart';

class AvancesActividadScreen extends StatefulWidget {
  final int idActividad;
  final int idObra;
  final String nombreActividad;

  const AvancesActividadScreen({
    super.key,
    required this.idActividad,
    required this.idObra,
    required this.nombreActividad,
  });

  @override
  State<AvancesActividadScreen> createState() => _AvancesActividadScreenState();
}

class _AvancesActividadScreenState extends State<AvancesActividadScreen> {
  final _picker = ImagePicker();
  late AvanceDao _avanceDao;
  List<Avance> _avances = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _initDao();
  }

  Future<void> _initDao() async {
    final db = await AppDatabase().database;
    _avanceDao = AvanceDao(db);
    await _cargarAvances();
  }

  Future<void> _cargarAvances() async {
    setState(() => _cargando = true);
    final avances = await _avanceDao.getByActividad(widget.idActividad);
    avances.sort((a, b) => b.fecha.compareTo(a.fecha));
    setState(() {
      _avances = avances;
      _cargando = false;
    });
  }

  void _mensaje(String texto, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(esError ? Icons.warning_amber : Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 10),
            Text(texto),
          ],
        ),
        backgroundColor: esError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ================= VISUALIZADOR DE FOTO (MEJORA UX) =================
  void _verFotoGrande(String path) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(File(path), fit: BoxFit.contain),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  // ================= NUEVO MÉTODO IDÉNTICO AL DEL INCIDENTE =================
  Future<String?> _gestionarCaptura() async {
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
      try {
        final XFile? photo = await _picker.pickImage(source: fuente, imageQuality: 70);
        return photo?.path;
      } catch (e) {
        _mensaje('Error al capturar la foto: $e', esError: true);
        return null;
      }
    }
    return null;
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

  void _mostrarFormularioAvance() {
    final descripcionCtrl = TextEditingController();
    final horasCtrl = TextEditingController();
    String? rutaFotoTemporal;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF181B35),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20, right: 20, top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                  const SizedBox(height: 20),
                  const Text('Nuevo Registro de Avance', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: descripcionCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecor('¿Qué se hizo hoy?', Icons.description),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: horasCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecor('Horas dedicadas', Icons.timer_outlined),
                  ),
                  const SizedBox(height: 16),

                  // ================= CAJA DE FOTO MEJORADA =================
                  InkWell(
                    onTap: () async {
                      String? path = await _gestionarCaptura();
                      if (path != null) setModalState(() => rutaFotoTemporal = path);
                    },
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: rutaFotoTemporal != null ? Colors.orange : Colors.white10, width: 2),
                      ),
                      child: rutaFotoTemporal == null
                          ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: Colors.orange, size: 40),
                          SizedBox(height: 8),
                          Text('SUBIR EVIDENCIA VISUAL', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      )
                          : Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: Image.file(File(rutaFotoTemporal!), fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 8, top: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                icon: const Icon(Icons.refresh, color: Colors.white),
                                onPressed: () async {
                                  String? path = await _gestionarCaptura();
                                  if (path != null) setModalState(() => rutaFotoTemporal = path);
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                      ),
                      onPressed: () async {
                        if (descripcionCtrl.text.trim().isEmpty || rutaFotoTemporal == null) {
                          _mensaje('Descripción y foto son obligatorias', esError: true);
                          return;
                        }
                        final nuevo = Avance(
                          idActividad: widget.idActividad,
                          idObra: widget.idObra,
                          fecha: DateTime.now(),
                          horasTrabajadas: double.tryParse(horasCtrl.text) ?? 0,
                          descripcion: descripcionCtrl.text.trim(),
                          evidenciaFoto: rutaFotoTemporal,
                          estado: 'REGISTRADO',
                          sincronizado: 0,
                        );
                        await _avanceDao.insert(nuevo);
                        Navigator.pop(context);
                        _cargarAvances();
                        _mensaje('Avance registrado correctamente');
                      },
                      child: const Text('GUARDAR AVANCE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.orange, size: 22),
      filled: true,
      fillColor: Colors.black26,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white10)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.orange, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F1F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181B35),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text('AVANCES DE ACTIVIDAD', style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
            Text(widget.nombreActividad, style: const TextStyle(fontSize: 16, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormularioAvance,
        backgroundColor: Colors.orange,
        elevation: 4,
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text('NUEVO AVANCE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _avances.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: _avances.length,
        itemBuilder: (context, index) => _itemAvance(_avances[index]),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text('No hay avances registrados aún', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Pulsa el botón inferior para empezar', style: TextStyle(color: Colors.white24, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _itemAvance(Avance avance) {
    final String hora = "${avance.fecha.hour.toString().padLeft(2, '0')}:${avance.fecha.minute.toString().padLeft(2, '0')}";
    final String fecha = "${avance.fecha.day}/${avance.fecha.month}/${avance.fecha.year}";

    return Card(
      color: const Color(0xFF181B35).withOpacity(0.9),
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 4,
      shadowColor: Colors.black45,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del Card
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF0D0F1F),
              child: Icon(Icons.construction, color: Colors.orange, size: 20),
            ),
            title: Text(fecha, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('A las $hora', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${avance.horasTrabajadas}h', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 24),
                  onPressed: () => _confirmarEliminar(avance),
                ),
              ],
            ),
          ),

          // Cuerpo del Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              avance.descripcion ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            ),
          ),

          // Evidencia Visual con UX de click
          if (avance.evidenciaFoto != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: InkWell(
                onTap: () => _verFotoGrande(avance.evidenciaFoto!),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Hero( // Animación fluida
                        tag: 'img_${avance.idAvance}',
                        child: Image.file(
                          File(avance.evidenciaFoto!),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12, right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30)),
                        child: const Icon(Icons.fullscreen, color: Colors.white, size: 20),
                      ),
                    )
                  ],
                ),
              ),
            ),

          // Footer del Card (Indicador de sincronización local)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Icon(Icons.cloud_done_outlined, size: 14, color: Colors.blue.withOpacity(0.5)),
                const SizedBox(width: 5),
                Text('Guardado localmente', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _confirmarEliminar(Avance avance) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF181B35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar registro?', style: TextStyle(color: Colors.white)),
        content: const Text('Esta acción no se puede deshacer.', style: TextStyle(color: Colors.white60)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('MANTENER', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
    if (confirmar == true && avance.idAvance != null) {
      await _avanceDao.delete(avance.idAvance!);
      _cargarAvances();
      _mensaje('El registro ha sido eliminado', esError: true);
    }
  }
}


