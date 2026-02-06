import 'package:flutter/material.dart';
import '../../models/actividad.dart';

class ActividadListItem extends StatelessWidget {
  final Actividad actividad;
  final VoidCallback? onTap;

  const ActividadListItem({
    super.key,
    required this.actividad,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF181B35).withOpacity(0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ───── Header ─────
            Row(
              children: [
                Icon(
                  actividad.estadoIcon,
                  color: actividad.estadoColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    actividad.nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // ───── Progreso ─────
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (actividad.porcentajeCompletado ?? 0) / 100,
                minHeight: 6,
                backgroundColor: Colors.white12,
                color: actividad.estadoColor,
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                actividad.porcentajeCompletadoTexto ?? '0%',
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


