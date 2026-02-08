import 'package:flutter/material.dart';

import '../../../models/gestion_obras/obra.dart';


class ObraCard extends StatelessWidget {
  final Obra obra;
  final VoidCallback? onEditar;
  final VoidCallback? onFinalizar;
  final VoidCallback? onEliminar;
  final VoidCallback? onTap;

  const ObraCard({
    super.key,
    required this.obra,
    this.onEditar,
    this.onFinalizar,
    this.onEliminar,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // UX: Usamos el color de estado de la obra para acentuar detalles
    final Color colorEstado = obra.estadoColor;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // UX: Fondo oscuro coherente con el resto de la app
      color: const Color(0xFF181B35).withOpacity(0.9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white10, width: 1),
      ),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CABECERA: Nombre y Badge de Estado
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          obra.nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (obra.cliente != null)
                          Text(
                            obra.cliente!,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(colorEstado),
                ],
              ),

              const SizedBox(height: 16),

              // SECCIÓN DE PROGRESO (UX: Más visual y limpia)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progreso del proyecto',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  Text(
                    '${obra.porcentajeAvance?.toStringAsFixed(1) ?? 0}%',
                    style: TextStyle(
                      color: colorEstado,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (obra.porcentajeAvance ?? 0) / 100,
                  backgroundColor: Colors.white.withOpacity(0.05),
                  color: colorEstado,
                  minHeight: 8,
                ),
              ),

              const SizedBox(height: 16),

              // INFORMACIÓN ADICIONAL (Iconos con colores suaves)
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (obra.direccion != null && obra.direccion!.isNotEmpty)
                    _buildInfoItem(Icons.location_on_outlined, obra.direccion!),
                  _buildInfoItem(Icons.calendar_today_outlined, obra.fechaInicioFormatted),
                  if (obra.presupuesto != null)
                    _buildInfoItem(
                        Icons.monetization_on_outlined,
                        '\$${obra.presupuesto!.toStringAsFixed(2)}',
                        color: Colors.greenAccent
                    ),
                ],
              ),

              const Divider(height: 32, color: Colors.white10),

              // BOTONES DE ACCIÓN (UX: Botones más estilizados y táctiles)
              Row(
                children: [
                  _buildCircularAction(
                    icon: Icons.edit_outlined,
                    color: Colors.blueAccent,
                    onPressed: onEditar,
                  ),
                  const SizedBox(width: 12),
                  _buildCircularAction(
                    icon: Icons.delete_outline,
                    color: Colors.redAccent,
                    onPressed: onEliminar,
                  ),
                  const Spacer(),
                  _buildMainAction(
                    label: obra.estado == 'FINALIZADA' ? 'COMPLETADA' : 'FINALIZAR',
                    icon: Icons.check_circle_outline,
                    color: obra.estado == 'FINALIZADA' ? Colors.green : Colors.orange,
                    onPressed: obra.estado == 'FINALIZADA' ? null : onFinalizar,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para el Badge de estado (Esquina superior derecha)
  Widget _buildStatusBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        obra.estado.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Widget para items de información (Dirección, fecha, etc)
  Widget _buildInfoItem(IconData icon, String text, {Color color = Colors.white70}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.orange.withOpacity(0.8), size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }

  // Botones secundarios circulares (Editar/Eliminar)
  Widget _buildCircularAction({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  // Botón principal (Finalizar)
  Widget _buildMainAction({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Colors.white10,
        disabledForegroundColor: Colors.white30,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }
}
