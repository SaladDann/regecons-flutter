import 'package:sqflite/sqflite.dart';

class ReporteDao {
  final Database db;
  ReporteDao(this.db);

  // Cuenta incidentes en un rango de fechas para una obra específica
  Future<int> contarIncidentes(int idObra, int inicio, int fin) async {
    final result = await db.rawQuery('''
      SELECT COUNT(*) as total FROM reportes_seguridad 
      WHERE id_obra = ? AND fecha_evento BETWEEN ? AND ?
    ''', [idObra, inicio, fin]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Cuenta riesgos activos (Severidad ALTA o CRITICA)
  Future<int> contarRiesgosActivos(int idObra) async {
    final result = await db.rawQuery('''
      SELECT COUNT(*) FROM reportes_seguridad 
      WHERE id_obra = ? AND severidad IN ('ALTA', 'CRITICA') AND estado != 'RESUELTO'
    ''', [idObra]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Calcula el avance promedio basado en actividades finalizadas
  Future<double> obtenerAvanceGlobal(int idObra) async {
    final result = await db.rawQuery('''
      SELECT 
        (CAST(SUM(CASE WHEN estado = 'FINALIZADA' THEN 1 ELSE 0 END) AS REAL) / COUNT(*)) * 100 as progreso
      FROM actividades WHERE id_obra = ?
    ''', [idObra]);
    return (result.first['progreso'] as num?)?.toDouble() ?? 0.0;
  }
}