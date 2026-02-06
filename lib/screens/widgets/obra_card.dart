import 'package:flutter/material.dart';
import '../../../models/obra.dart';

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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CABECERA: Nombre y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      obra.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: obra.estadoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: obra.estadoColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          obra.estadoIcon,
                          color: obra.estadoColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          obra.estado,
                          style: TextStyle(
                            color: obra.estadoColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // DESCRIPCIÓN
              if (obra.descripcion != null && obra.descripcion!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    obra.descripcion!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // AVANCE
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Avance: ${obra.porcentajeAvance?.toStringAsFixed(1) ?? 0}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (obra.cliente != null && obra.cliente!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.blue,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              obra.cliente!,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: (obra.porcentajeAvance ?? 0) / 100,
                      backgroundColor: Colors.grey[300],
                      color: obra.estadoColor,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),

              // INFORMACIÓN ADICIONAL
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    if (obra.direccion != null && obra.direccion!.isNotEmpty)
                      _buildInfoItem(
                        icon: Icons.location_on,
                        text: obra.direccion!,
                        color: Colors.green,
                      ),
                    if (obra.fechaInicio != null)
                      _buildInfoItem(
                        icon: Icons.calendar_today,
                        text: 'Inicio: ${obra.fechaInicioFormatted}',
                        color: Colors.orange,
                      ),
                    if (obra.fechaFin != null)
                      _buildInfoItem(
                        icon: Icons.event_available,
                        text: 'Fin: ${obra.fechaFinFormatted}',
                        color: Colors.red,
                      ),
                    if (obra.presupuesto != null)
                      _buildInfoItem(
                        icon: Icons.attach_money,
                        text: '\$${obra.presupuesto!.toStringAsFixed(2)}',
                        color: Colors.green,
                      ),
                  ],
                ),
              ),

              // BOTONES DE ACCIÓN
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.edit,
                        label: 'Editar',
                        color: const Color(0xFFFBC02D),
                        onPressed: onEditar,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.check_circle,
                        label: obra.estado == 'FINALIZADA' ? 'Finalizada' : 'Finalizar',
                        color: obra.estado == 'FINALIZADA'
                            ? Colors.green
                            : const Color(0xFF4CAF50),
                        onPressed: obra.estado == 'FINALIZADA' ? null : onFinalizar,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.delete,
                        label: 'Borrar',
                        color: const Color(0xFFF44336),
                        onPressed: onEliminar,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: color, width: 1),
        ),
        elevation: 0,
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
